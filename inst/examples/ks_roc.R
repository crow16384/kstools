## ============================================================
## ks_roc() — compare correlated ROC AUCs
## ============================================================

library(kstools)

set.seed(123)
n <- 120
y <- rbinom(n, size = 1, prob = 0.45)

## Three correlated predictors with different separation strength
x1 <- y + rnorm(n, sd = 0.8)
x2 <- 0.7 * y + rnorm(n, sd = 0.9)
x3 <- 0.5 * y + rnorm(n, sd = 1.0)

df <- data.frame(y = y, x1 = x1, x2 = x2, x3 = x3)

## 1) Default: all pairwise contrasts
res_all <- ks_roc(df, var = c("x1", "x2", "x3"), response = "y", details = TRUE)
res_all$areas
res_all$contrasts
res_all$overall_test

## 2) Custom contrast matrix
L <- rbind(
  c(1, -1, 0),
  c(1, 0, -1)
)
res_custom <- ks_roc(df, var = c("x1", "x2", "x3"), response = "y", contrast = L)
res_custom$contrasts
