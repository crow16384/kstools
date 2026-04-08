## ============================================================
## ks_eairdiff_mn() — rate difference CI (Miettinen-Nurminen)
## ============================================================

library(kstools)

## Single comparison
ks_eairdiff_mn(n1 = 10, n2 = 5, T1 = 100, T2 = 100)

## Vectorised comparisons (e.g., AE terms)
n1 <- c(12, 8, 15, 3)
n2 <- c(6, 9, 10, 2)
T1 <- c(200, 200, 200, 200)
T2 <- c(190, 190, 190, 190)

res <- ks_eairdiff_mn(n1, n2, T1, T2)
round(res, 4)

## 90% CI
ks_eairdiff_mn(10, 5, 100, 100, alpha = 0.10)
