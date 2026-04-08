## ============================================================
## ks_compare_check_state() — compare check snapshots
## ============================================================

library(kstools)

old <- data.frame(
  USUBJID = c("01-001", "01-002", "01-003"),
  PARAMCD = c("ALT", "ALT", "ALT"),
  AVAL = c(30, 45, 70),
  check_msgs = c("OK", "High ALT", "High ALT"),
  stringsAsFactors = FALSE
)

new <- data.frame(
  USUBJID = c("01-001", "01-002", "01-003", "01-004"),
  PARAMCD = c("ALT", "ALT", "ALT", "ALT"),
  AVAL = c(30, 40, 72, 80),
  check_msgs = c("OK", "OK", "High ALT", "High ALT"),
  stringsAsFactors = FALSE
)

cmp <- ks_compare_check_state(
  current = new,
  previous = old,
  key_cols = c("USUBJID", "PARAMCD"),
  compare_cols = c("AVAL", "check_msgs")
)

cmp[, c("USUBJID", "PARAMCD", "status")]
