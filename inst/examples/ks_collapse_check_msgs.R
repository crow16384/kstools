## ============================================================
## ks_collapse_check_msgs() — list-column to text column
## ============================================================

library(kstools)

df <- data.frame(
  USUBJID = sprintf("01-%03d", 1:4),
  AGE = c(20, -1, 30, 50),
  SEX = c("M", "F", NA, "X"),
  stringsAsFactors = FALSE
)

rules <- list(
  list(expr = ~ AGE < 0, msg = "Negative AGE"),
  list(expr = ~ is.na(SEX), msg = "Missing SEX"),
  list(expr = ~ !(SEX %in% c("M", "F")) & !is.na(SEX), msg = "Invalid SEX")
)

checked <- ks_check_rules(df, rules, mode = "all")
checked_collapsed <- ks_collapse_check_msgs(checked, col = check_msgs)

checked_collapsed[, c("USUBJID", "check_msgs")]
