// Rcpp interface for SAS XPORT read/write.
//
// The reader memory-maps the input file (POSIX `mmap`), decodes its header
// once, then streams row data into pre-allocated R column vectors. Numeric
// columns are decoded in parallel by a `std::thread` worker pool; string
// columns are finalised serially on the main thread because the R API is not
// thread-safe.
//
// Total parser scratch is bounded by:
//   * the row-buffer per writer (rowLen bytes, ~few KB)
//   * the 64 KB writer output buffer
//   * one `double` and side-bookkeeping array per numeric column (size = rowCount,
//     but these are part of the returned R vectors, not scratch)
//   * per-thread tagged-missing index lists (typically empty)
// regardless of file size.

#include <Rcpp.h>

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <exception>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include "core/types.hpp"
#include "xpt/mmap_file.hpp"
#include "xpt/parser.hpp"
#include "xpt/writer.hpp"
#include "xpt_epoch.hpp"

using namespace Rcpp;

namespace {

// Normalise format strings stored in column attributes to canonical
// "<NAME><width>.<dec>" form.
std::string canonicalFormat(const std::string &fmt) {
    if (fmt.empty()) return fmt;
    if (fmt.find('.') != std::string::npos) return fmt;
    return fmt + ".";
}

// ----- Resolve thread count --------------------------------------------------

unsigned resolveThreadCount(SEXP nThreadsSEXP) {
    unsigned hw = std::max(1u, std::thread::hardware_concurrency());
    if (Rf_isNull(nThreadsSEXP)) {
        // Default: leave one core for the main thread + the OS.
        return std::max(1u, hw > 1 ? hw - 1 : 1u);
    }
    int n = Rf_asInteger(nThreadsSEXP);
    if (n == NA_INTEGER || n < 1) return 1u;
    return static_cast<unsigned>(std::min<int>(n, static_cast<int>(hw * 4)));
}

// ----- Numeric decode per column over a row range ---------------------------
//
// Writes into `outValue[r]` and `outFlag[r]` (for r in [rowBegin, rowEnd)).
// Tagged-missing entries are appended to `tagsOut` as (rowIdx, tagChar).

struct TagEntry {
    std::uint32_t row;
    char tag;
};

void decodeNumericChunk(const std::uint8_t *base,
                        std::size_t rowLen,
                        std::size_t rowBegin,
                        std::size_t rowEnd,
                        const cxpt::XptVariable &var,
                        double *outValue,
                        std::uint8_t *outFlag,
                        std::vector<TagEntry> &tagsOut) {
    const std::size_t off = var.byteOffset;
    const std::size_t width = var.storageWidth;
    for (std::size_t r = rowBegin; r < rowEnd; ++r) {
        const std::uint8_t *p = base + r * rowLen + off;
        double v = 0.0;
        std::uint8_t flag = 0;
        char tag = 0;
        cxpt::decodeNumericFast(p, width, &v, &flag, &tag);
        if (flag == 1) {
            outValue[r - rowBegin] = v;
            outFlag[r - rowBegin] = 1;
        } else if (flag == 2) {
            outValue[r - rowBegin] = NA_REAL;
            outFlag[r - rowBegin] = 2;
            tagsOut.push_back({static_cast<std::uint32_t>(r), tag});
        } else {
            outValue[r - rowBegin] = NA_REAL;
            outFlag[r - rowBegin] = 0;
        }
    }
}

// ----- Build R columns from schema + mmap ------------------------------------

SEXP buildColumns(const cxpt::MappedFile &mf,
                  std::size_t fileBaseOffset,   // offset into mmap of member data start
                  const cxpt::XptSchema &schema,
                  bool convert_dates,
                  unsigned nThreads) {
    const std::size_t ncol = schema.variables.size();
    const std::size_t nrow = schema.rowCount;
    const std::size_t rowLen = schema.rowLen;

    List cols(ncol);
    CharacterVector names(static_cast<R_xlen_t>(ncol));

    // Identify numeric columns for parallel decode.
    std::vector<std::size_t> numIdx;
    numIdx.reserve(ncol);
    for (std::size_t i = 0; i < ncol; ++i) {
        names[static_cast<R_xlen_t>(i)] = schema.variables[i].name;
        if (!schema.variables[i].isString) numIdx.push_back(i);
    }

    // Allocate numeric column SEXPs first so workers can write into REAL(.).
    std::vector<SEXP> numericColSexps(ncol, R_NilValue);
    for (std::size_t i : numIdx) {
        SEXP s = PROTECT(Rf_allocVector(REALSXP, static_cast<R_xlen_t>(nrow)));
        numericColSexps[i] = s;
        cols[static_cast<R_xlen_t>(i)] = s;
        UNPROTECT(1);  // protected by the List `cols`
    }

    // Per-numeric-column flag arrays: 0=NA, 1=value, 2=tagged. We only need to
    // remember system-vs-tagged when the file actually has tagged missings.
    // Allocate a single flat buffer to keep allocation count constant.
    std::vector<std::vector<std::uint8_t>> flagBuffers(numIdx.size());
    std::vector<std::vector<TagEntry>> tagBuffers(numIdx.size());

    // ---- Parallel numeric decode ----
    if (nrow > 0 && !numIdx.empty()) {
        const std::uint8_t *base = mf.data() + fileBaseOffset;

        // Choose chunking: split rows so each thread gets a contiguous range.
        unsigned actualThreads = std::min<unsigned>(nThreads, std::max<unsigned>(1u,
                                  static_cast<unsigned>((nrow + 1023) / 1024)));
        if (actualThreads == 0) actualThreads = 1;

        const std::size_t rowsPerThread = (nrow + actualThreads - 1) / actualThreads;

        // Pre-allocate per-thread output buffers per numeric column.
        // Layout: column-major over threads to minimise false-sharing.
        std::vector<std::vector<std::vector<std::uint8_t>>> tFlags(actualThreads);
        std::vector<std::vector<std::vector<TagEntry>>> tTags(actualThreads);
        for (unsigned t = 0; t < actualThreads; ++t) {
            tFlags[t].resize(numIdx.size());
            tTags[t].resize(numIdx.size());
        }

        std::vector<std::thread> workers;
        workers.reserve(actualThreads);

        std::atomic<bool> failed{false};
        std::vector<std::string> threadErrors(actualThreads);

        for (unsigned t = 0; t < actualThreads; ++t) {
            const std::size_t rb = t * rowsPerThread;
            const std::size_t re = std::min(nrow, rb + rowsPerThread);
            if (rb >= re) continue;
            workers.emplace_back([&, t, rb, re]() {
                try {
                    for (std::size_t k = 0; k < numIdx.size(); ++k) {
                        const std::size_t colIdx = numIdx[k];
                        const auto &var = schema.variables[colIdx];
                        double *outV = REAL(numericColSexps[colIdx]) + rb;
                        tFlags[t][k].assign(re - rb, 0);
                        decodeNumericChunk(base, rowLen, rb, re, var,
                                           outV, tFlags[t][k].data(), tTags[t][k]);
                        // Re-base tag row indices to absolute (already absolute).
                    }
                } catch (const std::exception &e) {
                    threadErrors[t] = e.what();
                    failed.store(true, std::memory_order_relaxed);
                } catch (...) {
                    threadErrors[t] = "unknown decode error";
                    failed.store(true, std::memory_order_relaxed);
                }
            });
        }
        for (auto &th : workers) th.join();

        if (failed.load()) {
            for (const auto &e : threadErrors) {
                if (!e.empty()) Rcpp::stop("XPORT decode error: %s", e);
            }
            Rcpp::stop("XPORT decode error");
        }

        // Stitch per-thread flag/tag buffers into per-column arrays.
        for (std::size_t k = 0; k < numIdx.size(); ++k) {
            std::size_t colTotal = 0;
            for (unsigned t = 0; t < actualThreads; ++t) colTotal += tFlags[t][k].size();
            flagBuffers[k].assign(colTotal, 0);
            std::size_t pos = 0;
            for (unsigned t = 0; t < actualThreads; ++t) {
                std::memcpy(flagBuffers[k].data() + pos, tFlags[t][k].data(),
                            tFlags[t][k].size());
                pos += tFlags[t][k].size();
                tFlags[t][k].clear();
                tFlags[t][k].shrink_to_fit();
            }
            // Concatenate tags.
            std::size_t tagTotal = 0;
            for (unsigned t = 0; t < actualThreads; ++t) tagTotal += tTags[t][k].size();
            tagBuffers[k].reserve(tagTotal);
            for (unsigned t = 0; t < actualThreads; ++t) {
                tagBuffers[k].insert(tagBuffers[k].end(), tTags[t][k].begin(), tTags[t][k].end());
                tTags[t][k].clear();
                tTags[t][k].shrink_to_fit();
            }
        }
    }

    // ---- String columns: serial decode (R API is not thread-safe) ----
    for (std::size_t i = 0; i < ncol; ++i) {
        const auto &var = schema.variables[i];
        if (!var.isString) continue;
        SEXP s = PROTECT(Rf_allocVector(STRSXP, static_cast<R_xlen_t>(nrow)));
        const std::size_t off = var.byteOffset;
        const std::size_t width = var.storageWidth;
        const std::uint8_t *base = mf.data() + fileBaseOffset;
        for (std::size_t r = 0; r < nrow; ++r) {
            const char *cell = reinterpret_cast<const char *>(base + r * rowLen + off);
            // Trim trailing 0x20 spaces.
            std::size_t len = width;
            while (len > 0 && cell[len - 1] == ' ') --len;
            SET_STRING_ELT(s, static_cast<R_xlen_t>(r), Rf_mkCharLenCE(cell, static_cast<int>(len), CE_NATIVE));
        }
        cols[static_cast<R_xlen_t>(i)] = s;
        UNPROTECT(1);
    }

    // ---- Apply attributes + date conversion ----
    for (std::size_t i = 0; i < ncol; ++i) {
        const auto &var = schema.variables[i];
        SEXP col = cols[static_cast<R_xlen_t>(i)];

        if (var.isString) {
            if (!var.label.empty())   Rf_setAttrib(col, Rf_install("label"), Rf_mkString(var.label.c_str()));
            if (!var.format.empty())  Rf_setAttrib(col, Rf_install("format.sas"), Rf_mkString(canonicalFormat(var.format).c_str()));
            if (!var.informat.empty()) Rf_setAttrib(col, Rf_install("sas.informat"), Rf_mkString(canonicalFormat(var.informat).c_str()));
            if (var.displayWidth != 0) Rf_setAttrib(col, Rf_install("sas.display.width"), Rf_ScalarInteger(var.displayWidth));
            continue;
        }

        // Numeric: optional date/datetime conversion + attributes.
        const std::string &fmt = var.format;
        const bool isDate = convert_dates && kstools::isSasDateFormat(fmt);
        const bool isDateTime = convert_dates && kstools::isSasDatetimeFormat(fmt);

        if (isDate || isDateTime) {
            const double offset = isDate ? -kstools::kSasRDateOffset : -kstools::kSasRDatetimeOffset;
            (void)offset;
            const R_xlen_t n = Rf_xlength(col);
            double *p = REAL(col);
            if (isDate) {
                for (R_xlen_t k = 0; k < n; ++k) {
                    if (!ISNA(p[k]) && !std::isnan(p[k])) {
                        p[k] = kstools::sasDateToR(p[k]);
                    }
                }
                Rf_setAttrib(col, R_ClassSymbol, Rf_mkString("Date"));
            } else {
                for (R_xlen_t k = 0; k < n; ++k) {
                    if (!ISNA(p[k]) && !std::isnan(p[k])) {
                        p[k] = kstools::sasDatetimeToR(p[k]);
                    }
                }
                CharacterVector klass = CharacterVector::create("POSIXct", "POSIXt");
                Rf_setAttrib(col, R_ClassSymbol, klass);
                Rf_setAttrib(col, Rf_install("tzone"), Rf_mkString("UTC"));
            }
        }

        if (!var.label.empty())   Rf_setAttrib(col, Rf_install("label"), Rf_mkString(var.label.c_str()));
        if (!fmt.empty())         Rf_setAttrib(col, Rf_install("format.sas"), Rf_mkString(canonicalFormat(fmt).c_str()));
        if (!var.informat.empty()) Rf_setAttrib(col, Rf_install("sas.informat"), Rf_mkString(canonicalFormat(var.informat).c_str()));
        if (var.displayWidth != 0) Rf_setAttrib(col, Rf_install("sas.display.width"), Rf_ScalarInteger(var.displayWidth));
        if (var.decimals != 0)    Rf_setAttrib(col, Rf_install("sas.decimals"), Rf_ScalarInteger(var.decimals));
    }

    // ---- Tagged-missing attribute (only if any column has any tag) ----
    bool anyTagsAtAll = false;
    for (const auto &t : tagBuffers) if (!t.empty()) { anyTagsAtAll = true; break; }
    if (anyTagsAtAll) {
        for (std::size_t k = 0; k < numIdx.size(); ++k) {
            if (tagBuffers[k].empty()) continue;
            const std::size_t colIdx = numIdx[k];
            SEXP col = cols[static_cast<R_xlen_t>(colIdx)];
            CharacterVector tags(static_cast<R_xlen_t>(nrow));
            for (R_xlen_t r = 0; r < static_cast<R_xlen_t>(nrow); ++r) tags[r] = "";
            for (const auto &te : tagBuffers[k]) {
                tags[te.row] = std::string(1, te.tag);
            }
            Rf_setAttrib(col, Rf_install("sas.missing.tag"), tags);
        }
    }

    // Build data.frame.
    cols.attr("names") = names;
    cols.attr("class") = "data.frame";
    cols.attr("row.names") = IntegerVector::create(NA_INTEGER, -static_cast<int>(nrow));
    return cols;
}

// ===== Writer helpers ========================================================

std::string defaultFormatForClass(SEXP col) {
    SEXP klassSexp = Rf_getAttrib(col, R_ClassSymbol);
    if (!Rf_isNull(klassSexp)) {
        CharacterVector klass(klassSexp);
        for (R_xlen_t i = 0; i < klass.size(); ++i) {
            std::string c = as<std::string>(klass[i]);
            if (c == "Date") return "DATE9.";
            if (c == "POSIXct") return "DATETIME20.";
            if (c == "POSIXt") return "DATETIME20.";
        }
    }
    return "";
}

std::string getAttrStr(SEXP col, const char *name, const std::string &fallback = "") {
    SEXP a = Rf_getAttrib(col, Rf_install(name));
    if (Rf_isNull(a)) return fallback;
    if (TYPEOF(a) == STRSXP && Rf_length(a) >= 1) {
        return as<std::string>(STRING_ELT(a, 0));
    }
    return fallback;
}

std::string lookupNamed(SEXP namedVec, const std::string &key) {
    if (Rf_isNull(namedVec) || TYPEOF(namedVec) != STRSXP) return "";
    SEXP names = Rf_getAttrib(namedVec, R_NamesSymbol);
    if (Rf_isNull(names) || TYPEOF(names) != STRSXP) return "";
    R_xlen_t n = Rf_xlength(namedVec);
    for (R_xlen_t i = 0; i < n; ++i) {
        std::string nm(CHAR(STRING_ELT(names, i)));
        if (nm == key) {
            SEXP v = STRING_ELT(namedVec, i);
            if (v == NA_STRING) return "";
            return std::string(CHAR(v));
        }
    }
    return "";
}

}  // namespace

// ===== Reader entry point ====================================================

// [[Rcpp::export(name = ".rcpp_read_xpt")]]
Rcpp::List rcpp_read_xpt(const std::string &path,
                         bool convert_dates,
                         Rcpp::Nullable<int> n_threads = R_NilValue) {
    cxpt::MappedFile mf;
    try {
        mf.open(path);
    } catch (const std::exception &e) {
        stop("%s", e.what());
    }
    if (mf.size() < 240) stop("File too small to be a valid XPORT: %s", path);

    SEXP nThreadsSEXP = n_threads.isNotNull() ? Rcpp::wrap(Rcpp::as<int>(n_threads)) : R_NilValue;
    unsigned nThreads = resolveThreadCount(nThreadsSEXP);

    const std::uint8_t *data = mf.data();
    const std::size_t size = mf.size();

    // Member detection: scan for additional MEMBER/MEMBV8 records beyond the
    // mandatory leading one.
    std::vector<std::size_t> memberOffsets = cxpt::scanMemberOffsets(data, size);
    const bool multi = memberOffsets.size() > 1;

    CharacterVector warnings;

    if (!multi) {
        cxpt::XptSchema schema;
        std::string err;
        if (!cxpt::parseSchema(data, size, 0, schema, err)) {
            stop("XPORT parse error: %s", err);
        }
        for (const auto &w : schema.warnings) warnings.push_back(w);

        SEXP df = PROTECT(buildColumns(mf, schema.dataOffset, schema, convert_dates, nThreads));
        List out = List::create(
            Named("data") = df,
            Named("warnings") = warnings,
            Named("multi_member") = false);
        UNPROTECT(1);
        return out;
    }

    // ---- Multi-member (zero-copy via mmap offsets) ----
    List members(memberOffsets.size());
    CharacterVector memberNames(memberOffsets.size());

    for (std::size_t k = 0; k < memberOffsets.size(); ++k) {
        const std::size_t startOff = memberOffsets[k];
        const std::size_t endOff = (k + 1 < memberOffsets.size())
                                       ? memberOffsets[k + 1]
                                       : size;
        cxpt::XptSchema schema;
        std::string err;
        // For non-leading members, parseSchema is given a window that begins at
        // the MEMBER record itself; it will skip the LIBRARY prelude logic.
        if (!cxpt::parseSchema(data, endOff, startOff, schema, err)) {
            warnings.push_back(std::string("member ") + std::to_string(k + 1) + ": " + err);
            continue;
        }
        for (const auto &w : schema.warnings) warnings.push_back(w);

        memberNames[static_cast<R_xlen_t>(k)] = schema.tableName.empty()
                              ? std::string("MEMBER_") + std::to_string(k + 1)
                              : schema.tableName;
        SEXP df = PROTECT(buildColumns(mf, schema.dataOffset, schema, convert_dates, nThreads));
        members[static_cast<R_xlen_t>(k)] = df;
        UNPROTECT(1);
    }
    members.attr("names") = memberNames;
    return List::create(
        Named("data") = members,
        Named("warnings") = warnings,
        Named("multi_member") = true);
}

// ===== Writer entry point ====================================================

// [[Rcpp::export(name = ".rcpp_write_xpt")]]
void rcpp_write_xpt(Rcpp::List df,
                    const std::string &path,
                    int version,
                    bool convert_dates,
                    Rcpp::Nullable<std::string> dataset_name,
                    Rcpp::Nullable<std::string> dataset_label,
                    Rcpp::Nullable<Rcpp::CharacterVector> labels,
                    Rcpp::Nullable<Rcpp::CharacterVector> formats) {
    if (version != 5 && version != 8) stop("version must be 5 or 8");

    CharacterVector colNames = df.names();
    const std::size_t ncol = static_cast<std::size_t>(df.size());
    if (colNames.size() != static_cast<R_xlen_t>(ncol)) stop("data must have column names");

    R_xlen_t nrow = 0;
    if (ncol > 0) {
        SEXP first = df[0];
        nrow = Rf_xlength(first);
    }
    for (std::size_t i = 0; i < ncol; ++i) {
        SEXP col = df[static_cast<R_xlen_t>(i)];
        if (Rf_xlength(col) != nrow) stop("all columns must have the same length");
    }

    SEXP labelsSexp  = labels.isNotNull()  ? SEXP(CharacterVector(labels))  : R_NilValue;
    SEXP formatsSexp = formats.isNotNull() ? SEXP(CharacterVector(formats)) : R_NilValue;

    // ---- Build schema (no row data!) ----
    cxpt::XptSchema schema;
    schema.version = version;
    if (dataset_label.isNotNull()) schema.fileLabel = as<std::string>(dataset_label);

    schema.variables.reserve(ncol);
    for (std::size_t i = 0; i < ncol; ++i) {
        std::string nm = as<std::string>(colNames[static_cast<R_xlen_t>(i)]);
        SEXP col = df[static_cast<R_xlen_t>(i)];
        cxpt::XptVariable v;
        v.index = i;
        v.varNumber = static_cast<std::uint16_t>(i + 1);
        v.name = nm;

        std::string lbl = lookupNamed(labelsSexp, nm);
        if (lbl.empty()) lbl = getAttrStr(col, "label");
        v.label = lbl;

        std::string fmt = lookupNamed(formatsSexp, nm);
        if (fmt.empty()) fmt = getAttrStr(col, "format.sas");
        if (fmt.empty()) fmt = defaultFormatForClass(col);
        v.format = fmt;

        v.informat = getAttrStr(col, "sas.informat");

        bool isChar = (TYPEOF(col) == STRSXP) || Rf_isFactor(col);
        if (isChar) {
            v.ntypeRaw = 2;
            v.isString = true;
            std::uint16_t w = 1;
            if (TYPEOF(col) == STRSXP) {
                R_xlen_t n = Rf_xlength(col);
                for (R_xlen_t r = 0; r < n; ++r) {
                    SEXP s = STRING_ELT(col, r);
                    if (s != NA_STRING) {
                        std::size_t L = std::strlen(CHAR(s));
                        if (L > w) w = static_cast<std::uint16_t>(std::min<std::size_t>(L, 32767));
                    }
                }
            } else {
                CharacterVector levels = Rf_getAttrib(col, R_LevelsSymbol);
                for (R_xlen_t r = 0; r < levels.size(); ++r) {
                    std::size_t L = std::strlen(CHAR(STRING_ELT(levels, r)));
                    if (L > w) w = static_cast<std::uint16_t>(std::min<std::size_t>(L, 32767));
                }
            }
            v.storageWidth = w;
        } else {
            v.ntypeRaw = 1;
            v.isString = false;
            v.storageWidth = 8;
        }
        schema.variables.push_back(std::move(v));
    }

    cxpt::WriteOptions opts;
    opts.version = version;
    opts.datasetName = dataset_name.isNotNull() ? as<std::string>(dataset_name)
                                                : std::string("DATASET");
    if (dataset_label.isNotNull()) opts.fileLabel = as<std::string>(dataset_label);

    // Compute per-variable byte offsets so the row-buffer fill loop matches the
    // writer's row layout.
    {
        std::size_t off = 0;
        for (auto &v : schema.variables) {
            v.byteOffset = off;
            off += v.storageWidth;
        }
    }

    cxpt::XptWriter writer(path, schema, opts);

    // ---- Stream rows ----
    // Cache column SEXPs and types once.
    std::vector<SEXP> colSexps(ncol);
    std::vector<int> colTypes(ncol);  // 1=numeric, 2=character, 3=factor
    std::vector<bool> isDate(ncol, false);
    std::vector<bool> isDateTime(ncol, false);
    for (std::size_t i = 0; i < ncol; ++i) {
        colSexps[i] = df[static_cast<R_xlen_t>(i)];
        if (schema.variables[i].isString) {
            colTypes[i] = (TYPEOF(colSexps[i]) == STRSXP) ? 2 : 3;
        } else {
            colTypes[i] = 1;
            if (convert_dates) {
                if (Rf_inherits(colSexps[i], "Date")) isDate[i] = true;
                else if (Rf_inherits(colSexps[i], "POSIXct")) isDateTime[i] = true;
            }
        }
    }

    std::uint8_t *rowBuf = writer.rowBuffer();
    for (R_xlen_t r = 0; r < nrow; ++r) {
        for (std::size_t i = 0; i < ncol; ++i) {
            const auto &var = schema.variables[i];
            std::uint8_t *slot = rowBuf + var.byteOffset;

            if (colTypes[i] == 1) {
                double d = NA_REAL;
                bool isNA = false;
                SEXP col = colSexps[i];
                int tp = TYPEOF(col);
                if (tp == REALSXP) {
                    d = REAL(col)[r];
                    isNA = ISNA(d) || std::isnan(d);
                } else if (tp == INTSXP) {
                    int iv = INTEGER(col)[r];
                    if (iv == NA_INTEGER) isNA = true;
                    else d = static_cast<double>(iv);
                } else if (tp == LGLSXP) {
                    int lv = LOGICAL(col)[r];
                    if (lv == NA_LOGICAL) isNA = true;
                    else d = static_cast<double>(lv);
                } else {
                    isNA = true;
                }
                std::uint8_t enc[8] = {0};
                if (isNA) {
                    enc[0] = 0x2E;  // '.'
                } else {
                    if (isDate[i]) d = kstools::rDateToSas(d);
                    else if (isDateTime[i]) d = kstools::rDatetimeToSas(d);
                    cxpt::encodeIbmXport(d, enc);
                }
                std::size_t w = std::min<std::size_t>(8, var.storageWidth);
                if (w == 0) w = 8;
                std::memcpy(slot, enc, w);
            } else if (colTypes[i] == 2) {
                SEXP s = STRING_ELT(colSexps[i], r);
                if (s == NA_STRING) {
                    // Leave slot as spaces (already memset by writer).
                } else {
                    const char *cstr = CHAR(s);
                    std::size_t L = std::strlen(cstr);
                    std::size_t n = std::min<std::size_t>(L, var.storageWidth);
                    std::memcpy(slot, cstr, n);
                    if (n < var.storageWidth) {
                        std::memset(slot + n, 0x20, var.storageWidth - n);
                    }
                }
            } else {  // factor
                int idx = INTEGER(colSexps[i])[r];
                if (idx == NA_INTEGER) {
                    // spaces (already)
                } else {
                    CharacterVector levels = Rf_getAttrib(colSexps[i], R_LevelsSymbol);
                    SEXP s = STRING_ELT(levels, idx - 1);
                    const char *cstr = CHAR(s);
                    std::size_t L = std::strlen(cstr);
                    std::size_t n = std::min<std::size_t>(L, var.storageWidth);
                    std::memcpy(slot, cstr, n);
                    if (n < var.storageWidth) {
                        std::memset(slot + n, 0x20, var.storageWidth - n);
                    }
                }
            }
        }
        writer.commitRow();
    }

    writer.finish();
}
