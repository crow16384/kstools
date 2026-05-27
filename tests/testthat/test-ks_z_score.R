## Regression tests for ks_z_score()

test_that("ks_z_score computes standard z-scores", {
  x <- c(1, 2, 3, 4, 5)
  expect_equal(ks_z_score(x), (x - mean(x)) / sd(x))
})

test_that("ks_z_score handles NA with na.rm = TRUE", {
  x <- c(1, 2, 3, NA, 5)
  expect_false(any(is.nan(ks_z_score(x))))
})

test_that("ks_z_score returns NA vector when sd is zero (constant input)", {
  res <- ks_z_score(rep(5, 4))
  expect_length(res, 4L)
  expect_true(all(is.na(res)))
})

test_that("ks_z_score returns NA vector when input is all NA", {
  res <- ks_z_score(c(NA_real_, NA_real_, NA_real_))
  expect_length(res, 3L)
  expect_true(all(is.na(res)))
})
