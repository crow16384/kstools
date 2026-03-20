test_that("ks_get_data assigns objects to .GlobalEnv", {
  d <- tempdir()
  on.exit(suppressWarnings(rm("dm_test_gd", envir = .GlobalEnv)), add = TRUE)

  saveRDS(data.frame(x = 1:3), file.path(d, "dm_test_gd.rds"))

  ks_get_data(dm_test_gd, path = d)

  expect_true(exists("dm_test_gd", envir = .GlobalEnv, inherits = FALSE))
  expect_equal(get("dm_test_gd", envir = .GlobalEnv), data.frame(x = 1:3))
})

test_that("ks_get_data assigns multiple domains", {
  d <- tempdir()
  on.exit({
    suppressWarnings(rm("ae_test_gd", "lb_test_gd", envir = .GlobalEnv))
  }, add = TRUE)

  saveRDS(data.frame(a = 1), file.path(d, "ae_test_gd.rds"))
  saveRDS(data.frame(b = 2), file.path(d, "lb_test_gd.rds"))

  ks_get_data(ae_test_gd, lb_test_gd, path = d)

  expect_true(exists("ae_test_gd", envir = .GlobalEnv, inherits = FALSE))
  expect_true(exists("lb_test_gd", envir = .GlobalEnv, inherits = FALSE))
})

test_that("ks_get_data accepts quoted strings as domain names", {
  d <- tempdir()
  on.exit(suppressWarnings(rm("vs_test_gd", envir = .GlobalEnv)), add = TRUE)

  saveRDS(data.frame(v = 9), file.path(d, "vs_test_gd.rds"))

  ks_get_data("vs_test_gd", path = d)

  expect_true(exists("vs_test_gd", envir = .GlobalEnv, inherits = FALSE))
  expect_equal(get("vs_test_gd", envir = .GlobalEnv), data.frame(v = 9))
})

test_that("ks_get_data returns the domain names invisibly", {
  d <- tempdir()
  on.exit(suppressWarnings(rm("ex_test_gd", envir = .GlobalEnv)), add = TRUE)

  saveRDS(TRUE, file.path(d, "ex_test_gd.rds"))

  ret <- ks_get_data(ex_test_gd, path = d)

  expect_type(ret, "character")
  expect_equal(ret, "ex_test_gd")
})

test_that("ks_get_data returns multiple names invisibly", {
  d <- tempdir()
  on.exit(suppressWarnings(rm("p1_test_gd", "p2_test_gd", envir = .GlobalEnv)), add = TRUE)

  saveRDS(1L, file.path(d, "p1_test_gd.rds"))
  saveRDS(2L, file.path(d, "p2_test_gd.rds"))

  ret <- ks_get_data(p1_test_gd, p2_test_gd, path = d)

  expect_type(ret, "character")
  expect_length(ret, 2L)
  expect_setequal(ret, c("p1_test_gd", "p2_test_gd"))
})

test_that("ks_get_data uses getOption('path.data.rds') as default path", {
  d <- tempdir()
  on.exit({
    suppressWarnings(rm("opt_test_gd", envir = .GlobalEnv))
    options(path.data.rds = NULL)
  }, add = TRUE)

  saveRDS("hello", file.path(d, "opt_test_gd.rds"))
  options(path.data.rds = d)

  ks_get_data(opt_test_gd)

  expect_true(exists("opt_test_gd", envir = .GlobalEnv, inherits = FALSE))
  expect_equal(get("opt_test_gd", envir = .GlobalEnv), "hello")
})

test_that("ks_get_data errors with clear message when directory is missing", {
  expect_error(
    ks_get_data(dm, path = "/no/such/directory/xyz"),
    regexp = "Directory not found"
  )
})

test_that("ks_get_data error message includes the bad path", {
  bad_path <- "/no/such/directory/xyz_99"
  err <- tryCatch(
    ks_get_data(dm, path = bad_path),
    error = conditionMessage
  )
  expect_true(grepl(bad_path, err, fixed = TRUE))
})

test_that("ks_get_data errors with clear message when file is missing", {
  d <- tempdir()
  expect_error(
    ks_get_data(zzz_does_not_exist_gd, path = d),
    regexp = "File not found"
  )
})

test_that("ks_get_data error message includes the missing file path", {
  d <- tempdir()
  err <- tryCatch(
    ks_get_data(zzz_missing_name_gd, path = d),
    error = conditionMessage
  )
  expect_true(grepl("zzz_missing_name_gd.rds", err, fixed = TRUE))
})

test_that("ks_get_data stops at first missing file without partial side-effects", {
  d <- tempdir()
  on.exit(suppressWarnings(rm("first_test_gd", envir = .GlobalEnv)), add = TRUE)

  saveRDS(1L, file.path(d, "first_test_gd.rds"))
  # second file intentionally absent

  expect_error(
    ks_get_data(first_test_gd, second_missing_gd, path = d),
    regexp = "File not found"
  )

  # first domain should still have been loaded (stop is per-domain)
  expect_true(exists("first_test_gd", envir = .GlobalEnv, inherits = FALSE))
})

test_that("ks_get_data preserves the object type (data.frame)", {
  d <- tempdir()
  on.exit(suppressWarnings(rm("df_test_gd", envir = .GlobalEnv)), add = TRUE)

  saveRDS(data.frame(x = 1:2, y = c("a", "b"), stringsAsFactors = FALSE),
          file.path(d, "df_test_gd.rds"))

  ks_get_data(df_test_gd, path = d)

  obj <- get("df_test_gd", envir = .GlobalEnv)
  expect_s3_class(obj, "data.frame")
  expect_equal(nrow(obj), 2L)
  expect_named(obj, c("x", "y"))
})
