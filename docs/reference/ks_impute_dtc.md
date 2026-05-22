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

# Date-only → midnight, flag "H"
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

# Case C — date complete but time missing, date matches ref → take time from ref
ks_impute_dtc("2020-03-15", "start", ref = ref)
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
