# Bioequivalence: 2x2 crossover analysis

Fits the standard two-period, two-sequence crossover model \`response ~
sequence + treatment + period\` (subject nested in sequence in the
random term, \`random = ~ seq \| subject\`) and returns the
test-minus-reference treatment difference with its confidence interval.
The sequence main effect absorbs carryover. This is the R twin of the
SAS \`PROC MIXED\` bioequivalence analysis in the R tricks article
(verified: estimate 0.0145, SE 0.0142, df 7, matching SAS \`CL=DF=7\`).

## Usage

``` r
ks_be_2x2(
  data,
  response,
  trt,
  test,
  reference,
  seq,
  period,
  subject,
  log = TRUE,
  conf.level = 0.9
)
```

## Arguments

- data:

  Data frame with one row per subject-period.

- response:

  Unquoted name of the numeric response column.

- trt:

  Unquoted name of the treatment column (factor with exactly the two
  levels named in \`test\` and \`reference\`).

- test, reference:

  Character labels of the test and reference treatment levels (e.g.
  \`"T"\`, \`"R"\`).

- seq, period, subject:

  Unquoted names of sequence, period, and subject columns.

- log:

  Apply \`log()\` to the response before fitting (default \`TRUE\`,
  standard for BE on concentration data). Requires all responses
  positive.

- conf.level:

  Confidence level; BE conventionally uses \`0.90\`.

## Value

A list with \`estimate\`, \`se\`, \`df\`, \`t\`, \`p.value\`, \`lcl\`,
\`ucl\` (log scale when \`log = TRUE\`), plus \`ratio\`, \`ratio.lcl\`,
\`ratio.ucl\` on the original scale when \`log = TRUE\`.

## Examples

``` r
cross <- data.frame(
  per = as.factor(rep(c(1, 2), 9)),
  trt = as.factor(c(rep(c("T", "R"), 4), rep(c("R", "T"), 5))),
  seq = as.factor(c(rep(1, 8), rep(2, 10))),
  cow = as.factor(rep(1:9, each = 2)),
  my  = c(29.9, 27.8, 54.0, 49.7, 41.6, 38.4, 28.5, 26.5, 22.2,
          21.4, 55.5, 49.1, 43.5, 41.3, 33.2, 34.3, 18.2, 17.1))
fit <- ks_be_2x2(cross, response = my, trt = trt, test = "T",
                 reference = "R", seq = seq, period = per, subject = cow)
c(TvR_log = fit$estimate, ratio = fit$ratio,
  lcl = fit$ratio.lcl, ucl = fit$ratio.ucl)
#>    TvR_log      ratio        lcl        ucl 
#> 0.01448831 1.01459377 0.98773441 1.04218353 
```
