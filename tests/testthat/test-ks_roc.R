tol <- 1e-8


test_that("ks_roc validates response values", {
  df <- data.frame(
    y = c(0, 1, 2, 1),
    x1 = c(0.1, 0.2, 0.3, 0.4)
  )

  expect_error(
    ks_roc(df, var = "x1", response = "y"),
    regexp = "0/1"
  )
})


test_that("ks_roc returns expected structure for two predictors", {
  df <- data.frame(
    y = c(0, 0, 0, 1, 1, 1),
    x1 = c(0.10, 0.20, 0.30, 0.70, 0.80, 0.90),
    x2 = c(0.20, 0.40, 0.10, 0.60, 0.50, 0.80)
  )

  out <- ks_roc(df, var = c("x1", "x2"), response = "y", details = TRUE)

  expect_true(is.list(out))
  expect_true(all(c("areas", "contrasts", "contrast_coefficients", "overall_test", "pvalue", "details") %in% names(out)))

  expect_equal(nrow(out$areas), 2L)
  expect_true(all(c("predictor", "roc_area", "std_error", "lcl", "ucl") %in% names(out$areas)))

  expect_equal(nrow(out$contrasts), 1L)
  expect_true(all(c("contrast", "estimate", "std_error", "lcl", "ucl", "chi_square", "p_value") %in% names(out$contrasts)))

  expect_equal(dim(out$contrast_coefficients), c(1L, 2L))
  expect_equal(unname(out$contrast_coefficients[1, ]), c(1, -1))

  expect_true(all(c("chi_square", "df", "p_value") %in% names(out$overall_test)))
  expect_equal(out$pvalue, unname(out$overall_test["p_value"]), tolerance = tol)

  expect_true(all(c("t", "v", "nx", "ny", "lv") %in% names(out$details)))
})


test_that("ks_roc accepts custom contrast matrix", {
  df <- data.frame(
    y = c(0, 0, 0, 0, 1, 1, 1, 1),
    x1 = c(0.10, 0.20, 0.30, 0.35, 0.70, 0.80, 0.90, 0.85),
    x2 = c(0.15, 0.25, 0.20, 0.40, 0.65, 0.75, 0.85, 0.95),
    x3 = c(0.05, 0.30, 0.22, 0.33, 0.71, 0.82, 0.88, 0.91)
  )

  L <- rbind(c(1, -1, 0), c(0, 1, -1))
  out <- ks_roc(df, var = c("x1", "x2", "x3"), response = "y", contrast = L)

  expect_equal(dim(out$contrast_coefficients), c(2L, 3L))
  expect_equal(nrow(out$contrasts), 2L)
})


test_that("ks_roc errors when a pair has insufficient class counts", {
  df <- data.frame(
    y = c(0, 0, 1, 1),
    x1 = c(0.1, 0.2, 0.8, 0.9),
    x2 = c(NA, 0.3, 0.7, NA)
  )

  expect_error(
    ks_roc(df, var = c("x1", "x2"), response = "y"),
    regexp = "at least 2 observations per response class"
  )
})
