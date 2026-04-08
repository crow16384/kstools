## ============================================================
## ks_newcombe_hs_strata() — stratified Newcombe HS CI
## ============================================================

library(kstools)

## Two strata
ks_newcombe_hs_strata(
  x1 = c(36L, 10L), n1 = c(54L, 30L),
  x2 = c(41L, 8L),  n2 = c(56L, 30L)
)

## Single stratum: same target as ks_newcombe_hs
ks_newcombe_hs_strata(36L, 54L, 41L, 56L)
ks_newcombe_hs(36L, 54L, 41L, 56L)
