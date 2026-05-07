#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace cxpt {

[[nodiscard]] std::string_view trimRightSpacesView(std::string_view text);
[[nodiscard]] std::string_view trimRightSpacesAndNullsView(std::string_view text);
[[nodiscard]] std::string_view trimBothSpacesView(std::string_view text);

[[nodiscard]] std::string trimRightSpaces(std::string_view text);
[[nodiscard]] std::string trimRightSpacesAndNulls(std::string_view text);
[[nodiscard]] std::string trimBothSpaces(std::string_view text);

[[nodiscard]] std::string escapeForDisplay(std::string_view text, std::size_t maxBytes = 80);
[[nodiscard]] std::string bytesToHex(const std::vector<std::uint8_t> &bytes, std::size_t maxBytes = 24);
[[nodiscard]] std::string formatDouble(double value);
[[nodiscard]] bool nearlyEqual(double left, double right);

[[nodiscard]] bool parseSize(std::string_view text, std::size_t &value, std::string &error);
[[nodiscard]] std::vector<std::string> splitCommaSeparated(std::string_view text);

} // namespace cxpt
