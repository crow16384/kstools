# Smoothed weight of evidence (SWOE) for categorical predictors

Encodes each level of a categorical variable with a smoothed log-odds of
the response, relative to the overall response rate. Useful as a numeric
replacement for a factor when screening logistic-type models.

## Usage

``` r
ks_swoe(data, par, resp, quoted = FALSE, prior.n = 24)
```

## Arguments

- data:

  A `data.frame` (or `tibble`).

- par:

  Name of the predictor column (factor or coercible to grouping
  variable). With `quoted = FALSE`, pass the column name unquoted
  (`ks_swoe(dt, sex, yn)`).

- resp:

  Name of the binary response column (0/1 or logical). Unquoted unless
  `quoted = TRUE`.

- quoted:

  If `FALSE` (default), `par` and `resp` are captured with `substitute`
  and converted to column names. If `TRUE`, `par` and `resp` must be
  character strings.

- prior.n:

  Pseudo-count (prior strength) for the empirical-Bayes-style smoothing
  in the logit; the original implementation used `24`.

## Value

A numeric vector of length `nrow(data)` (unnamed), giving the SWOE score
for each row's level of `par`.

## Details

Let \\\rho\\ be the overall mean of the response and, for each level
\\k\\ of `par`, let \\e_k\\ be the number of events (response = 1) and
\\n_k\\ the number of non-missing responses. The smoothed logit for
level \\k\\ is \$\$\log \frac{e_k + \rho \cdot m}{n_k - e_k +
(1-\rho)\cdot m}\$\$ with \\m = \\`prior.n`. A global logit
\\\log(\rho/(1-\rho))\\ is appended internally for completeness; row
values are taken by matching each row's `par` level to the named level
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
ks_swoe(dt, sex, yn)
#>  [1] -1.516347 -1.516347 -1.199417 -1.516347 -1.516347 -1.516347 -1.516347
#>  [8] -1.199417 -1.516347 -1.199417 -1.199417 -1.516347 -1.516347 -1.516347
#> [15] -1.516347 -1.199417 -1.516347 -1.516347 -1.516347 -1.199417 -1.516347
#> [22] -1.199417 -1.516347 -1.199417 -1.516347 -1.516347 -1.516347 -1.516347
#> [29] -1.516347 -1.199417 -1.199417 -1.516347 -1.516347 -1.516347 -1.516347
#> [36] -1.199417 -1.516347 -1.516347 -1.516347 -1.199417 -1.516347 -1.199417
#> [43] -1.516347 -1.516347 -1.516347 -1.516347 -1.516347 -1.516347 -1.516347
#> [50] -1.199417
ks_swoe(dt, par = "sex", resp = "yn", quoted = TRUE)
#>  [1] -1.516347 -1.516347 -1.199417 -1.516347 -1.516347 -1.516347 -1.516347
#>  [8] -1.199417 -1.516347 -1.199417 -1.199417 -1.516347 -1.516347 -1.516347
#> [15] -1.516347 -1.199417 -1.516347 -1.516347 -1.516347 -1.199417 -1.516347
#> [22] -1.199417 -1.516347 -1.199417 -1.516347 -1.516347 -1.516347 -1.516347
#> [29] -1.516347 -1.199417 -1.199417 -1.516347 -1.516347 -1.516347 -1.516347
#> [36] -1.199417 -1.516347 -1.516347 -1.516347 -1.199417 -1.516347 -1.199417
#> [43] -1.516347 -1.516347 -1.516347 -1.516347 -1.516347 -1.516347 -1.516347
#> [50] -1.199417
```
