test_that("HL statistic matches reference example", {
  set.seed(1)
  d <- data.frame(x = rnorm(200))
  d$y <- rbinom(200, 1, plogis(0.8 * d$x))
  m <- glm(y ~ x, binomial, data = d)
  hl <- ks_hosmer_lemeshow(d$y, fitted(m))
  expect_named(hl, c("chisq", "p.value", "df"))
  expect_equal(hl$df, 8L)
  expect_true(hl$p.value > 0.05)  # correctly specified model
  if (requireNamespace("ResourceSelection", quietly = TRUE)) {
    ref <- ResourceSelection::hoslem.test(d$y, fitted(m))
    expect_equal(hl$chisq, unname(ref$statistic), tolerance = 1e-6)
  }
})

test_that("input validation", {
  expect_error(ks_hosmer_lemeshow(c(0, 1), c(0.5)), "same length")
  expect_error(ks_hosmer_lemeshow(c(0, 2), c(0.5, 0.5)), "binary")
})
