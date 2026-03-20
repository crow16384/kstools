## ks_n_pct — format count / percentage pairs
## ------------------------------------------

library(kstools)


## 1. Numeric method — single denominator (recycled) --------------------------
ks_n_pct(c(10L, 20L, 30L), 56L)
# [1] "10 ( 17.9%)" "20 ( 35.7%)" "30 ( 53.6%)"


## 2. Numeric method — element-wise denominators -------------------------------
ks_n_pct(c(10L, 20L, 30L), c(34L, 42L, 56L))
# [1] "10 ( 29.4%)" "20 ( 47.6%)" "30 ( 53.6%)"


## 3. NA handling — propagate (default) ----------------------------------------
ks_n_pct(c(10L, NA_integer_, 30L), 100L)
# [1] "10 ( 10.0%)"  NA             "30 ( 30.0%)"


## 4. NA handling — replace with zero-row string -------------------------------
ks_n_pct(c(10L, NA_integer_, 30L), 100L, na.rep = "0 (  0.0%)")
# [1] "10 ( 10.0%)" "0 (  0.0%)"  "30 ( 30.0%)"


## 5. NA handling — replace with empty string ----------------------------------
ks_n_pct(c(10L, NA_integer_, 30L), 100L, na.rep = "")
# [1] "10 ( 10.0%)" ""            "30 ( 30.0%)"


## 6. data.frame method — two arms, summary parameter -------------------------
safety <- data.frame(
  PARAM     = c("Any AE", "Headache", "Nausea", "Fatigue"),
  Arm_A     = c(42L, 18L,  9L, 21L),
  Arm_B     = c(38L, 14L, 11L, 17L)
)
N <- c(Arm_A = 60L, Arm_B = 55L)

ks_n_pct(safety, N)
#   PARAM    Arm_A        Arm_B
# 1 Any AE   42 ( 70.0%)  38 ( 69.1%)
# 2 Headache 18 ( 30.0%)  14 ( 25.5%)
# 3 Nausea    9 ( 15.0%)  11 ( 20.0%)
# 4 Fatigue  21 ( 35.0%)  17 ( 30.9%)


## 7. data.frame method — format only selected columns -------------------------
labs <- data.frame(
  LBTEST = c("ALT", "AST", "Bilirubin"),
  n_high  = c(5L, 3L, NA_integer_),
  n_low   = c(2L, 0L, 1L),
  n_total = c(60L, 60L, 60L)        # numeric, NOT formatted
)
ks_n_pct(labs, c(n_high = 60L, n_low = 60L), na.rep = "0 (  0.0%)")


## 8. data.frame method — NA propagated for one column, replaced in another ---
mixed <- data.frame(
  grp = c("X", "Y", "Z"),
  a   = c(10L, NA_integer_, 5L),
  b   = c(20L, 15L, NA_integer_)
)
ks_n_pct(mixed, c(a = 50L, b = 50L))           # both propagate NA
ks_n_pct(mixed, c(a = 50L, b = 50L), na.rep = "—")  # both replaced


## 9. Use inside dplyr::mutate() for derived formatted columns -----------------
if (requireNamespace("dplyr", quietly = TRUE)) {
  library(dplyr)

  results <- data.frame(
    TRT   = c("Placebo", "Low Dose", "High Dose"),
    RESP  = c(12L, 28L, 35L),
    N_TRT = c(50L, 50L, 50L)
  )

  results |>
    mutate(Responders = ks_n_pct(RESP, N_TRT))
}


## 10. Warning on zero denominator ---------------------------------------------
tryCatch(
  ks_n_pct(c(5L, 10L), c(100L, 0L)),
  warning = function(w) message("Caught warning: ", conditionMessage(w))
)


## 11. Error — column not found in data.frame -----------------------------------
tryCatch(
  ks_n_pct(safety, c(Missing_Arm = 60L)),
  error = function(e) message("Error: ", conditionMessage(e))
)
# Error: Column(s) not found in 'n': Missing_Arm


## 12. Full two-arm AE table with ks_aligndec alignment ------------------------
if (requireNamespace("dplyr", quietly = TRUE)) {
  ae_summary <- data.frame(
    Term    = c("Any AE", "Headache", "Nausea", "Dizziness"),
    Arm_A   = c(45L, 18L, 9L, 6L),
    Arm_B   = c(38L, 12L, 14L, 4L)
  )
  N_arms <- c(Arm_A = 60L, Arm_B = 55L)

  ae_formatted <- ks_n_pct(ae_summary, N_arms, na.rep = "0 (  0.0%)")
  ae_formatted
}
