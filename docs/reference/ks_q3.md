# 75th percentile (Q3)

Computes the 75th percentile using
[`quantile`](https://rdrr.io/r/stats/quantile.html).

The quantile algorithm type can be set globally via
`options(kstools.quantile.type = <1..9>)` (e.g. in `.Rprofile`). Type 2
matches SAS default; type 7 is the R default. When the option is not set
the package default of `2` is used.

## Usage

``` r
ks_q3(x, na.rm = TRUE, type = getOption("kstools.quantile.type", default = 2L))
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

[`ks_q1`](https://crow16384.github.io/kstools/reference/ks_q1.md),
[`quantile`](https://rdrr.io/r/stats/quantile.html)

## Examples

``` r
## Use SAS-compatible algorithm for this call
ks_q3(rnorm(100), type = 2)
#>       75% 
#> 0.5711746 

## Set package-wide default (e.g. in .Rprofile)
old <- options(kstools.quantile.type = 7L)
ks_q3(rnorm(100))   # now uses type 7
#>       75% 
#> 0.4578703 
options(old)         # restore
```
