## ============================================================
## ks_mianalyze() / mianalyze() — Rubin pooling over imputations
## ============================================================

library(kstools)

## Example from documentation
est <- c(0.345, 0.303, 0.298, 0.378)
err <- c(0.056, 0.101, 0.099, 0.034)

out <- mianalyze(est, err)
out

## With finite complete-data df adjustment
mianalyze(est, err, v0 = 120)

## Null-hypothesis test at non-zero theta0
mianalyze(est, err, theta0 = 0.30)

## Alias
identical(names(ks_mianalyze(est, err)), names(mianalyze(est, err)))
