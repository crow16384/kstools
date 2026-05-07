test_that("XPT round-trip preserves numerics, strings, labels, formats, dates, datetimes", {
  skip_on_cran()
  df <- data.frame(
    ID  = 1:3,
    X   = c(1.5, 2.5, NA_real_),
    S   = c("a", "bb", "ccc"),
    D   = as.Date(c("2020-01-01", "2021-06-15", "2024-12-31")),
    TS  = as.POSIXct(
      c("2020-01-01 12:00:00", "2021-06-15 03:30:45", "2024-12-31 23:59:59"),
      tz = "UTC"
    ),
    stringsAsFactors = FALSE
  )
  attr(df$X, "label")     <- "A measurement"
  attr(df$S, "label")     <- "A string"
  attr(df$X, "format.sas") <- "F8.2"

  tmp <- tempfile(fileext = ".xpt")
  on.exit(unlink(tmp), add = TRUE)

  ks_write_xpt(df, tmp,
               version = 5L,
               dataset_name = "TEST",
               dataset_label = "Smoke test")
  expect_true(file.exists(tmp))
  expect_gt(file.size(tmp), 240L)

  back <- suppressWarnings(ks_read_xpt(tmp, warn = FALSE))

  expect_s3_class(back, "tbl_df")
  expect_equal(nrow(back), 3L)
  expect_equal(ncol(back), 5L)
  expect_equal(as.numeric(back$ID), c(1, 2, 3))
  expect_equal(as.numeric(back$X), c(1.5, 2.5, NA_real_))
  expect_equal(as.character(back$S), c("a", "bb", "ccc"))
  expect_s3_class(back$D, "Date")
  expect_equal(as.numeric(back$D), as.numeric(df$D))
  expect_s3_class(back$TS, "POSIXct")
  expect_equal(as.numeric(back$TS), as.numeric(df$TS), tolerance = 1e-6)

  # Labels and formats round-tripped
  labs <- ks_xpt_labels(back)
  fmts <- ks_xpt_formats(back)
  expect_equal(unname(labs[["X"]]), "A measurement")
  expect_equal(unname(labs[["S"]]), "A string")
  expect_equal(unname(fmts[["X"]]), "F8.2")
  expect_equal(unname(fmts[["D"]]), "DATE9.")
  expect_equal(unname(fmts[["TS"]]), "DATETIME20.")
})

test_that("convert_dates = FALSE returns raw SAS day numbers", {
  skip_on_cran()
  df <- data.frame(D = as.Date("2020-01-01"))
  tmp <- tempfile(fileext = ".xpt")
  on.exit(unlink(tmp), add = TRUE)
  ks_write_xpt(df, tmp)
  raw <- suppressWarnings(ks_read_xpt(tmp, convert_dates = FALSE, warn = FALSE))
  # 2020-01-01 = 21915 days after 1960-01-01
  expect_equal(as.numeric(raw$D[[1]]), 21915)
})

test_that("ks_set_labels / ks_set_formats / ks_xpt_labels / ks_xpt_formats", {
  df <- data.frame(a = 1:2, b = c("x", "y"), stringsAsFactors = FALSE)
  df <- ks_set_labels(df, c(a = "Var A", b = "Var B"))
  df <- ks_set_formats(df, c(a = "F8.0", b = "$1."))
  expect_equal(unname(ks_xpt_labels(df)[["a"]]), "Var A")
  expect_equal(unname(ks_xpt_labels(df)[["b"]]), "Var B")
  expect_equal(unname(ks_xpt_formats(df)[["a"]]), "F8.0")
  expect_equal(unname(ks_xpt_formats(df)[["b"]]), "$1.")
})

test_that("ks_write_xpt validates version", {
  expect_error(ks_write_xpt(data.frame(a = 1), tempfile(), version = 9L),
               "version")
})

test_that("ks_read_xpt errors on missing file", {
  expect_error(ks_read_xpt(tempfile()), "does not exist")
})

test_that("V8 (long-name) format round-trips", {
  skip_on_cran()
  df <- data.frame(
    LongVariableName = c(1.0, 2.0, 3.0),
    Another_Long_Col = c("alpha", "beta", "gamma"),
    stringsAsFactors = FALSE
  )
  attr(df$LongVariableName, "label") <- "A label that is fairly long indeed"
  tmp <- tempfile(fileext = ".xpt")
  on.exit(unlink(tmp), add = TRUE)
  ks_write_xpt(df, tmp, version = 8L, dataset_name = "LONGNAMETEST")
  back <- suppressWarnings(ks_read_xpt(tmp, warn = FALSE))
  expect_equal(names(back), names(df))
  expect_equal(as.numeric(back$LongVariableName), as.numeric(df$LongVariableName))
  expect_equal(as.character(back$Another_Long_Col), as.character(df$Another_Long_Col))
  expect_equal(unname(ks_xpt_labels(back)[["LongVariableName"]]),
               "A label that is fairly long indeed")
})
