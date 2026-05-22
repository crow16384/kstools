# Imputing Incomplete ISO 8601 Dates with ks_impute_dtc()

``` r

library(kstools)
library(dplyr, warn.conflicts = FALSE)
```

## Overview

ISO 8601 dates from clinical data sources are often **truncated**: a
patient visit recorded as `"2020-03"` means “sometime in March 2020”,
and a value of `"2020"` means “sometime in 2020”. Statistical analyses
and listings typically require a fully-specified `POSIXct`, so the
truncated value must be **imputed** before use.

[`ks_impute_dtc()`](https://crow16384.github.io/kstools/reference/ks_impute_dtc.md)
handles this imputation in a vectorised, tidyverse- compatible way. It
returns a two-column tibble — `dt` (`POSIXct`) and `imputation_flag`
(`character`) — that can be appended to a data frame with
[`dplyr::bind_cols()`](https://dplyr.tidyverse.org/reference/bind_cols.html)
or `tidyr::unpack(mutate(...))`.

------------------------------------------------------------------------

## Imputation Logic

### Step 1 — Parse

Each element is matched against a regex that independently captures:

| Token  | Regex group | Notes                                     |
|--------|-------------|-------------------------------------------|
| Year   | `\d{4}`     | Required — absence produces `NA`          |
| Month  | `\d{2}`     | Optional                                  |
| Day    | `\d{2}`     | Optional                                  |
| Hour   | `\d{2}`     | Optional; `T` or space separator required |
| Minute | `\d{2}`     | Optional                                  |
| Second | `\d{2}`     | Optional; defaults to 0 when absent       |

Trailing timezone designators (`Z`, `+HH:MM`, `-HHMM`) are **silently
stripped**; all output is placed in the timezone given by `tz` (default
`"UTC"`).

### Step 2 — Completeness check

A string is **complete** when year, month, and day are all present, and
— if a time separator is present — hour and minute are also present.
Complete strings skip imputation and receive `imputation_flag = NA`,
**except** for date-only strings under `direction = "end"` (Case D).

### Step 3 — Imputation flags

The flag records the most significant component that was imputed:

| Flag  | Meaning                                                 |
|-------|---------------------------------------------------------|
| `"M"` | Month was imputed (year was the only component present) |
| `"D"` | Day was imputed (year and month were present)           |
| `"H"` | Hour (and minute) were imputed                          |
| `"S"` | Minute was imputed (hour was already present)           |
| `NA`  | No imputation was performed                             |

### Step 4 — Direction rules

| Direction | Missing month | Missing day         | Missing hour | Missing minute   |
|-----------|---------------|---------------------|--------------|------------------|
| `"start"` | → 1           | → 1                 | → 00         | → 00             |
| `"end"`   | → 12          | → last day of month | → 23         | → 59             |
| `"no"`    | —             | —                   | —            | — (returns `NA`) |

For `"end"` the last day of month is computed per-year, so **leap years
are handled correctly** (e.g. February 2020 → day 29).

### Step 5 — Case D: date-only strings under `direction = "end"`

A date-only string such as `"2020-04-06"` is complete (no time
separator), but under `direction = "end"` the missing time is imputed as
`23:59:00` with `imputation_flag = "H"`. Under `direction = "start"` the
time defaults to `00:00:00` with `imputation_flag = NA` — midnight is
the natural start-of-day value, so no flag is raised.

### Step 6 — Reference-guided imputation

When `ref` is supplied and `direction != "no"`, the function checks
whether the parsed components match the reference **before** applying
the directional fallback. Cases are evaluated in order:

| Case | Condition | Action | Flag |
|----|----|----|----|
| **A** | Day missing; year + month match ref | Take day, hour, minute from ref | `"D"` |
| **B** | Month missing; year matches ref | Take month, day, hour, minute from ref | `"M"` |
| **C** | Date complete, time absent; full date matches ref | Take hour, minute from ref (overrides Case D) | `"H"` |
| Fallback | None of A–C | Apply directional start/end values | — |

`ref` is recycled to `length(x)` and coerced to `POSIXct` in `tz` before
component extraction.

------------------------------------------------------------------------

## Basic Examples

### `direction = "no"` — no imputation

``` r

ks_impute_dtc(c("2020-03-15T10:30:00",  # complete → NA flag
                "2020-03-15",           # date-only → NA flag
                "2020-03",              # truncated → NA dt
                "bad"),                 # invalid   → NA dt
              direction = "no")
#> # A tibble: 4 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-03-15 10:30:00 NA             
#> 2 2020-03-15 00:00:00 NA             
#> 3 NA                  NA             
#> 4 NA                  NA
```

### `direction = "start"` — earliest plausible values

``` r

ks_impute_dtc(c("2020",           # year only
                "2020-03",        # year-month
                "2020-03-15",     # date-only
                "2020-03-15T10"), # partial datetime
              direction = "start")
#> # A tibble: 4 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-01-01 00:00:00 M              
#> 2 2020-03-01 00:00:00 D              
#> 3 2020-03-15 00:00:00 NA             
#> 4 2020-03-15 10:00:00 S
```

### `direction = "end"` — latest plausible values

``` r

ks_impute_dtc(c("2020",           # year only → 2020-12-31 23:59
                "2020-03",        # year-month → 2020-03-31 23:59
                "2020-03-15",     # date-only  → 2020-03-15 23:59  (Case D)
                "2020-03-15T10"), # partial    → 2020-03-15 10:59
              direction = "end")
#> # A tibble: 4 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-12-31 23:59:00 M              
#> 2 2020-03-31 23:59:00 D              
#> 3 2020-03-15 23:59:00 H              
#> 4 2020-03-15 10:59:00 S
```

------------------------------------------------------------------------

## Leap-Year End-of-Month

The last day of the month is calculated per-year using
[`lubridate::days_in_month()`](https://lubridate.tidyverse.org/reference/days_in_month.html),
so leap years are always handled correctly:

``` r

ks_impute_dtc(c("2020-02",   # leap year  → 2020-02-29
                "2021-02",   # non-leap   → 2021-02-28
                "2000-02",   # century leap → 2000-02-29
                "1900-02"),  # century non-leap → 1900-02-28
              direction = "end")
#> # A tibble: 4 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-02-29 23:59:00 D              
#> 2 2021-02-28 23:59:00 D              
#> 3 2000-02-29 23:59:00 D              
#> 4 1900-02-28 23:59:00 D
```

------------------------------------------------------------------------

## Reference-Guided Imputation

### Case A — day missing, year + month match ref

When only the year and month are present and they match the reference,
the day and time are taken from the reference rather than being set to
the 1st or 31st.

``` r

ref_a <- as.POSIXct("2020-03-15 10:30:00", tz = "UTC")

ks_impute_dtc("2020-03", direction = "start", ref = ref_a)
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-03-15 10:30:00 D
# → 2020-03-15 10:30:00 / "D"  (from ref, not 2020-03-01 00:00:00)

ks_impute_dtc("2020-04", direction = "start", ref = ref_a)
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-04-01 00:00:00 D
# → 2020-04-01 00:00:00 / "D"  (month mismatch → fallback)
```

### Case B — month missing, year matches ref

``` r

ref_b <- as.POSIXct("2020-05-20 08:00:00", tz = "UTC")

ks_impute_dtc("2020", direction = "start", ref = ref_b)
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-05-20 08:00:00 M
# → 2020-05-20 08:00:00 / "M"  (from ref)

ks_impute_dtc("2021", direction = "start", ref = ref_b)
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2021-01-01 00:00:00 M
# → 2021-01-01 00:00:00 / "M"  (year mismatch → fallback)
```

### Case C — date complete, time absent, date matches ref

Case C takes priority over Case D: when the full date matches the
reference, the reference time is used instead of 23:59.

``` r

ref_c <- as.POSIXct("2020-04-06 14:30:00", tz = "UTC")

# Same date as ref → take time from ref (Case C beats Case D)
ks_impute_dtc("2020-04-06", direction = "end", ref = ref_c)
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-04-06 14:30:00 H

# Different date → Case D applies → 23:59
ks_impute_dtc("2020-04-07", direction = "end", ref = ref_c)
#> # A tibble: 1 × 2
#>   dt                  imputation_flag
#>   <dttm>              <chr>          
#> 1 2020-04-07 23:59:00 H
```

------------------------------------------------------------------------

## Vectorised Use with dplyr

[`ks_impute_dtc()`](https://crow16384.github.io/kstools/reference/ks_impute_dtc.md)
returns a tibble, so it integrates naturally with
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) +
[`tidyr::unpack()`](https://tidyr.tidyverse.org/reference/pack.html):

``` r

adsl_dtc <- tibble::tibble(
  USUBJID  = sprintf("01-%03d", 1:6),
  RFSTDTC  = c("2020-03-15T08:00",  # complete
               "2020-03-15",        # date-only → Case D
               "2020-03",           # year-month
               "2020",              # year-only
               "bad",               # invalid
               NA_character_),      # missing
  RFSTREF  = as.POSIXct(
    c("2020-03-15 08:00:00", "2020-03-15 14:30:00",
      "2020-03-10 09:00:00", "2020-05-01 00:00:00",
      NA, NA),
    tz = "UTC"
  )
)

adsl_dtc |>
  mutate(imp = ks_impute_dtc(RFSTDTC, "start", ref = RFSTREF)) |>
  tidyr::unpack(imp) |>
  select(USUBJID, RFSTDTC, dt, imputation_flag)
#> # A tibble: 6 × 4
#>   USUBJID RFSTDTC          dt                  imputation_flag
#>   <chr>   <chr>            <dttm>              <chr>          
#> 1 01-001  2020-03-15T08:00 2020-03-15 08:00:00 NA             
#> 2 01-002  2020-03-15       2020-03-15 14:30:00 H              
#> 3 01-003  2020-03          2020-03-10 09:00:00 D              
#> 4 01-004  2020             2020-05-01 00:00:00 M              
#> 5 01-005  bad              NA                  NA             
#> 6 01-006  NA               NA                  NA
```

The `imputation_flag` column can then be used to flag records for
medical review or to drive sensitivity analyses:

``` r

adsl_dtc |>
  mutate(imp = ks_impute_dtc(RFSTDTC, "start", ref = RFSTREF)) |>
  tidyr::unpack(imp) |>
  filter(!is.na(imputation_flag)) |>
  select(USUBJID, RFSTDTC, imputation_flag)
#> # A tibble: 3 × 3
#>   USUBJID RFSTDTC    imputation_flag
#>   <chr>   <chr>      <chr>          
#> 1 01-002  2020-03-15 H              
#> 2 01-003  2020-03    D              
#> 3 01-004  2020       M
```
