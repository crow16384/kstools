test_that("Mardia matches QuantPsyc implementation", {
  skip_if_not_installed("QuantPsyc")
  set.seed(0)
  dat <- data.frame(x1 = rnorm(50), x2 = rnorm(50), x3 = rnorm(50))
  out <- ks_mv_normality(dat, R = 99, seed = 1L)
  ref <- QuantPsyc::mult.norm(dat)$mult.test
  expect_equal(as.numeric(out$mardia["Skewness", ]), as.numeric(ref["Skewness", ]),
               tolerance = 1e-7)
  expect_equal(as.numeric(out$mardia["Kurtosis", ]), as.numeric(ref["Kurtosis", ]),
               tolerance = 1e-7)
})

test_that("small n returns NULL mardia gracefully", {
  set.seed(0)
  dat <- data.frame(x1 = rnorm(3), x2 = rnorm(3), x3 = rnorm(3), x4 = rnorm(3))
  out <- ks_mv_normality(dat, R = 1)
  expect_null(out$mardia)
})
