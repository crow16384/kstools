## ============================================================
## ks_supp_consistency_check() / ks_supp_merge()
## SDTM supplemental domain merge
## ============================================================
## SDTM SUPP-- datasets store additional subject- or record-level
## variables in a long EAV ("name-value") format:
##
##   STUDYID  USUBJID  IDVAR  IDVARVAL  QNAM    QLABEL   QVAL
##   -------  -------  -----  --------  ------  -------  -----
##   S1       01                         RACE2   Race     Asian
##
## ks_supp_merge() transposes the SUPP, resolves the correct join
## key, and left-joins the result onto the primary domain.
## ============================================================

library(kstools)

## ══════════════════════════════════════════════════════════════════
## Part 1: Consistency check
## ══════════════════════════════════════════════════════════════════

cat("=== 1. Valid SUPP (subject-level, noid) ===\n\n")

suppdm_valid <- data.frame(
  STUDYID  = "S1",
  USUBJID  = c("01", "02", "03"),
  IDVAR    = "",
  IDVARVAL = "",
  QNAM     = "RACE2",
  QLABEL   = "Race (detail)",
  QVAL     = c("Asian", "White", "Asian"),
  stringsAsFactors = FALSE
)
print(ks_supp_consistency_check(suppdm_valid))

cat("\n=== 2. Valid SUPP with IDVAR (record-level) ===\n\n")

suppex_valid <- data.frame(
  STUDYID  = "S1",
  USUBJID  = c("01", "01", "02"),
  IDVAR    = "EXSEQ",
  IDVARVAL = c("1", "2", "1"),
  QNAM     = "EXROUTE",
  QLABEL   = "Route of Administration",
  QVAL     = c("Oral", "IV", "Oral"),
  stringsAsFactors = FALSE
)
print(ks_supp_consistency_check(suppex_valid))

cat("\n=== 3. Invalid: missing required column ===\n\n")

suppdm_bad_cols <- suppdm_valid[, setdiff(names(suppdm_valid), "QLABEL")]
print(ks_supp_consistency_check(suppdm_bad_cols))

cat("\n=== 4. Invalid: non-character column ===\n\n")

suppdm_bad_type <- suppdm_valid
suppdm_bad_type$QVAL <- c(1, 2, 1)   # numeric instead of character
print(ks_supp_consistency_check(suppdm_bad_type))

cat("\n=== 5. Invalid: mixed blank/non-blank IDVAR ===\n\n")

suppdm_mixed <- suppdm_valid
suppdm_mixed$IDVAR[1] <- "DMSEQ"   # first row has IDVAR, others do not
print(ks_supp_consistency_check(suppdm_mixed))

## ══════════════════════════════════════════════════════════════════
## Part 2: Subject-level merge (IDVAR / IDVARVAL all blank)
## ══════════════════════════════════════════════════════════════════

cat("\n\n=== 6. Subject-level merge — SUPPDM → DM ===\n\n")

dm <- data.frame(
  STUDYID = "S1",
  USUBJID = c("01", "02", "03"),
  AGE     = c(34L, 52L, 47L),
  SEX     = c("M", "F", "M"),
  stringsAsFactors = FALSE
)

## SUPPDM has two supplemental variables: RACE2 and ETHNIC
suppdm <- data.frame(
  STUDYID  = "S1",
  USUBJID  = rep(c("01", "02", "03"), times = 2L),
  IDVAR    = "",
  IDVARVAL = "",
  QNAM     = rep(c("RACE2", "ETHNIC"), each = 3L),
  QLABEL   = rep(c("Race (detail)", "Ethnicity"), each = 3L),
  QVAL     = c("Asian", "White", "Asian",
               "Not Hispanic", "Hispanic", "Not Hispanic"),
  stringsAsFactors = FALSE
)

merged_dm <- ks_supp_merge(dm, suppdm)
print(merged_dm)

cat("\nColumn label on RACE2:", attr(merged_dm$RACE2, "label"), "\n")

## ------------------------------------------------------------------
## 7. Merge only a subset of QNAMs
## ------------------------------------------------------------------
cat("\n=== 7. Selective merge (mvars) ===\n\n")

print(ks_supp_merge(dm, suppdm, mvars = "ETHNIC"))

## ------------------------------------------------------------------
## 8. Subject missing from SUPP — rep_na replaces NA with ""
## ------------------------------------------------------------------
cat("\n=== 8. Missing subject in SUPP — rep_na = TRUE ===\n\n")

dm_extra <- rbind(dm,
  data.frame(STUDYID = "S1", USUBJID = "04",
             AGE = 60L, SEX = "F", stringsAsFactors = FALSE))

cat("rep_na = FALSE (default) — NA kept:\n")
print(ks_supp_merge(dm_extra, suppdm, rep_na = FALSE))

cat("\nrep_na = TRUE — NA replaced with empty string:\n")
print(ks_supp_merge(dm_extra, suppdm, rep_na = TRUE))

## ══════════════════════════════════════════════════════════════════
## Part 3: Record-level merge (IDVAR / IDVARVAL non-blank)
## ══════════════════════════════════════════════════════════════════

cat("\n\n=== 9. Record-level merge — SUPPEX → EX ===\n\n")

## EX domain: two exposures for subject 01, one for subject 02
ex <- data.frame(
  STUDYID = "S1",
  USUBJID = c("01", "01", "02"),
  EXSEQ   = c(1L,   2L,   1L),
  EXTRT   = "DRUG A",
  EXDOSE  = c(100L, 200L, 100L),
  stringsAsFactors = FALSE
)

## SUPPEX: route of administration per EX record
suppex <- data.frame(
  STUDYID  = "S1",
  USUBJID  = c("01", "01", "02"),
  IDVAR    = "EXSEQ",
  IDVARVAL = c("1", "2", "1"),     # character in SUPP; coerced to integer
  QNAM     = "EXROUTE",
  QLABEL   = "Route of Administration",
  QVAL     = c("Oral", "IV", "Oral"),
  stringsAsFactors = FALSE
)

print(ks_supp_merge(ex, suppex))

## ------------------------------------------------------------------
## 10. Record-level merge with two supplemental variables
## ------------------------------------------------------------------
cat("\n=== 10. Two QNAMs in SUPPEX ===\n\n")

suppex2 <- rbind(
  suppex,
  data.frame(
    STUDYID  = "S1",
    USUBJID  = c("01", "02"),
    IDVAR    = "EXSEQ",
    IDVARVAL = c("1", "1"),
    QNAM     = "EXDOSFRQ",
    QLABEL   = "Dose Frequency",
    QVAL     = c("QD", "BID"),
    stringsAsFactors = FALSE
  )
)

print(ks_supp_merge(ex, suppex2))

## ------------------------------------------------------------------
## 11. Record-level merge — select only one QNAM via mvars
## ------------------------------------------------------------------
cat("\n=== 11. Record-level with mvars = 'EXDOSFRQ' ===\n\n")

print(ks_supp_merge(ex, suppex2, mvars = "EXDOSFRQ"))

## ══════════════════════════════════════════════════════════════════
## Part 4: get_labels = FALSE (skip attribute assignment)
## ══════════════════════════════════════════════════════════════════

cat("\n\n=== 12. get_labels = FALSE ===\n\n")

merged_no_lbl <- ks_supp_merge(dm, suppdm, get_labels = FALSE)

cat("Column label on RACE2 (should be NULL):",
    deparse(attr(merged_no_lbl$RACE2, "label")), "\n")
