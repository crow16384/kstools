## ks_newcombe_hs / ks_newcombe_hs_strata
## Newcombe Hybrid Score CI for difference of two proportions
## ----------------------------------------------------------

library(kstools)


## 1. Single comparison (95% CI, default) -------------------------------------
##    x1 = 36 events in n1 = 54;  x2 = 41 events in n2 = 56
ks_newcombe_hs(36L, 54L, 41L, 56L)
#      delta        lcl        ucl
# -0.0654762 -0.2308971  0.1039630


## 2. 90% CI (alpha = 0.10) ----------------------------------------------------
ks_newcombe_hs(36L, 54L, 41L, 56L, alpha = 0.10)
#      delta        lcl        ucl
# -0.0654762 -0.2054459  0.0773553


## 3. Rare events: small counts ------------------------------------------------
ks_newcombe_hs(3L, 86L, 3L, 93L, alpha = 0.10)
#       delta        lcl        ucl
# 0.002626 -0.047645  0.055502


## 4. Zero events in group 1 ---------------------------------------------------
##    Wilson score CI handles x = 0 correctly (no continuity correction needed)
ks_newcombe_hs(0L, 50L, 10L, 50L)
#    delta        lcl        ucl
# -0.2 -0.330371 -0.087050


## 5. Vectorised: three comparisons in one call --------------------------------
ks_newcombe_hs(
  x1 = c(36L, 38L, 3L),
  n1 = c(54L, 57L, 86L),
  x2 = c(41L, 42L, 3L),
  n2 = c(56L, 57L, 93L),
  alpha = 0.10
)
#          delta        lcl        ucl
# [1,] -0.065476 -0.205446  0.077355
# [2,] -0.070175 -0.206909  0.070204
# [3,]  0.002626 -0.047645  0.055502


## 6. CI width narrows as alpha decreases (wider for 99% than 95%) -------------
ci95 <- ks_newcombe_hs(36L, 54L, 41L, 56L, alpha = 0.05)
ci90 <- ks_newcombe_hs(36L, 54L, 41L, 56L, alpha = 0.10)
ci99 <- ks_newcombe_hs(36L, 54L, 41L, 56L, alpha = 0.01)

cat(sprintf("99%%: [%.4f, %.4f]  width = %.4f\n",
            ci99[, "lcl"], ci99[, "ucl"], ci99[, "ucl"] - ci99[, "lcl"]))
cat(sprintf("95%%: [%.4f, %.4f]  width = %.4f\n",
            ci95[, "lcl"], ci95[, "ucl"], ci95[, "ucl"] - ci95[, "lcl"]))
cat(sprintf("90%%: [%.4f, %.4f]  width = %.4f\n",
            ci90[, "lcl"], ci90[, "ucl"], ci90[, "ucl"] - ci90[, "lcl"]))


## 7. Stratified CI — two strata -----------------------------------------------
##    Stratum 1 (main centre): x1=36/54, x2=41/56
##    Stratum 2 (satellite centre): x1=10/30, x2=8/30
ks_newcombe_hs_strata(
  x1 = c(36L, 10L), n1 = c(54L, 30L),
  x2 = c(41L,  8L), n2 = c(56L, 30L)
)
#       delta        lcl        ucl
# -0.018828 -0.152517  0.115138


## 8. Single stratum = non-stratified ------------------------------------------
strat <- ks_newcombe_hs_strata(36L, 54L, 41L, 56L)
unstrat <- ks_newcombe_hs(36L, 54L, 41L, 56L)
all.equal(unname(strat), unname(unstrat[1L, ]))  # TRUE


## 9. Typical clinical trial workflow ------------------------------------------
##    Build a results table for multiple endpoints using dplyr

if (requireNamespace("dplyr", quietly = TRUE)) {
  library(dplyr)

  endpoints <- data.frame(
    Endpoint   = c("Responders", "AE (any)", "SAE"),
    x_Active   = c(48L, 32L, 5L),
    n_Active   = c(75L, 75L, 75L),
    x_Placebo  = c(36L, 41L, 8L),
    n_Placebo  = c(70L, 70L, 70L)
  )

  ci_mat <- do.call(rbind, Map(
    function(x1, n1, x2, n2) ks_newcombe_hs(x1, n1, x2, n2),
    endpoints$x_Active, endpoints$n_Active,
    endpoints$x_Placebo, endpoints$n_Placebo
  ))

  endpoints |>
    mutate(
      Diff = sprintf("% .1f%%", ci_mat[, "delta"] * 100),
      LCL  = sprintf("% .1f%%", ci_mat[, "lcl"]   * 100),
      UCL  = sprintf("% .1f%%", ci_mat[, "ucl"]   * 100)
    ) |>
    select(Endpoint, Diff, LCL, UCL)
}


## 10. Stratified CI across three centres (gender sub-study) -------------------
ks_newcombe_hs_strata(
  x1 = c(12L, 20L, 8L),  n1 = c(25L, 40L, 20L),
  x2 = c(10L, 14L, 9L),  n2 = c(25L, 40L, 20L),
  alpha = 0.10
)
