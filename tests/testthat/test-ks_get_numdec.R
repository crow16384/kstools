## Tests for ks_get_numdec()

# ─── correctness ──────────────────────────────────────────────────────────────

test_that("counts decimal places correctly", {
  d <- data.frame(g = "A", val = c(1.1, 2.34, 3.0))
  res <- ks_get_numdec(d, "val", "g")
  expect_true("NUMDEC" %in% names(res))
  expect_equal(unique(res$NUMDEC), 2L)
})

test_that("integer values yield NUMDEC = 0", {
  d <- data.frame(g = "X", val = c(10, 20, 30))
  res <- ks_get_numdec(d, "val", "g")
  expect_equal(unique(res$NUMDEC), 0L)
})

test_that("values beyond 4 decimals are capped at 4", {
  d <- data.frame(g = "A", val = c(0.00001, 0.123456789))
  res <- ks_get_numdec(d, "val", "g")
  expect_equal(unique(res$NUMDEC), 4L)
})

test_that("NA values are ignored in group max", {
  d <- data.frame(g = c("A", "A"), val = c(1.23, NA))
  res <- ks_get_numdec(d, "val", "g")
  expect_equal(unique(res$NUMDEC), 2L)
})

test_that("groups get independent NUMDEC values", {
  d <- data.frame(
    g   = c("A", "A", "B", "B"),
    val = c(1.1, 2.0, 3.456, 4.0)
  )
  res <- ks_get_numdec(d, "val", "g")
  expect_equal(res$NUMDEC[res$g == "A"], c(1L, 1L))
  expect_equal(res$NUMDEC[res$g == "B"], c(3L, 3L))
})

test_that("multiple grouping columns work", {
  d <- data.frame(
    g1  = c("A", "A", "B", "B"),
    g2  = c("X", "Y", "X", "Y"),
    val = c(1.1, 2.34, 3.0, 4.567)
  )
  res <- ks_get_numdec(d, "val", c("g1", "g2"))
  expect_equal(nrow(res), 4L)
  expect_equal(res$NUMDEC[res$g1 == "A" & res$g2 == "X"], 1L)
  expect_equal(res$NUMDEC[res$g1 == "B" & res$g2 == "Y"], 3L)
})

test_that("original columns are preserved", {
  d <- data.frame(g = "A", val = 1.5, extra = "z")
  res <- ks_get_numdec(d, "val", "g")
  expect_true(all(c("g", "val", "extra", "NUMDEC") %in% names(res)))
  expect_equal(res$extra, "z")
})

test_that("negative values are handled", {
  d <- data.frame(g = "A", val = c(-1.23, -4.5))
  res <- ks_get_numdec(d, "val", "g")
  expect_equal(unique(res$NUMDEC), 2L)
})

# ─── validation ───────────────────────────────────────────────────────────────

test_that("errors when data is not a data.frame", {
  expect_error(ks_get_numdec(1:5, "x", "g"), regexp = "data.frame")
})

test_that("errors when var is not a single string", {
  d <- data.frame(g = "A", val = 1)
  expect_error(ks_get_numdec(d, 1, "g"), regexp = "character")
  expect_error(ks_get_numdec(d, c("a", "b"), "g"), regexp = "single")
})

test_that("errors when by is empty or non-character", {
  d <- data.frame(g = "A", val = 1)
  expect_error(ks_get_numdec(d, "val", 1), regexp = "character")
  expect_error(ks_get_numdec(d, "val", character(0)), regexp = "character")
})

test_that("errors when columns are missing", {
  d <- data.frame(g = "A", val = 1)
  expect_error(ks_get_numdec(d, "nope", "g"), regexp = "not found")
  expect_error(ks_get_numdec(d, "val", "nope"), regexp = "not found")
})
