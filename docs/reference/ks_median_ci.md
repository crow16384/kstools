# Confidence interval for the median

Computes the sample median and a confidence interval using one of three
approaches: bootstrap (boot), Olive's simple median interval, or a
normal approximation based on the binomial distribution of ranks (the
`"z"` method).

## Usage

``` r
ks_median_ci(
  x,
  na.rm = TRUE,
  alpha = 0.05,
  method = c("boot", "olive", "z"),
  R = 10000L,
  seed = 0L,
  type = 2L
)
```

## Arguments

- x:

  Numeric vector.

- na.rm:

  Logical. If `TRUE`, `NA`s are removed before computing (default
  `TRUE`).

- alpha:

  Significance level; the interval has nominal coverage \\(1 -
  \alpha\\). Must be in \\((0, 1)\\).

- method:

  Character: `"boot"` (default), `"olive"`, or `"z"`. See **Details**.

- R:

  Number of bootstrap replicates when `method = "boot"`.

- seed:

  Integer passed to [`set.seed`](https://rdrr.io/r/base/Random.html)
  immediately before bootstrap resampling (for reproducibility). The
  default `0L` fixes the RNG state; use another integer for a different
  stream.

- type:

  Integer `1`–`9`: quantile definition for the reported median when
  `method = "z"` (passed to
  [`quantile`](https://rdrr.io/r/stats/quantile.html)). Default `2`
  matches SAS `PROC UNIVARIATE` / Hyndman & Fan type 2.

## Value

A named numeric vector. The first element is always `Median`. Remaining
elements depend on `method`:

- `boot`:

  `Basic.LCI`, `Basic.UCI`, `Normal.LCI`, `Normal.UCI`, `Percent.LCI`,
  `Percent.UCI`, `BCa.LCI`, `BCa.UCI` (BCa may be `NA` in small
  samples).

- `olive`:

  `Olive.LCI`, `Olive.UCI`.

- `z`:

  `z.LCI`, `z.UCI` (limits are order statistics of the sorted data).

## Details

- `boot`:

  Uses [`boot`](https://rdrr.io/pkg/boot/man/boot.html) with the sample
  median as the statistic and
  [`boot.ci`](https://rdrr.io/pkg/boot/man/boot.ci.html) to produce
  Basic, Normal, percentile, and BCa intervals (when BCa is defined).

- `olive`:

  Implements David Olive's simple median CI (order statistics with a
  \\(t\\)-based multiplier). Requires at least two non-missing
  observations.

- `z`:

  Approximate CI from the normal approximation to the binomial number of
  observations below the population median: bounds are the order
  statistics with ranks \\(n/2 \pm z\_{1-\alpha/2}\sqrt{n}/2\\) (rounded
  inward). The reported `Median` uses `quantile(..., type)`.

## References

Olive, D. J. (2005). *Applied robust statistics*. Preprint. (median CI
procedure.)

Davison, A. C. and Hinkley, D. V. (1997). *Bootstrap Methods and Their
Applications*. Cambridge University Press.

## See also

[`median`](https://rdrr.io/r/stats/median.html),
[`quantile`](https://rdrr.io/r/stats/quantile.html)

## Examples

``` r
x <- rnorm(100, 56, 2.5)
ks_median_ci(x, method = "olive")
#>    Median Olive.LCI Olive.UCI 
#>  56.06176  55.40239  56.72113 

vv <- c(8, 11, 12, 13, 15, 17, 19, 20, 21, 21, 22, 23, 25, 26, 28)
ks_median_ci(vv, method = "boot", R = 1000, seed = 1L)
#> Warning: bootstrap variances needed for studentized intervals
#>      Median   Basic.LCI   Basic.UCI  Normal.LCI  Normal.UCI Percent.LCI 
#>    20.00000    17.00000    25.00000    16.28281    24.52919    15.00000 
#> Percent.UCI     BCa.LCI     BCa.UCI 
#>    23.00000    12.00000    21.00000 
ks_median_ci(vv, method = "olive")
#>    Median Olive.LCI Olive.UCI 
#>  20.00000  14.44711  25.55289 
ks_median_ci(vv, method = "olive", alpha = 0.1)
#>    Median Olive.LCI Olive.UCI 
#>  20.00000  15.73631  24.26369 
ks_median_ci(vv, method = "z")
#> Median  z.LCI  z.UCI 
#>     20     13     22 
ks_median_ci(vv, method = "z", alpha = 0.1)
#> Median  z.LCI  z.UCI 
#>     20     15     21 
```
