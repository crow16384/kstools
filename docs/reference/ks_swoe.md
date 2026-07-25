# Smoothed weight of evidence (SWOE) for categorical predictors

Encodes each level of a categorical variable with a smoothed log-odds of
the response, relative to the overall response rate. Useful as a numeric
replacement for a factor when screening logistic-type models. Designed
for use inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Usage

``` r
ks_swoe(x, y, prior.n = 24)
```

## Arguments

- x:

  Categorical predictor (factor, character, or other grouping vector).

- y:

  Binary response (numeric 0/1 or logical), same length as `x`.

- prior.n:

  Pseudo-count (prior strength) for the empirical-Bayes-style smoothing
  in the logit; the original implementation used `24`.

## Value

A numeric vector of length `length(x)` (unnamed), giving the SWOE score
for each row's level of `x`.

## Details

Let \\\rho\\ be the overall mean of the response and, for each level
\\k\\ of `x`, let \\e_k\\ be the number of events (response = 1) and
\\n_k\\ the number of non-missing responses. The smoothed logit for
level \\k\\ is \$\$\log \frac{e_k + \rho \cdot m}{n_k - e_k +
(1-\rho)\cdot m}\$\$ with \\m = \\`prior.n`. A global logit
\\\log(\rho/(1-\rho))\\ is appended internally for completeness; row
values are taken by matching each row's `x` level to the named level
logits.

If \\\rho \in \\0,1\\\\, the global logit is undefined; the function
clamps \\\rho\\ to \\(\varepsilon, 1-\varepsilon)\\ for that term only,
with a warning.

## References

The construction follows common “weight of evidence” encodings with
Dirichlet-style smoothing; the choice `prior.n = 24` matches the
historical default in this package.

## See also

[`glm`](https://rdrr.io/r/stats/glm.html) for logistic regression

## Examples

``` r
set.seed(1234)
dt <- data.frame(
  yn  = rbinom(50, 1, 0.3),
  sex = factor(rbinom(50, 1, 0.55), levels = c(0, 1), labels = c("F", "M"))
)
ks_swoe(dt$sex, dt$yn)
#>  [1] -1.516347 -1.516347 -1.199417 -1.516347 -1.516347 -1.516347 -1.516347
#>  [8] -1.199417 -1.516347 -1.199417 -1.199417 -1.516347 -1.516347 -1.516347
#> [15] -1.516347 -1.199417 -1.516347 -1.516347 -1.516347 -1.199417 -1.516347
#> [22] -1.199417 -1.516347 -1.199417 -1.516347 -1.516347 -1.516347 -1.516347
#> [29] -1.516347 -1.199417 -1.199417 -1.516347 -1.516347 -1.516347 -1.516347
#> [36] -1.199417 -1.516347 -1.516347 -1.516347 -1.199417 -1.516347 -1.199417
#> [43] -1.516347 -1.516347 -1.516347 -1.516347 -1.516347 -1.516347 -1.516347
#> [50] -1.199417
if (requireNamespace("dplyr", quietly = TRUE)) {
  dplyr::mutate(dt, sex_swoe = ks_swoe(sex, yn))
}
#>    yn sex  sex_swoe
#> 1   0   M -1.516347
#> 2   0   M -1.516347
#> 3   0   F -1.199417
#> 4   0   M -1.516347
#> 5   1   M -1.516347
#> 6   0   M -1.516347
#> 7   0   M -1.516347
#> 8   0   F -1.199417
#> 9   0   M -1.516347
#> 10  0   F -1.199417
#> 11  0   F -1.199417
#> 12  0   M -1.516347
#> 13  0   M -1.516347
#> 14  1   M -1.516347
#> 15  0   M -1.516347
#> 16  1   F -1.199417
#> 17  0   M -1.516347
#> 18  0   M -1.516347
#> 19  0   M -1.516347
#> 20  0   F -1.199417
#> 21  0   M -1.516347
#> 22  0   F -1.199417
#> 23  0   M -1.516347
#> 24  0   F -1.199417
#> 25  0   M -1.516347
#> 26  1   M -1.516347
#> 27  0   M -1.516347
#> 28  1   M -1.516347
#> 29  1   M -1.516347
#> 30  0   F -1.199417
#> 31  0   F -1.199417
#> 32  0   M -1.516347
#> 33  0   M -1.516347
#> 34  0   M -1.516347
#> 35  0   M -1.516347
#> 36  1   F -1.199417
#> 37  0   M -1.516347
#> 38  0   M -1.516347
#> 39  1   M -1.516347
#> 40  1   F -1.199417
#> 41  0   M -1.516347
#> 42  0   F -1.199417
#> 43  0   M -1.516347
#> 44  0   M -1.516347
#> 45  0   M -1.516347
#> 46  0   M -1.516347
#> 47  0   M -1.516347
#> 48  0   M -1.516347
#> 49  0   M -1.516347
#> 50  1   F -1.199417
```
