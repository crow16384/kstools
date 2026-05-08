#pragma once

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "core/types.hpp"

namespace cxpt {

// Parse the header block of a member starting at [memberPrefixOffset, ...).
//
// `memberPrefixOffset` points either at the start of the file (single-member)
// or at the MEMBER/MEMBV8 header record of a non-leading member (multi-member).
// On success populates `schema` (variables, dataOffset, dataEnd, rowCount,
// trailingBlankRows). Returns true on success; on failure returns false and
// fills `error`.
[[nodiscard]] bool parseSchema(const std::uint8_t *data,
                               std::size_t size,
                               std::size_t memberPrefixOffset,
                               XptSchema &schema,
                               std::string &error);

// Locate every MEMBER/MEMBV8 header record in the buffer (offsets are
// 80-byte aligned).
[[nodiscard]] std::vector<std::size_t> scanMemberOffsets(const std::uint8_t *data,
                                                         std::size_t size);

// ---- Inlined hot-path numeric decode ---------------------------------------
//
// Decodes a single XPORT numeric cell of `width` bytes (3..8) from `p`.
//   *flag = 0 : system missing (NA), `*value` undefined.
//   *flag = 1 : normal value, `*value` populated.
//   *flag = 2 : tagged missing, `*tag` populated with the marker byte.
//
// IBM hex float layout: 1 bit sign | 7-bit excess-64 base-16 exponent
// | 56-bit fraction. Truncated cells (`width < 8`) are zero-padded on the
// right (least-significant bytes).
inline void decodeNumericFast(const std::uint8_t *p,
                              std::size_t width,
                              double *value,
                              std::uint8_t *flag,
                              char *tag) noexcept {
    if (width < 3 || width > 8) {
        *flag = 0;
        return;
    }

    const std::uint8_t b0 = p[0];

    bool restZero = true;
    for (std::size_t i = 1; i < width; ++i) {
        if (p[i] != 0) {
            restZero = false;
            break;
        }
    }
    if (restZero) {
        if (b0 == '.') {
            *flag = 0;
            return;
        }
        if (b0 == '_' || (b0 >= 'A' && b0 <= 'Z')) {
            *flag = 2;
            *tag = static_cast<char>(b0);
            return;
        }
        if (b0 == 0) {
            *flag = 1;
            *value = 0.0;
            return;
        }
    }

    // Pack up to 8 big-endian bytes (right-zero-padded) into a 64-bit word.
    std::uint64_t raw = 0;
    for (std::size_t i = 0; i < 8; ++i) {
        raw <<= 8;
        if (i < width) raw |= p[i];
    }

    const int sign = (raw & 0x8000000000000000ULL) ? -1 : 1;
    const int exp16 = static_cast<int>((raw >> 56) & 0x7FU) - 64;
    const std::uint64_t fraction = raw & 0x00FFFFFFFFFFFFFFULL;

    // value = (fraction / 2^56) * 16^exp16 = fraction * 2^(4*exp16 - 56)
    double v = static_cast<double>(fraction);
    v = std::ldexp(v, 4 * exp16 - 56);
    if (sign < 0) v = -v;

    *flag = 1;
    *value = v;
}

// Returns true if the row at `data + offset` (`rowLen` bytes) is all 0x20.
inline bool isBlankRow(const std::uint8_t *data, std::size_t rowLen) noexcept {
    for (std::size_t i = 0; i < rowLen; ++i) {
        if (data[i] != 0x20U) return false;
    }
    return true;
}

}  // namespace cxpt
