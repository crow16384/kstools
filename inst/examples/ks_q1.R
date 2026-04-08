## ============================================================
## ks_q1() — 25th percentile with configurable quantile type
## ============================================================

library(kstools)

x <- c(2, 4, 6, 8, 10, 12, 14, 16, NA)

## Default package behavior (type 2 unless option overridden)
ks_q1(x)

## Explicit quantile type
ks_q1(x, type = 7)

## Global option override
old <- options(kstools.quantile.type = 7L)
ks_q1(x)
options(old)
