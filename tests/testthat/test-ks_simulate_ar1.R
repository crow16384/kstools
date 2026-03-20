## Tests for ks_simulate_ar1()

test_that("returns groupedData with id, obs, y", {
  d <- ks_simulate_ar1(
    n = 5L, beta0 = 0, beta1 = 1, ar.val = 0.2, sigma = 1,
    tau0 = 0.5, tau1 = 0.2, m = 8L, seed = 1L
  )
  expect_s3_class(d, "groupedData")
  expect_named(as.data.frame(d), c("id", "obs", "y"))
})

test_that("rows equal sum of per-subject observation counts", {
  n <- 7L
  m <- 10L
  d <- ks_simulate_ar1(
    n = n, beta0 = 0, beta1 = 0, ar.val = 0.1, sigma = 1,
    tau0 = 0.5, tau1 = 0.2, m = m, seed = 2L
  )
  expect_equal(nrow(d), nrow(unique(d[, c("id", "obs")])))
  p <- table(d$id)
  expect_true(all(p >= 4L & p <= m))
})

test_that("each subject has obs = 1 at least once", {
  d <- ks_simulate_ar1(
    n = 12L, beta0 = 0, beta1 = 0, ar.val = 0.1, sigma = 1,
    tau0 = 0.5, tau1 = 0.2, m = 9L, seed = 3L
  )
  has_one <- tapply(d$obs, d$id, function(x) any(x == 1L))
  expect_true(all(has_one))
})

test_that("seed makes output reproducible", {
  a <- ks_simulate_ar1(
    n = 4L, beta0 = 1, beta1 = 0.5, ar.val = 0.3, sigma = 2,
    tau0 = 1, tau1 = 0.5, m = 6L, seed = 99L
  )
  b <- ks_simulate_ar1(
    n = 4L, beta0 = 1, beta1 = 0.5, ar.val = 0.3, sigma = 2,
    tau0 = 1, tau1 = 0.5, m = 6L, seed = 99L
  )
  expect_equal(a$y, b$y)
})

test_that("errors on invalid ar.val", {
  expect_error(
    ks_simulate_ar1(3, 0, 0, ar.val = 1, sigma = 1, tau0 = 1, tau1 = 1, m = 8),
    regexp = "ar.val"
  )
})

test_that("errors when m < 4", {
  expect_error(
    ks_simulate_ar1(3, 0, 0, ar.val = 0.1, sigma = 1, tau0 = 1, tau1 = 1, m = 3),
    regexp = "m"
  )
})

test_that("errors on non-positive sigma", {
  expect_error(
    ks_simulate_ar1(3, 0, 0, ar.val = 0.1, sigma = 0, tau0 = 1, tau1 = 1, m = 8),
    regexp = "sigma"
  )
})
