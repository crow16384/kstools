#include "xpt/parser.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <span>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

#include "core/text.hpp"

namespace cxpt {
namespace {

// ===== Bit/byte helpers ======================================================

[[nodiscard]] std::uint16_t readBe16(const std::uint8_t *ptr) {
    return static_cast<std::uint16_t>((static_cast<std::uint16_t>(ptr[0]) << 8U) |
                                      static_cast<std::uint16_t>(ptr[1]));
}

[[nodiscard]] std::uint32_t readBe32(const std::uint8_t *ptr) {
    return (static_cast<std::uint32_t>(ptr[0]) << 24U) |
           (static_cast<std::uint32_t>(ptr[1]) << 16U) |
           (static_cast<std::uint32_t>(ptr[2]) << 8U) |
           static_cast<std::uint32_t>(ptr[3]);
}

// ===== Lightweight read cursor over the mmap region ==========================

class Cursor {
public:
    Cursor(const std::uint8_t *data, std::size_t size, std::size_t pos)
        : data_(data), size_(size), pos_(pos) {}

    [[nodiscard]] std::size_t pos() const noexcept { return pos_; }
    [[nodiscard]] std::size_t remaining() const noexcept { return size_ - pos_; }
    [[nodiscard]] const std::uint8_t *ptr() const noexcept { return data_ + pos_; }

    bool readRecord(std::string &out) {
        if (remaining() < kRecordLen) return false;
        out.assign(reinterpret_cast<const char *>(data_ + pos_), kRecordLen);
        pos_ += kRecordLen;
        return true;
    }
    bool peekRecord(std::string &out) const {
        if (remaining() < kRecordLen) return false;
        out.assign(reinterpret_cast<const char *>(data_ + pos_), kRecordLen);
        return true;
    }
    bool skipRecord() {
        if (remaining() < kRecordLen) return false;
        pos_ += kRecordLen;
        return true;
    }
    bool readBlock(std::size_t len, const std::uint8_t *&out) {
        if (remaining() < len) return false;
        out = data_ + pos_;
        pos_ += len;
        return true;
    }
    bool readU16Be(std::uint16_t &v) {
        if (remaining() < 2) return false;
        v = readBe16(data_ + pos_);
        pos_ += 2;
        return true;
    }
    bool readVarBlock(std::size_t len, std::string &out) {
        if (remaining() < len) return false;
        out.assign(reinterpret_cast<const char *>(data_ + pos_), len);
        pos_ += len;
        return true;
    }
    bool alignToRecordBoundary() {
        const std::size_t rem = pos_ % kRecordLen;
        if (rem == 0) return true;
        const std::size_t pad = kRecordLen - rem;
        if (remaining() < pad) return false;
        pos_ += pad;
        return true;
    }

private:
    const std::uint8_t *data_;
    std::size_t size_;
    std::size_t pos_;
};

// ===== Header record parsing =================================================

[[nodiscard]] bool parseFixedIntField(std::string_view token, int &out) {
    const std::string_view trimmed = trimBothSpacesView(token);
    if (trimmed.empty()) {
        out = 0;
        return true;
    }
    auto *begin = trimmed.data();
    auto *end = begin + trimmed.size();
    auto [ptr, ec] = std::from_chars(begin, end, out, 10);
    return ec == std::errc{} && ptr == end;
}

[[nodiscard]] bool parseHeaderRecordLine(const std::string &line,
                                         HeaderRecord &header,
                                         std::string &error) {
    constexpr std::string_view kPrefix = "HEADER RECORD*******";
    constexpr std::string_view kMiddle = "HEADER RECORD!!!!!!!";

    if (line.size() != kRecordLen) {
        error = "record length is not 80 bytes";
        return false;
    }
    if (line.compare(0, kPrefix.size(), kPrefix) != 0) {
        error = "record does not start with HEADER RECORD*******";
        return false;
    }
    if (line.compare(kPrefix.size() + 8, kMiddle.size(), kMiddle) != 0) {
        error = "record does not contain HEADER RECORD!!!!!!! marker";
        return false;
    }

    header.raw = line;
    header.name = trimRightSpaces(std::string_view(line).substr(kPrefix.size(), 8));
    if (header.name.empty()) {
        error = "header name is empty";
        return false;
    }

    const std::size_t numbersStart = kPrefix.size() + 8 + kMiddle.size();
    for (std::size_t i = 0; i < header.numbers.size(); ++i) {
        const std::size_t begin = numbersStart + i * 5;
        if (begin >= line.size()) {
            header.numbers[i] = 0;
            continue;
        }
        const std::size_t len = std::min<std::size_t>(5, line.size() - begin);
        int value = 0;
        if (!parseFixedIntField(std::string_view(line).substr(begin, len), value)) {
            std::ostringstream oss;
            oss << "invalid numeric field in header record at index " << i;
            error = oss.str();
            return false;
        }
        header.numbers[i] = value;
    }
    return true;
}

[[nodiscard]] bool readHeaderRecord(Cursor &cur, HeaderRecord &header, std::string &error) {
    std::string line;
    if (!cur.readRecord(line)) {
        error = "unexpected EOF while reading header record";
        return false;
    }
    return parseHeaderRecordLine(line, header, error);
}

// ===== NAMESTR parsing =======================================================

[[nodiscard]] XptVariable parseNameStr(const std::uint8_t *ns, int version, std::size_t index) {
    XptVariable v;
    v.index = index;
    std::copy_n(ns, kNameStrLen, v.namestrRaw.begin());

    v.ntypeRaw = readBe16(ns + 0);
    v.storageWidth = readBe16(ns + 4);
    v.varNumber = readBe16(ns + 6);
    v.displayWidth = readBe16(ns + 64);
    v.decimals = readBe16(ns + 66);
    v.alignmentCode = readBe16(ns + 68);
    v.position = readBe32(ns + 84);
    v.isString = (v.ntypeRaw == 2);

    const std::string nname = trimRightSpacesAndNulls(
        std::string_view(reinterpret_cast<const char *>(ns + 8), 8));
    const std::string longname = trimRightSpacesAndNulls(
        std::string_view(reinterpret_cast<const char *>(ns + 88), 32));
    v.name = (version == 8 && !longname.empty()) ? longname : nname;

    v.label = trimRightSpacesAndNulls(
        std::string_view(reinterpret_cast<const char *>(ns + 16), 40));

    const std::string nform = trimRightSpacesAndNulls(
        std::string_view(reinterpret_cast<const char *>(ns + 56), 8));
    if (!nform.empty()) {
        std::ostringstream f;
        f << nform;
        if (v.displayWidth != 0) f << v.displayWidth;
        if (v.decimals != 0) f << '.' << v.decimals;
        v.format = f.str();
    }

    const std::string niform = trimRightSpacesAndNulls(
        std::string_view(reinterpret_cast<const char *>(ns + 72), 8));
    const std::uint16_t nifl = readBe16(ns + 80);
    const std::uint16_t nifd = readBe16(ns + 82);
    if (!niform.empty()) {
        std::ostringstream f;
        f << niform;
        if (nifl != 0) f << nifl;
        if (nifd != 0) f << '.' << nifd;
        v.informat = f.str();
    }
    return v;
}

// ===== LABELV8 / LABELV9 sections (V8 only) ==================================

[[nodiscard]] bool parseLabelV8Section(Cursor &cur, XptSchema &schema, int labelCount,
                                       std::string &error) {
    for (int i = 0; i < labelCount; ++i) {
        std::uint16_t index = 0, nameLen = 0, labelLen = 0;
        if (!cur.readU16Be(index) || !cur.readU16Be(nameLen) || !cur.readU16Be(labelLen)) {
            error = "unexpected EOF while reading LABELV8 descriptor";
            return false;
        }
        if (index == 0 || index > schema.variables.size()) {
            error = "LABELV8 variable index is out of range";
            return false;
        }
        std::string name, label;
        if (!cur.readVarBlock(nameLen, name) || !cur.readVarBlock(labelLen, label)) {
            error = "unexpected EOF while reading LABELV8 payload";
            return false;
        }
        XptVariable &v = schema.variables[index - 1];
        v.name = trimRightSpacesAndNulls(name);
        v.label = trimRightSpacesAndNulls(label);
    }
    if (!cur.alignToRecordBoundary()) {
        error = "unexpected EOF while aligning after LABELV8 section";
        return false;
    }
    HeaderRecord obs;
    if (!readHeaderRecord(cur, obs, error)) return false;
    if (obs.name != "OBSV8") {
        error = "expected OBSV8 after LABELV8 section";
        return false;
    }
    return true;
}

[[nodiscard]] bool parseLabelV9Section(Cursor &cur, XptSchema &schema, int labelCount,
                                       std::string &error) {
    for (int i = 0; i < labelCount; ++i) {
        std::uint16_t index = 0, nameLen = 0, labelLen = 0, formatLen = 0, informatLen = 0;
        if (!cur.readU16Be(index) || !cur.readU16Be(nameLen) || !cur.readU16Be(labelLen) ||
            !cur.readU16Be(formatLen) || !cur.readU16Be(informatLen)) {
            error = "unexpected EOF while reading LABELV9 descriptor";
            return false;
        }
        if (index == 0 || index > schema.variables.size()) {
            error = "LABELV9 variable index is out of range";
            return false;
        }
        std::string name, label, format, informat;
        if (!cur.readVarBlock(nameLen, name) || !cur.readVarBlock(labelLen, label) ||
            !cur.readVarBlock(formatLen, format) || !cur.readVarBlock(informatLen, informat)) {
            error = "unexpected EOF while reading LABELV9 payload";
            return false;
        }
        XptVariable &v = schema.variables[index - 1];
        v.name = trimRightSpacesAndNulls(name);
        v.label = trimRightSpacesAndNulls(label);
        v.format = trimRightSpacesAndNulls(format);
        v.informat = trimRightSpacesAndNulls(informat);
    }
    if (!cur.alignToRecordBoundary()) {
        error = "unexpected EOF while aligning after LABELV9 section";
        return false;
    }
    HeaderRecord obs;
    if (!readHeaderRecord(cur, obs, error)) return false;
    if (obs.name != "OBSV8") {
        error = "expected OBSV8 after LABELV9 section";
        return false;
    }
    return true;
}

// ===== Trailing blank-row strip =============================================

// Compute how many full all-space `rowLen`-byte records sit at the tail end of
// the data block. These are stripped from the output (matches XPORT spec
// padding behaviour).
[[nodiscard]] std::size_t countTrailingBlankRows(const std::uint8_t *data,
                                                 std::size_t dataOffset,
                                                 std::size_t dataEnd,
                                                 std::size_t rowLen) {
    if (rowLen == 0 || dataEnd <= dataOffset) return 0;
    const std::size_t totalBytes = dataEnd - dataOffset;
    const std::size_t fullRows = totalBytes / rowLen;
    std::size_t blank = 0;
    for (std::size_t r = fullRows; r > 0; --r) {
        const std::uint8_t *p = data + dataOffset + (r - 1) * rowLen;
        if (!isBlankRow(p, rowLen)) break;
        ++blank;
    }
    return blank;
}

}  // namespace

// ===== Public API ============================================================

bool parseSchema(const std::uint8_t *data,
                 std::size_t size,
                 std::size_t memberPrefixOffset,
                 XptSchema &schema,
                 std::string &error) {
    schema.fileSize = size;

    // Single-member files start with the LIBRARY/LIBV8 prelude (3 records, 240 B)
    // followed by the MEMBER/MEMBV8 record. Multi-member callers point us
    // directly at the MEMBER record and hand us the version separately via
    // schema.version (set non-zero before calling).
    Cursor cur(data, size, memberPrefixOffset);

    bool sawLibraryPrelude = false;
    if (memberPrefixOffset == 0) {
        HeaderRecord libHeader;
        if (!readHeaderRecord(cur, libHeader, error)) {
            error = "failed to read first header record: " + error;
            return false;
        }
        if (libHeader.name == "LIBRARY") {
            schema.version = 5;
        } else if (libHeader.name == "LIBV8") {
            schema.version = 8;
        } else {
            error = "unsupported XPORT library header: " + libHeader.name;
            return false;
        }
        if (!cur.skipRecord()) {
            error = "unexpected EOF while skipping real header record";
            return false;
        }
        std::string ts;
        if (!cur.readRecord(ts)) {
            error = "unexpected EOF while reading timestamp record";
            return false;
        }
        schema.timestamp = trimRightSpaces(ts.substr(0, 16));
        sawLibraryPrelude = true;
    }

    HeaderRecord memberHeader;
    if (!readHeaderRecord(cur, memberHeader, error)) {
        error = "failed to read MEMBER header: " + error;
        return false;
    }
    if (memberHeader.name == "MEMBER") {
        if (schema.version == 0) schema.version = 5;
        else if (schema.version != 5) {
            error = "MEMBER record found but file version is not 5";
            return false;
        }
    } else if (memberHeader.name == "MEMBV8") {
        if (schema.version == 0) schema.version = 8;
        else if (schema.version != 8) {
            error = "MEMBV8 record found but file version is not 8";
            return false;
        }
    } else {
        error = "unexpected member header: " + memberHeader.name;
        return false;
    }

    HeaderRecord descHeader;
    if (!readHeaderRecord(cur, descHeader, error)) {
        error = "failed to read descriptor header: " + error;
        return false;
    }
    if ((schema.version == 5 && descHeader.name != "DSCRPTR") ||
        (schema.version == 8 && descHeader.name != "DSCPTV8")) {
        error = "unexpected descriptor header: " + descHeader.name;
        return false;
    }

    std::string tableRecord;
    if (!cur.readRecord(tableRecord)) {
        error = "unexpected EOF while reading table name record";
        return false;
    }
    const std::size_t tableNameLen = schema.version == 5 ? 8 : 32;
    schema.tableName = trimRightSpacesAndNulls(tableRecord.substr(8, tableNameLen));

    std::string fileLabelRecord;
    if (!cur.readRecord(fileLabelRecord)) {
        error = "unexpected EOF while reading file label record";
        return false;
    }
    schema.fileLabel = trimRightSpacesAndNulls(fileLabelRecord.substr(32, 40));

    HeaderRecord nsHeader;
    if (!readHeaderRecord(cur, nsHeader, error)) {
        error = "failed to read NAMESTR/NAMSTV8 header: " + error;
        return false;
    }
    if ((schema.version == 5 && nsHeader.name != "NAMESTR") ||
        (schema.version == 8 && nsHeader.name != "NAMSTV8")) {
        error = "unexpected namestr header: " + nsHeader.name;
        return false;
    }

    const int varCount = nsHeader.numbers[1];
    if (varCount < 0) {
        error = "invalid negative variable count in namestr header";
        return false;
    }
    schema.variables.reserve(static_cast<std::size_t>(varCount));
    for (int i = 0; i < varCount; ++i) {
        const std::uint8_t *nsBytes = nullptr;
        if (!cur.readBlock(kNameStrLen, nsBytes)) {
            error = "unexpected EOF while reading NAMESTR entry " + std::to_string(i + 1);
            return false;
        }
        XptVariable v = parseNameStr(nsBytes, schema.version, static_cast<std::size_t>(i));
        if (v.ntypeRaw != 1 && v.ntypeRaw != 2) {
            std::ostringstream w;
            w << "variable index " << (i + 1) << " has unexpected ntype=" << v.ntypeRaw
              << "; treating non-2 as numeric";
            schema.warnings.push_back(w.str());
        }
        schema.variables.push_back(std::move(v));
    }

    if (!cur.alignToRecordBoundary()) {
        error = "unexpected EOF while aligning after NAMESTR records";
        return false;
    }

    HeaderRecord post;
    if (!readHeaderRecord(cur, post, error)) {
        error = "failed to read post-schema header: " + error;
        return false;
    }
    if (schema.version == 5) {
        if (post.name != "OBS") {
            error = "expected OBS header, found: " + post.name;
            return false;
        }
    } else {
        if (post.name == "OBSV8") {
            // ready for data
        } else if (post.name == "LABELV8") {
            if (!parseLabelV8Section(cur, schema, post.numbers[0], error)) return false;
        } else if (post.name == "LABELV9") {
            if (!parseLabelV9Section(cur, schema, post.numbers[0], error)) return false;
        } else {
            error = "expected OBSV8/LABELV8/LABELV9 header, found: " + post.name;
            return false;
        }
    }

    // Compute per-variable byte offsets within a row.
    std::size_t rowLen = 0;
    for (auto &v : schema.variables) {
        v.byteOffset = rowLen;
        rowLen += v.storageWidth;
    }
    schema.rowLen = rowLen;
    schema.dataOffset = cur.pos();

    // Find the end of this member's data block. For a single-member file, that
    // is the end of the buffer (modulo trailing space padding). For
    // multi-member files the caller will have constrained `size` to the byte
    // range of this member.
    schema.dataEnd = size;

    // Strip trailing all-space records from the row-count tally.
    schema.trailingBlankRows = countTrailingBlankRows(data, schema.dataOffset, schema.dataEnd, rowLen);

    if (rowLen == 0) {
        schema.rowCount = 0;
    } else {
        const std::size_t totalBytes = schema.dataEnd - schema.dataOffset;
        const std::size_t fullRows = totalBytes / rowLen;
        const std::size_t trailingPartial = totalBytes - fullRows * rowLen;
        if (trailingPartial > 0) {
            std::ostringstream w;
            w << "ignored " << trailingPartial
              << " trailing byte(s) after row parsing (likely record padding)";
            schema.warnings.push_back(w.str());
        }
        schema.rowCount = fullRows - schema.trailingBlankRows;
        // Adjust dataEnd to exclude the stripped trailing blanks so the row
        // decoder treats the file as ending exactly at row N.
        schema.dataEnd = schema.dataOffset + schema.rowCount * rowLen;
    }

    if (sawLibraryPrelude && schema.version != 5 && schema.version != 8) {
        error = "unsupported XPORT version";
        return false;
    }
    return true;
}

std::vector<std::size_t> scanMemberOffsets(const std::uint8_t *data, std::size_t size) {
    std::vector<std::size_t> out;
    static constexpr char kPrefix[] = "HEADER RECORD*******";
    static constexpr char kInfix[] = "HEADER RECORD!!!!!!!";
    constexpr std::size_t prefLen = 20;
    constexpr std::size_t infixLen = 20;
    constexpr std::size_t recLen = kRecordLen;

    if (size < recLen) return out;
    for (std::size_t pos = 0; pos + recLen <= size; pos += recLen) {
        if (std::memcmp(data + pos, kPrefix, prefLen) != 0) continue;
        if (std::memcmp(data + pos + 28, kInfix, infixLen) != 0) continue;
        std::string name(reinterpret_cast<const char *>(data + pos + 20), 8);
        while (!name.empty() && name.back() == ' ') name.pop_back();
        if (name == "MEMBER" || name == "MEMBV8") out.push_back(pos);
    }
    return out;
}

}  // namespace cxpt
