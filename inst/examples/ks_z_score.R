## ============================================================
## ks_z_score() — standardize values
## ============================================================

library(kstools)

set.seed(345)
x <- rnorm(10, mean = 50, sd = 8)

z <- ks_z_score(x)
z

## Check standardized moments (approximately 0 mean, 1 sd)
c(mean = mean(z), sd = sd(z))
