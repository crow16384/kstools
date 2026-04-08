# Compare correlated ROC curve areas (AUC) via Mann-Whitney contrasts

R analogue of the classic SAS ROC macro: computes AUC estimates for
multiple predictors measured on the same subjects, estimates their
covariance matrix using Mann-Whitney components with pairwise deletion,
and performs Wald-style tests for user-specified linear contrasts.

## Usage

``` r
ks_roc(data, var, response, contrast = NULL, details = FALSE, alpha = 0.05)
```

## Arguments

- data:

  A data frame containing predictors and the binary response.

- var:

  Character vector of predictor column names.

- response:

  Single character scalar naming the binary response column coded as
  0/1.

- contrast:

  Optional numeric contrast matrix. Columns must match `length(var)`. If
  `NULL` (default), all pairwise contrasts `AUC_i - AUC_j` for `i < j`
  are generated.

- details:

  Logical; if `TRUE`, include intermediate matrices (`t`, `v`, `nx`,
  `ny`, `lv`) in output.

- alpha:

  Significance level for two-sided confidence intervals.

## Value

A list with elements:

- areas:

  Data frame with AUC, standard error, and confidence bounds.

- contrasts:

  Data frame with contrast estimates, SE, CI, chi-square, and p-value (1
  df each row).

- contrast_coefficients:

  Contrast matrix used in the analysis.

- overall_test:

  Named numeric vector: chi-square, df, p-value for simultaneous
  contrast test.

- pvalue:

  Overall contrast-test p-value (same as `overall_test[["p_value"]]`).

- details:

  Only when `details = TRUE`: list of intermediate matrices `t`, `v`,
  `nx`, `ny`, `lv`.
