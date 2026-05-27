## Regression tests for ks_n_pct()

test_that("ks_n_pct.numeric formats n and percent", {
  expect_equal(ks_n_pct(c(1, 2, 3), 10),
               c("1 ( 10.0%)", "2 ( 20.0%)", "3 ( 30.0%)"))
})

test_that("ks_n_pct.numeric returns na.rep for zero totals (no Inf% in output)", {
  out <- suppressWarnings(ks_n_pct(c(1, 2), c(0, 10), na.rep = "-"))
  expect_equal(out, c("-", "2 ( 20.0%)"))
  expect_false(any(grepl("Inf", out, fixed = TRUE)))
})

test_that("ks_n_pct.numeric warns on zero totals", {
  expect_warning(ks_n_pct(c(1L), 0L), "zero")
})

test_that("ks_n_pct.numeric returns NA_character_ when na.rep is NA", {
  out <- suppressWarnings(ks_n_pct(c(1L, 2L), c(0L, 10L)))
  expect_true(is.na(out[1]))
  expect_equal(out[2], "2 ( 20.0%)")
})

test_that("ks_n_pct.data.frame replaces zero-totals column with na.rep", {
  d <- data.frame(A = c(1L, 2L), B = c(3L, 4L))
  out <- suppressWarnings(
    ks_n_pct(d, c(A = 0L, B = 10L), na.rep = "-")
  )
  expect_equal(out$A, c("-", "-"))
  expect_false(any(grepl("Inf", out$B, fixed = TRUE)))
})
