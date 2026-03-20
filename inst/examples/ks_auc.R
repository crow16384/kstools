## ============================================================
## ks_auc() — Area Under the Curve
## ============================================================
## Computes AUC from concentration-time data using:
##   type = "trapez"      — linear trapezoidal rule (default)
##   type = "log-trapez"  — log-linear trapezoidal rule
##
## The log-linear method is more accurate during exponential
## decline phases; it automatically falls back to the linear
## rule when two consecutive concentrations are equal or
## one is zero / negative.
##
## Rows are sorted by c(by, time) automatically.
## ============================================================

library(kstools)

## ------------------------------------------------------------------
## 1. Single subject — basic linear trapezoid
##    conc: 0 → 4 → 2 → 1 → 0 at t = 0,1,2,4,8
##    Analytical AUC = 2 + 3 + 3 + 2 = 10
## ------------------------------------------------------------------
cat("=== 1. Single subject — linear trapezoid ===\n\n")

pk1 <- data.frame(
  time = c(0, 1, 2, 4, 8),
  conc = c(0, 4, 2, 1, 0)
)

cat("AUC (expect 10):", ks_auc(pk1, val = conc, time = time), "\n\n")

## ------------------------------------------------------------------
## 2. Linear vs log-linear — exponential decline
##    True profile: C(t) = 4 * exp(-0.5 * t)
##    Analytical AUC(0→4) = 4/0.5 * (1 - exp(-2)) ≈ 6.940
##    Log-linear should be closer than linear to the analytic value.
## ------------------------------------------------------------------
cat("=== 2. Linear vs log-linear — exponential decline ===\n\n")

pk_exp <- data.frame(
  time = c(0, 1, 2, 4),
  conc = 4 * exp(-0.5 * c(0, 1, 2, 4))
)

cat(sprintf("%-35s %.4f\n", "Analytical AUC(0→4):", 4 / 0.5 * (1 - exp(-2))))
cat(sprintf("%-35s %.4f\n", "Linear trapezoid AUC:",
            ks_auc(pk_exp, val = conc, time = time)))
cat(sprintf("%-35s %.4f\n\n", "Log-linear trapezoid AUC:",
            ks_auc(pk_exp, val = conc, time = time, type = "log-trapez")))

## ------------------------------------------------------------------
## 3. Two-phase PK profile
##    Absorption phase (rising): linear trapezoid preferred
##    Elimination phase (falling): log-linear preferred
## ------------------------------------------------------------------
cat("=== 3. Two-phase profile (rising then falling) ===\n\n")

pk2phase <- data.frame(
  time = c(0, 0.5, 1, 1.5, 2, 3, 4, 6, 8, 12),
  conc = c(0, 1.8, 3.9, 4.9, 4.7, 3.6, 2.8, 1.7, 1.0, 0.37)
)

cat(sprintf("Linear trapezoid AUC(0→12):   %.4f\n",
            ks_auc(pk2phase, val = conc, time = time)))
cat(sprintf("Log-linear trapezoid AUC(0→12): %.4f\n\n",
            ks_auc(pk2phase, val = conc, time = time, type = "log-trapez")))

## ------------------------------------------------------------------
## 4. Multiple subjects — grouped by subject ID
## ------------------------------------------------------------------
cat("=== 4. Grouped: two subjects ===\n\n")

pk_grouped <- data.frame(
  usubjid = rep(c("S01", "S02"), each = 5L),
  time    = rep(c(0, 1, 2, 4, 8), times = 2L),
  conc    = c(0, 4, 2, 1, 0,       # S01
              0, 6, 3, 1.5, 0.3)    # S02
)

print(ks_auc(pk_grouped, by = "usubjid", val = conc, time = time))
cat("\n")

## ------------------------------------------------------------------
## 5. Multiple grouping variables (subject + treatment)
## ------------------------------------------------------------------
cat("=== 5. Two grouping variables (usubjid + trt) ===\n\n")

pk_multi <- data.frame(
  usubjid = rep(c("S01", "S02"), each = 4L),
  trt     = rep(c("Drug A", "Placebo"), each = 4L),
  time    = rep(c(0, 1, 2, 4), times = 2L),
  conc    = c(0, 5, 3, 1,
              0, 3, 2, 0.5)
)

print(ks_auc(pk_multi, by = c("usubjid", "trt"), val = conc, time = time))
cat("\n")

## ------------------------------------------------------------------
## 6. Log-linear with equal consecutive values
##    (0/0 → NaN in naive implementation; falls back to linear here)
## ------------------------------------------------------------------
cat("=== 6. Log-linear: equal consecutive values ===\n\n")

pk_flat <- data.frame(
  time = 0:3,
  conc = c(2, 2, 4, 4)
)
# Interval 0→1: c=2→2 (equal) → linear: (2+2)*1/2 = 2.0
# Interval 1→2: c=2→4        → log:     (4-2)*1/log(4/2) = 2.885
# Interval 2→3: c=4→4 (equal) → linear: (4+4)*1/2 = 4.0
# Total ≈ 8.885

cat(sprintf("AUC (expect ~8.885): %.3f\n\n",
            ks_auc(pk_flat, val = conc, time = time, type = "log-trapez")))

## ------------------------------------------------------------------
## 7. Log-linear with a zero concentration
##    (log(0) = -Inf → falls back to linear for that interval)
## ------------------------------------------------------------------
cat("=== 7. Log-linear: zero concentration at baseline ===\n\n")

pk_zero <- data.frame(
  time = 0:3,
  conc = c(0, 2, 4, 2)
)
# Interval 0→1: c=0→2 (zero) → linear: (0+2)*1/2 = 1.0
# Interval 1→2: c=2→4        → log:     2*1/log(2) = 2.885
# Interval 2→3: c=4→2        → log:     (2-4)*1/(log(2)-log(4)) = 2.885
# Total ≈ 6.770

cat(sprintf("AUC (expect ~6.770): %.3f\n\n",
            suppressWarnings(
              ks_auc(pk_zero, val = conc, time = time, type = "log-trapez"))))

## ------------------------------------------------------------------
## 8. Unsorted input — ks_auc sorts by (by, time) automatically
## ------------------------------------------------------------------
cat("=== 8. Unsorted input (auto-sort) ===\n\n")

pk_unsorted <- data.frame(
  id   = c("B", "A", "B", "A", "A", "B"),
  time = c(1,   2,   0,   1,   0,   2),
  conc = c(3,   2,   6,   4,   0,   1)
)

cat("Input rows in arbitrary order:\n")
print(pk_unsorted)

cat("\nAUC per subject (A: 0+4+2=6/2*1=... B: (6+3)*1/2+(3+1)*1/2 = 4.5+2=6.5):\n")
print(ks_auc(pk_unsorted, by = "id", val = conc, time = time))

## ------------------------------------------------------------------
## 9. AUC summary table across treatment arms
## ------------------------------------------------------------------
cat("\n=== 9. Summary table: AUC by treatment arm ===\n\n")

library(dplyr)

set.seed(42)

# Simulate 20 subjects, 2 arms, PK profile at 6 time points
sim_pk <- expand.grid(
  usubjid = sprintf("S%02d", 1:20),
  time    = c(0, 0.5, 1, 2, 4, 8)
) |>
  mutate(
    trt  = ifelse(as.integer(sub("S", "", usubjid)) <= 10, "Drug A", "Placebo"),
    cmax = ifelse(trt == "Drug A", 10, 6),
    tmax = 1,
    kel  = ifelse(trt == "Drug A", 0.35, 0.45),
    conc = pmax(0, cmax * exp(-kel * abs(time - tmax)) +
                  rnorm(n(), 0, 0.3))
  ) |>
  select(usubjid, trt, time, conc)

auc_by_subj <- ks_auc(sim_pk, by = c("usubjid", "trt"), val = conc, time = time)

auc_summary <- auc_by_subj |>
  group_by(trt) |>
  summarise(
    n      = n(),
    mean   = round(mean(AUC), 2),
    sd     = round(sd(AUC),   2),
    median = round(median(AUC), 2),
    min    = round(min(AUC),  2),
    max    = round(max(AUC),  2),
    .groups = "drop"
  )

cat("AUC summary by treatment arm:\n")
print(as.data.frame(auc_summary))
