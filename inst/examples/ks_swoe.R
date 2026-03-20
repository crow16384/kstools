## ks_swoe — smoothed weight of evidence for a categorical predictor
## ------------------------------------------------------------------

library(kstools)

set.seed(1234)
dt <- data.frame(
  yn  = rbinom(50, 1, 0.3),
  sex = factor(rbinom(50, 1, 0.55), levels = c(0, 1), labels = c("F", "M"))
)

## 1. Unquoted column names (typical interactive use)
sw <- ks_swoe(dt, sex, yn)
head(sw)
summary(sw)


## 2. Quoted names (programmatic / dplyr)
ks_swoe(dt, par = "sex", resp = "yn", quoted = TRUE)


## 3. Stronger / weaker smoothing (default prior.n = 24)
ks_swoe(dt, sex, yn, prior.n = 12L)
ks_swoe(dt, sex, yn, prior.n = 48L)


## 4. Use as a numeric column for modelling
dt$sex_swoe <- ks_swoe(dt, sex, yn)
cor(dt$sex_swoe, dt$yn)


## 5. Character vector grouping (not a factor)
d2 <- data.frame(
  y = c(1, 0, 1, 1, 0),
  g = c("low", "low", "high", "high", "high")
)
ks_swoe(d2, g, y)


## 6. Boundary response (all 0 or all 1) — warning and finite scores
d3 <- data.frame(y = rep(0L, 8L), g = factor(rep(c("a", "b"), each = 4L)))
tryCatch(
  ks_swoe(d3, g, y),
  warning = function(w) message("Note: ", conditionMessage(w))
)
