#pragma once

#include <string>
#include "core/types.hpp"

namespace cxpt {

struct WriteOptions {
    int version = 5;            // 5 or 8
    std::string datasetName;    // 8 chars (V5) or up to 32 (V8)
    std::string fileLabel;      // up to 40 chars
    std::string sasLib = "SAS";
    std::string sasOs;          // OS string (max 8 V5 / 16 V8)
    std::string timestamp;      // "ddMMMyy:hh:mm:ss" - filled if empty
};

// Write XptFile to disk in XPORT format. version controls V5 vs V8.
// Throws std::runtime_error on I/O or validation failure.
void writeXptFile(const XptFile &file, const std::string &path, const WriteOptions &opts);

}  // namespace cxpt
