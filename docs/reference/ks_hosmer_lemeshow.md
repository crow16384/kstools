# Hosmer–Lemeshow goodness-of-fit test

Groups fitted probabilities into quantile-based bins, cross-tabulates
observed versus expected successes/failures, and returns the chi-squared
statistic with \`g - 2\` degrees of freedom (Hosmer & Lemeshow, 1980). A
high p-value indicates no evidence of miscalibration.

## Usage

``` r
ks_hosmer_lemeshow(y, yhat, g = 10)
```

## Arguments

- y:

  Binary response (0/1), same length as \`yhat\`.

- yhat:

  Fitted probabilities from a logistic model.

- g:

  Number of groups (default 10 = deciles).

## Value

A list with components `chisq` and `p.value`.

## References

Hosmer, D. and Lemeshow, S. (1980). Goodness of fit tests for the
multiple logistic regression model. *Biometrics*, **36**, 1045–1054.

## Examples

``` r
set.seed(1)
d <- data.frame(x = rnorm(200))
d$y <- rbinom(200, 1, plogis(0.8 * d$x))
m <- glm(y ~ x, binomial, data = d)
ks_hosmer_lemeshow(d$y, fitted(m))
#> $chisq
#> [1] 5.995023
#> 
#> $p.value
#> [1] 0.6477895
#> 
#> $df
#> [1] 8
#> 
```
