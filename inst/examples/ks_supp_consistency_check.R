## ============================================================
## ks_supp_consistency_check() — validate SUPP domain structure
## ============================================================

library(kstools)

## Valid subject-level SUPP domain
supp_ok <- data.frame(
  STUDYID = "S1",
  USUBJID = c("01", "02"),
  IDVAR = "",
  IDVARVAL = "",
  QNAM = c("RACE2", "RACE2"),
  QLABEL = c("Race (detail)", "Race (detail)"),
  QVAL = c("Asian", "White"),
  stringsAsFactors = FALSE
)

ks_supp_consistency_check(supp_ok)

## Invalid: missing required column
supp_bad <- supp_ok[, setdiff(names(supp_ok), "QLABEL")]
ks_supp_consistency_check(supp_bad)

## Invalid: mixed blank/non-blank IDVAR
supp_mixed <- supp_ok
supp_mixed$IDVAR[1] <- "EXSEQ"
supp_mixed$IDVARVAL[1] <- "1"
ks_supp_consistency_check(supp_mixed)
