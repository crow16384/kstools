## ============================================================
## ks_summary() — descriptive statistics for continuous variables
## ============================================================
## Columns returned: n, mean, sd, median, q1, q3, min, max, [extras], cv
## Grouping variables go in `...` (before any named arguments).
## na.rm, p.change, and extras are keyword-only: always name them.
##
## Q1/Q3 default to quantile type 2 (SAS-compatible).
## Override globally: options(kstools.quantile.type = 7L)
## ============================================================

library(kstools)

set.seed(42)

## ------------------------------------------------------------------
## Synthetic clinical dataset
##   - 120 subjects, 2 treatment arms, 2 visits
##   - AVAL: a continuous lab parameter (e.g. ALT, U/L)
##   - CHG:  change from baseline
## ------------------------------------------------------------------
n_arm <- 60L

adlb <- data.frame(
  usubjid = rep(sprintf("S%03d", seq_len(n_arm * 2L)), each = 2L),
  trt     = rep(c("Drug A", "Placebo"), each = n_arm * 2L),
  visit   = rep(c("Week 4", "Week 12"), times = n_arm * 2L),
  aval    = c(
    rnorm(n_arm * 2L, mean = 28, sd = 8),   # Drug A
    rnorm(n_arm * 2L, mean = 32, sd = 9)    # Placebo
  ),
  stringsAsFactors = FALSE
)

## Simulate change from baseline (negative = improvement)
adlb$chg <- adlb$aval - rnorm(nrow(adlb), mean = 30, sd = 7)

## Introduce a few NAs
adlb$aval[sample(nrow(adlb), 5L)] <- NA

## ------------------------------------------------------------------
## 1. No grouping — overall summary
## ------------------------------------------------------------------
cat("=== 1. Overall summary (no grouping) ===\n\n")

print(ks_summary(adlb, aval))

## ------------------------------------------------------------------
## 2. Single grouping variable
## ------------------------------------------------------------------
cat("\n\n=== 2. By treatment arm ===\n\n")

print(ks_summary(adlb, aval, trt))

## ------------------------------------------------------------------
## 3. Two grouping variables
## ------------------------------------------------------------------
cat("\n\n=== 3. By treatment arm and visit ===\n\n")

print(ks_summary(adlb, aval, trt, visit))

## ------------------------------------------------------------------
## 4. NA handling
##    na.rm = TRUE  (default): NAs silently excluded; n reflects
##                             non-missing observations only.
##    na.rm = FALSE: pass only on NA-free data; quantile() throws
##                   an error if NAs are present.
## ------------------------------------------------------------------
cat("\n\n=== 4. NA handling ===\n\n")

cat("Data has", sum(is.na(adlb$aval)), "NAs — n reflects non-missing count:\n")
print(ks_summary(adlb, aval, trt, na.rm = TRUE))

cat("\nna.rm = FALSE on clean data (no NAs present):\n")
adlb_clean <- adlb[!is.na(adlb$aval), ]
print(ks_summary(adlb_clean, aval, trt, na.rm = FALSE))

## ------------------------------------------------------------------
## 5. p.change = TRUE  — p-value for change from zero
##    Useful for change-from-baseline variables.
##    Selection: Shapiro-Wilk p > 0.05 → t-test; otherwise Wilcoxon.
## ------------------------------------------------------------------
cat("\n\n=== 5. Change from baseline with p-value ===\n\n")

print(ks_summary(adlb, chg, trt, visit, p.change = TRUE))

## ------------------------------------------------------------------
## 6. Quantile type option
##    Default type = 2 (SAS PROC MEANS / PROC UNIVARIATE compatible).
##    Switch to type = 7 (R default) globally via options().
## ------------------------------------------------------------------
cat("\n\n=== 6. Quantile type option ===\n\n")

x_vec <- c(2, 4, 6, 8, 10, 12, 14, 16)

cat("Q1 / Q3 with type 2 (SAS):\n")
cat(sprintf("  Q1 = %g,  Q3 = %g\n", ks_q1(x_vec), ks_q3(x_vec)))

old_opt <- options(kstools.quantile.type = 7L)
cat("Q1 / Q3 with type 7 (R default) — after options():\n")
cat(sprintf("  Q1 = %g,  Q3 = %g\n", ks_q1(x_vec), ks_q3(x_vec)))
options(old_opt)   # restore

cat("\nks_summary Q1/Q3 column — type 2 (restored):\n")
print(ks_summary(adlb[adlb$trt == "Drug A" & adlb$visit == "Week 4", ], aval)[
  , c("n", "q1", "median", "q3")])

## ------------------------------------------------------------------
## 7. Pipe-friendly usage
## ------------------------------------------------------------------
cat("\n\n=== 7. Pipe-friendly usage (dplyr filter → ks_summary) ===\n\n")

library(dplyr)

adlb |>
  filter(visit == "Week 12", !is.na(aval)) |>
  ks_summary(aval, trt) |>
  mutate(across(where(is.numeric), \(x) round(x, 2))) |>
  print()

## ------------------------------------------------------------------
## 8. Custom extra statistics via `extras`
##    Pass a named list of functions.  Each receives (x, na.rm).
##    Column names come from the list names.
## ------------------------------------------------------------------
cat("\n\n=== 8. extras: MAD, SEM, and IQR ===\n\n")

print(ks_summary(adlb, aval, trt,
  extras = list(
    mad = stats::mad,
    sem = function(x, na.rm) sd(x, na.rm = na.rm) / sqrt(sum(!is.na(x))),
    iqr = IQR
  )
))

## ------------------------------------------------------------------
## 9. extras combined with p.change
## ------------------------------------------------------------------
cat("\n\n=== 9. extras + p.change ===\n\n")

print(ks_summary(adlb, chg, trt, visit,
  p.change = TRUE,
  extras = list(iqr = IQR)
))
