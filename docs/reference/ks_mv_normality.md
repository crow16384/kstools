# Multivariate normality tests (Mardia, energy)

Mardia's skewness and kurtosis tests are implemented in base R (verified
against \`QuantPsyc::mult.norm\`); the energy test
(\`energy::mvnorm.etest\`) is attached automatically when the suggested
energy package is installed, and silently skipped otherwise.

## Usage

``` r
ks_mv_normality(x, R = 999, seed = NULL)
```

## Arguments

- x:

  A numeric matrix or data frame (rows = observations). \`NA\` rows are
  dropped.

- R:

  Number of energy-test replicates.

- seed:

  Integer seed for the energy permutation (reproducibility).

## Value

A list with \`mardia\` (a \`2 x 3\` matrix: Beta-hat, kappa, p-val;
\`NULL\` if the sample is too small), \`energy\` (or \`NULL\` when the
energy package is missing), and \`n\`, \`p\`.

## Details

Mardia: under multivariate normality, \`A = n b1_p / 6\` is chi-squared
with \`p(p+1)(p+2)/6\` df, and the standardized \`b2_p\` is standard
normal. The energy test is a consistent omnibus alternative; with \`n \<
p + 2\` Mardia's test is not defined and \`NULL\` is returned.

## Examples

``` r
set.seed(0)
dat <- data.frame(x1 = rnorm(50), x2 = rnorm(50), x3 = rnorm(50))
out <- ks_mv_normality(dat)
out$mardia
#>           Beta-hat      kappa     p-val
#> Skewness  1.630474 13.5872843 0.1926626
#> Kurtosis 13.895364 -0.7130395 0.4758213
out$energy$statistic
#> E-statistic 
#>   0.9092327 
```
