# Stratified Miettinen-Nurminen CI for the difference of incidence rates

Stratified version of
[`ks_eairdiff_mn`](https://crow16384.github.io/kstools/reference/ks_eairdiff_mn.md):
pools evidence across strata using inverse-variance-like weights and
returns a single CI for the common rate difference.

## Usage

``` r
ks_eairdiff_strata_mn(n1, n2, T1, T2, alpha = 0.05)
```

## Arguments

- n1, n2:

  Numeric vectors of event counts per stratum (Test, Control).

- T1, T2:

  Numeric vectors of person-time per stratum (Test, Control). All four
  vectors must have the same length.

- alpha:

  Significance level for the two-sided CI. Default `0.05`.

## Value

A named numeric vector of length 3: `delta` (point estimate), `lcl`
(lower bound), `ucl` (upper bound).

## Details

Each stratum \\(j\\) contributes a weight \\(W_j = (\tilde\lambda\_{1j}
/ (\tilde\lambda\_{2j} T\_{1j}) + 1/T\_{2j})^{-1}\\) and the combined
score statistic is \\(\sum_j W_j^2 V_j^{-1} \cdot (\sum_j W_j (r\_{1j} -
r\_{2j} - \theta))^2\\).

The point estimate `delta` is the unweighted arithmetic mean of the
stratum-specific rate differences.

Strata with `NA` in any of their inputs are silently dropped via
`na.rm = TRUE` in the stratum sums.

## References

Miettinen O, Nurminen M (1985). Comparative analysis of two rates.
*Statistics in Medicine*, 4(2), 213–226.

## See also

[`ks_eairdiff_mn`](https://crow16384.github.io/kstools/reference/ks_eairdiff_mn.md)

## Examples

``` r
## Two strata
ks_eairdiff_strata_mn(
  n1 = c(10,  5),
  n2 = c( 5,  3),
  T1 = c(100, 80),
  T2 = c(100, 70)
)
#>       delta         lcl         ucl 
#>  0.03482143 -0.01869878  0.09902783 

## Single stratum — equivalent to ks_eairdiff_mn() up to point estimate
ks_eairdiff_strata_mn(n1 = 10, n2 = 5, T1 = 100, T2 = 100)
#>       delta         lcl         ucl 
#>  0.05000000 -0.02953395  0.13962995 

## 90 %% CI
ks_eairdiff_strata_mn(
  n1 = c(10, 5), n2 = c(5, 3),
  T1 = c(100, 80), T2 = c(100, 70),
  alpha = 0.10
)
#>        delta          lcl          ucl 
#>  0.034821429 -0.008756036  0.088051785 
```
