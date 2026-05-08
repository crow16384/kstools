#include "xpt/writer.hpp"

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace cxpt {
namespace {

constexpr std::size_t kRec = kRecordLen;   // 80
constexpr std::size_t kNs  = kNameStrLen;  // 140
constexpr std::size_t kOutBufSize = 64 * 1024;

// ----- Byte layout primitives ------------------------------------------------

void putBe16(std::uint8_t *p, std::uint16_t v) {
    p[0] = static_cast<std::uint8_t>((v >> 8) & 0xFF);
    p[1] = static_cast<std::uint8_t>(v & 0xFF);
}
void putBe32(std::uint8_t *p, std::uint32_t v) {
    p[0] = static_cast<std::uint8_t>((v >> 24) & 0xFF);
    p[1] = static_cast<std::uint8_t>((v >> 16) & 0xFF);
    p[2] = static_cast<std::uint8_t>((v >> 8) & 0xFF);
    p[3] = static_cast<std::uint8_t>(v & 0xFF);
}
void putFixedField(std::uint8_t *dst, std::size_t width, std::string_view s) {
    std::memset(dst, 0x20, width);
    const std::size_t n = std::min(width, s.size());
    if (n > 0) std::memcpy(dst, s.data(), n);
}

// ----- Format parsing --------------------------------------------------------

struct ParsedFormat {
    std::string name;
    std::uint16_t width = 0;
    std::uint16_t decimals = 0;
};

ParsedFormat parseSasFormat(std::string_view fmt) {
    ParsedFormat pf;
    std::size_t i = 0;
    if (i < fmt.size() && fmt[i] == '$') { pf.name.push_back('$'); ++i; }
    while (i < fmt.size() && std::isalpha(static_cast<unsigned char>(fmt[i]))) {
        pf.name.push_back(fmt[i]);
        ++i;
    }
    std::uint16_t w = 0;
    bool wAny = false;
    while (i < fmt.size() && std::isdigit(static_cast<unsigned char>(fmt[i]))) {
        w = static_cast<std::uint16_t>(w * 10 + (fmt[i] - '0'));
        wAny = true;
        ++i;
    }
    if (wAny) pf.width = w;
    if (i < fmt.size() && fmt[i] == '.') {
        ++i;
        std::uint16_t d = 0;
        while (i < fmt.size() && std::isdigit(static_cast<unsigned char>(fmt[i]))) {
            d = static_cast<std::uint16_t>(d * 10 + (fmt[i] - '0'));
            ++i;
        }
        pf.decimals = d;
    }
    return pf;
}

// ----- Record builders -------------------------------------------------------

std::array<std::uint8_t, 80> makeHeaderRecord(std::string_view name8,
                                              const std::array<int, 6> &nums) {
    std::array<std::uint8_t, 80> rec{};
    std::memset(rec.data(), 0x20, rec.size());
    static const char kPrefix[] = "HEADER RECORD*******";
    static const char kMiddle[] = "HEADER RECORD!!!!!!!";
    std::memcpy(rec.data() + 0, kPrefix, 20);
    putFixedField(rec.data() + 20, 8, name8);
    std::memcpy(rec.data() + 28, kMiddle, 20);
    for (std::size_t i = 0; i < 6; ++i) {
        char buf[6];
        std::snprintf(buf, sizeof(buf), "%5d", nums[i]);
        std::memcpy(rec.data() + 48 + i * 5, buf, 5);
    }
    return rec;
}

std::array<std::uint8_t, 80> makeRealHeader(std::string_view sasVersion,
                                            std::string_view osName,
                                            std::string_view timestamp) {
    std::array<std::uint8_t, 80> rec{};
    std::memset(rec.data(), 0x20, rec.size());
    putFixedField(rec.data() + 0,  8, "SAS");
    putFixedField(rec.data() + 8,  8, "SAS");
    putFixedField(rec.data() + 16, 8, "SASLIB");
    putFixedField(rec.data() + 24, 8, sasVersion.empty() ? std::string_view{"9.0"} : sasVersion);
    putFixedField(rec.data() + 32, 8, osName);
    putFixedField(rec.data() + 64, 16, timestamp);
    return rec;
}

std::array<std::uint8_t, 80> makeTimestampRecord(std::string_view timestamp) {
    std::array<std::uint8_t, 80> rec{};
    std::memset(rec.data(), 0x20, rec.size());
    putFixedField(rec.data(), 16, timestamp);
    return rec;
}

std::string makeNowTimestamp() {
    std::time_t t = std::time(nullptr);
    std::tm tm{};
    gmtime_r(&t, &tm);
    static constexpr const char *months[] = {"JAN","FEB","MAR","APR","MAY","JUN",
                                             "JUL","AUG","SEP","OCT","NOV","DEC"};
    char buf[17];
    std::snprintf(buf, sizeof(buf), "%02d%s%02d:%02d:%02d:%02d",
                  tm.tm_mday, months[tm.tm_mon], tm.tm_year % 100,
                  tm.tm_hour, tm.tm_min, tm.tm_sec);
    return std::string(buf);
}

std::array<std::uint8_t, 80> makeMemberHeader(int version) {
    std::array<int, 6> nums = {0, 160, 0, static_cast<int>(kNs), 0, 140};
    return makeHeaderRecord(version == 8 ? std::string_view{"MEMBV8"} : std::string_view{"MEMBER"}, nums);
}
std::array<std::uint8_t, 80> makeDscrptrHeader(int version) {
    std::array<int, 6> nums = {0, 0, 0, 0, 0, 0};
    return makeHeaderRecord(version == 8 ? std::string_view{"DSCPTV8"} : std::string_view{"DSCRPTR"}, nums);
}

std::array<std::uint8_t, 80> makeMemberInfoRecord(std::string_view dsname,
                                                  std::string_view sasVersion,
                                                  std::string_view osName,
                                                  std::string_view timestamp,
                                                  int version) {
    std::array<std::uint8_t, 80> rec{};
    std::memset(rec.data(), 0x20, rec.size());
    putFixedField(rec.data() + 0,  8, "SAS");
    if (version == 8) {
        putFixedField(rec.data() + 8, 32, dsname);
        putFixedField(rec.data() + 40, 8, sasVersion.empty() ? std::string_view{"9.0"} : sasVersion);
        putFixedField(rec.data() + 48, 8, osName);
        putFixedField(rec.data() + 64, 16, timestamp);
    } else {
        putFixedField(rec.data() + 8,  8, dsname);
        putFixedField(rec.data() + 16, 8, "SASDATA");
        putFixedField(rec.data() + 24, 8, sasVersion.empty() ? std::string_view{"9.0"} : sasVersion);
        putFixedField(rec.data() + 32, 8, osName);
        putFixedField(rec.data() + 64, 16, timestamp);
    }
    return rec;
}

std::array<std::uint8_t, 80> makeMemberInfo2Record(std::string_view modifiedTs,
                                                   std::string_view fileLabel) {
    std::array<std::uint8_t, 80> rec{};
    std::memset(rec.data(), 0x20, rec.size());
    putFixedField(rec.data() + 0, 16, modifiedTs);
    putFixedField(rec.data() + 32, 40, fileLabel);
    putFixedField(rec.data() + 72, 8, "DATA");
    return rec;
}

std::array<std::uint8_t, kNs> buildNamestr(const XptVariable &v,
                                           std::uint32_t pos, int version) {
    std::array<std::uint8_t, kNs> r{};
    putBe16(r.data() + 0, v.ntypeRaw);
    putBe16(r.data() + 2, 0);
    putBe16(r.data() + 4, v.storageWidth);
    putBe16(r.data() + 6, v.varNumber);

    putFixedField(r.data() + 8,  8,  v.name);
    putFixedField(r.data() + 16, 40, v.label);

    ParsedFormat fmt = parseSasFormat(v.format);
    putFixedField(r.data() + 56, 8, fmt.name);
    putBe16(r.data() + 64, fmt.width != 0 ? fmt.width : v.displayWidth);
    putBe16(r.data() + 66, fmt.decimals != 0 ? fmt.decimals : v.decimals);
    putBe16(r.data() + 68, v.alignmentCode);

    ParsedFormat ifmt = parseSasFormat(v.informat);
    putFixedField(r.data() + 72, 8, ifmt.name);
    putBe16(r.data() + 80, ifmt.width);
    putBe16(r.data() + 82, ifmt.decimals);

    putBe32(r.data() + 84, pos);

    if (version == 8) {
        putFixedField(r.data() + 88, 32, v.name);
    }
    return r;
}

}  // namespace

// ===== XptWriter =============================================================

XptWriter::XptWriter(const std::string &path, const XptSchema &schema,
                     const WriteOptions &opts)
    : schema_(schema), opts_(opts) {
    if (opts_.version != 5 && opts_.version != 8) {
        throw std::runtime_error("WriteOptions.version must be 5 or 8");
    }

    rowLen_ = 0;
    for (auto &v : schema_.variables) {
        v.byteOffset = rowLen_;
        rowLen_ += v.storageWidth;
    }
    rowLen_ = std::max<std::size_t>(rowLen_, 1);
    rowBuf_.assign(rowLen_, 0x20);

    outBuf_.resize(kOutBufSize);
    outPos_ = 0;

    file_ = std::fopen(path.c_str(), "wb");
    if (file_ == nullptr) {
        throw std::runtime_error("Cannot open file for writing: " + path);
    }
    // Disable C stdio internal buffering; we manage our own 64 KB buffer.
    std::setvbuf(file_, nullptr, _IONBF, 0);

    writeFileHeader();
}

XptWriter::~XptWriter() {
    try {
        finish();
    } catch (...) {
        // Destructor must not throw. Caller should call finish() explicitly to
        // surface I/O errors.
    }
    if (file_ != nullptr) {
        std::fclose(file_);
        file_ = nullptr;
    }
}

void XptWriter::flushBuffer() {
    if (outPos_ == 0) return;
    if (std::fwrite(outBuf_.data(), 1, outPos_, file_) != outPos_) {
        throw std::runtime_error("Failed to write XPT output buffer");
    }
    outPos_ = 0;
}

namespace {
void appendBytes(XptWriter &writer, std::vector<std::uint8_t> &buf, std::size_t &pos,
                 std::FILE *file, const std::uint8_t *src, std::size_t n) {
    (void)writer;
    while (n > 0) {
        const std::size_t cap = buf.size() - pos;
        if (cap == 0) {
            if (std::fwrite(buf.data(), 1, pos, file) != pos) {
                throw std::runtime_error("Failed to write XPT output buffer");
            }
            pos = 0;
            continue;
        }
        const std::size_t chunk = std::min(n, cap);
        std::memcpy(buf.data() + pos, src, chunk);
        pos += chunk;
        src += chunk;
        n -= chunk;
    }
}
}  // namespace

void XptWriter::commitRow() {
    if (finished_) {
        throw std::runtime_error("XptWriter::commitRow called after finish()");
    }
    appendBytes(*this, outBuf_, outPos_, file_, rowBuf_.data(), rowLen_);
    ++totalRowsWritten_;
    // Reset row buffer to spaces so the caller does not have to re-pad string
    // cells on every row.
    std::memset(rowBuf_.data(), 0x20, rowLen_);
}

void XptWriter::writeFileHeader() {
    const std::string ts = opts_.timestamp.empty() ? makeNowTimestamp() : opts_.timestamp;
    const std::string osName = opts_.sasOs.empty() ? std::string{"R"} : opts_.sasOs;

    auto write = [&](const std::uint8_t *p, std::size_t n) {
        appendBytes(*this, outBuf_, outPos_, file_, p, n);
    };
    auto writeRec = [&](const std::array<std::uint8_t, 80> &rec) {
        write(rec.data(), rec.size());
    };

    // File header (240 B)
    {
        std::array<int, 6> nums = {0, 0, 0, 0, 0, 0};
        writeRec(makeHeaderRecord(opts_.version == 8 ? std::string_view{"LIBV8"}
                                                      : std::string_view{"LIBRARY"}, nums));
        writeRec(makeRealHeader("9.0", osName, ts));
        writeRec(makeTimestampRecord(ts));
    }

    // Member + Descriptor header (160 B)
    writeRec(makeMemberHeader(opts_.version));
    writeRec(makeDscrptrHeader(opts_.version));

    // Member info (160 B)
    const std::string dsname = opts_.datasetName.empty() ? std::string{"DATASET"}
                                                          : opts_.datasetName;
    writeRec(makeMemberInfoRecord(dsname, "9.0", osName, ts, opts_.version));
    writeRec(makeMemberInfo2Record(ts, opts_.fileLabel));

    // NAMESTR header
    {
        std::array<int, 6> nums = {0, static_cast<int>(schema_.variables.size()), 0, 0, 0, 0};
        writeRec(makeHeaderRecord(opts_.version == 8 ? std::string_view{"NAMSTV8"}
                                                       : std::string_view{"NAMESTR"}, nums));

        std::uint32_t pos = 0;
        std::size_t totalNs = 0;
        for (std::size_t i = 0; i < schema_.variables.size(); ++i) {
            XptVariable v = schema_.variables[i];
            if (v.varNumber == 0) v.varNumber = static_cast<std::uint16_t>(i + 1);
            if (v.storageWidth == 0) v.storageWidth = 8;
            v.position = pos;
            auto ns = buildNamestr(v, pos, opts_.version);
            write(ns.data(), ns.size());
            pos += v.storageWidth;
            totalNs += ns.size();
        }
        // Pad NAMESTR section to 80-byte boundary.
        const std::size_t pad = totalNs % kRec;
        if (pad != 0) {
            std::vector<std::uint8_t> padBuf(kRec - pad, 0x20);
            write(padBuf.data(), padBuf.size());
        }
    }

    // LABELV8 / LABELV9 (V8 only)
    if (opts_.version == 8) {
        bool useV9 = false;
        for (const auto &v : schema_.variables) {
            if (!v.format.empty() || !v.informat.empty()) { useV9 = true; break; }
        }
        std::vector<std::size_t> idxs;
        for (std::size_t i = 0; i < schema_.variables.size(); ++i) {
            const auto &v = schema_.variables[i];
            bool need = (v.name.size() > 8) || !v.label.empty();
            if (useV9) need = need || !v.format.empty() || !v.informat.empty();
            if (need) idxs.push_back(i);
        }
        if (!idxs.empty()) {
            std::array<int, 6> nums = {static_cast<int>(idxs.size()), 0, 0, 0, 0, 0};
            writeRec(makeHeaderRecord(useV9 ? std::string_view{"LABELV9"}
                                              : std::string_view{"LABELV8"}, nums));
            std::vector<std::uint8_t> sec;
            sec.reserve(idxs.size() * 64);
            for (std::size_t i : idxs) {
                const auto &v = schema_.variables[i];
                std::uint16_t nameLen = static_cast<std::uint16_t>(v.name.size());
                std::uint16_t labelLen = static_cast<std::uint16_t>(v.label.size());
                std::uint8_t hdr[10];
                putBe16(hdr + 0, static_cast<std::uint16_t>(i + 1));
                putBe16(hdr + 2, nameLen);
                putBe16(hdr + 4, labelLen);
                std::size_t hdrLen = 6;
                if (useV9) {
                    putBe16(hdr + 6, static_cast<std::uint16_t>(v.format.size()));
                    putBe16(hdr + 8, static_cast<std::uint16_t>(v.informat.size()));
                    hdrLen = 10;
                }
                sec.insert(sec.end(), hdr, hdr + hdrLen);
                sec.insert(sec.end(), v.name.begin(), v.name.end());
                sec.insert(sec.end(), v.label.begin(), v.label.end());
                if (useV9) {
                    sec.insert(sec.end(), v.format.begin(), v.format.end());
                    sec.insert(sec.end(), v.informat.begin(), v.informat.end());
                }
            }
            write(sec.data(), sec.size());
            const std::size_t pad = sec.size() % kRec;
            if (pad != 0) {
                std::vector<std::uint8_t> padBuf(kRec - pad, 0x20);
                write(padBuf.data(), padBuf.size());
            }
        }
    }

    // OBS / OBSV8 header
    {
        std::array<int, 6> nums = {0, 0, 0, 0, 0, 0};
        writeRec(makeHeaderRecord(opts_.version == 8 ? std::string_view{"OBSV8"}
                                                       : std::string_view{"OBS"}, nums));
    }
}

void XptWriter::finish() {
    if (finished_) return;
    finished_ = true;

    // Pad data section to next 80-byte boundary with spaces.
    const std::size_t totalDataBytes = totalRowsWritten_ * rowLen_;
    const std::size_t mod = totalDataBytes % kRec;
    if (mod != 0) {
        const std::size_t padN = kRec - mod;
        std::array<std::uint8_t, kRec> pad;
        std::memset(pad.data(), 0x20, pad.size());
        appendBytes(*this, outBuf_, outPos_, file_, pad.data(), padN);
    }
    flushBuffer();
    if (file_ != nullptr) {
        if (std::fflush(file_) != 0) {
            throw std::runtime_error("Failed to flush XPT output");
        }
    }
}

}  // namespace cxpt
