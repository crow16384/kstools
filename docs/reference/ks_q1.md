# 25th percentile (Q1)

Computes the 25th percentile using
[`quantile`](https://rdrr.io/r/stats/quantile.html).

The quantile algorithm type can be set globally via
`options(kstools.quantile.type = <1..9>)` (e.g. in `.Rprofile`). Type 2
matches SAS default; type 7 is the R default. When the option is not set
the package default of `2` is used.

## Usage

``` r
ks_q1(x, na.rm = TRUE, type = getOption("kstools.quantile.type", default = 2L))
```

## Arguments

- x:

  Numeric vector.

- na.rm:

  Logical; remove `NA`s before computing. Default `TRUE`.

- type:

  Integer (1–9); quantile algorithm passed to
  [`quantile`](https://rdrr.io/r/stats/quantile.html). Defaults to
  `getOption("kstools.quantile.type", 2L)`.

## See also

[`ks_q3`](https://crow16384.github.io/kstools/reference/ks_q3.md),
[`quantile`](https://rdrr.io/r/stats/quantile.html)

## Examples

``` r
## Use R default algorithm for this call
ks_q1(rnorm(100), type = 7)
#>        25% 
#> -0.5385212 

## Set package-wide default (e.g. in .Rprofile)
old <- options(kstools.quantile.type = 7L)
ks_q1(rnorm(100))   # now uses type 7
#>       25% 
#> -0.518017 
options(old)         # restore
```
