make_tmp_dir <- function(prefix = "ks_batch_load_") {
  path <- file.path(tempdir(), paste0(prefix, as.integer(stats::runif(1L, 1, 1e9))))
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

if (!exists("ks_batch_load", mode = "function")) {
  src_candidates <- c(
    file.path("R", "batch_load.r"),
    file.path("..", "..", "R", "batch_load.r")
  )
  src_file <- src_candidates[file.exists(src_candidates)][1]
  if (!is.na(src_file)) {
    source(src_file)
  }
}

test_that("ks_batch_load loads RDS files as a named list", {
  in_dir <- make_tmp_dir("ks_batch_rds_in_")
  on.exit(unlink(in_dir, recursive = TRUE), add = TRUE)

  saveRDS(data.frame(a = 1:2), file.path(in_dir, "DM.rds"))
  saveRDS(data.frame(b = 3:4), file.path(in_dir, "ae.rds"))

  res <- ks_batch_load(data = in_dir, type = "rds")

  expect_type(res, "list")
  expect_setequal(names(res), c("dm", "ae"))
  expect_equal(res$dm$a, 1:2)
  expect_equal(res$ae$b, 3:4)
})

test_that("ks_batch_load writes per-domain RDS when save.path is provided", {
  in_dir <- make_tmp_dir("ks_batch_save_in_")
  out_dir <- make_tmp_dir("ks_batch_save_out_")
  on.exit(unlink(in_dir, recursive = TRUE), add = TRUE)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  saveRDS(data.frame(x = 10), file.path(in_dir, "adsl.rds"))

  res <- ks_batch_load(data = in_dir, type = "rds", save.path = out_dir)

  expect_true(file.exists(file.path(out_dir, "adsl.rds")))
  expect_equal(res$adsl$x, 10)
})

test_that("ks_batch_load keep and save.rdata options create expected side effects", {
  in_dir <- make_tmp_dir("ks_batch_keep_in_")
  out_file <- file.path(make_tmp_dir("ks_batch_keep_out_"), "domains.RData")
  on.exit(unlink(in_dir, recursive = TRUE), add = TRUE)
  on.exit(unlink(dirname(out_file), recursive = TRUE), add = TRUE)

  saveRDS(data.frame(v = 1L), file.path(in_dir, "keepdm.rds"))

  if (exists("keepdm", envir = .GlobalEnv, inherits = FALSE)) {
    rm("keepdm", envir = .GlobalEnv)
  }

  ks_batch_load(
    data = in_dir,
    type = "rds",
    keep = TRUE,
    save.rdata = out_file
  )

  expect_true(exists("keepdm", envir = .GlobalEnv, inherits = FALSE))
  expect_true(file.exists(out_file))

  loaded <- new.env(parent = emptyenv())
  load(out_file, envir = loaded)
  expect_true("keepdm" %in% ls(loaded, all.names = TRUE))

  if (exists("keepdm", envir = .GlobalEnv, inherits = FALSE)) {
    rm("keepdm", envir = .GlobalEnv)
  }
})

test_that("ks_batch_load loads CSV files in batch", {
  in_dir <- make_tmp_dir("ks_batch_csv_in_")
  on.exit(unlink(in_dir, recursive = TRUE), add = TRUE)

  utils::write.csv(data.frame(id = 1:2), file.path(in_dir, "DM.csv"), row.names = FALSE)

  res <- ks_batch_load(data = in_dir, type = "csv")

  expect_true("dm" %in% names(res))
  expect_s3_class(res$dm, "data.frame")
})

test_that("ks_batch_load loads XLSX files in batch", {
  testthat::skip_if_not_installed("openxlsx")

  in_dir <- make_tmp_dir("ks_batch_xlsx_in_")
  on.exit(unlink(in_dir, recursive = TRUE), add = TRUE)

  openxlsx::write.xlsx(data.frame(id = 1:3), file.path(in_dir, "AE.xlsx"))

  res <- ks_batch_load(data = in_dir, type = "xlsx")

  expect_true("ae" %in% names(res))
  expect_s3_class(res$ae, "data.frame")
  expect_equal(nrow(as.data.frame(res$ae)), 3L)
})

test_that("ks_batch_load loads XPT files in batch", {
  testthat::skip_if_not_installed("haven")

  in_dir <- make_tmp_dir("ks_batch_xpt_in_")
  on.exit(unlink(in_dir, recursive = TRUE), add = TRUE)

  haven::write_xpt(data.frame(usubjid = c("01", "02")), file.path(in_dir, "ADSL.xpt"))

  res <- ks_batch_load(data = in_dir, type = "xpt")

  expect_true("adsl" %in% names(res))
  expect_equal(nrow(as.data.frame(res$adsl)), 2L)
})

test_that("ks_batch_load_xlsx wrapper remains compatible", {
  testthat::skip_if_not_installed("openxlsx")

  in_dir <- make_tmp_dir("ks_batch_xlsx_wrap_in_")
  out_dir <- make_tmp_dir("ks_batch_xlsx_wrap_out_")
  on.exit(unlink(in_dir, recursive = TRUE), add = TRUE)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  openxlsx::write.xlsx(data.frame(id = 1:2), file.path(in_dir, "CM.xlsx"))

  res <- ks_batch_load_xlsx(data = in_dir, save.path = out_dir, keep = FALSE)

  expect_true("cm" %in% names(res))
  expect_true(file.exists(file.path(out_dir, "cm.rds")))
})
