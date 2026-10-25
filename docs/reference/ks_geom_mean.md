# Geometric mean and confidence interval

Computes the geometric mean of a numeric vector and an approximate
confidence interval based on the Student \\(t\\)-distribution on the
**log scale** (assuming log-transformed values are approximately
normal).

## Usage

``` r
ks_geom_mean(x, na.rm = TRUE, zero.propagate = FALSE, alpha = 0.05)
```

## Arguments

- x:

  Numeric vector (non-negative values; see **Details**).

- na.rm:

  Logical. If `TRUE`, `NA`s are removed first.

- zero.propagate:

  Logical. If `TRUE`, the presence of any zero in `x` forces a geometric
  mean of `0` (and `NA` confidence limits). If `FALSE`, zeros are
  excluded from the mean (only strictly positive values are used).

- alpha:

  Significance level for the two-sided CI (coverage nominal
  \\(1-\alpha\\)). Must lie in \\((0, 1)\\).

## Value

A list with components:

- `geom.mean`:

  Geometric mean (numeric scalar).

- `geom.sd`:

  Geometric standard deviation, \\(\exp(\mathrm{sd}(\log x))\\) on the
  positive data used (same as common PK notation; `NA` if not defined).

- `geom.mean.lcl`:

  Lower limit of the \\(100(1-\alpha)\\)% CI.

- `geom.mean.ucl`:

  Upper limit of the \\(100(1-\alpha)\\)% CI.

## Details

The geometric mean of positive values \\(x_1,\ldots,x_k\\) is
\\(\exp(\frac{1}{k}\sum\_{i=1}^k \log x_i)\\).

If `zero.propagate = FALSE`, only \\(x_i \> 0\\) are used. If there are
no positive values, the geometric mean is `0` (all zeros) or `NA` (empty
or invalid input after removing `NA`s).

Negative values are not allowed: the function returns `NaN` for
`geom.mean` (and `CI` components) because the geometric mean is not
defined in the reals.

The confidence interval is \\(\exp(\bar y \pm t\_{1-\alpha/2,\\,df}\\,
s/\sqrt{n})\\) where \\(y = \log x\\) for the positive observations
used, \\(s\\) is the sample SD of \\(y\\), \\(n\\) is their count, and
\\(df = n-1\\). For \\(n \< 2\\) the limits are `NA`.

## References

Kirkwood, T. B. (1979). Geometric means and measures of dispersion.
*Biometrics*, **35**(4), 908–909.

## See also

[`log`](https://rdrr.io/r/base/Log.html),
[`quantile`](https://rdrr.io/r/stats/quantile.html)

## Examples

``` r
x <- abs(rnorm(100,10,5))
ks_geom_mean(x)
#> $geom.mean
#> [1] 8.583378
#> 
#> $geom.sd
#> [1] 2.171799
#> 
#> $geom.mean.lcl
#> [1] 7.359121
#> 
#> $geom.mean.ucl
#> [1] 10.0113
#> 
```
