## ============================================================
## ks_check_rules() — row-level rule engine
## ============================================================

library(kstools)

adsl <- data.frame(
  USUBJID = sprintf("01-%03d", 1:6),
  AGE = c(34, 52, -1, 40, 29, 70),
  SEX = c("M", "F", "M", NA, "F", "X"),
  WEIGHT = c(70, 80, 75, 65, 500, 68),
  stringsAsFactors = FALSE
)

rules <- list(
  list(expr = ~ AGE < 0, msg = "AGE must be non-negative"),
  list(expr = ~ is.na(SEX), msg = "SEX is missing"),
  list(expr = ~ !(SEX %in% c("M", "F")) & !is.na(SEX), msg = "SEX must be M/F"),
  list(expr = ~ WEIGHT > 300, msg = "WEIGHT out of range")
)

## first failing rule per row
res_first <- ks_check_rules(adsl, rules, mode = "first")
res_first[, c("USUBJID", "check_msgs")]

## all failing rules per row
res_all <- ks_check_rules(adsl, rules, mode = "all")
res_all[, c("USUBJID", "check_msgs")]
