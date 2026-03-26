## Tests for ks_current_filename()

test_that("returns a single character string", {
  res <- ks_current_filename()
  expect_type(res, "character")
  expect_length(res, 1L)
})

test_that("returns non-NA value", {
  expect_false(is.na(ks_current_filename()))
})

test_that("returns basename (no directory separators) via source()", {
  tf <- tempfile("test_cfn_", fileext = ".R")
  writeLines("ks_current_filename()", tf)
  res <- source(tf, local = TRUE)$value
  unlink(tf)
  expect_equal(res, basename(tf))
  expect_false(grepl(.Platform$file.sep, res, fixed = TRUE))
})

test_that("source() detection works for nested source()", {
  outer <- tempfile("outer_", fileext = ".R")
  inner <- tempfile("inner_", fileext = ".R")
  writeLines("ks_current_filename()", inner)
  writeLines(sprintf("source('%s', local = TRUE)$value", inner), outer)
  res <- source(outer, local = TRUE)$value
  unlink(c(outer, inner))
  expect_equal(res, basename(inner))
})
