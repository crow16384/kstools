# Stratified Newcombe Hybrid Score CI for a difference of two proportions

Extends Newcombe's Hybrid Score method to stratified data using
Mantel-Haenszel harmonic-mean weights. Within each stratum the Wilson
score intervals are computed for both groups; the stratum-level
contributions are then pooled via weighted combination to produce a
single CI for the overall difference.

## Usage

``` r
ks_newcombe_hs_strata(x1, n1, x2, n2, alpha = 0.05)
```

## Arguments

- x1:

  Integer vector of event counts for group 1, one element per stratum.

- n1:

  Integer vector of sample sizes for group 1, one element per stratum
  (\\(\> 0\\)).

- x2:

  Integer vector of event counts for group 2, one element per stratum.

- n2:

  Integer vector of sample sizes for group 2, one element per stratum
  (\\(\> 0\\)).

- alpha:

  Significance level; scalar in \\((0,1)\\). Defaults to `0.05` (95%
  CI).

## Value

A named numeric vector of length 3:

- `delta`:

  Weighted pooled point estimate.

- `lcl`:

  Lower confidence limit.

- `ucl`:

  Upper confidence limit.

## Details

**Algorithm**:

1.  Compute Wilson CIs \\(\[l\_{1i},\\,u\_{1i}\]\\) and
    \\(\[l\_{2i},\\,u\_{2i}\]\\) for each stratum \\(i\\).

2.  Assign stratum weights \\(W_i = n\_{1i}\\,n\_{2i} / (n\_{1i} +
    n\_{2i})\\) (harmonic-mean / Mantel-Haenszel weights).

3.  Pooled point estimate: \\(\hat\delta = \sum W_i (p\_{1i}-p\_{2i}) /
    \sum W_i\\).

4.  Pooled lower limit: \$\$\mathrm{LCL} = \hat\delta - \sqrt{\frac{\sum
    W_i^2(p\_{1i}-l\_{1i})^2}{(\sum W_i)^2} + \frac{\sum
    W_i^2(u\_{2i}-p\_{2i})^2}{(\sum W_i)^2}}\$\$

5.  Pooled upper limit: analogously.

A single stratum reduces to the un-stratified formula.

## References

Newcombe, R. G. (1998). Interval estimation for the difference between
independent proportions: comparison of eleven methods. *Statistics in
Medicine*, **17**(8), 873–890.
[doi:10.1002/(SICI)1097-0258(19980430)17:8\<873::AID-SIM779\>3.0.CO;2-I](https://doi.org/10.1002/%28SICI%291097-0258%2819980430%2917%3A8%3C873%3A%3AAID-SIM779%3E3.0.CO%3B2-I)

## See also

[`ks_newcombe_hs`](https://crow16384.github.io/kstools/reference/ks_newcombe_hs.md)

## Examples

``` r
## Two-stratum example
ks_newcombe_hs_strata(
  x1 = c(36L, 10L), n1 = c(54L, 30L),
  x2 = c(41L,  8L), n2 = c(56L, 30L)
)
#>       delta         lcl         ucl 
#> -0.01882756 -0.15251739  0.11513790 

## Single stratum — identical to ks_newcombe_hs()
ks_newcombe_hs_strata(36L, 54L, 41L, 56L)
#>       delta         lcl         ucl 
#> -0.06547619 -0.23089667  0.10396319 
ks_newcombe_hs(36L, 54L, 41L, 56L)  # same result
#>            delta        lcl       ucl
#> [1,] -0.06547619 -0.2308967 0.1039632
```
