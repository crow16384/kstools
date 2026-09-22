test_that("two-sided Dunnett multiplier reproduces published value", {
  skip_if_not_installed("mnormt")
  q <- ks_dunnett_crit(p = 0.95, df = 24, k = 3, rho = 0.5)
  expect_equal(q, 2.5067, tolerance = 1e-3)
  if (requireNamespace("nCDunnett", quietly = TRUE)) {
    expect_equal(q, nCDunnett::qNCDun(0.95, df = 24, k = 3), tolerance = 5e-3)
  }
})

test_that("one-sided is smaller than two-sided", {
  skip_if_not_installed("mnormt")
  a <- suppressWarnings(ks_dunnett_crit(p = 0.95, df = 24, k = 3, rho = 0.5,
                                        type = "one-sided"))
  b <- ks_dunnett_crit(p = 0.95, df = 24, k = 3, rho = 0.5)
  expect_lt(a, b)
})

test_that("validation", {
  expect_error(ks_dunnett_crit(0.95, 24, 1), "at least 2")
  expect_error(ks_dunnett_crit(1.5, 24, 3), "\\(0, 1\\)")
})
