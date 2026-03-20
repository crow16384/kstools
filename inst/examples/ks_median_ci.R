## ks_median_ci — median with confidence interval
## ----------------------------------------------

library(kstools)

## Fixed demo vector (n = 15)
vv <- c(8, 11, 12, 13, 15, 17, 19, 20, 21, 21, 22, 23, 25, 26, 28)


## 1. Bootstrap: Basic / Normal / Percentile / BCa (set seed for reproducibility)
suppressWarnings(
  ks_median_ci(vv, method = "boot", R = 2000L, seed = 1L)
)


## 2. Olive: simple median CI
ks_median_ci(vv, method = "olive", alpha = 0.05)


## 3. z: order-statistic CI — compare 95% vs 90% (type = 2, SAS-style median)
ks_median_ci(vv, method = "z", alpha = 0.05)
ks_median_ci(vv, method = "z", alpha = 0.10)


## 4. NA handling — default na.rm = TRUE
ks_median_ci(c(vv, NA_real_), method = "olive")


## 5. Random normal data (bootstrap + Olive)
set.seed(123)
x <- rnorm(80, mean = 56, sd = 2.5)
ks_median_ci(x, method = "boot", R = 1500L, seed = 7L)
ks_median_ci(x, method = "olive")


## 6. Single observation — z method gives a point
ks_median_ci(42, method = "z")


## 7. By arm — base R `by()` (one CI per group)
if (requireNamespace("dplyr", quietly = TRUE)) {
  d <- dplyr::tibble(
    arm = rep(c("A", "B"), each = 20L),
    val = c(rnorm(20, 10, 2), rnorm(20, 12, 2))
  )
  by(d, d$arm, function(sub) ks_median_ci(sub$val, method = "olive"))
}
