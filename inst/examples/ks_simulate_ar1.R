## ks_simulate_ar1 — longitudinal data with AR(1) residuals
## ---------------------------------------------------------

library(kstools)

## 1. Simulate and inspect
set.seed(1)
dt <- ks_simulate_ar1(
  n = 15L,
  beta0 = 5,
  beta1 = 0.8,
  ar.val = 0.35,
  sigma = 2,
  tau0 = 1.2,
  tau1 = 0.4,
  tau01 = 0.15,
  m = 10L,
  seed = 42L
)
head(dt, 12L)
summary(dt)


## 2. Reproducible draws — same seed ⇒ same y
a <- ks_simulate_ar1(6L, 0, 1, 0.25, 1, 0.5, 0.2, m = 8L, seed = 7L)
b <- ks_simulate_ar1(6L, 0, 1, 0.25, 1, 0.5, 0.2, m = 8L, seed = 7L)
identical(a$y, b$y)


## 3. Plot (nlme groupedData method)
if (requireNamespace("graphics", quietly = TRUE)) {
  plot(dt)
}


## 4. Fit a simple mixed model (optional — needs nlme)
if (requireNamespace("nlme", quietly = TRUE)) {
  suppressPackageStartupMessages(library(nlme))
  fit <- try(
    lme(y ~ log(obs), random = ~ log(obs) | id, data = dt),
    silent = TRUE
  )
  if (!inherits(fit, "try-error"))
    summary(fit)
}
