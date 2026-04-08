## ============================================================
## ks_p_norm() — Shapiro-Wilk p-value wrapper
## ============================================================

library(kstools)

set.seed(7)

## Approximately normal sample
x_norm <- rnorm(40)
ks_p_norm(x_norm)

## Non-normal sample
x_skew <- rexp(40)
ks_p_norm(x_skew)

## Too-short sample (returns NA via tryCatch)
ks_p_norm(c(1, 2))
