# Exact Dunnett critical value (multivariate-t)

Computes the two- or one-sided Dunnett critical value for \`k\`
comparisons against a common control by inverting the equicorrelated
multivariate Student-t CDF (\`mnormt::sadmvt\` / \`mnormt::pmt\` via
`uniroot`). For balanced designs the control-correlation is \`rho =
1/2\`. Numerically equivalent to \`nCDunnett::qNCDun\` (2.5067 vs
2.506845 at \`p = 0.95, df = 24, k = 3\`).

## Usage

``` r
ks_dunnett_crit(p, df, k, rho = 0.5, type = c("two-sided", "one-sided"))
```

## Arguments

- p:

  Coverage probability (e.g. \`0.95\`).

- df:

  Error degrees of freedom.

- k:

  Number of treatments compared to the control (\`k \>= 2\`).

- rho:

  Correlation between pairs of contrasts; \`1/2\` for balanced Dunnett
  designs.

- type:

  \`"two-sided"\` (default) or \`"one-sided"\`.

## Value

A single numeric critical value.

## Examples

``` r
ks_dunnett_crit(p = 0.95, df = 24, k = 3, rho = 0.5)
#> [1] 2.506654
ks_dunnett_crit(p = 0.95, df = 24, k = 3, rho = 0.5, type = "one-sided")
#> [1] 2.169586
```
