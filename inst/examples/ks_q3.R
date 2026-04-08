## ============================================================
## ks_q3() — 75th percentile with configurable quantile type
## ============================================================

library(kstools)

x <- c(2, 4, 6, 8, 10, 12, 14, 16, NA)

## Default package behavior (type 2 unless option overridden)
ks_q3(x)

## Explicit quantile type
ks_q3(x, type = 7)

## Compare type 2 vs type 7
c(type2 = ks_q3(x, type = 2), type7 = ks_q3(x, type = 7))
