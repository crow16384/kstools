#include "core/text.hpp"

#include <algorithm>
#include <charconv>
#include <cmath>
#include <iomanip>
#include <limits>
#include <sstream>
#include <system_error>

namespace cxpt {

std::string_view trimRightSpacesView(std::string_view text) {
    std::size_t end = text.size();
    while (end > 0 && text[end - 1] == ' ') {
        --end;
    }
    return text.substr(0, end);
}

std::string_view trimRightSpacesAndNullsView(std::string_view text) {
    std::size_t end = text.size();
    while (end > 0 && (text[end - 1] == ' ' || text[end - 1] == '\0')) {
        --end;
    }
    return text.substr(0, end);
}

std::string_view trimBothSpacesView(std::string_view text) {
    std::size_t start = 0;
    while (start < text.size() && text[start] == ' ') {
        ++start;
    }

    std::size_t end = text.size();
    while (end > start && text[end - 1] == ' ') {
        --end;
    }

    return text.substr(start, end - start);
}

std::string trimRightSpaces(std::string_view text) {
    return std::string(trimRightSpacesView(text));
}

std::string trimRightSpacesAndNulls(std::string_view text) {
    return std::string(trimRightSpacesAndNullsView(text));
}

std::string trimBothSpaces(std::string_view text) {
    return std::string(trimBothSpacesView(text));
}

std::string escapeForDisplay(std::string_view text, std::size_t maxBytes) {
    std::ostringstream oss;
    std::size_t shown = 0;
    for (const char rawC : text) {
        const unsigned char c = static_cast<unsigned char>(rawC);
        if (shown >= maxBytes) {
            oss << "...";
            break;
        }
        if (c == '\\') {
            oss << "\\\\";
        } else if (c == '"') {
            oss << "\\\"";
        } else if (c == '\n') {
            oss << "\\n";
        } else if (c == '\r') {
            oss << "\\r";
        } else if (c == '\t') {
            oss << "\\t";
        } else if (c >= 32 && c <= 126) {
            oss << static_cast<char>(c);
        } else {
            oss << "\\x" << std::uppercase << std::hex << std::setw(2) << std::setfill('0')
                << static_cast<int>(c) << std::dec;
        }
        ++shown;
    }
    return oss.str();
}

std::string bytesToHex(const std::vector<std::uint8_t> &bytes, std::size_t maxBytes) {
    std::ostringstream oss;
    const std::size_t shown = std::min(maxBytes, bytes.size());
    for (std::size_t i = 0; i < shown; ++i) {
        if (i != 0) {
            oss << ' ';
        }
        oss << std::uppercase << std::hex << std::setw(2) << std::setfill('0')
            << static_cast<int>(bytes[i]) << std::dec;
    }
    if (bytes.size() > shown) {
        oss << " ... (" << bytes.size() << " bytes)";
    }
    return oss.str();
}

std::string formatDouble(double value) {
    if (!std::isfinite(value)) {
        if (std::isnan(value)) {
            return "NaN";
        }
        return value > 0 ? "+Inf" : "-Inf";
    }

    std::ostringstream oss;
    oss << std::setprecision(17) << value;
    return oss.str();
}

bool nearlyEqual(double left, double right) {
    if (std::isnan(left) && std::isnan(right)) {
        return true;
    }
    if (!std::isfinite(left) || !std::isfinite(right)) {
        return left == right;
    }

    const double scale = std::max({1.0, std::fabs(left), std::fabs(right)});
    return std::fabs(left - right) <= (1e-12 * scale);
}

bool parseSize(std::string_view text, std::size_t &value, std::string &error) {
    const std::string_view trimmed = trimBothSpacesView(text);
    if (trimmed.empty()) {
        error = "value is empty";
        return false;
    }

    unsigned long long parsed = 0;
    const char *begin = trimmed.data();
    const char *end = begin + trimmed.size();
    auto [ptr, ec] = std::from_chars(begin, end, parsed, 10);
    if (ec == std::errc::invalid_argument || ptr != end) {
        error = "value is not a valid unsigned integer";
        return false;
    }
    if (ec == std::errc::result_out_of_range || parsed > std::numeric_limits<std::size_t>::max()) {
        error = "value is out of range";
        return false;
    }

    value = static_cast<std::size_t>(parsed);
    return true;
}

std::vector<std::string> splitCommaSeparated(std::string_view text) {
    std::vector<std::string> values;
    std::size_t start = 0;

    while (start <= text.size()) {
        const std::size_t comma = text.find(',', start);
        const std::size_t end = (comma == std::string_view::npos) ? text.size() : comma;
        const std::string_view token = text.substr(start, end - start);
        const std::string trimmed = trimBothSpaces(token);
        if (!trimmed.empty()) {
            values.push_back(trimmed);
        }
        if (comma == std::string_view::npos) {
            break;
        }
        start = comma + 1;
    }

    return values;
}

} // namespace cxpt
