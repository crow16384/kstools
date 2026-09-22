cross <- data.frame(
  per = as.factor(rep(c(1, 2), 9)),
  trt = as.factor(c(rep(c("T", "R"), 4), rep(c("R", "T"), 5))),
  seq = as.factor(c(rep(1, 8), rep(2, 10))),
  cow = as.factor(rep(1:9, each = 2)),
  my  = c(29.9, 27.8, 54.0, 49.7, 41.6, 38.4, 28.5, 26.5, 22.2,
          21.4, 55.5, 49.1, 43.5, 41.3, 33.2, 34.3, 18.2, 17.1)
)

test_that("2x2 BE reproduces published values", {
  fit <- ks_be_2x2(cross, response = my, trt = trt, test = "T",
                   reference = "R", seq = seq, period = per, subject = cow)
  expect_equal(fit$estimate, 0.014488, tolerance = 1e-3)
  expect_equal(fit$se, 0.014161, tolerance = 1e-3)
  expect_equal(fit$df, 7)
  # default 90% BE interval (verified: exp(est +/- qt(.95,7)*se))
  expect_equal(fit$ratio.lcl, 0.9877, tolerance = 2e-3)
  expect_equal(fit$ratio.ucl, 1.0422, tolerance = 2e-3)
})

test_that("reference first gives sign convention T-R", {
  fit <- ks_be_2x2(cross, response = my, trt = trt, test = "T",
                   reference = "R", seq = seq, period = per, subject = cow)
  # swapping the labels must flip the estimate
  fit2 <- ks_be_2x2(cross, response = my, trt = trt, test = "R",
                    reference = "T", seq = seq, period = per, subject = cow)
  expect_equal(fit$estimate, -fit2$estimate, tolerance = 1e-12)
})

test_that("non-positive response with log=TRUE errors", {
  c2 <- cross; c2$my[1] <- 0
  expect_error(
    ks_be_2x2(c2, response = my, trt = trt, test = "T", reference = "R",
              seq = seq, period = per, subject = cow),
    "Non-positive")
})
