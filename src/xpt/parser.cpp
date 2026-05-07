#include "xpt/parser.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <fstream>
#include <limits>
#include <span>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

#include "core/text.hpp"

namespace cxpt {
namespace {

class ByteCursor {
public:
    explicit ByteCursor(const std::vector<std::uint8_t> &bytes) : bytes_(bytes) {}

    [[nodiscard]] std::size_t pos() const { return pos_; }
    [[nodiscard]] std::size_t remaining() const { return bytes_.size() - pos_; }

    bool readRecord(std::string &out) {
        if (remaining() < kRecordLen) {
            return false;
        }
        out.assign(reinterpret_cast<const char *>(bytes_.data() + pos_), kRecordLen);
        pos_ += kRecordLen;
        return true;
    }

    bool skipRecord() {
        if (remaining() < kRecordLen) {
            return false;
        }
        pos_ += kRecordLen;
        return true;
    }

    bool readBlock(std::size_t len, std::span<const std::uint8_t> &out) {
        if (remaining() < len) {
            return false;
        }
        out = std::span<const std::uint8_t>(bytes_.data() + pos_, len);
        pos_ += len;
        return true;
    }

    bool alignToRecordBoundary() {
        const std::size_t rem = pos_ % kRecordLen;
        if (rem == 0) {
            return true;
        }
        const std::size_t pad = kRecordLen - rem;
        if (remaining() < pad) {
            return false;
        }
        pos_ += pad;
        return true;
    }

private:
    const std::vector<std::uint8_t> &bytes_;
    std::size_t pos_ = 0;
};

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

[[nodiscard]] bool parseHeaderRecordLine(const std::string &line, HeaderRecord &header, std::string &error) {
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

[[nodiscard]] bool readHeaderRecord(ByteCursor &cursor, HeaderRecord &header, std::string &error) {
    std::string line;
    if (!cursor.readRecord(line)) {
        error = "unexpected EOF while reading header record";
        return false;
    }

    return parseHeaderRecordLine(line, header, error);
}

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

[[nodiscard]] bool ibmXportToDouble(std::span<const std::uint8_t> rawValue, double &outValue) {
    if (rawValue.empty()) {
        return false;
    }

    std::array<std::uint8_t, 8> full{};
    const std::size_t width = std::min<std::size_t>(8, rawValue.size());
    std::copy_n(rawValue.begin(), width, full.begin());

    const bool allZero = std::all_of(full.begin(), full.end(), [](std::uint8_t b) { return b == 0; });
    if (allZero) {
        outValue = 0.0;
        return true;
    }

    const int sign = (full[0] & 0x80U) ? -1 : 1;
    const int exponent16 = static_cast<int>(full[0] & 0x7FU) - 64;

    std::uint64_t fraction = 0;
    for (std::size_t i = 1; i < full.size(); ++i) {
        fraction = (fraction << 8U) | full[i];
    }

    const long double mantissa = static_cast<long double>(fraction) /
                                 static_cast<long double>(std::uint64_t{1} << 56U);
    const long double value = std::ldexp(mantissa, exponent16 * 4);
    const long double signedValue = static_cast<long double>(sign) * value;
    const double result = static_cast<double>(signedValue);

    if (!std::isfinite(result)) {
        return false;
    }

    outValue = result;
    return true;
}

[[nodiscard]] bool isSasTaggedMissingByte(std::uint8_t value) {
    return value == '_' || (value >= 'A' && value <= 'Z');
}

[[nodiscard]] NumericValue decodeNumericCell(const std::vector<std::uint8_t> &raw) {
    NumericValue numeric;
    numeric.raw = raw;

    if (raw.size() < 3 || raw.size() > 8) {
        return numeric;
    }

    bool restZero = true;
    for (std::size_t i = 1; i < raw.size(); ++i) {
        if (raw[i] != 0) {
            restZero = false;
            break;
        }
    }

    if (restZero && (raw[0] == '.' || isSasTaggedMissingByte(raw[0]))) {
        if (raw[0] == '.') {
            numeric.isSystemMissing = true;
        } else {
            numeric.isTaggedMissing = true;
            numeric.tag = static_cast<char>(raw[0]);
        }
        return numeric;
    }

    double parsed = std::numeric_limits<double>::quiet_NaN();
    if (ibmXportToDouble(raw, parsed)) {
        numeric.hasValue = true;
        numeric.value = parsed;
    }

    return numeric;
}

[[nodiscard]] std::vector<std::uint8_t> readWholeFile(const std::string &path, std::string &error) {
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        error = "failed to open file";
        return {};
    }

    in.seekg(0, std::ios::end);
    const std::streampos end = in.tellg();
    if (end < 0) {
        error = "failed to determine file size";
        return {};
    }
    in.seekg(0, std::ios::beg);

    std::vector<std::uint8_t> bytes(static_cast<std::size_t>(end));
    if (!bytes.empty()) {
        in.read(reinterpret_cast<char *>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
        if (!in) {
            error = "failed to read file bytes";
            return {};
        }
    }

    return bytes;
}

[[nodiscard]] XptVariable parseNameStr(std::span<const std::uint8_t, kNameStrLen> ns, int version,
                                       std::size_t index) {
    XptVariable variable;
    variable.index = index;

    std::copy_n(ns.begin(), kNameStrLen, variable.namestrRaw.begin());

    variable.ntypeRaw = readBe16(ns.data() + 0);
    variable.storageWidth = readBe16(ns.data() + 4);
    variable.varNumber = readBe16(ns.data() + 6);
    variable.displayWidth = readBe16(ns.data() + 64);
    variable.decimals = readBe16(ns.data() + 66);
    variable.alignmentCode = readBe16(ns.data() + 68);
    variable.position = readBe32(ns.data() + 84);

    variable.isString = (variable.ntypeRaw == 2);

    const std::string nname = trimRightSpacesAndNulls(
        std::string_view(reinterpret_cast<const char *>(ns.data() + 8), 8));
    const std::string longname = trimRightSpacesAndNulls(
        std::string_view(reinterpret_cast<const char *>(ns.data() + 88), 32));
    variable.name = (version == 8 && !longname.empty()) ? longname : nname;

    variable.label = trimRightSpacesAndNulls(
        std::string_view(reinterpret_cast<const char *>(ns.data() + 16), 40));

    const std::string nform = trimRightSpacesAndNulls(
        std::string_view(reinterpret_cast<const char *>(ns.data() + 56), 8));
    if (!nform.empty()) {
        std::ostringstream format;
        format << nform;
        if (variable.displayWidth != 0) {
            format << variable.displayWidth;
        }
        if (variable.decimals != 0) {
            format << '.' << variable.decimals;
        }
        variable.format = format.str();
    }

    const std::string niform = trimRightSpacesAndNulls(
        std::string_view(reinterpret_cast<const char *>(ns.data() + 72), 8));
    const std::uint16_t nifl = readBe16(ns.data() + 80);
    const std::uint16_t nifd = readBe16(ns.data() + 82);
    if (!niform.empty()) {
        std::ostringstream informat;
        informat << niform;
        if (nifl != 0) {
            informat << nifl;
        }
        if (nifd != 0) {
            informat << '.' << nifd;
        }
        variable.informat = informat.str();
    }

    return variable;
}

[[nodiscard]] bool readU16Be(ByteCursor &cursor, std::uint16_t &value) {
    std::span<const std::uint8_t> data;
    if (!cursor.readBlock(2, data)) {
        return false;
    }
    value = readBe16(data.data());
    return true;
}

[[nodiscard]] bool readVariableLengthBlock(ByteCursor &cursor, std::size_t len, std::string &out) {
    std::span<const std::uint8_t> data;
    if (!cursor.readBlock(len, data)) {
        return false;
    }
    out.assign(reinterpret_cast<const char *>(data.data()), data.size());
    return true;
}

[[nodiscard]] bool parseLabelV8Section(ByteCursor &cursor, XptFile &file, int labelCount,
                                       std::string &error) {
    for (int i = 0; i < labelCount; ++i) {
        std::uint16_t index = 0;
        std::uint16_t nameLen = 0;
        std::uint16_t labelLen = 0;
        if (!readU16Be(cursor, index) || !readU16Be(cursor, nameLen) || !readU16Be(cursor, labelLen)) {
            error = "unexpected EOF while reading LABELV8 descriptor";
            return false;
        }

        if (index == 0 || index > file.variables.size()) {
            error = "LABELV8 variable index is out of range";
            return false;
        }

        std::string name;
        std::string label;
        if (!readVariableLengthBlock(cursor, nameLen, name) || !readVariableLengthBlock(cursor, labelLen, label)) {
            error = "unexpected EOF while reading LABELV8 payload";
            return false;
        }

        XptVariable &var = file.variables[index - 1];
        var.name = trimRightSpacesAndNulls(name);
        var.label = trimRightSpacesAndNulls(label);
    }

    if (!cursor.alignToRecordBoundary()) {
        error = "unexpected EOF while aligning after LABELV8 section";
        return false;
    }

    HeaderRecord obsHeader;
    if (!readHeaderRecord(cursor, obsHeader, error)) {
        return false;
    }
    if (obsHeader.name != "OBSV8") {
        error = "expected OBSV8 after LABELV8 section";
        return false;
    }

    return true;
}

[[nodiscard]] bool parseLabelV9Section(ByteCursor &cursor, XptFile &file, int labelCount,
                                       std::string &error) {
    for (int i = 0; i < labelCount; ++i) {
        std::uint16_t index = 0;
        std::uint16_t nameLen = 0;
        std::uint16_t labelLen = 0;
        std::uint16_t formatLen = 0;
        std::uint16_t informatLen = 0;

        if (!readU16Be(cursor, index) || !readU16Be(cursor, nameLen) || !readU16Be(cursor, labelLen) ||
            !readU16Be(cursor, formatLen) || !readU16Be(cursor, informatLen)) {
            error = "unexpected EOF while reading LABELV9 descriptor";
            return false;
        }

        if (index == 0 || index > file.variables.size()) {
            error = "LABELV9 variable index is out of range";
            return false;
        }

        std::string name;
        std::string label;
        std::string format;
        std::string informat;

        if (!readVariableLengthBlock(cursor, nameLen, name) || !readVariableLengthBlock(cursor, labelLen, label) ||
            !readVariableLengthBlock(cursor, formatLen, format) ||
            !readVariableLengthBlock(cursor, informatLen, informat)) {
            error = "unexpected EOF while reading LABELV9 payload";
            return false;
        }

        XptVariable &var = file.variables[index - 1];
        var.name = trimRightSpacesAndNulls(name);
        var.label = trimRightSpacesAndNulls(label);
        var.format = trimRightSpacesAndNulls(format);
        var.informat = trimRightSpacesAndNulls(informat);
    }

    if (!cursor.alignToRecordBoundary()) {
        error = "unexpected EOF while aligning after LABELV9 section";
        return false;
    }

    HeaderRecord obsHeader;
    if (!readHeaderRecord(cursor, obsHeader, error)) {
        return false;
    }
    if (obsHeader.name != "OBSV8") {
        error = "expected OBSV8 after LABELV9 section";
        return false;
    }

    return true;
}

[[nodiscard]] XptRow parseRow(const std::vector<std::uint8_t> &rowBytes,
                              const std::vector<XptVariable> &variables, bool wasBlankPaddingRow) {
    XptRow row;
    row.raw = rowBytes;
    row.wasBlankPaddingRow = wasBlankPaddingRow;
    row.cells.reserve(variables.size());

    std::size_t pos = 0;
    for (const XptVariable &var : variables) {
        CellValue cell;
        cell.isString = var.isString;

        const std::size_t width = var.storageWidth;
        cell.raw.assign(rowBytes.begin() + static_cast<std::ptrdiff_t>(pos),
                        rowBytes.begin() + static_cast<std::ptrdiff_t>(pos + width));

        if (var.isString) {
            cell.stringRaw.assign(reinterpret_cast<const char *>(cell.raw.data()), cell.raw.size());
            cell.stringTrimmed = trimRightSpaces(cell.stringRaw);
        } else {
            cell.numeric = decodeNumericCell(cell.raw);
        }

        pos += width;
        row.cells.push_back(std::move(cell));
    }

    return row;
}

void parseDataRows(ByteCursor &cursor, XptFile &file) {
    std::size_t rowLen = 0;
    for (const XptVariable &var : file.variables) {
        rowLen += var.storageWidth;
    }

    if (rowLen == 0) {
        return;
    }

    std::vector<std::uint8_t> blankRow(rowLen, static_cast<std::uint8_t>(' '));
    std::size_t pendingBlankRows = 0;

    while (cursor.remaining() >= rowLen) {
        std::span<const std::uint8_t> rowData;
        if (!cursor.readBlock(rowLen, rowData)) {
            break;
        }

        std::vector<std::uint8_t> rowBytes(rowData.begin(), rowData.end());
        const bool allSpaces = std::all_of(rowBytes.begin(), rowBytes.end(), [](std::uint8_t b) {
            return b == static_cast<std::uint8_t>(' ');
        });

        if (allSpaces) {
            ++pendingBlankRows;
            continue;
        }

        while (pendingBlankRows > 0) {
            file.rows.push_back(parseRow(blankRow, file.variables, true));
            --pendingBlankRows;
        }

        file.rows.push_back(parseRow(rowBytes, file.variables, false));
    }

    if (pendingBlankRows > 0) {
        std::ostringstream warn;
        warn << "dropped " << pendingBlankRows
             << " trailing all-space row chunk(s) due to end-of-file padding ambiguity";
        file.warnings.push_back(warn.str());
    }

    if (cursor.remaining() > 0) {
        std::ostringstream warn;
        warn << "ignored " << cursor.remaining()
             << " trailing byte(s) after row parsing (likely record padding)";
        file.warnings.push_back(warn.str());
    }
}

} // namespace

ParseResult parseXptFile(const std::string &path) {
    ParseResult result;
    result.file.path = path;

    std::string ioError;
    std::vector<std::uint8_t> bytes = readWholeFile(path, ioError);
    if (!ioError.empty()) {
        result.error = ioError;
        return result;
    }

    result.file.fileSize = bytes.size();
    ByteCursor cursor(bytes);

    HeaderRecord libHeader;
    if (!readHeaderRecord(cursor, libHeader, result.error)) {
        result.error = "failed to read first header record: " + result.error;
        return result;
    }

    if (libHeader.name == "LIBRARY") {
        result.file.version = 5;
    } else if (libHeader.name == "LIBV8") {
        result.file.version = 8;
    } else {
        result.error = "unsupported XPORT library header: " + libHeader.name;
        return result;
    }

    if (!cursor.skipRecord()) {
        result.error = "unexpected EOF while skipping real header record";
        return result;
    }

    std::string timestampRecord;
    if (!cursor.readRecord(timestampRecord)) {
        result.error = "unexpected EOF while reading timestamp record";
        return result;
    }
    result.file.timestamp = trimRightSpaces(timestampRecord.substr(0, 16));

    HeaderRecord memberHeader;
    if (!readHeaderRecord(cursor, memberHeader, result.error)) {
        result.error = "failed to read MEMBER header: " + result.error;
        return result;
    }
    if ((result.file.version == 5 && memberHeader.name != "MEMBER") ||
        (result.file.version == 8 && memberHeader.name != "MEMBV8")) {
        result.error = "unexpected member header: " + memberHeader.name;
        return result;
    }

    HeaderRecord descriptorHeader;
    if (!readHeaderRecord(cursor, descriptorHeader, result.error)) {
        result.error = "failed to read descriptor header: " + result.error;
        return result;
    }
    if ((result.file.version == 5 && descriptorHeader.name != "DSCRPTR") ||
        (result.file.version == 8 && descriptorHeader.name != "DSCPTV8")) {
        result.error = "unexpected descriptor header: " + descriptorHeader.name;
        return result;
    }

    std::string tableRecord;
    if (!cursor.readRecord(tableRecord)) {
        result.error = "unexpected EOF while reading table name record";
        return result;
    }
    const std::size_t tableNameLen = result.file.version == 5 ? 8 : 32;
    result.file.tableName = trimRightSpacesAndNulls(tableRecord.substr(8, tableNameLen));

    std::string fileLabelRecord;
    if (!cursor.readRecord(fileLabelRecord)) {
        result.error = "unexpected EOF while reading file label record";
        return result;
    }
    result.file.fileLabel = trimRightSpacesAndNulls(fileLabelRecord.substr(32, 40));

    HeaderRecord namestrHeader;
    if (!readHeaderRecord(cursor, namestrHeader, result.error)) {
        result.error = "failed to read NAMESTR/NAMSTV8 header: " + result.error;
        return result;
    }

    if ((result.file.version == 5 && namestrHeader.name != "NAMESTR") ||
        (result.file.version == 8 && namestrHeader.name != "NAMSTV8")) {
        result.error = "unexpected namestr header: " + namestrHeader.name;
        return result;
    }

    const int varCount = namestrHeader.numbers[1];
    if (varCount < 0) {
        result.error = "invalid negative variable count in namestr header";
        return result;
    }

    result.file.variables.reserve(static_cast<std::size_t>(varCount));
    for (int i = 0; i < varCount; ++i) {
        std::span<const std::uint8_t> namestrData;
        if (!cursor.readBlock(kNameStrLen, namestrData)) {
            result.error = "unexpected EOF while reading NAMESTR entry " + std::to_string(i + 1);
            return result;
        }

        const auto fixedSpan = std::span<const std::uint8_t, kNameStrLen>(namestrData.data(), kNameStrLen);
        XptVariable variable = parseNameStr(fixedSpan, result.file.version, static_cast<std::size_t>(i));
        if (variable.ntypeRaw != 1 && variable.ntypeRaw != 2) {
            std::ostringstream warn;
            warn << "variable index " << (i + 1) << " has unexpected ntype=" << variable.ntypeRaw
                 << "; treating non-2 as numeric";
            result.file.warnings.push_back(warn.str());
        }

        result.file.variables.push_back(std::move(variable));
    }

    if (!cursor.alignToRecordBoundary()) {
        result.error = "unexpected EOF while aligning after NAMESTR records";
        return result;
    }

    HeaderRecord postSchemaHeader;
    if (!readHeaderRecord(cursor, postSchemaHeader, result.error)) {
        result.error = "failed to read post-schema header: " + result.error;
        return result;
    }

    if (result.file.version == 5) {
        if (postSchemaHeader.name != "OBS") {
            result.error = "expected OBS header, found: " + postSchemaHeader.name;
            return result;
        }
    } else {
        if (postSchemaHeader.name == "OBSV8") {
            // Ready for row data.
        } else if (postSchemaHeader.name == "LABELV8") {
            if (!parseLabelV8Section(cursor, result.file, postSchemaHeader.numbers[0], result.error)) {
                return result;
            }
        } else if (postSchemaHeader.name == "LABELV9") {
            if (!parseLabelV9Section(cursor, result.file, postSchemaHeader.numbers[0], result.error)) {
                return result;
            }
        } else {
            result.error = "expected OBSV8/LABELV8/LABELV9 header, found: " + postSchemaHeader.name;
            return result;
        }
    }

    result.file.dataOffset = cursor.pos();
    parseDataRows(cursor, result.file);

    return result;
}

} // namespace cxpt
