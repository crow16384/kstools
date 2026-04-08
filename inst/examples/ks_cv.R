## ============================================================
## ks_cv() — coefficient of variation
## ============================================================

library(kstools)

x <- c(10, 12, 9, 11, 10, NA, 8, 13)

ks_cv(x)
ks_cv(x, na.rm = FALSE)

## Compare groups
grp <- data.frame(
  trt = rep(c("A", "B"), each = 6),
  aval = c(10, 9, 11, 10, 12, 9, 20, 18, 22, 17, 19, 21)
)

by(grp$aval, grp$trt, ks_cv)
