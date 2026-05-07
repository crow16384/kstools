#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <string>
#include <vector>

namespace cxpt {

constexpr std::size_t kRecordLen = 80;
constexpr std::size_t kNameStrLen = 140;

enum class CompareMode {
    Strict,
    Keyed
};

struct HeaderRecord {
    std::string name;
    std::array<int, 6> numbers{};
    std::string raw;
};

struct NumericValue {
    bool isSystemMissing = false;
    bool isTaggedMissing = false;
    char tag = '\0';
    bool hasValue = false;
    double value = std::numeric_limits<double>::quiet_NaN();
    std::vector<std::uint8_t> raw;
};

struct CellValue {
    bool isString = false;
    std::string stringRaw;
    std::string stringTrimmed;
    NumericValue numeric;
    std::vector<std::uint8_t> raw;
};

struct XptVariable {
    std::size_t index = 0;
    std::uint16_t ntypeRaw = 0;
    bool isString = false;
    std::uint16_t storageWidth = 0;
    std::uint16_t varNumber = 0;
    std::string name;
    std::string label;
    std::string format;
    std::string informat;
    std::uint16_t displayWidth = 0;
    std::uint16_t decimals = 0;
    std::uint16_t alignmentCode = 0;
    std::uint32_t position = 0;
    std::array<std::uint8_t, kNameStrLen> namestrRaw{};
};

struct XptRow {
    std::vector<CellValue> cells;
    bool wasBlankPaddingRow = false;
    std::vector<std::uint8_t> raw;
};

struct XptFile {
    std::string path;
    int version = 0;
    std::string timestamp;
    std::string tableName;
    std::string fileLabel;
    std::vector<XptVariable> variables;
    std::vector<XptRow> rows;
    std::vector<std::string> warnings;
    std::size_t fileSize = 0;
    std::size_t dataOffset = 0;
};

struct ParseResult {
    XptFile file;
    std::string error;
};

struct DiffEntry {
    std::string category;
    std::string detail;
};

struct CompareResult {
    std::vector<DiffEntry> differences;
    bool truncated = false;
    std::size_t totalDifferences = 0;

    [[nodiscard]] bool hasDifferences() const {
        return totalDifferences > 0;
    }
};

} // namespace cxpt
