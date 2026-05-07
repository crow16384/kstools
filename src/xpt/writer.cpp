#include "xpt/writer.hpp"

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <fstream>
#include <ostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace cxpt {
namespace {

constexpr std::size_t kRec = kRecordLen;  // 80
constexpr std::size_t kNs  = kNameStrLen; // 140

// -------- byte writers --------

void writeBe16(std::vector<std::uint8_t> &out, std::uint16_t v) {
    out.push_back(static_cast<std::uint8_t>((v >> 8) & 0xFF));
    out.push_back(static_cast<std::uint8_t>( v       & 0xFF));
}
void writeBe32(std::vector<std::uint8_t> &out, std::uint32_t v) {
    out.push_back(static_cast<std::uint8_t>((v >> 24) & 0xFF));
    out.push_back(static_cast<std::uint8_t>((v >> 16) & 0xFF));
    out.push_back(static_cast<std::uint8_t>((v >>  8) & 0xFF));
    out.push_back(static_cast<std::uint8_t>( v        & 0xFF));
}
void putBe16(std::uint8_t *p, std::uint16_t v) {
    p[0] = static_cast<std::uint8_t>((v >> 8) & 0xFF);
    p[1] = static_cast<std::uint8_t>( v       & 0xFF);
}
void putBe32(std::uint8_t *p, std::uint32_t v) {
    p[0] = static_cast<std::uint8_t>((v >> 24) & 0xFF);
    p[1] = static_cast<std::uint8_t>((v >> 16) & 0xFF);
    p[2] = static_cast<std::uint8_t>((v >>  8) & 0xFF);
    p[3] = static_cast<std::uint8_t>( v        & 0xFF);
}

void appendBytes(std::vector<std::uint8_t> &out, const void *data, std::size_t n) {
    const auto *p = static_cast<const std::uint8_t *>(data);
    out.insert(out.end(), p, p + n);
}


// Write a fixed-width left-justified, space-padded ASCII field at [offset, offset+width).
void putFixedField(std::uint8_t *dst, std::size_t width, std::string_view s) {
    std::memset(dst, 0x20, width);
    const std::size_t n = std::min(width, s.size());
    if (n > 0) std::memcpy(dst, s.data(), n);
}

// -------- IBM XPORT float encoding --------
// value = sign * (mantissa / 2^56) * 16^(charac - 64)
// mantissa is in [1/16, 1) for normalized numbers.

std::array<std::uint8_t, 8> doubleToIbmXport(double v) {
    std::array<std::uint8_t, 8> out{};

    if (v == 0.0 || !std::isfinite(v)) {
        return out;  // all zeros
    }

    const bool sign = std::signbit(v);
    double absv = std::fabs(v);

    // Find characteristic so that mantissa = absv * 16^-(c-64) is in [1/16, 1).
    int charac = static_cast<int>(std::floor(std::log(absv) / std::log(16.0))) + 1;
    double mantissa = absv * std::pow(16.0, -static_cast<double>(charac));

    // Renormalize for floating-point inaccuracies
    while (mantissa >= 1.0) { mantissa /= 16.0; ++charac; }
    while (mantissa > 0.0 && mantissa < 1.0 / 16.0) { mantissa *= 16.0; --charac; }

    int storedExp = charac + 64;
    if (storedExp <= 0 || storedExp > 127) {
        // Out of range -> store as zero (best-effort)
        return out;
    }

    // Pack mantissa into 56-bit unsigned integer.
    std::uint64_t m = static_cast<std::uint64_t>(mantissa * std::ldexp(1.0, 56) + 0.5);
    if (m >= (static_cast<std::uint64_t>(1) << 56)) {
        m >>= 4;
        ++storedExp;
        if (storedExp > 127) return out;
    }

    out[0] = static_cast<std::uint8_t>((sign ? 0x80 : 0x00) | (storedExp & 0x7F));
    for (int i = 1; i <= 7; ++i) {
        out[i] = static_cast<std::uint8_t>((m >> (8 * (7 - i))) & 0xFF);
    }
    return out;
}

// -------- format string parsing --------
// "DATE9." -> ("DATE", 9, 0); "F8.2" -> ("F", 8, 2); "$20." -> ("$", 20, 0)
struct ParsedFormat {
    std::string name;
    std::uint16_t width = 0;
    std::uint16_t decimals = 0;
};

ParsedFormat parseSasFormat(std::string_view fmt) {
    ParsedFormat pf;
    std::size_t i = 0;
    // Optional leading '$' for character formats
    if (i < fmt.size() && fmt[i] == '$') { pf.name.push_back('$'); ++i; }
    // Alphabetic prefix
    while (i < fmt.size() && std::isalpha(static_cast<unsigned char>(fmt[i]))) {
        pf.name.push_back(fmt[i]);
        ++i;
    }
    // Digits (width)
    std::uint16_t w = 0;
    bool wAny = false;
    while (i < fmt.size() && std::isdigit(static_cast<unsigned char>(fmt[i]))) {
        w = static_cast<std::uint16_t>(w * 10 + (fmt[i] - '0'));
        wAny = true;
        ++i;
    }
    if (wAny) pf.width = w;
    // Optional .decimals
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

// -------- 80-byte HEADER RECORD construction --------
// Layout: "HEADER RECORD*******" + 8-char name + " HEADER RECORD!!!!!!!!" + 6 × 5-char numeric fields + space pad
//
// Note: parser checks the literal at offset 0..19 ("HEADER RECORD*******")
// then 8-char name, then "HEADER RECORD!!!!!!!" at offset 28..47.
std::array<std::uint8_t, 80> makeHeaderRecord(std::string_view name8, const std::array<int, 6> &nums) {
    std::array<std::uint8_t, 80> rec{};
    std::memset(rec.data(), 0x20, rec.size());
    static const char kPrefix[] = "HEADER RECORD*******";
    static const char kMiddle[] = "HEADER RECORD!!!!!!!";
    std::memcpy(rec.data() + 0,  kPrefix, 20);
    putFixedField(rec.data() + 20, 8, name8);
    std::memcpy(rec.data() + 28, kMiddle, 20);
    // Six 5-digit numeric fields: total 30 bytes at offset 48..77, then 2 spaces at 78..79
    for (std::size_t i = 0; i < 6; ++i) {
        char buf[6];
        std::snprintf(buf, sizeof(buf), "%5d", nums[i]);
        std::memcpy(rec.data() + 48 + i * 5, buf, 5);
    }
    return rec;
}

// -------- Real header (the 2nd record of the 240-byte file header triplet) --------
// Format from SAS docs: "SAS     SAS     SASLIB  9.0     <OS>            ddMMMyy:hh:mm:ss"
//   bytes 0-7   : "SAS     "
//   bytes 8-15  : "SAS     "
//   bytes 16-23 : "SASLIB  "
//   bytes 24-31 : SAS version, e.g. "9.0     "
//   bytes 32-39 : OS name (8 chars, V5)
//   bytes 40-63 : padding
//   bytes 64-79 : creation timestamp "ddMMMyy:hh:mm:ss"
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

// -------- Timestamp record: "ddMMMyy:hh:mm:ss" left-justified --------
std::array<std::uint8_t, 80> makeTimestampRecord(std::string_view timestamp) {
    std::array<std::uint8_t, 80> rec{};
    std::memset(rec.data(), 0x20, rec.size());
    putFixedField(rec.data(), 16, timestamp);
    return rec;
}

std::string makeNowTimestamp() {
    std::time_t t = std::time(nullptr);
    std::tm tm{};
#if defined(_WIN32)
    gmtime_s(&tm, &t);
#else
    gmtime_r(&t, &tm);
#endif
    static constexpr const char * const months[] = {"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"};
    char buf[17];
    std::snprintf(buf, sizeof(buf), "%02d%s%02d:%02d:%02d:%02d",
                  tm.tm_mday, months[tm.tm_mon], tm.tm_year % 100,
                  tm.tm_hour, tm.tm_min, tm.tm_sec);
    return std::string(buf);
}

// -------- Member-info pair: MEMBER/MEMBV8 + DSCRPTR/DSCPTV8 --------
// MEMBER header: nums[0]=0 nums[1]=160 nums[2]=0 nums[3]=140 nums[4]=0 nums[5]=140
//   (Per SAS docs, the magic "marker" record numbers tell tools the member descriptor sizes.)
// We follow the convention used by SAS, ReadStat, haven, and cxpt fixtures.
std::array<std::uint8_t, 80> makeMemberHeader(int version) {
    // num[3] is the NAMESTR length (140) -- this is what triggers parser member detection.
    std::array<int, 6> nums = {0, 160, 0, static_cast<int>(kNs), 0, 140};
    return makeHeaderRecord(version == 8 ? std::string_view{"MEMBV8"} : std::string_view{"MEMBER"}, nums);
}
std::array<std::uint8_t, 80> makeDscrptrHeader(int version) {
    std::array<int, 6> nums = {0, 0, 0, 0, 0, 0};
    return makeHeaderRecord(version == 8 ? std::string_view{"DSCPTV8"} : std::string_view{"DSCRPTR"}, nums);
}

// -------- Member info record (table name + label + type + os + version + timestamp + modified) --------
// 80 bytes. Layout per SAS docs:
//   bytes 0-31 : "SAS     <dsname>SASDATA <version>" (V5)
//                or extended for V8 (table name 32 chars at offset 8..31 plus)
//   bytes 32-39: SAS version
//   bytes 40-47: OS name
//   bytes 48-63: padding
//   bytes 64-79: creation timestamp
// For V5 the dataset name occupies bytes 8..15 (8 chars).
// For V8 we use the same record format; the dataset's longer name is conveyed via
// the second member record (the table name record below) at offset 8..39.
std::array<std::uint8_t, 80> makeMemberInfoRecord(std::string_view dsname,
                                                  std::string_view sasVersion,
                                                  std::string_view osName,
                                                  std::string_view timestamp,
                                                  int version) {
    std::array<std::uint8_t, 80> rec{};
    std::memset(rec.data(), 0x20, rec.size());
    putFixedField(rec.data() + 0,  8, "SAS");
    if (version == 8) {
        // V8: dataset name 32 chars at offset 8..39
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

// Second member record: modified-timestamp + dataset label.
//   bytes 0-15 : modified timestamp
//   bytes 16-23: padding (V5) -- some specs put dataset type "DATA" here
//   bytes 32-71: dataset label (40 chars)
//   bytes 72-79: dataset type ("DATA") + padding
std::array<std::uint8_t, 80> makeMemberInfo2Record(std::string_view modifiedTs,
                                                   std::string_view fileLabel) {
    std::array<std::uint8_t, 80> rec{};
    std::memset(rec.data(), 0x20, rec.size());
    putFixedField(rec.data() + 0, 16, modifiedTs);
    putFixedField(rec.data() + 32, 40, fileLabel);
    putFixedField(rec.data() + 72, 8, "DATA");
    return rec;
}

// -------- NAMESTR (140 bytes) --------
std::array<std::uint8_t, kNs> buildNamestr(const XptVariable &v, std::uint32_t pos, int version) {
    std::array<std::uint8_t, kNs> r{};
    // All-zero by default (matches reserved fields)

    putBe16(r.data() + 0,  v.ntypeRaw);            // ntype: 1=numeric, 2=character
    putBe16(r.data() + 2,  0);                      // nhfun (reserved)
    putBe16(r.data() + 4,  v.storageWidth);         // nlng
    putBe16(r.data() + 6,  v.varNumber);            // nvar0

    putFixedField(r.data() + 8,  8,  v.name);       // nname (truncated to 8)
    putFixedField(r.data() + 16, 40, v.label);      // nlabel

    // Format: nform (8 char name prefix) + nfl + nfd
    ParsedFormat fmt = parseSasFormat(v.format);
    putFixedField(r.data() + 56, 8, fmt.name);
    putBe16(r.data() + 64, fmt.width != 0 ? fmt.width : v.displayWidth);
    putBe16(r.data() + 66, fmt.decimals != 0 ? fmt.decimals : v.decimals);
    putBe16(r.data() + 68, v.alignmentCode);        // nfj
    // bytes 70-71 nfill: zero (already)

    // Informat
    ParsedFormat ifmt = parseSasFormat(v.informat);
    putFixedField(r.data() + 72, 8, ifmt.name);
    putBe16(r.data() + 80, ifmt.width);
    putBe16(r.data() + 82, ifmt.decimals);

    putBe32(r.data() + 84, pos);                    // npos

    // V8 longname at offset 88 (32 bytes)
    if (version == 8) {
        putFixedField(r.data() + 88, 32, v.name);
    }
    // bytes 120-121 labeln, 122-139 rest: zero (already)
    return r;
}

// -------- writer entry --------

void appendRecord(std::vector<std::uint8_t> &out, const std::array<std::uint8_t, 80> &rec) {
    out.insert(out.end(), rec.begin(), rec.end());
}

// LABELV8 / LABELV9 section construction.
//   LABELV8 entry: [u16 idx][u16 nameLen][u16 labelLen][name][label]
//   LABELV9 entry: [u16 idx][u16 nameLen][u16 labelLen][u16 fmtLen][u16 ifmtLen]
//                  [name][label][format][informat]
// Header is HEADER RECORD with name "LABELV8"/"LABELV9", num1=count of entries.
void appendLabelSection(std::vector<std::uint8_t> &out,
                        const std::vector<XptVariable> &vars,
                        bool useV9) {
    // Decide which variables need entries. For V8: name>8 chars OR label nonempty.
    // For V9: also include if format or informat nonempty.
    std::vector<std::size_t> idxs;
    for (std::size_t i = 0; i < vars.size(); ++i) {
        const auto &v = vars[i];
        bool need = (v.name.size() > 8) || !v.label.empty();
        if (useV9) need = need || !v.format.empty() || !v.informat.empty();
        if (need) idxs.push_back(i);
    }
    if (idxs.empty()) return;

    std::array<int, 6> nums = {static_cast<int>(idxs.size()), 0, 0, 0, 0, 0};
    auto hdr = makeHeaderRecord(useV9 ? std::string_view{"LABELV9"} : std::string_view{"LABELV8"}, nums);
    appendRecord(out, hdr);

    std::size_t startSection = out.size();

    for (std::size_t i : idxs) {
        const auto &v = vars[i];
        std::uint16_t nameLen  = static_cast<std::uint16_t>(v.name.size());
        std::uint16_t labelLen = static_cast<std::uint16_t>(v.label.size());
        writeBe16(out, static_cast<std::uint16_t>(i + 1)); // 1-based variable index
        writeBe16(out, nameLen);
        writeBe16(out, labelLen);
        if (useV9) {
            writeBe16(out, static_cast<std::uint16_t>(v.format.size()));
            writeBe16(out, static_cast<std::uint16_t>(v.informat.size()));
        }
        appendBytes(out, v.name.data(), v.name.size());
        appendBytes(out, v.label.data(), v.label.size());
        if (useV9) {
            appendBytes(out, v.format.data(), v.format.size());
            appendBytes(out, v.informat.data(), v.informat.size());
        }
    }
    // Pad section to 80-byte boundary with spaces.
    std::size_t sectionLen = out.size() - startSection;
    std::size_t r = sectionLen % kRec;
    if (r != 0) out.insert(out.end(), kRec - r, 0x20);
}

void encodeRow(std::vector<std::uint8_t> &out,
               const XptRow &row,
               const std::vector<XptVariable> &vars) {
    if (row.cells.size() != vars.size()) {
        throw std::runtime_error("row cell count does not match variable count");
    }
    for (std::size_t i = 0; i < vars.size(); ++i) {
        const auto &var = vars[i];
        const auto &cell = row.cells[i];
        if (var.isString) {
            // Right-pad with spaces to storageWidth.
            std::vector<std::uint8_t> buf(var.storageWidth, 0x20);
            const std::string &s = cell.stringRaw.empty() ? cell.stringTrimmed : cell.stringRaw;
            std::size_t n = std::min(static_cast<std::size_t>(var.storageWidth), s.size());
            for (std::size_t j = 0; j < n; ++j) {
                buf[j] = static_cast<std::uint8_t>(s[j]);
            }
            out.insert(out.end(), buf.begin(), buf.end());
        } else {
            std::array<std::uint8_t, 8> ibm{};
            if (cell.numeric.isSystemMissing) {
                ibm[0] = 0x2E;  // '.'
            } else if (cell.numeric.isTaggedMissing) {
                ibm[0] = static_cast<std::uint8_t>(cell.numeric.tag);
            } else if (cell.numeric.hasValue) {
                ibm = doubleToIbmXport(cell.numeric.value);
            }
            // storageWidth is the number of bytes to write (3..8); high bytes go first.
            std::size_t w = std::min<std::size_t>(8, var.storageWidth);
            if (w == 0) w = 8;
            out.insert(out.end(), ibm.begin(), ibm.begin() + w);
        }
    }
}

}  // namespace

void writeXptFile(const XptFile &file, const std::string &path, const WriteOptions &opts) {
    if (opts.version != 5 && opts.version != 8) {
        throw std::runtime_error("WriteOptions.version must be 5 or 8");
    }

    const std::string ts = opts.timestamp.empty() ? makeNowTimestamp() : opts.timestamp;
    const std::string osName = opts.sasOs.empty() ? std::string{"R"} : opts.sasOs;

    std::vector<std::uint8_t> buf;
    buf.reserve(1024);

    // -------- File header (240 bytes) --------
    {
        std::array<int, 6> nums = {0, 0, 0, 0, 0, 0};
        auto libHdr = makeHeaderRecord(opts.version == 8 ? std::string_view{"LIBV8"} : std::string_view{"LIBRARY"}, nums);
        appendRecord(buf, libHdr);
        appendRecord(buf, makeRealHeader("9.0", osName, ts));
        appendRecord(buf, makeTimestampRecord(ts));
    }

    // -------- Member header (160 bytes) --------
    appendRecord(buf, makeMemberHeader(opts.version));
    appendRecord(buf, makeDscrptrHeader(opts.version));

    // -------- Member info records (table name + label, 160 bytes total) --------
    const std::string dsname = opts.datasetName.empty() ? std::string{"DATASET"} : opts.datasetName;
    appendRecord(buf, makeMemberInfoRecord(dsname, "9.0", osName, ts, opts.version));
    appendRecord(buf, makeMemberInfo2Record(ts, opts.fileLabel));

    // -------- NAMESTR header --------
    {
        const auto &vars = file.variables;
        std::array<int, 6> nums = {0, static_cast<int>(vars.size()), 0, 0, 0, 0};
        auto nsHdr = makeHeaderRecord(opts.version == 8 ? std::string_view{"NAMSTV8"} : std::string_view{"NAMESTR"}, nums);
        appendRecord(buf, nsHdr);

        std::size_t startNs = buf.size();
        std::uint32_t pos = 0;
        for (std::size_t i = 0; i < vars.size(); ++i) {
            XptVariable v = vars[i];
            if (v.varNumber == 0) v.varNumber = static_cast<std::uint16_t>(i + 1);
            if (v.storageWidth == 0) v.storageWidth = v.isString ? 8 : 8;
            v.position = pos;
            auto ns = buildNamestr(v, pos, opts.version);
            buf.insert(buf.end(), ns.begin(), ns.end());
            pos += v.storageWidth;
        }
        std::size_t namestrLen = buf.size() - startNs;
        std::size_t r = namestrLen % kRec;
        if (r != 0) buf.insert(buf.end(), kRec - r, 0x20);  // pad with spaces (SAS spec)
    }

    // -------- LABELV8/LABELV9 (V8 only) --------
    if (opts.version == 8) {
        // Use LABELV9 if any variable has format or informat info.
        bool hasFmt = false;
        for (const auto &v : file.variables) {
            if (!v.format.empty() || !v.informat.empty()) { hasFmt = true; break; }
        }
        appendLabelSection(buf, file.variables, hasFmt);
    }

    // -------- OBS header --------
    {
        std::array<int, 6> nums = {0, 0, 0, 0, 0, 0};
        auto obsHdr = makeHeaderRecord(opts.version == 8 ? std::string_view{"OBSV8"} : std::string_view{"OBS"}, nums);
        appendRecord(buf, obsHdr);
    }

    // -------- Data rows --------
    std::size_t dataStart = buf.size();
    for (const auto &row : file.rows) {
        encodeRow(buf, row, file.variables);
    }
    // Pad data section to 80-byte boundary with spaces (XPORT spec).
    std::size_t dataLen = buf.size() - dataStart;
    std::size_t r = dataLen % kRec;
    if (r != 0) buf.insert(buf.end(), kRec - r, 0x20);

    // -------- Write to disk --------
    std::ofstream ofs(path, std::ios::binary);
    if (!ofs) {
        throw std::runtime_error("Cannot open file for writing: " + path);
    }
    ofs.write(reinterpret_cast<const char *>(buf.data()), static_cast<std::streamsize>(buf.size()));
    if (!ofs) {
        throw std::runtime_error("Failed writing XPORT file: " + path);
    }
}

}  // namespace cxpt
