#pragma once

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <functional>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

#include "core/types.hpp"

namespace cxpt {

struct WriteOptions {
    int version = 5;            // 5 or 8
    std::string datasetName;    // 8 chars (V5) or up to 32 (V8)
    std::string fileLabel;      // up to 40 chars
    std::string sasLib = "SAS";
    std::string sasOs;          // 8 chars (V5) or 16 (V8)
    std::string timestamp;      // "ddMMMyy:hh:mm:ss"; auto-filled if empty
};

// Streaming XPT writer. Holds a small fixed-size output buffer (64 KB) and a
// single row-buffer (`rowLen` bytes). The caller fills the row buffer for each
// row through `rowBuffer()` then calls `commitRow()`. Total scratch is well
// under 4 MB regardless of input size.
class XptWriter {
public:
    XptWriter(const std::string &path, const XptSchema &schema, const WriteOptions &opts);
    ~XptWriter();

    XptWriter(const XptWriter &) = delete;
    XptWriter &operator=(const XptWriter &) = delete;

    // Pointer to a `rowLen`-byte buffer pre-filled with 0x20 (space) bytes.
    // Caller must overwrite the bytes for each variable's slot before commit.
    [[nodiscard]] std::uint8_t *rowBuffer() noexcept { return rowBuf_.data(); }
    [[nodiscard]] std::size_t rowLen() const noexcept { return rowLen_; }

    // Commits the current row to the output buffer, flushing to disk if needed.
    void commitRow();

    // Pads the trailing data block to the next 80-byte boundary and closes the
    // file. Idempotent.
    void finish();

private:
    void flushBuffer();
    void writeFileHeader();

    XptSchema schema_;
    WriteOptions opts_;
    std::FILE *file_ = nullptr;
    std::vector<std::uint8_t> outBuf_;
    std::vector<std::uint8_t> rowBuf_;
    std::size_t rowLen_ = 0;
    std::size_t outPos_ = 0;
    std::size_t totalRowsWritten_ = 0;
    bool finished_ = false;
};

// ===== Inline numeric encode (hot path) ======================================
//
// Encodes `v` as IBM hex float into `out` (8 bytes). For storage widths < 8 the
// caller copies the leading `width` bytes (XPORT spec keeps the most-significant
// portion).
inline void encodeIbmXport(double v, std::uint8_t out[8]) noexcept {
    for (int i = 0; i < 8; ++i) out[i] = 0;

    if (v == 0.0 || !(v == v) || v == std::numeric_limits<double>::infinity() ||
        v == -std::numeric_limits<double>::infinity()) {
        return;
    }

    const bool neg = v < 0.0;
    if (neg) v = -v;

    // Decompose v = m * 2^e, m in [0.5, 1.0).
    int e2 = 0;
    double m = std::frexp(v, &e2);
    // Convert to base-16 exponent. We want m16 in [1/16, 1) and 16^exp16 such
    // that v = m16 * 16^exp16. m * 2^e2 = m16 * 16^exp16 = m16 * 2^(4*exp16).
    // Choose exp16 = ceil(e2/4) so 4*exp16 >= e2.
    int exp16 = (e2 + 3) >> 2;          // arithmetic shift (e2 may be negative)
    if (exp16 * 4 < e2) ++exp16;        // guard for negative-shift rounding
    double m16 = std::ldexp(m, e2 - 4 * exp16);
    while (m16 >= 1.0) {
        m16 /= 16.0;
        ++exp16;
    }
    while (m16 > 0.0 && m16 < 1.0 / 16.0) {
        m16 *= 16.0;
        --exp16;
    }

    int storedExp = exp16 + 64;
    if (storedExp <= 0 || storedExp > 127) {
        return;  // out of range -> all zero
    }

    std::uint64_t mant = static_cast<std::uint64_t>(m16 * std::ldexp(1.0, 56) + 0.5);
    if (mant >= (std::uint64_t{1} << 56)) {
        mant >>= 4;
        ++storedExp;
        if (storedExp > 127) return;
    }

    out[0] = static_cast<std::uint8_t>((neg ? 0x80 : 0x00) | (storedExp & 0x7F));
    for (int i = 1; i <= 7; ++i) {
        out[i] = static_cast<std::uint8_t>((mant >> (8 * (7 - i))) & 0xFFU);
    }
}

}  // namespace cxpt
