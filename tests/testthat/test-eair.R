## Tests for ks_eairdiff_mn() and ks_eairdiff_strata_mn()
##
## Reference values obtained from the implementation itself and verified
## against structural properties of the Miettinen-Nurminen score CI:
##   - delta = n1/T1 - n2/T2  (exact for the non-stratified version)
##   - CI is symmetric around 0 when rates are equal
##   - CI narrows with larger alpha (less stringent)
##   - lcl <= delta <= ucl

tol <- 1e-6   ## tolerance for numeric comparisons

## ─────────────────────────────────────────────────────────────────────────────
## ks_eairdiff_mn — non-stratified
## ─────────────────────────────────────────────────────────────────────────────

## -- output structure ---------------------------------------------------------

test_that("returns a matrix", {
  res <- ks_eairdiff_mn(10, 5, 100, 100)
  expect_true(is.matrix(res))
})

test_that("single pair returns 1-row matrix with columns delta/lcl/ucl", {
  res <- ks_eairdiff_mn(10, 5, 100, 100)
  expect_equal(dim(res), c(1L, 3L))
  expect_equal(colnames(res), c("delta", "lcl", "ucl"))
})

test_that("vectorised input returns one row per pair", {
  res <- ks_eairdiff_mn(c(10, 20, 8), c(5, 15, 6),
                         c(100, 150, 90), c(100, 150, 90))
  expect_equal(nrow(res), 3L)
  expect_equal(colnames(res), c("delta", "lcl", "ucl"))
})

## -- point estimate -----------------------------------------------------------

test_that("delta equals n1/T1 - n2/T2 exactly", {
  expect_equal(unname(ks_eairdiff_mn(10, 5, 100, 100)[, "delta"]),
               10/100 - 5/100)
  expect_equal(unname(ks_eairdiff_mn(0, 5, 100, 100)[, "delta"]),
               0/100 - 5/100)
})

test_that("delta is 0 when rates are equal", {
  expect_equal(unname(ks_eairdiff_mn(5, 5, 100, 100)[, "delta"]), 0)
  expect_equal(unname(ks_eairdiff_mn(10, 20, 50, 100)[, "delta"]), 0)
})

## -- CI ordering --------------------------------------------------------------

test_that("lcl <= delta <= ucl", {
  cases <- list(
    ks_eairdiff_mn(10, 5, 100, 100),
    ks_eairdiff_mn(0, 5, 100, 100),
    ks_eairdiff_mn(0, 0, 100, 100)
  )
  for (res in cases) {
    expect_true(unname(res[, "lcl"]) <= unname(res[, "delta"]))
    expect_true(unname(res[, "delta"]) <= unname(res[, "ucl"]))
  }
})

## -- CI symmetry for equal rates ----------------------------------------------

test_that("CI is symmetric around 0 when rates are equal", {
  res <- ks_eairdiff_mn(5, 5, 100, 100)
  expect_equal(unname(res[, "ucl"]), unname(-res[, "lcl"]), tolerance = tol)
})

## -- reference values (regression guard) -------------------------------------

test_that("95%% CI for n1=10,n2=5,T1=T2=100 matches reference", {
  res <- ks_eairdiff_mn(10, 5, 100, 100)
  expect_equal(unname(res[, "delta"]),  0.05,        tolerance = tol)
  expect_equal(unname(res[, "lcl"]),   -0.02953395,  tolerance = 1e-5)
  expect_equal(unname(res[, "ucl"]),    0.13963,     tolerance = 1e-4)
})

test_that("95%% CI for equal rates n1=n2=5,T1=T2=100 matches reference", {
  res <- ks_eairdiff_mn(5, 5, 100, 100)
  expect_equal(unname(res[, "lcl"]), -0.07307177, tolerance = 1e-5)
  expect_equal(unname(res[, "ucl"]),  0.07307177, tolerance = 1e-5)
})

test_that("95%% CI when Test has 0 events matches reference", {
  res <- ks_eairdiff_mn(0, 5, 100, 100)
  expect_equal(unname(res[, "delta"]), -0.05,       tolerance = tol)
  expect_equal(unname(res[, "lcl"]),  -0.1169447,   tolerance = 1e-5)
  expect_equal(unname(res[, "ucl"]),  -0.01158541,  tolerance = 1e-5)
})

## -- alpha effect -------------------------------------------------------------

test_that("90%% CI is narrower than 95%% CI", {
  r95 <- ks_eairdiff_mn(10, 5, 100, 100, alpha = 0.05)
  r90 <- ks_eairdiff_mn(10, 5, 100, 100, alpha = 0.10)
  width95 <- unname(r95[, "ucl"] - r95[, "lcl"])
  width90 <- unname(r90[, "ucl"] - r90[, "lcl"])
  expect_lt(width90, width95)
})

test_that("90%% CI reference values", {
  res <- ks_eairdiff_mn(10, 5, 100, 100, alpha = 0.10)
  expect_equal(unname(res[, "lcl"]), -0.01501574, tolerance = 1e-5)
  expect_equal(unname(res[, "ucl"]),  0.1226028,  tolerance = 1e-5)
})

## -- input validation ---------------------------------------------------------

test_that("stops when T1 or T2 is zero or negative", {
  expect_error(ks_eairdiff_mn(5, 5,  0, 100), "'T1' and 'T2' must be strictly positive")
  expect_error(ks_eairdiff_mn(5, 5, 100,  0), "'T1' and 'T2' must be strictly positive")
  expect_error(ks_eairdiff_mn(5, 5, -1, 100), "'T1' and 'T2' must be strictly positive")
})

test_that("stops when alpha is out of (0, 1)", {
  expect_error(ks_eairdiff_mn(5, 5, 100, 100, alpha = 0),   "'alpha' must be in \\(0, 1\\)")
  expect_error(ks_eairdiff_mn(5, 5, 100, 100, alpha = 1),   "'alpha' must be in \\(0, 1\\)")
  expect_error(ks_eairdiff_mn(5, 5, 100, 100, alpha = 1.5), "'alpha' must be in \\(0, 1\\)")
})

## ─────────────────────────────────────────────────────────────────────────────
## ks_eairdiff_strata_mn — stratified
## ─────────────────────────────────────────────────────────────────────────────

## -- output structure ---------------------------------------------------------

test_that("returns a named numeric vector of length 3", {
  res <- ks_eairdiff_strata_mn(c(10, 5), c(5, 3), c(100, 80), c(100, 70))
  expect_true(is.numeric(res))
  expect_equal(length(res), 3L)
  expect_equal(names(res), c("delta", "lcl", "ucl"))
})

## -- CI ordering --------------------------------------------------------------

test_that("lcl <= delta <= ucl", {
  res <- ks_eairdiff_strata_mn(c(10, 5), c(5, 3), c(100, 80), c(100, 70))
  expect_true(res["lcl"] <= res["delta"])
  expect_true(res["delta"] <= res["ucl"])
})

## -- CI symmetry for equal rates ----------------------------------------------

test_that("CI is symmetric around 0 when all stratum rates are equal", {
  res <- ks_eairdiff_strata_mn(c(5, 5), c(5, 5), c(100, 100), c(100, 100))
  expect_equal(unname(res["delta"]), 0, tolerance = tol)
  expect_equal(unname(res["ucl"]), unname(-res["lcl"]), tolerance = tol)
})

## -- reference values ---------------------------------------------------------

test_that("2-stratum 95%% CI matches reference", {
  res <- ks_eairdiff_strata_mn(c(10, 5), c(5, 3), c(100, 80), c(100, 70))
  expect_equal(unname(res["delta"]),  0.03482143,  tolerance = 1e-5)
  expect_equal(unname(res["lcl"]),   -0.01869878,  tolerance = 1e-5)
  expect_equal(unname(res["ucl"]),    0.09902783,  tolerance = 1e-5)
})

test_that("single stratum CI matches non-stratified (bounds agree, delta may differ)", {
  r_strat <- ks_eairdiff_strata_mn(10, 5, 100, 100)
  r_plain <- ks_eairdiff_mn(10, 5, 100, 100)
  ## CI bounds should agree; delta is identical when stratum = full dataset
  expect_equal(unname(r_strat["delta"]), unname(r_plain[, "delta"]), tolerance = tol)
  expect_equal(unname(r_strat["lcl"]),  unname(r_plain[, "lcl"]),   tolerance = tol)
  expect_equal(unname(r_strat["ucl"]),  unname(r_plain[, "ucl"]),   tolerance = tol)
})

## -- alpha effect -------------------------------------------------------------

test_that("90%% CI is narrower than 95%% CI", {
  r95 <- ks_eairdiff_strata_mn(c(10,5), c(5,3), c(100,80), c(100,70))
  r90 <- ks_eairdiff_strata_mn(c(10,5), c(5,3), c(100,80), c(100,70), alpha=0.10)
  expect_lt(r90["ucl"] - r90["lcl"], r95["ucl"] - r95["lcl"])
})

test_that("90%% CI reference values", {
  res <- ks_eairdiff_strata_mn(c(10,5), c(5,3), c(100,80), c(100,70), alpha=0.10)
  expect_equal(unname(res["lcl"]), -0.008756036, tolerance = 1e-5)
  expect_equal(unname(res["ucl"]),  0.088051785, tolerance = 1e-5)
})

## -- input validation ---------------------------------------------------------

test_that("stops when vector lengths differ", {
  expect_error(
    ks_eairdiff_strata_mn(c(10, 5), c(5), c(100, 80), c(100, 70)),
    "must all have the same length"
  )
})

test_that("stops when T1 or T2 contains non-positive values", {
  expect_error(
    ks_eairdiff_strata_mn(c(10, 5), c(5, 3), c(0, 80), c(100, 70)),
    "'T1' and 'T2' must be strictly positive"
  )
})

test_that("stops when alpha is out of (0, 1)", {
  expect_error(
    ks_eairdiff_strata_mn(c(10,5), c(5,3), c(100,80), c(100,70), alpha=2),
    "'alpha' must be in \\(0, 1\\)"
  )
})
