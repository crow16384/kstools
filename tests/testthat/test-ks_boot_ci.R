test_that("percentile CI for the mean brackets the estimate", {
  set.seed(1)
  x <- rnorm(50, 5, 2)
  out <- suppressWarnings(ks_boot_ci(x, function(d, i) mean(d[i]), R = 499, seed = 7L))
  expect_equal(out$estimate, mean(x))
  expect_lt(out$lcl, out$ucl)
  expect_true(out$lcl < mean(x) && mean(x) < out$ucl)
})

test_that("rejects non-scalar statistic", {
  set.seed(1)
  x <- rnorm(20)
  expect_error(ks_boot_ci(x, function(d, i) c(1, 2), R = 99, seed = 1L), "single numeric")
})

test_that("conf and R validation", {
  x <- rnorm(20)
  expect_error(ks_boot_ci(x, median, conf = 1.2), "\\(0, 1\\)")
  expect_error(ks_boot_ci(x, median, R = 1), ">= 2")
})
