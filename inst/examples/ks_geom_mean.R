## ks_geom_mean — geometric mean and CI on the log scale
## -------------------------------------------------------

library(kstools)

## 1. Basic use (positive data)
x <- c(2, 4, 8, 16, 32)
ks_geom_mean(x)


## 2. Compare with zeros excluded vs propagated
v <- c(1, 2, 0, 4)
ks_geom_mean(v, zero.propagate = FALSE)   # uses 1, 2, 4 only
ks_geom_mean(v, zero.propagate = TRUE)    # geometric mean 0


## 3. 90% CI
ks_geom_mean(x, alpha = 0.10)


## 4. Simulate positive data (log-normal-ish)
set.seed(1)
z <- abs(rnorm(50, mean = 10, sd = 3))
summary(z)
ks_geom_mean(z)


## 5. Negative values — not defined (NaN)
ks_geom_mean(c(1, -2, 4))


## 6. Single observation — GM defined, CI not
ks_geom_mean(42)


## 7. By group — one call per group
set.seed(2)
d <- data.frame(
  grp  = rep(c("A", "B"), each = 5L),
  conc = c(runif(5, 1, 10), runif(5, 2, 20))
)
by(d, d$grp, function(sub) ks_geom_mean(sub$conc))
