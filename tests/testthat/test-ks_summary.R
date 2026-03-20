## Tests for ks_summary()

tol <- 1e-8

base_cols <- c("n", "mean", "sd", "median", "q1", "q3", "min", "max", "cv")

# ─── baseline (no extras) ────────────────────────────────────────────────────

test_that("returns expected base columns without extras", {
  df <- data.frame(g = rep("A", 5L), x = 1:5)
  res <- ks_summary(df, x, g)
  expect_true(all(c("g", base_cols) %in% names(res)))
  expect_false("p.chg" %in% names(res))
})

test_that("base column values match manual calculation", {
  x <- c(2, 4, 6, 8, 10)
  df <- data.frame(x = x)
  res <- ks_summary(df, x)
  expect_equal(res$n, 5L)
  expect_equal(res$mean, mean(x), tolerance = tol)
  expect_equal(res$sd, sd(x), tolerance = tol)
  expect_equal(res$median, median(x), tolerance = tol)
  expect_equal(res$min, min(x), tolerance = tol)
  expect_equal(res$max, max(x), tolerance = tol)
  expect_equal(res$cv, sd(x) * 100 / mean(x), tolerance = tol)
})

# ─── extras ───────────────────────────────────────────────────────────────────

test_that("extras adds named columns with correct values", {
  x <- c(1, 2, 3, 4, 5, 6)
  df <- data.frame(x = x)
  res <- ks_summary(df, x,
    extras = list(
      mad_val = stats::mad,
      iqr_val = IQR
    )
  )
  expect_true("mad_val" %in% names(res))
  expect_true("iqr_val" %in% names(res))
  expect_equal(res$mad_val, stats::mad(x, na.rm = TRUE), tolerance = tol)
  expect_equal(res$iqr_val, IQR(x, na.rm = TRUE), tolerance = tol)
})

test_that("extras work with grouping", {
  df <- data.frame(
    g = rep(c("A", "B"), each = 5L),
    x = c(1:5, 11:15)
  )
  res <- ks_summary(df, x, g, extras = list(iqr_val = IQR))
  expect_equal(nrow(res), 2L)
  expect_equal(
    res$iqr_val[res$g == "A"],
    IQR(1:5, na.rm = TRUE),
    tolerance = tol
  )
  expect_equal(
    res$iqr_val[res$g == "B"],
    IQR(11:15, na.rm = TRUE),
    tolerance = tol
  )
})

test_that("extras columns appear after max and before cv", {
  df <- data.frame(x = 1:10)
  res <- ks_summary(df, x, extras = list(my_stat = stats::mad))
  nms <- names(res)
  expect_true(which(nms == "my_stat") > which(nms == "max"))
  expect_true(which(nms == "my_stat") < which(nms == "cv"))
})

test_that("extras with custom function (SEM)", {
  x <- c(2, 4, 6, 8, 10)
  df <- data.frame(x = x)
  sem_fn <- function(x, na.rm) sd(x, na.rm = na.rm) / sqrt(sum(!is.na(x)))
  res <- ks_summary(df, x, extras = list(sem = sem_fn))
  expect_equal(res$sem, sd(x) / sqrt(5L), tolerance = tol)
})

test_that("extras combined with p.change", {
  set.seed(1)
  df <- data.frame(g = rep("A", 20L), x = rnorm(20))
  res <- ks_summary(df, x, g, p.change = TRUE, extras = list(iqr_val = IQR))
  expect_true("iqr_val" %in% names(res))
  expect_true("p.chg" %in% names(res))
})

test_that("NULL extras returns same structure as no extras", {
  df <- data.frame(g = "A", x = 1:5)
  r1 <- ks_summary(df, x, g)
  r2 <- ks_summary(df, x, g, extras = NULL)
  expect_equal(names(r1), names(r2))
  expect_equal(r1, r2)
})

# ─── extras validation ───────────────────────────────────────────────────────

test_that("errors on name clash with built-in column", {
  df <- data.frame(x = 1:5)
  expect_error(
    ks_summary(df, x, extras = list(mean = stats::mad)),
    regexp = "clash"
  )
  expect_error(
    ks_summary(df, x, extras = list(cv = stats::mad)),
    regexp = "clash"
  )
})

test_that("errors when extras is not a list", {
  df <- data.frame(x = 1:5)
  expect_error(
    ks_summary(df, x, extras = stats::mad),
    regexp = "named list"
  )
})

test_that("errors when extras has unnamed elements", {
  df <- data.frame(x = 1:5)
  expect_error(
    ks_summary(df, x, extras = list(stats::mad)),
    regexp = "named"
  )
})

test_that("errors when extras has duplicate names", {
  df <- data.frame(x = 1:5)
  expect_error(
    ks_summary(df, x, extras = list(a = stats::mad, a = IQR)),
    regexp = "duplicate"
  )
})

test_that("errors when extras element is not a function", {
  df <- data.frame(x = 1:5)
  expect_error(
    ks_summary(df, x, extras = list(bad = 42)),
    regexp = "function"
  )
})
