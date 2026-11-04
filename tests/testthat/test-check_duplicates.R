test_that("unique keys: silent TRUE", {
  d <- data.frame(x = c("a", "b", "c"))
  expect_silent(res <- ks_check_duplicates(d, x))
  expect_true(res)
})

test_that("duplicates: single warning, invisible FALSE, group count", {
  d <- data.frame(STUDYID = c("A", "A", "B"), USUBJID = c("1", "1", "2"))
  expect_warning(
    res <- ks_check_duplicates(d, STUDYID, USUBJID),
    "Found duplicates: 1"
  )
  expect_false(res)
  w <- expect_warning(ks_check_duplicates(d, STUDYID, USUBJID))
  expect_match(conditionMessage(w), "Keys: STUDYID, USUBJID", fixed = TRUE)
  expect_match(conditionMessage(w), "DUPLICATES", fixed = TRUE)
  expect_false(withVisible(suppressWarnings(
    ks_check_duplicates(d, STUDYID, USUBJID)))$visible)
})

test_that("count is duplicated key GROUPS, not surplus rows", {
  d <- data.frame(k = c("s", "s", "s", "o"))
  expect_warning(ks_check_duplicates(d, k), "Found duplicates: 1")
})

test_that("joint key only: single-column key has no duplicates here", {
  d <- data.frame(ID = c(1, 2), V = c("x", "y"))
  expect_silent(expect_true(ks_check_duplicates(d, ID)))
})

test_that("quoted column names behave like unquoted", {
  d <- data.frame(STUDYID = c("A", "A", "B"), USUBJID = c("1", "1", "2"))
  expect_warning(
    res <- ks_check_duplicates(d, "STUDYID", "USUBJID"),
    "Found duplicates: 1"
  )
  expect_false(res)
})

test_that("NA values group like regular values", {
  d <- data.frame(k = c(NA, NA, "b"))
  expect_warning(ks_check_duplicates(d, k), "Found duplicates: 1")
})

test_that("zero-row data is clean", {
  d <- data.frame(k = character(0))
  expect_silent(expect_true(ks_check_duplicates(d, k)))
})
