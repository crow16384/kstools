## ============================================================
## ks_eairdiff_mn() / ks_eairdiff_strata_mn()
## Miettinen-Nurminen CI for the difference of incidence rates
## ============================================================
## Common use-case: clinical trial AE summary comparing
##   Test (arm 1) vs Control (arm 2)
##   delta = rate_Test - rate_Control = n/T difference
##   CI: Miettinen-Nurminen score-based
##
## Units: n = events, T = person-time (e.g. patient-years)
## ============================================================

library(kstools)

## ------------------------------------------------------------------
## 1. Single comparison — basic usage
## ------------------------------------------------------------------
cat("=== 1. Single comparison ===\n\n")

## Test: 10 events / 100 patient-years  → EAIR = 0.10
## Control:  5 events / 100 patient-years → EAIR = 0.05
## delta = 0.05 events/patient-year

res1 <- ks_eairdiff_mn(n1 = 10, n2 = 5, T1 = 100, T2 = 100)
print(res1)
cat(sprintf("delta = %.4f [%.4f, %.4f]\n\n",
            res1[, "delta"], res1[, "lcl"], res1[, "ucl"]))

## ------------------------------------------------------------------
## 2. Equal rates — CI straddles zero
## ------------------------------------------------------------------
cat("=== 2. Equal rates (delta = 0) ===\n\n")

res2 <- ks_eairdiff_mn(n1 = 5, n2 = 5, T1 = 100, T2 = 100)
print(res2)

## ------------------------------------------------------------------
## 3. Zero events in one arm
## ------------------------------------------------------------------
cat("\n=== 3. Zero events in the Test arm ===\n\n")

res3 <- ks_eairdiff_mn(n1 = 0, n2 = 5, T1 = 100, T2 = 100)
print(res3)

## ------------------------------------------------------------------
## 4. Vectorised — one row per AE term
## ------------------------------------------------------------------
cat("\n=== 4. Vectorised over multiple AE terms ===\n\n")

ae_summary <- data.frame(
  ae_term  = c("Headache", "Nausea", "Fatigue", "Rash"),
  n_test   = c(12L,  8L, 15L,  3L),
  n_ctrl   = c( 6L,  9L, 10L,  2L),
  pt_test  = c(200, 200, 200, 200),
  pt_ctrl  = c(190, 190, 190, 190)
)

ci_mat <- ks_eairdiff_mn(
  n1 = ae_summary$n_test,
  n2 = ae_summary$n_ctrl,
  T1 = ae_summary$pt_test,
  T2 = ae_summary$pt_ctrl
)

result <- cbind(ae_summary["ae_term"], round(ci_mat, 4))
print(result, row.names = FALSE)

## ------------------------------------------------------------------
## 5. Effect of alpha (confidence level)
## ------------------------------------------------------------------
cat("\n=== 5. CI width vs. alpha ===\n\n")

alphas <- c(0.01, 0.05, 0.10, 0.20)

ci_by_alpha <- do.call(rbind, lapply(alphas, function(a) {
  r <- ks_eairdiff_mn(10, 5, 100, 100, alpha = a)
  data.frame(alpha   = a,
             conf_pct = sprintf("%.0f%%", (1 - a) * 100),
             lcl     = round(r[, "lcl"], 4),
             ucl     = round(r[, "ucl"], 4),
             width   = round(r[, "ucl"] - r[, "lcl"], 4))
}))

print(ci_by_alpha, row.names = FALSE)

## ------------------------------------------------------------------
## 6. Stratified analysis — ks_eairdiff_strata_mn()
## ------------------------------------------------------------------
cat("\n=== 6. Stratified by region ===\n\n")

## Two strata: Europe and North America
strat <- data.frame(
  region = c("Europe", "N. America"),
  n_test = c(10L,  5L),
  n_ctrl = c( 5L,  3L),
  pt_test = c(100, 80),
  pt_ctrl = c(100, 70)
)

cat("Per-stratum rate differences:\n")
cat(sprintf("  %-12s  rate_Test=%.4f  rate_Ctrl=%.4f  diff=%.4f\n",
    strat$region[1],
    strat$n_test[1] / strat$pt_test[1],
    strat$n_ctrl[1] / strat$pt_ctrl[1],
    strat$n_test[1] / strat$pt_test[1] - strat$n_ctrl[1] / strat$pt_ctrl[1]))
cat(sprintf("  %-12s  rate_Test=%.4f  rate_Ctrl=%.4f  diff=%.4f\n",
    strat$region[2],
    strat$n_test[2] / strat$pt_test[2],
    strat$n_ctrl[2] / strat$pt_ctrl[2],
    strat$n_test[2] / strat$pt_test[2] - strat$n_ctrl[2] / strat$pt_ctrl[2]))

cat("\nStratified CI (pooled across regions):\n")
res6 <- ks_eairdiff_strata_mn(
  n1 = strat$n_test, n2 = strat$n_ctrl,
  T1 = strat$pt_test, T2 = strat$pt_ctrl
)
cat(sprintf("  delta = %.4f [%.4f, %.4f]\n\n",
            res6["delta"], res6["lcl"], res6["ucl"]))

## Compare with unstratified (ignores regional imbalance):
cat("Unstratified CI (pooled counts):\n")
res6u <- ks_eairdiff_mn(
  n1 = sum(strat$n_test), n2 = sum(strat$n_ctrl),
  T1 = sum(strat$pt_test), T2 = sum(strat$pt_ctrl)
)
cat(sprintf("  delta = %.4f [%.4f, %.4f]\n", res6u[,"delta"], res6u[,"lcl"], res6u[,"ucl"]))

## ------------------------------------------------------------------
## 7. Multiple strata with 90 % CI
## ------------------------------------------------------------------
cat("\n=== 7. Stratified 90%% CI ===\n\n")

res7 <- ks_eairdiff_strata_mn(
  n1 = c(10, 5), n2 = c(5, 3),
  T1 = c(100, 80), T2 = c(100, 70),
  alpha = 0.10
)
cat(sprintf("90%% CI: delta = %.4f [%.4f, %.4f]\n",
            res7["delta"], res7["lcl"], res7["ucl"]))
