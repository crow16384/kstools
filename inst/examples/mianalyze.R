## ============================================================
## mianalyze() — compatibility alias for ks_mianalyze()
## ============================================================
## See also inst/examples/ks_mianalyze.R for SAS Example 58.1.

library(kstools)

## Simple pooling
est <- c(0.345, 0.303, 0.298, 0.378)
err <- c(0.056, 0.101, 0.099, 0.034)
mianalyze(est, err)

## SAS Example 58.1 — Oxygen means with EDF=30
mianalyze(
  est = c(47.0120, 47.2407, 47.4995, 47.1485, 47.0042),
  err = c(0.95984, 0.93540, 1.00766, 0.95439, 0.96528),
  edf = 30
)
