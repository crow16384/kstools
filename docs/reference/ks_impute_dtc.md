# Impute incomplete ISO 8601 date/datetime strings

Parses truncated ISO 8601 date or datetime character strings and imputes
missing components according to the chosen direction, returning a
`tibble` with the resulting `POSIXct` and an imputation flag.

## Usage

``` r
ks_impute_dtc(x, direction = "no", tz = "UTC", ref = NULL)
```

## Arguments

- x:

  Character vector of ISO 8601 truncated date/datetime strings. Accepted
  formats: `"YYYY"`, `"YYYY-MM"`, `"YYYY-MM-DD"`, `"YYYY-MM-DDTHH"`,
  `"YYYY-MM-DDTHH:MM"`, `"YYYY-MM-DDTHH:MM:SS"`. A space may replace `T`
  as the date-time separator. Trailing timezone designators (`Z`,
  `+HH:MM`, `-HH:MM`) are accepted but ignored; the `tz` argument
  governs the output timezone.

- direction:

  One of `"no"`, `"start"`, or `"end"`. Controls how missing components
  are filled. Validated via
  [`match.arg`](https://rdrr.io/r/base/match.arg.html).

- tz:

  IANA timezone string applied to the output `POSIXct` values. Defaults
  to `"UTC"`.

- ref:

  `NULL` (default), or a `Date`, `POSIXct`, or `POSIXlt` reference
  vector recycled to `length(x)`. When provided, missing components
  whose year (and optionally month) match the corresponding reference
  are filled from that reference rather than using the directional
  fallback.

## Value

A [`tibble`](https://tibble.tidyverse.org/reference/tibble.html) with
one row per element of `x` and two columns:

- `dt`:

  `POSIXct` in timezone `tz`, or `NA` when the year is absent or
  imputation could not be completed.

- `imputation_flag`:

  `character`; the highest-priority component that was imputed: `"M"`
  (month), `"D"` (day), `"H"` (hour), `"S"` (minute). `NA` when no
  imputation was performed.

## Details

\## Parsing

Each element of `x` is matched against a regular expression that
captures year, month, day, hour, minute, and second independently. The
date-time separator may be `T` or a single space. Trailing timezone
designators (`Z`, `+HH:MM`, `-HHMM`) are silently stripped; all output
is placed in the timezone given by `tz`. Elements that do not match the
pattern produce `dt = NA` and `imputation_flag = NA`.

\## Completeness and imputation flags

A string is considered *complete* when year, month, and day are all
present, and — if a time separator (`T` or space) is present — hour and
minute are also present. Complete strings are assembled directly without
imputation (flag `NA`), *except* for date-only strings under
`direction = "end"` (Case D, see below).

The `imputation_flag` records the most significant component that was
imputed:

|          |                                                          |
|----------|----------------------------------------------------------|
| **Flag** | **Meaning**                                              |
| `"M"`    | Month was imputed (year was the only component present). |
| `"D"`    | Day was imputed (year and month were present).           |
| `"H"`    | Hour (and minute) were imputed.                          |
| `"S"`    | Minute was imputed (hour was already present).           |
| `NA`     | No imputation was performed.                             |

\## Direction

- `"start"`:

  Each missing component is filled with the *earliest* plausible value:
  month \\\to\\ 1, day \\\to\\ 1, hour \\\to\\ 0, minute \\\to\\ 0.

- `"end"`:

  Each missing component is filled with the *latest* plausible value:
  month \\\to\\ 12, day \\\to\\ last day of that month (correctly
  handling leap years), hour \\\to\\ 23, minute \\\to\\ 59.

- `"no"`:

  No imputation is performed. Incomplete strings return `dt = NA` and
  `imputation_flag = NA`.

\## Date-only strings with `direction = "end"` (Case D)

A date-only string such as `"2020-04-06"` contains no time separator and
is otherwise complete. Under `direction = "end"` the missing time is
imputed as `23:59:00` and the flag is set to `"H"`. Under
`direction = "start"` the time defaults to `00:00:00` with flag `NA` (no
imputation — midnight is the natural start-of-day value).

\## Reference-guided imputation

When `ref` is provided and `direction != "no"`, the function first
checks whether the parsed year (and optionally month and day) match the
corresponding reference value before applying the directional fallback.
Cases are evaluated in priority order:

- **Case A** — day missing, year + month match ref:

  When the day (and time) are absent but year and month equal the
  reference, day, hour, and minute are taken from `ref`. Directional
  start/end values are *not* used. Typical flag: `"D"`.

- **Case B** — month missing, year matches ref:

  When month (and therefore day and time) are absent but the year equals
  the reference year, month, day, hour, and minute are all taken from
  `ref`. Typical flag: `"M"`.

- **Case C** — date complete, time absent, full date matches ref:

  A date-only string whose year, month, *and* day all equal the
  reference has its time filled from `ref`. This takes priority over the
  Case D end-of-day fallback. Flag: `"H"`.

- **Fallback**:

  If none of Cases A–C applies — because `ref` is `NULL`, the year does
  not match, or the month does not match — the directional start/end
  values are used as described above.

`ref` is recycled to `length(x)` via
[`rep_len()`](https://rdrr.io/r/base/rep.html). A `Date` ref is coerced
to `POSIXct` in timezone `tz` before its components are extracted.

## Examples

``` r
# --- direction = "no" -------------------------------------------------------
# Complete datetime — no imputation, flag NA
ks_impute_dtc("2020-03-15T10:30:00", "no")
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-03-15 10:30:00 NA             

# Truncated with direction = "no" — returns NA (nothing to impute)
ks_impute_dtc("2020-03", "no")
#> # A tibble: 1 × 2
#>   dt     imputation_flag
#>   <dttm> <chr>          
#> 1 NA     NA             

# Invalid string
ks_impute_dtc("not-a-date", "no")
#> # A tibble: 1 × 2
#>   dt     imputation_flag
#>   <dttm> <chr>          
#> 1 NA     NA             

# --- direction = "start" ----------------------------------------------------
# Year only → 2020-01-01 00:00:00, flag "M"
ks_impute_dtc("2020", "start")
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-01-01 00:00:00 M              

# Year-month → first day of month, flag "D"
ks_impute_dtc("2020-03", "start")
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-03-01 00:00:00 D              

# Date-only + end → end-of-day 23:59, flag "H" (Case D)
ks_impute_dtc("2020-03-15", "end")
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-03-15 23:59:00 H              

# Date-only + start → midnight 00:00, no imputation
ks_impute_dtc("2020-03-15", "start")
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-03-15 00:00:00 NA             

# --- direction = "end" ------------------------------------------------------
# End of February in a leap year → 2020-02-29 23:59:00, flag "D"
ks_impute_dtc("2020-02", "end")
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-02-29 23:59:00 D              

# End of March → 2020-03-31 23:59:00, flag "D"
ks_impute_dtc("2020-03", "end")
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-03-31 23:59:00 D              

# --- ref: same-period guided imputation ------------------------------------
ref <- as.POSIXct("2020-03-15 10:30:00", tz = "UTC")

# Case A — day missing, year+month match ref → take day/time from ref
ks_impute_dtc("2020-03", "start", ref = ref)
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-03-15 10:30:00 D              

# Case C overrides D — date matches ref → take time from ref, not 23:59
ks_impute_dtc("2020-03-15", "end", ref = ref)
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-03-15 10:30:00 H              

# ref year/month mismatch → directional fallback used instead
ks_impute_dtc("2020-04", "start", ref = ref)
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-04-01 00:00:00 D              

# --- Vectorised with dplyr::bind_cols() ------------------------------------
if (FALSE) { # \dontrun{
library(dplyr)
df <- tibble::tibble(
  dtc = c("2020-03-15T08:00", "2020-03-15", "2020-03", "2020", "bad"),
  ref = as.POSIXct(c(NA, "2020-03-15 14:30:00",
                     "2020-03-10 08:00:00", "2020-05-01 00:00:00", NA),
                   tz = "UTC")
)
dplyr::bind_cols(df, ks_impute_dtc(df$dtc, "start", ref = df$ref))
} # }
```
