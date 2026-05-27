## Regression tests for ks_cv()

test_that("ks_cv computes coefficient of variation", {
  expect_equal(ks_cv(c(2, 4, 4, 4, 5, 5, 7, 9)),
               sd(c(2, 4, 4, 4, 5, 5, 7, 9)) * 100 / mean(c(2, 4, 4, 4, 5, 5, 7, 9)))
})

test_that("ks_cv handles NA", {
  expect_equal(ks_cv(c(1, 2, 3, NA, 5)),
               ks_cv(c(1, 2, 3, 5)))
})

test_that("ks_cv returns NA when mean is zero", {
  expect_identical(ks_cv(c(-1, 0, 1)), NA_real_)
  expect_identical(ks_cv(c(0, 0, 0)), NA_real_)
})

test_that("ks_cv returns NA when input is all NA", {
  expect_identical(ks_cv(c(NA_real_, NA_real_)), NA_real_)
})
