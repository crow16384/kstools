#pragma once

// Streaming XPT type system.
//
// The previous design materialised whole files in memory as nested
// `XptRow{cells: vector<CellValue>}` aggregates that each carried up to four
// copies of every cell's raw bytes. The new design keeps **schema only** in
// memory; row data is decoded streaming from a memory-mapped file directly
// into pre-allocated R columns.

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

namespace cxpt {

constexpr std::size_t kRecordLen = 80;
constexpr std::size_t kNameStrLen = 140;

struct HeaderRecord {
    std::string name;
    std::array<int, 6> numbers{};
    std::string raw;
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
    // Cached running offset within a row record (sum of preceding storageWidths).
    std::size_t byteOffset = 0;
};

struct XptSchema {
    std::string path;
    int version = 0;
    std::string timestamp;
    std::string tableName;
    std::string fileLabel;
    std::vector<XptVariable> variables;
    std::vector<std::string> warnings;
    std::size_t fileSize = 0;
    std::size_t dataOffset = 0;   // file offset where row data begins
    std::size_t dataEnd = 0;      // file offset where row data ends (excl. trailing blank padding)
    std::size_t rowLen = 0;       // bytes per row record
    std::size_t rowCount = 0;     // number of non-blank rows
    std::size_t trailingBlankRows = 0;  // rows of all-space padding stripped at EOF
};

}  // namespace cxpt
