## Tests for ks_newcombe_hs() and ks_newcombe_hs_strata()

tol <- 1e-5   # tolerance for numeric comparisons

# ─── ks_newcombe_hs — output structure ───────────────────────────────────────

test_that("returns a matrix with 3 columns named delta/lcl/ucl", {
  res <- ks_newcombe_hs(10L, 50L, 8L, 50L)
  expect_true(is.matrix(res))
  expect_equal(ncol(res), 3L)
  expect_named(res[1L, ], c("delta", "lcl", "ucl"))
})

test_that("single pair returns a 1-row matrix", {
  res <- ks_newcombe_hs(10L, 50L, 8L, 50L)
  expect_equal(nrow(res), 1L)
})

test_that("vectorised input returns one row per pair", {
  res <- ks_newcombe_hs(c(10L, 20L), c(50L, 80L), c(8L, 16L), c(50L, 80L))
  expect_equal(nrow(res), 2L)
})

# ─── ks_newcombe_hs — point estimate -----------------------------------------

test_that("delta equals x1/n1 - x2/n2 exactly", {
  res <- ks_newcombe_hs(36L, 54L, 41L, 56L)
  expect_equal(unname(res[, "delta"]), 36/54 - 41/56, tolerance = tol)
})

test_that("delta is 0 when both proportions are equal", {
  res <- ks_newcombe_hs(20L, 50L, 20L, 50L)
  expect_equal(unname(res[, "delta"]), 0, tolerance = tol)
})

# ─── ks_newcombe_hs — CI ordering --------------------------------------------

test_that("lcl <= delta <= ucl for a typical comparison", {
  res <- ks_newcombe_hs(36L, 54L, 41L, 56L)
  expect_lte(unname(res[, "lcl"]), unname(res[, "delta"]))
  expect_lte(unname(res[, "delta"]), unname(res[, "ucl"]))
})

test_that("lcl <= delta <= ucl when x1 = 0", {
  res <- ks_newcombe_hs(0L, 50L, 10L, 50L)
  expect_lte(unname(res[, "lcl"]), unname(res[, "delta"]))
  expect_lte(unname(res[, "delta"]), unname(res[, "ucl"]))
})

test_that("lcl <= delta <= ucl when x2 = 0", {
  res <- ks_newcombe_hs(10L, 50L, 0L, 50L)
  expect_lte(unname(res[, "lcl"]), unname(res[, "delta"]))
  expect_lte(unname(res[, "delta"]), unname(res[, "ucl"]))
})

test_that("lcl <= delta <= ucl when x1 = n1 (all events)", {
  res <- ks_newcombe_hs(50L, 50L, 30L, 50L)
  expect_lte(unname(res[, "lcl"]), unname(res[, "delta"]))
  expect_lte(unname(res[, "delta"]), unname(res[, "ucl"]))
})

# ─── ks_newcombe_hs — CI symmetry --------------------------------------------

test_that("CI is symmetric around 0 when rates are equal", {
  res <- ks_newcombe_hs(20L, 50L, 20L, 50L)
  expect_equal(unname(res[, "lcl"]), -unname(res[, "ucl"]), tolerance = tol)
})

# ─── ks_newcombe_hs — regression against reference values --------------------

test_that("90% CI for test.pp matches reference (Newcombe 1998 test data)", {
  # x1=36, n1=54, x2=41, n2=56, alpha=0.10
  res <- ks_newcombe_hs(36L, 54L, 41L, 56L, alpha = 0.10)
  expect_equal(unname(res[, "delta"]), -0.065476, tolerance = tol)
  expect_equal(unname(res[, "lcl"]),   -0.205446, tolerance = tol)
  expect_equal(unname(res[, "ucl"]),    0.077355, tolerance = tol)
})

test_that("90% CI for test.itt matches reference", {
  # x1=38, n1=57, x2=42, n2=57, alpha=0.10
  res <- ks_newcombe_hs(38L, 57L, 42L, 57L, alpha = 0.10)
  expect_equal(unname(res[, "delta"]), -0.070175, tolerance = tol)
  expect_equal(unname(res[, "lcl"]),   -0.206909, tolerance = tol)
  expect_equal(unname(res[, "ucl"]),    0.070204, tolerance = tol)
})

test_that("90% CI for rare events matches reference", {
  # x1=3, n1=86, x2=3, n2=93, alpha=0.10
  res <- ks_newcombe_hs(3L, 86L, 3L, 93L, alpha = 0.10)
  expect_equal(unname(res[, "delta"]),  0.0026256564, tolerance = tol)
  expect_equal(unname(res[, "lcl"]),   -0.0476453201, tolerance = tol)
  expect_equal(unname(res[, "ucl"]),    0.0555018165, tolerance = tol)
})

test_that("95% CI for rare events matches reference", {
  res <- ks_newcombe_hs(3L, 86L, 3L, 93L, alpha = 0.05)
  expect_equal(unname(res[, "delta"]),  0.0026256564, tolerance = tol)
  expect_equal(unname(res[, "lcl"]),   -0.0600621408, tolerance = tol)
  expect_equal(unname(res[, "ucl"]),    0.0688452086, tolerance = tol)
})

test_that("95% CI with x1 = 0 matches reference", {
  res <- ks_newcombe_hs(0L, 50L, 10L, 50L)
  expect_equal(unname(res[, "delta"]), -0.2,       tolerance = tol)
  expect_equal(unname(res[, "lcl"]),   -0.330371,  tolerance = tol)
  expect_equal(unname(res[, "ucl"]),   -0.087050,  tolerance = tol)
})

# ─── ks_newcombe_hs — alpha effect -------------------------------------------

test_that("90% CI is narrower than 95% CI", {
  r95 <- ks_newcombe_hs(20L, 50L, 15L, 50L, alpha = 0.05)
  r90 <- ks_newcombe_hs(20L, 50L, 15L, 50L, alpha = 0.10)
  width95 <- r95[, "ucl"] - r95[, "lcl"]
  width90 <- r90[, "ucl"] - r90[, "lcl"]
  expect_lt(width90, width95)
})

# ─── ks_newcombe_hs — input validation ---------------------------------------

test_that("errors when n1 contains zero", {
  expect_error(ks_newcombe_hs(5L, 0L, 5L, 50L), regexp = "positive")
})

test_that("errors when n2 is negative", {
  expect_error(ks_newcombe_hs(5L, 50L, 5L, -1L), regexp = "positive")
})

test_that("errors when x1 > n1", {
  expect_error(ks_newcombe_hs(51L, 50L, 5L, 50L), regexp = "0 <= x <= n")
})

test_that("errors when x2 < 0", {
  expect_error(ks_newcombe_hs(5L, 50L, -1L, 50L), regexp = "0 <= x <= n")
})

test_that("errors when alpha = 0", {
  expect_error(ks_newcombe_hs(5L, 50L, 5L, 50L, alpha = 0), regexp = "alpha")
})

test_that("errors when alpha = 1", {
  expect_error(ks_newcombe_hs(5L, 50L, 5L, 50L, alpha = 1), regexp = "alpha")
})

test_that("errors when alpha is a vector", {
  expect_error(ks_newcombe_hs(5L, 50L, 5L, 50L, alpha = c(0.05, 0.10)), regexp = "alpha")
})

# ─── ks_newcombe_hs_strata — output structure ─────────────────────────────────

test_that("strata function returns a named numeric vector of length 3", {
  res <- ks_newcombe_hs_strata(c(36L, 10L), c(54L, 30L), c(41L, 8L), c(56L, 30L))
  expect_type(res, "double")
  expect_length(res, 3L)
  expect_named(res, c("delta", "lcl", "ucl"))
})

# ─── ks_newcombe_hs_strata — CI ordering ──────────────────────────────────────

test_that("strata: lcl <= delta <= ucl", {
  res <- ks_newcombe_hs_strata(c(36L, 10L), c(54L, 30L), c(41L, 8L), c(56L, 30L))
  expect_lte(res["lcl"], res["delta"])
  expect_lte(res["delta"], res["ucl"])
})

# ─── ks_newcombe_hs_strata — single stratum equals non-stratified ─────────────

test_that("single stratum matches ks_newcombe_hs exactly", {
  s <- ks_newcombe_hs_strata(36L, 54L, 41L, 56L)
  u <- ks_newcombe_hs(36L, 54L, 41L, 56L)
  expect_equal(unname(s), unname(u[1L, ]), tolerance = tol)
})

# ─── ks_newcombe_hs_strata — regression ───────────────────────────────────────

test_that("2-stratum 95% CI matches reference", {
  res <- ks_newcombe_hs_strata(
    x1 = c(36L, 10L), n1 = c(54L, 30L),
    x2 = c(41L,  8L), n2 = c(56L, 30L)
  )
  expect_equal(unname(res["delta"]), -0.0188275567, tolerance = tol)
  expect_equal(unname(res["lcl"]),   -0.1525173910, tolerance = tol)
  expect_equal(unname(res["ucl"]),    0.1151379047, tolerance = tol)
})

test_that("strata: CI is symmetric when all stratum rates are equal", {
  res <- ks_newcombe_hs_strata(
    x1 = c(10L, 5L), n1 = c(50L, 20L),
    x2 = c(10L, 5L), n2 = c(50L, 20L)
  )
  expect_equal(unname(res["delta"]),  0, tolerance = tol)
  expect_equal(unname(res["lcl"]), -unname(res["ucl"]), tolerance = tol)
})

# ─── ks_newcombe_hs_strata — input validation ──────────────────────────────────

test_that("strata: errors when n1 contains zero", {
  expect_error(
    ks_newcombe_hs_strata(c(5L, 5L), c(50L, 0L), c(5L, 5L), c(50L, 50L)),
    regexp = "positive"
  )
})

test_that("strata: errors when alpha out of range", {
  expect_error(
    ks_newcombe_hs_strata(c(5L, 5L), c(50L, 50L), c(5L, 5L), c(50L, 50L), alpha = 1.1),
    regexp = "alpha"
  )
})
