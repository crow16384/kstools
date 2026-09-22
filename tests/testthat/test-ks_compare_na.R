test_that("NA equals NA, differs from non-NA", {
  expect_equal(ks_compare_na(c(NA, "A", "B"), c(NA, "A", "C")), c(TRUE, TRUE, FALSE))
})

test_that("numeric comparison never returns NA", {
  out <- ks_compare_na(c(1, NA, 3), c(1, 2, NA))
  expect_equal(out, c(TRUE, FALSE, FALSE))
  expect_false(anyNA(out))
})

test_that("recycling works", {
  expect_equal(ks_compare_na(c(NA, NA), NA), c(TRUE, TRUE))
})
