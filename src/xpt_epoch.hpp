#pragma once

// SAS <-> R epoch conversion and SAS format detection.
//
// SAS date/datetime epoch: 1960-01-01 00:00:00 UTC.
// R Date / POSIXct epoch:  1970-01-01 00:00:00 UTC.
// Offset: 3653 days = 315,619,200 seconds.

#include <cctype>
#include <string>
#include <string_view>

namespace kstools {

inline constexpr double kSasRDateOffset = 3653.0;
inline constexpr double kSasRDatetimeOffset = 315619200.0;  // 3653 * 86400

namespace detail {

inline std::string toUpperAscii(std::string_view s) {
    std::string out;
    out.reserve(s.size());
    for (char c : s) {
        out.push_back(static_cast<char>(std::toupper(static_cast<unsigned char>(c))));
    }
    return out;
}

// Strip trailing width/decimal portion (digits, '.', $) so "DATE9." -> "DATE".
inline std::string formatPrefix(std::string_view fmt) {
    std::string up = toUpperAscii(fmt);
    std::size_t end = 0;
    while (end < up.size()) {
        char c = up[end];
        if (std::isalpha(static_cast<unsigned char>(c))) {
            ++end;
        } else {
            break;
        }
    }
    return up.substr(0, end);
}

}  // namespace detail

// True when the SAS format encodes a date (days since 1960-01-01).
inline bool isSasDateFormat(std::string_view fmt) {
    if (fmt.empty()) return false;
    const auto p = detail::formatPrefix(fmt);
    if (p.empty()) return false;
    // Common SAS date formats. Order independent.
    static constexpr const char * const kDateFormats[] = {
        "DATE", "DAY", "DDMMYY", "DDMMYYB", "DDMMYYC", "DDMMYYD", "DDMMYYN", "DDMMYYP", "DDMMYYS",
        "JULDAY", "JULIAN",
        "MMDDYY", "MMDDYYB", "MMDDYYC", "MMDDYYD", "MMDDYYN", "MMDDYYP", "MMDDYYS",
        "MMYY", "MMYYC", "MMYYD", "MMYYN", "MMYYP", "MMYYS",
        "MONNAME", "MONTH", "MONYY",
        "QTR", "QTRR",
        "WEEKDATE", "WEEKDATX", "WEEKDAY", "WEEKU", "WEEKV", "WEEKW",
        "WORDDATE", "WORDDATX",
        "YEAR", "YYMM", "YYMMC", "YYMMD", "YYMMDD", "YYMMDDB", "YYMMDDC", "YYMMDDD",
        "YYMMDDN", "YYMMDDP", "YYMMDDS", "YYMMN", "YYMMP", "YYMMS", "YYMON", "YYQ",
        "YYQR", "YYQRC", "YYQRD", "YYQRN", "YYQRP", "YYQRS",
        "B8601DA", "B8601DN", "E8601DA", "E8601DN",
        "EURDFDD", "EURDFDE", "EURDFDN", "EURDFDWN", "EURDFMN", "EURDFMY", "EURDFWDX", "EURDFWKX"
    };
    for (const char *f : kDateFormats) {
        if (p == f) return true;
    }
    return false;
}

// True when the SAS format encodes a datetime (seconds since 1960-01-01).
inline bool isSasDatetimeFormat(std::string_view fmt) {
    if (fmt.empty()) return false;
    const auto p = detail::formatPrefix(fmt);
    if (p.empty()) return false;
    static constexpr const char * const kDtFormats[] = {
        "DATETIME", "DATEAMPM", "MDYAMPM",
        "B8601DT", "B8601DZ", "B8601DH", "B8601DJ",
        "E8601DT", "E8601DZ", "E8601DH",
        "DTDATE", "DTMONYY", "DTWKDATX", "DTYEAR", "DTYYQC"
    };
    for (const char *f : kDtFormats) {
        if (p == f) return true;
    }
    return false;
}

// True when the SAS format encodes a time (seconds since midnight). No epoch shift required.
inline bool isSasTimeFormat(std::string_view fmt) {
    if (fmt.empty()) return false;
    const auto p = detail::formatPrefix(fmt);
    if (p.empty()) return false;
    static constexpr const char * const kTimeFormats[] = {
        "TIME", "TIMEAMPM", "TOD", "HHMM", "HOUR", "MMSS",
        "B8601TM", "B8601TZ", "E8601TM", "E8601TZ"
    };
    for (const char *f : kTimeFormats) {
        if (p == f) return true;
    }
    return false;
}

inline double sasDateToR(double sas)      { return sas - kSasRDateOffset; }
inline double rDateToSas(double r)        { return r   + kSasRDateOffset; }
inline double sasDatetimeToR(double sas)  { return sas - kSasRDatetimeOffset; }
inline double rDatetimeToSas(double r)    { return r   + kSasRDatetimeOffset; }

}  // namespace kstools
