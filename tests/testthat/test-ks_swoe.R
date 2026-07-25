## Tests for ks_swoe()

test_that("ks_swoe returns length-n finite scores for a 2-level factor", {
  set.seed(1)
  x <- factor(rep(c("F", "M"), each = 10))
  y <- c(rbinom(10, 1, 0.2), rbinom(10, 1, 0.6))
  res <- ks_swoe(x, y)
  expect_length(res, 20L)
  expect_type(res, "double")
  expect_true(all(is.finite(res)))
  expect_null(names(res))
  # same level => same score
  expect_equal(unique(res[x == "F"]), res[1])
  expect_equal(unique(res[x == "M"]), res[11])
})

test_that("ks_swoe works inside dplyr::mutate", {
  skip_if_not_installed("dplyr")
  dt <- data.frame(
    yn  = c(1, 0, 1, 1, 0, 0),
    sex = factor(c("F", "F", "M", "M", "F", "M"))
  )
  out <- dplyr::mutate(dt, sex_swoe = ks_swoe(sex, yn))
  expect_true("sex_swoe" %in% names(out))
  expect_equal(out$sex_swoe, ks_swoe(dt$sex, dt$yn))
})

test_that("ks_swoe errors on length mismatch", {
  expect_error(ks_swoe(c("a", "b"), c(1, 0, 1)), "same length")
})

test_that("ks_swoe errors when y is all NA", {
  expect_error(ks_swoe(c("a", "b"), c(NA_real_, NA_real_)), "all")
})

test_that("ks_swoe errors when y is not numeric or logical", {
  expect_error(ks_swoe(c("a", "b"), c("yes", "no")), "numeric or logical")
})

test_that("ks_swoe warns and returns finite scores for boundary response", {
  x <- factor(rep(c("a", "b"), each = 4L))
  y <- rep(0L, 8L)
  expect_warning(res <- ks_swoe(x, y), "boundary")
  expect_length(res, 8L)
  expect_true(all(is.finite(res)))
})
