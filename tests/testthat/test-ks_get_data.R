test_that("ks_get_data returns a tibble for a single domain", {
  tmp <- withr::local_tempdir()
  saveRDS(data.frame(USUBJID = c("01", "02"), AGE = c(30L, 40L)),
          file.path(tmp, "dm.rds"))

  out <- ks_get_data(dm, path = tmp)

  expect_s3_class(out, "tbl_df")
  expect_false(is.list(out) && !is.data.frame(out))
  expect_equal(nrow(out), 2L)
  expect_named(out, c("USUBJID", "AGE"))
})

test_that("ks_get_data returns a named list for multiple domains", {
  tmp <- withr::local_tempdir()
  saveRDS(data.frame(x = 1:2), file.path(tmp, "dm.rds"))
  saveRDS(data.frame(y = 1:3), file.path(tmp, "ae.rds"))

  out <- ks_get_data(dm, ae, path = tmp)

  expect_type(out, "list")
  expect_named(out, c("dm", "ae"))
  expect_s3_class(out$dm, "tbl_df")
  expect_equal(nrow(out$dm), 2L)
  expect_equal(nrow(out$ae), 3L)
})

test_that("ks_get_data lookup is case-insensitive (stem)", {
  tmp <- withr::local_tempdir()
  saveRDS(data.frame(x = 1:2), file.path(tmp, "dm.rds"))

  a <- ks_get_data(dm, path = tmp)
  b <- ks_get_data(DM, path = tmp)
  c1 <- ks_get_data("Dm", path = tmp)

  expect_identical(a, b)
  expect_identical(a, c1)
})

test_that("ks_get_data lookup is case-insensitive (extension)", {
  tmp <- withr::local_tempdir()
  file_rds <- file.path(tmp, "dm.RDS")
  saveRDS(data.frame(x = 1:2), file_rds)

  out <- ks_get_data(dm, path = tmp)
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
})

test_that("ks_get_data errors by default on case-duplicate filenames", {
  tmp <- withr::local_tempdir()
  saveRDS(data.frame(tag = "lower"), file.path(tmp, "dm.rds"))
  saveRDS(data.frame(tag = "upper"), file.path(tmp, "DM.rds"))
  skip_if(length(list.files(tmp)) < 2L,
          "case-insensitive filesystem cannot hold both dm.rds and DM.rds")

  withr::local_options(kstools.get_data.case = NULL)
  expect_error(ks_get_data(dm, path = tmp), "[Mm]ultiple files")
})

test_that("ks_get_data resolves case-duplicates with `lower` / `upper`", {
  tmp <- withr::local_tempdir()
  saveRDS(data.frame(tag = "lower"), file.path(tmp, "dm.rds"))
  saveRDS(data.frame(tag = "upper"), file.path(tmp, "DM.rds"))
  skip_if(length(list.files(tmp)) < 2L,
          "case-insensitive filesystem cannot hold both dm.rds and DM.rds")

  withr::local_options(kstools.get_data.case = "lower")
  expect_equal(ks_get_data(dm, path = tmp)$tag, "lower")

  withr::local_options(kstools.get_data.case = "upper")
  expect_equal(ks_get_data(dm, path = tmp)$tag, "upper")
})

test_that("ks_get_data `first` picks alphabetical first on ambiguity", {
  tmp <- withr::local_tempdir()
  saveRDS(data.frame(tag = "lower"), file.path(tmp, "dm.rds"))
  saveRDS(data.frame(tag = "upper"), file.path(tmp, "DM.rds"))
  skip_if(length(list.files(tmp)) < 2L,
          "case-insensitive filesystem cannot hold both dm.rds and DM.rds")

  withr::local_options(kstools.get_data.case = "first")
  got <- ks_get_data(dm, path = tmp)$tag
  expected <- readRDS(file.path(tmp, sort(c("DM.rds", "dm.rds"))[1L]))$tag
  expect_equal(got, expected)
})

test_that("ks_get_data validates kstools.get_data.case", {
  tmp <- withr::local_tempdir()
  saveRDS(data.frame(x = 1), file.path(tmp, "dm.rds"))

  withr::local_options(kstools.get_data.case = "nonsense")
  expect_error(ks_get_data(dm, path = tmp), "kstools.get_data.case")
})

test_that("ks_get_data does not touch .GlobalEnv", {
  tmp <- withr::local_tempdir()
  saveRDS(data.frame(x = 1:2), file.path(tmp, "zz_kstest_dm.rds"))

  if (exists("zz_kstest_dm", envir = globalenv()))
    rm("zz_kstest_dm", envir = globalenv())

  out <- ks_get_data(zz_kstest_dm, path = tmp)

  expect_s3_class(out, "tbl_df")
  expect_false(exists("zz_kstest_dm", envir = globalenv(), inherits = FALSE))
})

test_that("ks_get_data errors on missing directory / file", {
  tmp <- withr::local_tempdir()
  saveRDS(data.frame(x = 1), file.path(tmp, "dm.rds"))

  expect_error(ks_get_data(dm, path = "/no/such/path"), "[Dd]irectory")
  expect_error(ks_get_data(xx, path = tmp), "xx")
})
