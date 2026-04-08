## ============================================================
## ks_eairdiff_strata_mn() — stratified rate-difference CI
## ============================================================

library(kstools)

## Two strata example
strat <- data.frame(
  region = c("EU", "NA"),
  n1 = c(10, 5), n2 = c(5, 3),
  T1 = c(100, 80), T2 = c(100, 70)
)

ks_eairdiff_strata_mn(strat$n1, strat$n2, strat$T1, strat$T2)

## Compare with unstratified pooled counts
ks_eairdiff_mn(sum(strat$n1), sum(strat$n2), sum(strat$T1), sum(strat$T2))

## 90% CI
ks_eairdiff_strata_mn(strat$n1, strat$n2, strat$T1, strat$T2, alpha = 0.10)
