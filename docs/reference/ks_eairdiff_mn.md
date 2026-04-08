# Miettinen-Nurminen CI for the difference of two incidence rates

Computes the difference (Test \\-\\ Control) of two exposure-adjusted
incidence rates (EAIRs) and its confidence interval using the
score-based method of Miettinen & Nurminen (1985).

## Usage

``` r
ks_eairdiff_mn(n1, n2, T1, T2, alpha = 0.05)
```

## Arguments

- n1, n2:

  Non-negative integer event counts for Test and Control.

- T1, T2:

  Positive person-time at risk for Test and Control.

- alpha:

  Significance level for the two-sided CI. Default `0.05`.

## Value

A matrix with one row per input pair and three named columns: `delta`
(point estimate), `lcl` (lower bound), `ucl` (upper bound). Bounds are
`NA` when the score equation has fewer than two roots in `(-1, 1)`.

## Details

The CI is found by inverting the score statistic. For each candidate
rate difference \\\theta\\, the pooled estimate \\\tilde\lambda_2\\ is
obtained by solving the MLE equations under the constraint \\\lambda_1 -
\lambda_2 = \theta\\, and the score chi-squared is compared to
\\\chi^2\_{1,1-\alpha}\\. The two roots of this equation (found via
[`uniroot.all`](https://rdrr.io/pkg/rootSolve/man/uniroot.all.html)) are
the lower and upper confidence bounds.

The search interval for roots is fixed at `c(-1, 1)`, appropriate when
incidence rates are measured in events per person-time unit and are well
below 1. If rates exceed 1, expand the interval manually by calling
[`uniroot.all`](https://rdrr.io/pkg/rootSolve/man/uniroot.all.html)
directly.

The function is vectorised: when `n1`, `n2`, `T1`, `T2` are vectors of
equal length, one row per element is returned.

## References

Miettinen O, Nurminen M (1985). Comparative analysis of two rates.
*Statistics in Medicine*, 4(2), 213–226.

## See also

[`ks_eairdiff_strata_mn`](https://crow16384.github.io/kstools/reference/ks_eairdiff_strata_mn.md),
[`uniroot.all`](https://rdrr.io/pkg/rootSolve/man/uniroot.all.html)

## Examples

``` r
## Single comparison: Test rate = 0.10, Control rate = 0.05
ks_eairdiff_mn(n1 = 10, n2 = 5, T1 = 100, T2 = 100)
#>      delta         lcl     ucl
#> [1,]  0.05 -0.02953395 0.13963

## Equal rates → delta = 0, CI straddles zero
ks_eairdiff_mn(n1 = 5, n2 = 5, T1 = 100, T2 = 100)
#>      delta         lcl        ucl
#> [1,]     0 -0.07307177 0.07307177

## Vectorised over multiple time-point comparisons
ks_eairdiff_mn(
  n1 = c(10, 20, 8),
  n2 = c( 5, 15, 6),
  T1 = c(100, 150, 90),
  T2 = c(100, 150, 90)
)
#>           delta         lcl       ucl
#> [1,] 0.05000000 -0.02953395 0.1396300
#> [2,] 0.03333333 -0.04641174 0.1164774
#> [3,] 0.02222222 -0.06743854 0.1163687

## 90 %% CI
ks_eairdiff_mn(n1 = 10, n2 = 5, T1 = 100, T2 = 100, alpha = 0.10)
#>      delta         lcl       ucl
#> [1,]  0.05 -0.01501574 0.1226028
```
