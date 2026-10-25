# Newcombe Hybrid Score CI for a difference of two proportions

Computes a confidence interval for \\(p_1 - p_2\\) using Newcombe's
Hybrid Score method (Newcombe, 1998, Method 10). Each group's proportion
is first bounded by its Wilson score interval, and the two intervals are
then combined to yield the CI for the difference.

## Usage

``` r
ks_newcombe_hs(x1, n1, x2, n2, alpha = 0.05)
```

## Arguments

- x1:

  Integer vector of event counts for group 1 (\\(\ge 0\\)).

- n1:

  Integer vector of sample sizes for group 1 (\\(\> 0\\)).

- x2:

  Integer vector of event counts for group 2 (\\(\ge 0\\)).

- n2:

  Integer vector of sample sizes for group 2 (\\(\> 0\\)).

- alpha:

  Significance level; scalar in \\((0,1)\\). Defaults to `0.05` (95%
  CI).

## Value

A numeric matrix with one row per input pair and three columns:

- `delta`:

  Observed difference \\(\hat p_1 - \hat p_2\\).

- `lcl`:

  Lower confidence limit.

- `ucl`:

  Upper confidence limit.

## Details

**Algorithm** (Newcombe, 1998):

1.  Compute the Wilson score CI \\(\[l_i,\\, u_i\]\\) for each group at
    level \\(1-\alpha\\): \$\$l_i,\\, u_i = \frac{2x_i + z^2 \mp
    z\sqrt{z^2 + 4x_i(n_i-x_i)/n_i}}{2(n_i + z^2)}\$\$

2.  Form the CI for \\(\delta = p_1 - p_2\\): \$\$\mathrm{LCL} =
    \hat\delta - \sqrt{(p_1-l_1)^2 + (u_2-p_2)^2}\$\$ \$\$\mathrm{UCL} =
    \hat\delta + \sqrt{(u_1-p_1)^2 + (p_2-l_2)^2}\$\$

The function is vectorised: if vectors of length \\(k\\) are supplied,
each corresponding tuple \\((x\_{1i}, n\_{1i}, x\_{2i}, n\_{2i})\\) is
processed independently and the result is a \\(k \times 3\\) matrix.

## References

Newcombe, R. G. (1998). Interval estimation for the difference between
independent proportions: comparison of eleven methods. *Statistics in
Medicine*, **17**(8), 873–890.
[doi:10.1002/(SICI)1097-0258(19980430)17:8\<873::AID-SIM779\>3.0.CO;2-I](https://doi.org/10.1002/%28SICI%291097-0258%2819980430%2917%3A8%3C873%3A%3AAID-SIM779%3E3.0.CO%3B2-I)

## See also

[`ks_newcombe_hs_strata`](https://crow16384.github.io/kstools/reference/ks_newcombe_hs_strata.md),
[`ks_eairdiff_mn`](https://crow16384.github.io/kstools/reference/ks_eairdiff_mn.md)

## Examples

``` r
## Single comparison
ks_newcombe_hs(36L, 54L, 41L, 56L, alpha = 0.10)
#>            delta        lcl       ucl
#> [1,] -0.06547619 -0.2054461 0.0773548

## Zero events in one group
ks_newcombe_hs(0L, 50L, 10L, 50L)
#>      delta        lcl         ucl
#> [1,]  -0.2 -0.3303711 -0.08705014

## Vectorised: three comparisons at once
ks_newcombe_hs(
  x1 = c(36L, 38L, 3L),
  n1 = c(54L, 57L, 86L),
  x2 = c(41L, 42L, 3L),
  n2 = c(56L, 57L, 93L),
  alpha = 0.10
)
#>             delta         lcl        ucl
#> [1,] -0.065476190 -0.20544613 0.07735480
#> [2,] -0.070175439 -0.20690888 0.07020393
#> [3,]  0.002625656 -0.04764532 0.05550182
```
