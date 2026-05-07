// Rcpp interface for SAS XPORT read/write.

#include <Rcpp.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>

#include "core/types.hpp"
#include "xpt/parser.hpp"
#include "xpt/writer.hpp"
#include "xpt_epoch.hpp"

using namespace Rcpp;

// -------- Helpers --------

namespace {

// Reconstruct full SAS format string from parser's already-built variable.format,
// which uses convention "<NAME><width>[.<dec>]" (no trailing '.' if no decimals).
// We normalise to canonical "<NAME><width>.<dec>" if width != 0.
std::string canonicalFormat(const std::string &fmt) {
    if (fmt.empty()) return fmt;
    if (fmt.find('.') != std::string::npos) return fmt;
    return fmt + ".";
}

// Build a NumericVector from XptFile column index, applying epoch conversion if requested.
// Returns the vector with attributes/class set.
SEXP buildNumericColumn(const cxpt::XptFile &file,
                        std::size_t colIdx,
                        const std::vector<bool> &keepRow,
                        bool convert_dates) {
    const auto &var = file.variables[colIdx];
    std::size_t nKeep = 0;
    for (bool k : keepRow) if (k) ++nKeep;

    NumericVector out(nKeep);
    CharacterVector tags(nKeep);   // tagged-missing tag character per row, "" otherwise
    bool anyTag = false;

    std::size_t j = 0;
    for (std::size_t i = 0; i < file.rows.size(); ++i) {
        if (!keepRow[i]) continue;
        const auto &cell = file.rows[i].cells[colIdx];
        const auto &num = cell.numeric;
        if (num.isSystemMissing) {
            out[j] = NA_REAL;
            tags[j] = "";
        } else if (num.isTaggedMissing) {
            out[j] = NA_REAL;
            tags[j] = std::string(1, num.tag);
            anyTag = true;
        } else if (num.hasValue) {
            out[j] = num.value;
            tags[j] = "";
        } else {
            out[j] = NA_REAL;
            tags[j] = "";
        }
        ++j;
    }

    const std::string fmt = var.format;
    const bool isDate = convert_dates && kstools::isSasDateFormat(fmt);
    const bool isDateTime = convert_dates && kstools::isSasDatetimeFormat(fmt);

    if (isDate) {
        for (R_xlen_t k = 0; k < out.size(); ++k) {
            if (!NumericVector::is_na(out[k])) {
                out[k] = kstools::sasDateToR(out[k]);
            }
        }
        out.attr("class") = "Date";
    } else if (isDateTime) {
        for (R_xlen_t k = 0; k < out.size(); ++k) {
            if (!NumericVector::is_na(out[k])) {
                out[k] = kstools::sasDatetimeToR(out[k]);
            }
        }
        out.attr("class") = CharacterVector::create("POSIXct", "POSIXt");
        out.attr("tzone") = "UTC";
    }

    if (!var.label.empty())    out.attr("label") = var.label;
    if (!fmt.empty())          out.attr("format.sas") = canonicalFormat(fmt);
    if (!var.informat.empty()) out.attr("sas.informat") = canonicalFormat(var.informat);
    if (var.displayWidth != 0) out.attr("sas.display.width") = static_cast<int>(var.displayWidth);
    if (var.decimals != 0)     out.attr("sas.decimals") = static_cast<int>(var.decimals);
    if (anyTag)                out.attr("sas.missing.tag") = tags;

    return out;
}

SEXP buildStringColumn(const cxpt::XptFile &file,
                       std::size_t colIdx,
                       const std::vector<bool> &keepRow) {
    const auto &var = file.variables[colIdx];
    std::size_t nKeep = 0;
    for (bool k : keepRow) if (k) ++nKeep;

    CharacterVector out(nKeep);
    std::size_t j = 0;
    for (std::size_t i = 0; i < file.rows.size(); ++i) {
        if (!keepRow[i]) continue;
        const auto &cell = file.rows[i].cells[colIdx];
        out[j++] = cell.stringTrimmed;
    }
    if (!var.label.empty())    out.attr("label") = var.label;
    if (!var.format.empty())   out.attr("format.sas") = canonicalFormat(var.format);
    if (!var.informat.empty()) out.attr("sas.informat") = canonicalFormat(var.informat);
    if (var.displayWidth != 0) out.attr("sas.display.width") = static_cast<int>(var.displayWidth);
    return out;
}

// Convert a parsed XptFile to an R data.frame (no tibble class).
List xptFileToDataFrame(const cxpt::XptFile &file, bool convert_dates) {
    // Determine which rows to keep (skip blank-padding rows)
    std::vector<bool> keepRow(file.rows.size(), true);
    std::size_t nKeep = 0;
    for (std::size_t i = 0; i < file.rows.size(); ++i) {
        if (file.rows[i].wasBlankPaddingRow) keepRow[i] = false;
        else ++nKeep;
    }

    const std::size_t ncol = file.variables.size();
    List cols(ncol);
    CharacterVector names(ncol);
    for (std::size_t i = 0; i < ncol; ++i) {
        names[i] = file.variables[i].name;
        if (file.variables[i].isString) {
            cols[i] = buildStringColumn(file, i, keepRow);
        } else {
            cols[i] = buildNumericColumn(file, i, keepRow, convert_dates);
        }
    }
    cols.attr("names") = names;
    cols.attr("class") = "data.frame";
    cols.attr("row.names") = IntegerVector::create(NA_INTEGER, -static_cast<int>(nKeep));
    return cols;
}

// -------- Multi-member detection --------
//
// We scan for occurrences of the MEMBER/MEMBV8 header magic in the file:
// "HEADER RECORD*******MEMBER  HEADER RECORD!!!!!!!" (V5)
// "HEADER RECORD*******MEMBV8  HEADER RECORD!!!!!!!" (V8) -- name is space-padded to 8.
//
// Returns vector of byte offsets where MEMBER/MEMBV8 records begin.
std::vector<std::size_t> scanMemberOffsets(const std::vector<std::uint8_t> &bytes) {
    std::vector<std::size_t> out;
    static const char kPrefix[]  = "HEADER RECORD*******";
    static const char kInfix[]   = "HEADER RECORD!!!!!!!";
    const std::size_t prefLen = 20;
    const std::size_t infixLen = 20;
    const std::size_t recLen = 80;

    if (bytes.size() < recLen) return out;
    // Headers always start at 80-byte boundaries
    for (std::size_t pos = 0; pos + recLen <= bytes.size(); pos += recLen) {
        if (std::memcmp(bytes.data() + pos, kPrefix, prefLen) != 0) continue;
        if (std::memcmp(bytes.data() + pos + 28, kInfix, infixLen) != 0) continue;
        // Read the 8-char name field at offset 20..27
        std::string name(reinterpret_cast<const char *>(bytes.data() + pos + 20), 8);
        // Trim trailing spaces
        while (!name.empty() && name.back() == ' ') name.pop_back();
        if (name == "MEMBER" || name == "MEMBV8") {
            out.push_back(pos);
        }
    }
    return out;
}

// Read entire file into bytes vector
std::vector<std::uint8_t> readFileBytes(const std::string &path) {
    std::ifstream ifs(path, std::ios::binary);
    if (!ifs) throw std::runtime_error("Cannot open file for reading: " + path);
    ifs.seekg(0, std::ios::end);
    const std::streamoff sz = ifs.tellg();
    ifs.seekg(0, std::ios::beg);
    std::vector<std::uint8_t> buf(static_cast<std::size_t>(sz));
    if (sz > 0) ifs.read(reinterpret_cast<char *>(buf.data()), sz);
    return buf;
}

// Write bytes to a temp file and return its path. Caller must remove.
std::string writeTempFile(const std::vector<std::uint8_t> &bytes) {
    // Use R's tempfile()
    Function tempfile_fn("tempfile");
    std::string path = as<std::string>(tempfile_fn(Named("fileext") = ".xpt"));
    std::ofstream ofs(path, std::ios::binary);
    if (!ofs) throw std::runtime_error("Cannot create temp file: " + path);
    ofs.write(reinterpret_cast<const char *>(bytes.data()), bytes.size());
    return path;
}

void removeFile(const std::string &path) {
    (void)::remove(path.c_str());
}

}  // namespace

// [[Rcpp::export(name = ".rcpp_read_xpt")]]
Rcpp::List rcpp_read_xpt(const std::string &path, bool convert_dates) {
    std::vector<std::uint8_t> bytes = readFileBytes(path);
    if (bytes.size() < 240) stop("File too small to be a valid XPORT: %s", path);

    auto memberOffsets = scanMemberOffsets(bytes);
    const bool multi = memberOffsets.size() > 1;

    CharacterVector warnings;

    if (!multi) {
        // Single-member: parse the file path directly.
        auto pr = cxpt::parseXptFile(path);
        if (!pr.error.empty()) stop("XPORT parse error: %s", pr.error);
        for (const auto &w : pr.file.warnings) warnings.push_back(w);
        List df = xptFileToDataFrame(pr.file, convert_dates);
        return List::create(
            Named("data") = df,
            Named("warnings") = warnings,
            Named("multi_member") = false);
    }

    // Multi-member: extract each member to a temp file (with file-header prefix) and parse.
    // The file header (3 × 80 bytes = 240) must precede each member.
    if (bytes.size() < 240) stop("Multi-member file truncated: %s", path);
    std::vector<std::uint8_t> fileHeader(bytes.begin(), bytes.begin() + 240);

    List members(memberOffsets.size());
    CharacterVector memberNames(memberOffsets.size());

    for (std::size_t k = 0; k < memberOffsets.size(); ++k) {
        std::size_t startOff = memberOffsets[k];
        std::size_t endOff = (k + 1 < memberOffsets.size()) ? memberOffsets[k + 1] : bytes.size();

        std::vector<std::uint8_t> single;
        single.reserve(240 + (endOff - startOff));
        single.insert(single.end(), fileHeader.begin(), fileHeader.end());
        single.insert(single.end(), bytes.begin() + startOff, bytes.begin() + endOff);

        std::string tmpPath = writeTempFile(single);
        cxpt::ParseResult pr;
        try {
            pr = cxpt::parseXptFile(tmpPath);
        } catch (...) {
            removeFile(tmpPath);
            throw;
        }
        removeFile(tmpPath);

        if (!pr.error.empty()) {
            warnings.push_back(std::string("member ") + std::to_string(k + 1) + ": " + pr.error);
            continue;
        }
        for (const auto &w : pr.file.warnings) warnings.push_back(w);
        memberNames[k] = pr.file.tableName.empty() ? std::string("MEMBER_") + std::to_string(k + 1)
                                                   : pr.file.tableName;
        members[k] = xptFileToDataFrame(pr.file, convert_dates);
    }
    members.attr("names") = memberNames;
    return List::create(
        Named("data") = members,
        Named("warnings") = warnings,
        Named("multi_member") = true);
}

// -------- Writer side --------

namespace {

// Detect R column class to pick a default SAS format if no explicit one is given.
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

// Get an attribute as string, or fallback.
std::string getAttrStr(SEXP col, const char *name, const std::string &fallback = "") {
    SEXP a = Rf_getAttrib(col, Rf_install(name));
    if (Rf_isNull(a)) return fallback;
    if (TYPEOF(a) == STRSXP && Rf_length(a) >= 1) {
        return as<std::string>(STRING_ELT(a, 0));
    }
    return fallback;
}

// Look up a name in a named CharacterVector (or return empty if not present / vec is null).
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

bool inheritsClass(SEXP col, const char *name) {
    return Rf_inherits(col, name);
}

}  // namespace

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
    const std::size_t ncol = df.size();
    if (colNames.size() != static_cast<R_xlen_t>(ncol)) stop("data must have column names");

    R_xlen_t nrow = 0;
    if (ncol > 0) {
        SEXP first = df[0];
        nrow = Rf_xlength(first);
    }
    for (std::size_t i = 0; i < ncol; ++i) {
        SEXP col = df[i];
        if (Rf_xlength(col) != nrow) stop("all columns must have the same length");
    }

    SEXP labelsSexp  = labels.isNotNull()  ? SEXP(Rcpp::CharacterVector(labels))  : R_NilValue;
    SEXP formatsSexp = formats.isNotNull() ? SEXP(Rcpp::CharacterVector(formats)) : R_NilValue;

    // -------- Build XptFile --------
    cxpt::XptFile file;
    file.version = version;
    if (dataset_label.isNotNull()) file.fileLabel = as<std::string>(dataset_label);

    std::vector<int> colTypes(ncol);   // 1=numeric, 2=character
    std::vector<std::uint16_t> storageWidths(ncol);

    for (std::size_t i = 0; i < ncol; ++i) {
        std::string nm = as<std::string>(colNames[i]);
        SEXP col = df[i];
        cxpt::XptVariable v;
        v.index = i;
        v.varNumber = static_cast<std::uint16_t>(i + 1);
        v.name = nm;

        // Resolve label
        std::string lbl = lookupNamed(labelsSexp, nm);
        if (lbl.empty()) lbl = getAttrStr(col, "label");
        v.label = lbl;

        // Resolve format
        std::string fmt = lookupNamed(formatsSexp, nm);
        if (fmt.empty()) fmt = getAttrStr(col, "format.sas");
        if (fmt.empty()) fmt = defaultFormatForClass(col);
        v.format = fmt;

        // Informat (no command-line override; pull from attribute only)
        v.informat = getAttrStr(col, "sas.informat");

        // Type detection
        bool isChar = (TYPEOF(col) == STRSXP) || Rf_isFactor(col);
        if (isChar) {
            v.ntypeRaw = 2;
            v.isString = true;
            // Storage width: max nchar across rows, min 1
            std::uint16_t w = 1;
            if (TYPEOF(col) == STRSXP) {
                R_xlen_t n = Rf_xlength(col);
                for (R_xlen_t r = 0; r < n; ++r) {
                    SEXP s = STRING_ELT(col, r);
                    if (s != NA_STRING) {
                        std::size_t L = strlen(CHAR(s));
                        if (L > w) w = static_cast<std::uint16_t>(std::min<std::size_t>(L, 32767));
                    }
                }
            } else {  // factor: get levels and use max level width
                CharacterVector levels = Rf_getAttrib(col, R_LevelsSymbol);
                for (R_xlen_t r = 0; r < levels.size(); ++r) {
                    std::size_t L = strlen(CHAR(STRING_ELT(levels, r)));
                    if (L > w) w = static_cast<std::uint16_t>(std::min<std::size_t>(L, 32767));
                }
            }
            v.storageWidth = w;
        } else {
            v.ntypeRaw = 1;
            v.isString = false;
            v.storageWidth = 8;
        }

        // Set displayWidth/decimals from format if not yet
        // (writer's buildNamestr handles parsing again from v.format)

        colTypes[i] = v.ntypeRaw;
        storageWidths[i] = v.storageWidth;
        file.variables.push_back(std::move(v));
    }

    // -------- Build rows --------
    file.rows.reserve(static_cast<std::size_t>(nrow));
    for (R_xlen_t r = 0; r < nrow; ++r) {
        cxpt::XptRow row;
        row.cells.resize(ncol);
        for (std::size_t i = 0; i < ncol; ++i) {
            SEXP col = df[i];
            cxpt::CellValue &cell = row.cells[i];
            if (colTypes[i] == 2) {
                cell.isString = true;
                if (TYPEOF(col) == STRSXP) {
                    SEXP s = STRING_ELT(col, r);
                    cell.stringRaw = (s == NA_STRING) ? std::string{} : std::string(CHAR(s));
                } else {  // factor
                    int idx = INTEGER(col)[r];
                    if (idx == NA_INTEGER) {
                        cell.stringRaw = "";
                    } else {
                        CharacterVector levels = Rf_getAttrib(col, R_LevelsSymbol);
                        cell.stringRaw = std::string(CHAR(STRING_ELT(levels, idx - 1)));
                    }
                }
                cell.stringTrimmed = cell.stringRaw;
            } else {
                cell.isString = false;
                cell.numeric.hasValue = false;
                double d = NA_REAL;
                bool isNA = false;
                if (TYPEOF(col) == REALSXP) {
                    d = REAL(col)[r];
                    isNA = ISNA(d) || std::isnan(d);
                } else if (TYPEOF(col) == INTSXP) {
                    int iv = INTEGER(col)[r];
                    if (iv == NA_INTEGER) { isNA = true; }
                    else d = static_cast<double>(iv);
                } else if (TYPEOF(col) == LGLSXP) {
                    int lv = LOGICAL(col)[r];
                    if (lv == NA_LOGICAL) { isNA = true; }
                    else d = static_cast<double>(lv);
                } else {
                    isNA = true;
                }
                if (isNA) {
                    cell.numeric.isSystemMissing = true;
                } else {
                    if (convert_dates) {
                        if (inheritsClass(col, "Date")) {
                            d = kstools::rDateToSas(d);
                        } else if (inheritsClass(col, "POSIXct")) {
                            d = kstools::rDatetimeToSas(d);
                        }
                    }
                    cell.numeric.hasValue = true;
                    cell.numeric.value = d;
                }
            }
        }
        file.rows.push_back(std::move(row));
    }

    // -------- Write --------
    cxpt::WriteOptions opts;
    opts.version = version;
    if (dataset_name.isNotNull()) {
        opts.datasetName = as<std::string>(dataset_name);
    } else {
        opts.datasetName = "DATASET";
    }
    if (dataset_label.isNotNull()) {
        opts.fileLabel = as<std::string>(dataset_label);
    }

    cxpt::writeXptFile(file, path, opts);
}
