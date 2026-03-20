## Tests for ks_desc_coded()
##
## Dataset (5 events, 3 subjects, 2 SOCs, 4 PTs):
##
##  usubjid  soc      pt
##  "01"     Cardiac  Palp
##  "01"     Cardiac  Tachy
##  "02"     Nervous  Head
##  "02"     Nervous  Dizzy
##  "03"     Cardiac  Palp
##
## Expected 7 output rows (ordered: total, Cardiac SOC, Cardiac PTs,
##                                  Nervous SOC, Nervous PTs):
##
##  ord0 ord  soc       pt     n  e
##   1    1   "Total…"  NA     3  5   overall total
##   2    2   "Cardiac" NA     2  3   Cardiac SOC total
##   2    3   "Cardiac" "Palp" 2  2   Cardiac / Palpitation
##   2    3   "Cardiac" "Tachy"1  1   Cardiac / Tachycardia
##   2    2   "Nervous" NA     1  2   Nervous SOC total
##   2    3   "Nervous" "Dizzy"1  1   Nervous / Dizziness
##   2    3   "Nervous" "Head" 1  1   Nervous / Headache

make_ae <- function() {
  data.frame(
    usubjid = c("01","01","02","02","03"),
    soc     = c("Cardiac","Cardiac","Nervous","Nervous","Cardiac"),
    pt      = c("Palp","Tachy","Head","Dizzy","Palp"),
    stringsAsFactors = FALSE
  )
}

run <- function(...) ks_desc_coded(make_ae(), id = usubjid, l1 = soc, l2 = pt, ...)

## ── input validation ─────────────────────────────────────────────────────────

test_that("stops when data is not a data.frame or tibble", {
  expect_error(
    ks_desc_coded(list(), id = usubjid, l1 = soc, l2 = pt),
    "'data' must be a data.frame or tibble"
  )
})

## ── output type and columns ───────────────────────────────────────────────────

test_that("returns a data.frame", {
  expect_s3_class(run(), "data.frame")
})

test_that("output columns are ord0, soc, ord, pt, n, e — in that order", {
  expect_equal(names(run()), c("ord0","soc","ord","pt","n","e"))
})

test_that("column names follow the bare names passed as l1 / l2", {
  ae <- make_ae()
  names(ae)[names(ae) == "soc"] <- "meddra_soc"
  names(ae)[names(ae) == "pt"]  <- "meddra_pt"
  res <- ks_desc_coded(ae, id = usubjid, l1 = meddra_soc, l2 = meddra_pt)
  expect_equal(names(res), c("ord0","meddra_soc","ord","meddra_pt","n","e"))
})

test_that("no value or bold_row columns in output", {
  res <- run()
  expect_false("value"    %in% names(res))
  expect_false("bold_row" %in% names(res))
})

## ── row count and ordering ────────────────────────────────────────────────────

test_that("returns exactly 7 rows", {
  expect_equal(nrow(run()), 7L)
})

test_that("sort key sequence is correct", {
  res <- run()
  expect_equal(res$ord0, c(1L, 2L, 2L, 2L, 2L, 2L, 2L))
  expect_equal(res$ord,  c(1L, 2L, 3L, 3L, 2L, 3L, 3L))
})

test_that("l1 (soc) column values follow tot_label → Cardiac → Nervous order", {
  res <- run()
  expect_equal(res$soc,
               c("Total subjects",
                 "Cardiac","Cardiac","Cardiac",
                 "Nervous","Nervous","Nervous"))
})

test_that("PTs within each SOC are sorted alphabetically", {
  res <- run()
  expect_equal(res$pt[res$soc == "Cardiac" & !is.na(res$pt)],
               c("Palp","Tachy"))
  expect_equal(res$pt[res$soc == "Nervous" & !is.na(res$pt)],
               c("Dizzy","Head"))
})

## ── NA in l2 signals header / bold rows ──────────────────────────────────────

test_that("l2 (pt) is NA for overall-total and SOC-total rows", {
  res <- run()
  header_rows <- res$ord <= 2L
  expect_true(all(is.na(res$pt[header_rows])))
})

test_that("l2 (pt) is non-NA for all PT detail rows", {
  res <- run()
  pt_rows <- res$ord == 3L
  expect_true(all(!is.na(res$pt[pt_rows])))
})

## ── overall total row ─────────────────────────────────────────────────────────

test_that("overall-total row: n = 3 distinct subjects, e = 5 events", {
  res <- run()
  tot <- res[res$ord0 == 1L, ]
  expect_equal(tot$n, 3L)
  expect_equal(tot$e, 5L)
})

test_that("overall-total row: soc contains tot_label", {
  res <- run()
  expect_equal(res$soc[res$ord0 == 1L], "Total subjects")
})

## ── SOC-total rows ────────────────────────────────────────────────────────────

test_that("Cardiac SOC total: n = 2 subjects (01 + 03), e = 3 events", {
  res <- run()
  row <- res[res$soc == "Cardiac" & res$ord == 2L, ]
  expect_equal(row$n, 2L)
  expect_equal(row$e, 3L)
})

test_that("Nervous SOC total: n = 1 subject (02), e = 2 events", {
  res <- run()
  row <- res[res$soc == "Nervous" & res$ord == 2L, ]
  expect_equal(row$n, 1L)
  expect_equal(row$e, 2L)
})

## ── PT-level rows ─────────────────────────────────────────────────────────────

test_that("Cardiac/Palp: n = 2 subjects (01 + 03), e = 2 events", {
  res <- run()
  row <- res[!is.na(res$pt) & res$pt == "Palp", ]
  expect_equal(row$n, 2L)
  expect_equal(row$e, 2L)
})

test_that("Cardiac/Tachy: n = 1 subject (01), e = 1 event", {
  res <- run()
  row <- res[!is.na(res$pt) & res$pt == "Tachy", ]
  expect_equal(row$n, 1L)
  expect_equal(row$e, 1L)
})

test_that("Nervous/Head: n = 1 subject (02), e = 1 event", {
  res <- run()
  row <- res[!is.na(res$pt) & res$pt == "Head", ]
  expect_equal(row$n, 1L)
  expect_equal(row$e, 1L)
})

## ── n counts repeated events per subject once ─────────────────────────────────

test_that("subject with 2 Cardiac events counts as n=1 in Cardiac SOC total", {
  res <- run()
  ## "01" has Palp + Tachy under Cardiac → 2 events but 1 subject
  cardiac_soc <- res[res$soc == "Cardiac" & res$ord == 2L, ]
  expect_equal(cardiac_soc$n, 2L)   ## subjects 01 + 03
  expect_equal(cardiac_soc$e, 3L)   ## events: 01/Palp, 01/Tachy, 03/Palp
})

## ── n and e column types ──────────────────────────────────────────────────────

test_that("n and e are integer-like numerics with no NA", {
  res <- run()
  expect_true(is.numeric(res$n))
  expect_true(is.numeric(res$e))
  expect_false(anyNA(res$n))
  expect_false(anyNA(res$e))
})

## ── custom tot_label ─────────────────────────────────────────────────────────

test_that("custom tot_label appears in the overall-total soc cell", {
  res <- run(tot_label = "Subjects with AE")
  expect_equal(res$soc[res$ord0 == 1L], "Subjects with AE")
})

test_that("custom tot_label does not leak into l2 (pt) column", {
  res <- run(tot_label = "Subjects with AE")
  expect_true(all(is.na(res$pt[res$ord <= 2L])))
})

## ── n + ks_n_pct integration ──────────────────────────────────────────────────

test_that("ks_n_pct applied to n column produces formatted strings", {
  res <- run()
  formatted <- dplyr::mutate(res, value = ks_n_pct(n, totals = 10))
  expect_true(all(grepl("%", formatted$value)))
  ## overall total: 3 out of 10 → 30.0%
  expect_match(formatted$value[formatted$ord0 == 1L], "^3 ")
  expect_match(formatted$value[formatted$ord0 == 1L], "30\\.0")
})

## ── tibble input ──────────────────────────────────────────────────────────────

test_that("tibble input produces the same result as data.frame input", {
  tbl <- tibble::tibble(
    usubjid = c("01","01","02","02","03"),
    soc     = c("Cardiac","Cardiac","Nervous","Nervous","Cardiac"),
    pt      = c("Palp","Tachy","Head","Dizzy","Palp")
  )
  res_tbl <- ks_desc_coded(tbl, id = usubjid, l1 = soc, l2 = pt)
  res_df  <- ks_desc_coded(as.data.frame(tbl), id = usubjid, l1 = soc, l2 = pt)
  expect_equal(as.data.frame(res_tbl), res_df)
})

## ── different column name conventions ────────────────────────────────────────

test_that("works with medical-history style column names", {
  mh <- data.frame(
    usubjid   = c("01","01","02","03"),
    atc_grp   = c("Cardio","Cardio","CNS","CNS"),
    drug_name = c("DrugA","DrugB","DrugC","DrugC"),
    stringsAsFactors = FALSE
  )
  res <- ks_desc_coded(mh, id = usubjid, l1 = atc_grp, l2 = drug_name)
  expect_true(all(c("atc_grp","drug_name") %in% names(res)))
  ## 1 total + 2 SOC totals + 3 PTs = 6 rows (DrugC appears in both SOCs)
  expect_equal(nrow(res), 6L)
})
