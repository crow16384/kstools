# Descriptive summary for continuous variables

Computes n, mean, SD, CV, median, Q1, Q3, min, max by group. Optionally
adds a p-value for change from zero (paired t-test or Wilcoxon
signed-rank, chosen by Shapiro-Wilk normality test).

## Usage

``` r
ks_summary(
  data,
  var,
  ...,
  na.rm = TRUE,
  p.change = FALSE,
  extras = NULL,
  numdec = TRUE
)
```

## Arguments

- data:

  A data frame or tibble.

- var:

  Unquoted name of the numeric variable to summarise.

- ...:

  Unquoted grouping variables. Must come before `na.rm`, `p.change`,
  `extras`, and `numdec` in the call, which are keyword-only arguments
  (they must always be named).

- na.rm:

  Logical; remove `NA`s before computing. Default `TRUE`.

- p.change:

  Logical; if `TRUE`, append a `p.chg` column (p-value for paired
  change, chosen by normality). Default `FALSE`.

- extras:

  An optional **named list** of functions for additional per-group
  statistics. Each function is called as `f(x, na.rm = na.rm)` where `x`
  is the numeric vector of `var` for that group. Each function must
  return a single scalar value. The list names become column names in
  the result.

  Example:
  `extras = list(mad = stats::mad, sem = function(x, na.rm) sd(x, na.rm = na.rm) / sqrt(sum(!is.na(x))))`

  Names that clash with built-in columns (`n`, `mean`, `sd`, `cv`,
  `median`, `q1`, `q3`, `min`, `max`, `p.chg`, `NUMDEC`) will raise an
  error.

- numdec:

  Logical; if `TRUE` (the default), append a `NUMDEC` column giving the
  maximum number of decimal places observed in `var` within each group
  (via
  [`ks_get_numdec`](https://crow16384.github.io/kstools/reference/ks_get_numdec.md)
  logic, capped at 4). Set to `FALSE` to suppress.

## Value

A tibble with one row per group and columns `n`, `mean`, `sd`, `median`,
`q1`, `q3`, `min`, `max`, any `extras` columns, `cv`, (if
`numdec = TRUE`) `NUMDEC`, and (if `p.change = TRUE`) `p.chg`.

## Details

Q1 and Q3 use
[`ks_q1`](https://crow16384.github.io/kstools/reference/ks_q1.md) /
[`ks_q3`](https://crow16384.github.io/kstools/reference/ks_q3.md), whose
`type` argument defaults to `getOption("kstools.quantile.type", 2L)`
(SAS-compatible). Set that option in `.Rprofile` to change the algorithm
globally.

## See also

[`ks_q1`](https://crow16384.github.io/kstools/reference/ks_q1.md),
[`ks_q3`](https://crow16384.github.io/kstools/reference/ks_q3.md),
[`ks_get_numdec`](https://crow16384.github.io/kstools/reference/ks_get_numdec.md)

## Examples

``` r
d <- data.frame(
  grp = rep(c("A", "B"), each = 10),
  val = c(rnorm(10, 5), rnorm(10, 8))
)
ks_summary(d, val, grp)
#> # A tibble: 2 × 11
#>   grp       n  mean    sd median    q1    q3   min   max    cv NUMDEC
#>   <chr> <int> <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>  <int>
#> 1 A        10  5.21 0.912   5.27  4.50  5.82  3.95  6.56  17.5      4
#> 2 B        10  8.02 1.11    8.07  6.93  8.93  6.38  9.50  13.9      4

## Without NUMDEC
ks_summary(d, val, grp, numdec = FALSE)
#> # A tibble: 2 × 10
#>   grp       n  mean    sd median    q1    q3   min   max    cv
#>   <chr> <int> <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 A        10  5.21 0.912   5.27  4.50  5.82  3.95  6.56  17.5
#> 2 B        10  8.02 1.11    8.07  6.93  8.93  6.38  9.50  13.9

## With extra statistics
ks_summary(d, val, grp,
  extras = list(
    mad = stats::mad,
    sem = function(x, na.rm) sd(x, na.rm = na.rm) / sqrt(sum(!is.na(x)))
  )
)
#> # A tibble: 2 × 13
#>   grp       n  mean    sd median    q1    q3   min   max   mad   sem    cv
#>   <chr> <int> <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 A        10  5.21 0.912   5.27  4.50  5.82  3.95  6.56  1.04 0.288  17.5
#> 2 B        10  8.02 1.11    8.07  6.93  8.93  6.38  9.50  1.46 0.352  13.9
#> # ℹ 1 more variable: NUMDEC <int>
```
