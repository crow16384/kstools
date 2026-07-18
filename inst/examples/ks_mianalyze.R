## ============================================================
## ks_mianalyze() / mianalyze() — Rubin pooling over imputations
## ============================================================
##
## References (SAS/STAT 12.3 User's Guide, Chapter 58):
##   - Combining Inferences from Imputed Data Sets
##   - Example 58.1: means and standard errors (EDF=30)
##   - Getting Started / Example 58.3: regression coefficients

library(kstools)

## ------------------------------------------------------------
## Basic usage (package documentation example)
## ------------------------------------------------------------
est <- c(0.345, 0.303, 0.298, 0.378)
err <- c(0.056, 0.101, 0.099, 0.034)

out <- mianalyze(est, err)
out

## Barnard-Rubin adjusted df (SAS EDF= analogue)
mianalyze(est, err, edf = 120)

## Null hypothesis at a non-zero theta0
mianalyze(est, err, theta0 = 0.30)

## Alias
identical(names(ks_mianalyze(est, err)), names(mianalyze(est, err)))


## ------------------------------------------------------------
## SAS Example 58.1 — Oxygen / RunTime / RunPulse means (EDF=30)
## Fitness data, n = 31 => complete-data df = 30
## ------------------------------------------------------------
oxygen <- mianalyze(
  est = c(47.0120, 47.2407, 47.4995, 47.1485, 47.0042),
  err = c(0.95984, 0.93540, 1.00766, 0.95439, 0.96528),
  edf = 30
)
runtime <- mianalyze(
  est = c(10.4441, 10.5040, 10.5922, 10.5279, 10.4913),
  err = c(0.28520, 0.26661, 0.26302, 0.26405, 0.27275),
  edf = 30
)
runpulse <- mianalyze(
  est = c(171.216, 171.244, 171.909, 171.146, 172.072),
  err = c(1.59910, 1.75638, 1.85795, 1.75011, 1.84807),
  edf = 30
)

oxygen
runtime
runpulse

## SAS Output 58.1.3 (Oxygen): Estimate 47.181, StdErr 0.990, DF 26.3
c(
  Estimate = oxygen$Estimate,
  StdErr = oxygen$StdErr,
  DF = oxygen$df,
  FMI = oxygen$lambda,
  RE = oxygen$re
)


## ------------------------------------------------------------
## SAS Getting Started / Example 58.3 — Intercept (EDF=28)
## Reconstruct MI draws from published Between/Within variances
## ------------------------------------------------------------
make_mi_from_moments <- function(Qbar, Vb, Vw, m = 5L) {
  z <- seq_len(m) - mean(seq_len(m))
  z <- z / sqrt(sum(z^2) / (m - 1))
  list(est = as.numeric(Qbar + sqrt(Vb) * z), err = rep(sqrt(Vw), m))
}

intercept_mi <- make_mi_from_moments(
  Qbar = 90.837440,
  Vb = 45.529229,
  Vw = 76.543614
)

intercept_rubin <- mianalyze(intercept_mi$est, intercept_mi$err)
intercept_edf28 <- mianalyze(intercept_mi$est, intercept_mi$err, edf = 28)

## Unadjusted DF ~ 23.06 (Figure 58.3); EDF=28 DF ~ 9.19 (Output 58.3.2)
c(df_rubin = intercept_rubin$df, df_edf28 = intercept_edf28$df)
intercept_edf28
