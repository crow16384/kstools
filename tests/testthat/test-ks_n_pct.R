## Tests for ks_n_pct()

# ─── numeric method ──────────────────────────────────────────────────────────

test_that("numeric method: returns character vector same length as n", {
  out <- ks_n_pct(c(10L, 20L, 30L), 100L)
  expect_type(out, "character")
  expect_length(out, 3L)
})

test_that("numeric method: basic integer formatting", {
  out <- ks_n_pct(10L, 100L)
  expect_equal(out, "10 ( 10.0%)")
})

test_that("numeric method: single total recycled over vector", {
  out <- ks_n_pct(c(10L, 20L, 50L), 100L)
  expect_equal(out, c("10 ( 10.0%)", "20 ( 20.0%)", "50 ( 50.0%)"))
})

test_that("numeric method: element-wise totals", {
  out <- ks_n_pct(c(10L, 20L), c(50L, 80L))
  expect_equal(out, c("10 ( 20.0%)", "20 ( 25.0%)"))
})

test_that("numeric method: zero count gives 0 (  0.0%)", {
  out <- ks_n_pct(0L, 100L)
  expect_equal(out, "0 (  0.0%)")
})

test_that("numeric method: 100% count", {
  out <- ks_n_pct(100L, 100L)
  expect_equal(out, "100 (100.0%)")
})

test_that("numeric method: accepts whole-number double input", {
  out <- ks_n_pct(c(10.0, 20.0), 100.0)
  expect_equal(out, c("10 ( 10.0%)", "20 ( 20.0%)"))
})

test_that("numeric method: NA propagated by default", {
  out <- ks_n_pct(c(10L, NA_integer_, 30L), 100L)
  expect_equal(out, c("10 ( 10.0%)", NA_character_, "30 ( 30.0%)"))
})

test_that("numeric method: na.rep replaces NA elements", {
  out <- ks_n_pct(c(10L, NA_integer_, 30L), 100L, na.rep = "0 (  0.0%)")
  expect_equal(out, c("10 ( 10.0%)", "0 (  0.0%)", "30 ( 30.0%)"))
})

test_that("numeric method: na.rep = '' gives empty string for NA", {
  out <- ks_n_pct(c(10L, NA_integer_), 100L, na.rep = "")
  expect_equal(out, c("10 ( 10.0%)", ""))
})

test_that("numeric method: non-NA elements unaffected by na.rep", {
  out <- ks_n_pct(c(5L, NA_integer_, 15L), 50L, na.rep = "X")
  expect_equal(out[c(1L, 3L)], c("5 ( 10.0%)", "15 ( 30.0%)"))
  expect_equal(out[2L], "X")
})

test_that("numeric method: warns when totals contains zero", {
  expect_warning(
    ks_n_pct(c(5L, 10L), c(50L, 0L)),
    regexp = "zero"
  )
})

test_that("numeric method: zero total produces Inf in output", {
  out <- suppressWarnings(ks_n_pct(5L, 0L))
  expect_true(grepl("Inf", out))
})

test_that("numeric method: errors when totals is not numeric", {
  expect_error(ks_n_pct(10L, "100"), regexp = "'totals' must be numeric")
})

# ─── data.frame method ───────────────────────────────────────────────────────

test_that("data.frame method: returns a data.frame", {
  df  <- data.frame(a = c(10L, 20L), b = c(5L, 15L))
  res <- ks_n_pct(df, c(a = 100L, b = 50L))
  expect_s3_class(res, "data.frame")
})

test_that("data.frame method: formats named columns correctly", {
  df  <- data.frame(a = c(10L, 50L))
  res <- ks_n_pct(df, c(a = 100L))
  expect_equal(res$a, c("10 ( 10.0%)", "50 ( 50.0%)"))
})

test_that("data.frame method: formats multiple columns independently", {
  df  <- data.frame(a = c(10L, 20L), b = c(5L, 25L))
  res <- ks_n_pct(df, c(a = 100L, b = 50L))
  expect_equal(res$a, c("10 ( 10.0%)", "20 ( 20.0%)"))
  expect_equal(res$b, c("5 ( 10.0%)", "25 ( 50.0%)"))
})

test_that("data.frame method: non-count columns are unchanged", {
  df  <- data.frame(
    label = c("A", "B"),
    n_col = c(10L, 20L),
    stringsAsFactors = FALSE
  )
  res <- ks_n_pct(df, c(n_col = 100L))
  expect_equal(res$label, c("A", "B"))
})

test_that("data.frame method: NA replaced with default na.rep (propagate NA)", {
  df  <- data.frame(a = c(10L, NA_integer_, 30L))
  res <- ks_n_pct(df, c(a = 100L))
  expect_equal(res$a, c("10 ( 10.0%)", NA_character_, "30 ( 30.0%)"))
})

test_that("data.frame method: NA replaced with custom na.rep string", {
  df  <- data.frame(a = c(10L, NA_integer_, 30L))
  res <- ks_n_pct(df, c(a = 100L), na.rep = "0 (  0.0%)")
  expect_equal(res$a, c("10 ( 10.0%)", "0 (  0.0%)", "30 ( 30.0%)"))
})

test_that("data.frame method: all-NA column with na.rep", {
  df  <- data.frame(a = c(NA_integer_, NA_integer_))
  res <- ks_n_pct(df, c(a = 100L), na.rep = "")
  expect_equal(res$a, c("", ""))
})

test_that("data.frame method: only specified columns are formatted", {
  df  <- data.frame(a = c(10L, 20L), b = c(5L, 15L), c = c(1L, 2L))
  res <- ks_n_pct(df, c(a = 100L))
  expect_type(res$a, "character")
  expect_type(res$b, "integer")
  expect_type(res$c, "integer")
})

test_that("data.frame method: errors when totals is unnamed", {
  df <- data.frame(a = 10L)
  expect_error(ks_n_pct(df, 100L), regexp = "named")
})

test_that("data.frame method: errors when totals is not numeric", {
  df <- data.frame(a = 10L)
  expect_error(ks_n_pct(df, c(a = "100")), regexp = "'totals' must be numeric")
})

test_that("data.frame method: errors when column is missing from data", {
  df <- data.frame(a = 10L)
  expect_error(ks_n_pct(df, c(no_col = 100L)), regexp = "not found")
})

test_that("data.frame method: error message includes missing column name", {
  df  <- data.frame(a = 10L)
  err <- tryCatch(ks_n_pct(df, c(missing_col = 100L)), error = conditionMessage)
  expect_true(grepl("missing_col", err, fixed = TRUE))
})

test_that("data.frame method: warns when totals contains zero", {
  df <- data.frame(a = 10L)
  expect_warning(ks_n_pct(df, c(a = 0L)), regexp = "zero")
})

test_that("data.frame method: accepts tibble input", {
  skip_if_not_installed("tibble")
  tbl <- tibble::tibble(a = c(10L, 20L), b = c("X", "Y"))
  res <- ks_n_pct(tbl, c(a = 100L))
  expect_equal(res$a, c("10 ( 10.0%)", "20 ( 20.0%)"))
  expect_equal(res$b, c("X", "Y"))
})

# ─── default method ──────────────────────────────────────────────────────────

test_that("default method: errors for character n", {
  expect_error(ks_n_pct("10", 100L), regexp = "numeric vector or data.frame")
})

test_that("default method: errors for list n", {
  expect_error(ks_n_pct(list(10L), 100L), regexp = "numeric vector or data.frame")
})

# ─── format alignment ────────────────────────────────────────────────────────

test_that("percentage field is right-aligned to 5 characters", {
  out <- ks_n_pct(c(1L, 10L, 100L), 100L)
  # extract the percentage substring
  pct <- regmatches(out, regexpr("[0-9. ]+(?=%)", out, perl = TRUE))
  expect_true(all(nchar(pct) == 5L))
})
