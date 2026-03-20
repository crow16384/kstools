## Tests for ks_xpt_content(), ks_extract_single_xpt(),
##            ks_batch_load_from_single_xpt()
##
## Integration tests requiring a real XPORT v8 file are skipped unless one
## is provided via the environment variable KS_TEST_XPT (path to the file).

## ── Helper: build a minimal synthetic SAS XPORT v8 binary ───────────────────
## The file is not XPORT-data-valid (haven::read_xpt will fail on it) but has
## the correct magic headers and name-field layout for ks_xpt_content() to parse.

make_v8_xpt <- function(dataset_names,
                         path = tempfile(fileext = ".xpt")) {
  pad80 <- function(s) formatC(s, width = 80L, flag = "-")

  ## 240-byte file header  (3 × 80 bytes)
  file_hdr <- paste0(
    pad80("HEADER RECORD*******LIBV8   HEADER RECORD!!!!!!!"),
    pad80(""),
    pad80("")
  )

  ## Per-member block (3 × 80 = 240 bytes)
  member_blocks <- vapply(dataset_names, function(nm) {
    name_rec <- paste0(
      strrep(" ", 8L),                     # 8-byte padding before name field
      formatC(nm, width = 32L, flag = "-"),  # 32-char name (right-padded)
      strrep(" ", 40L)                      # trailing 40 bytes
    )
    paste0(
      pad80("HEADER RECORD*******MEMBV8  HEADER RECORD!!!!!!!"),
      pad80(""),
      name_rec
    )
  }, character(1L))

  writeBin(charToRaw(paste0(c(file_hdr, member_blocks), collapse = "")), path)
  path
}

## ── ks_xpt_content ──────────────────────────────────────────────────────────

test_that("stops when file does not exist", {
  expect_error(ks_xpt_content("/no/such/file.xpt"),
               "File not found")
})

test_that("stops when file is not a SAS XPORT v8 file", {
  bad <- tempfile()
  writeLines("this is not an XPT file", bad)
  on.exit(unlink(bad))
  expect_error(ks_xpt_content(bad),
               "does not appear to be a SAS XPORT v8 file")
})

test_that("accepts a real haven-written XPT file (haven uses v8 format)", {
  testthat::skip_if_not_installed("haven")
  xpt_path <- tempfile(fileext = ".xpt")
  on.exit(unlink(xpt_path))
  haven::write_xpt(data.frame(x = 1L), xpt_path)
  ## haven uses XPORT v8 format — ks_xpt_content should accept it
  res <- ks_xpt_content(xpt_path)
  expect_type(res, "list")
  expect_length(res, 1L)
})

test_that("returns a named list for a single-member v8 file", {
  p <- make_v8_xpt("DM")
  on.exit(unlink(p))
  res <- ks_xpt_content(p)
  expect_type(res, "list")
  expect_length(res, 1L)
  expect_named(res, "dm")         # names are lower-cased
})

test_that("returns start and stop byte positions for a single member", {
  p <- make_v8_xpt("AE")
  on.exit(unlink(p))
  res <- ks_xpt_content(p)
  ## File header = 3 × 80 = 240 bytes; MEMBV8 starts at byte 241 (1-based)
  expect_equal(unname(res$ae["start"]), 241L)
  ## Stop is exclusive upper bound = file_size + 1, so stop - start = bytes to read
  expect_equal(unname(res$ae["stop"]),  file.size(p) + 1L)
})

test_that("returns correct names and positions for a two-member file", {
  p <- make_v8_xpt(c("AE", "CM"))
  on.exit(unlink(p))
  res <- ks_xpt_content(p)
  expect_length(res, 2L)
  expect_named(res, c("ae", "cm"))
  ## AE starts right after the file header
  expect_equal(unname(res$ae["start"]), 241L)
  ## CM starts immediately after the AE block (240-byte member header)
  expect_equal(unname(res$cm["start"]), 241L + 240L)
  ## AE stop = CM start; CM stop = file_size + 1 (exclusive upper bound)
  expect_equal(unname(res$ae["stop"]),  unname(res$cm["start"]))
  expect_equal(unname(res$cm["stop"]),  file.size(p) + 1L)
})

test_that("all returned names are lower-case", {
  p <- make_v8_xpt(c("ADSL", "ADAE", "ADLB"))
  on.exit(unlink(p))
  res <- ks_xpt_content(p)
  expect_equal(names(res), tolower(c("ADSL", "ADAE", "ADLB")))
})

test_that("handles a five-member file correctly", {
  nms <- c("DM", "AE", "LB", "EX", "CM")
  p   <- make_v8_xpt(nms)
  on.exit(unlink(p))
  res <- ks_xpt_content(p)
  expect_length(res, 5L)
  expect_equal(names(res), tolower(nms))
  ## Each member occupies exactly 240 bytes in the synthetic file.
  ## stop uses an exclusive upper bound, so stop - start = byte count.
  widths <- vapply(res, function(r) as.integer(r["stop"] - r["start"]), integer(1L))
  expect_true(all(widths == 240L))
})

test_that("each element has start and stop components", {
  p <- make_v8_xpt(c("DM", "AE"))
  on.exit(unlink(p))
  res <- ks_xpt_content(p)
  for (nm in names(res)) {
    expect_true("start" %in% names(res[[nm]]))
    expect_true("stop"  %in% names(res[[nm]]))
    expect_true(res[[nm]]["start"] < res[[nm]]["stop"])
  }
})

test_that("stops when no MEMBV8 headers are found", {
  ## File has the LIBV8 header but no member headers
  p <- tempfile(fileext = ".xpt")
  on.exit(unlink(p))
  pad80 <- function(s) formatC(s, width = 80L, flag = "-")
  writeBin(charToRaw(paste0(
    pad80("HEADER RECORD*******LIBV8   HEADER RECORD!!!!!!!"),
    pad80(""), pad80("")
  )), p)
  expect_error(ks_xpt_content(p), "No MEMBV8 member headers found")
})

## ── ks_extract_single_xpt ───────────────────────────────────────────────────

test_that("stops when member name is not in content", {
  testthat::skip_if_not_installed("haven")
  p <- make_v8_xpt("DM")
  on.exit(unlink(p))
  content <- ks_xpt_content(p)
  expect_error(
    ks_extract_single_xpt("ae", p, content),
    "Member 'ae' not found"
  )
})

## ── ks_batch_load_from_single_xpt — argument validation ─────────────────────

test_that("stops with invalid action", {
  p <- make_v8_xpt("DM")
  on.exit(unlink(p))
  expect_error(
    ks_batch_load_from_single_xpt(p, action = "write"),
    "'arg' should be one of"
  )
})

test_that("stops when action='save' and save_path is missing", {
  p <- make_v8_xpt("DM")
  on.exit(unlink(p))
  expect_error(
    ks_batch_load_from_single_xpt(p, action = "save", save_type = "rds"),
    "'save_path' must be provided"
  )
})

test_that("stops when action='save' and save_type is missing", {
  p   <- make_v8_xpt("DM")
  tmp <- tempdir()
  on.exit(unlink(p))
  expect_error(
    ks_batch_load_from_single_xpt(p, action = "save", save_path = tmp),
    "'save_type' must be specified"
  )
})

test_that("stops when save_type='rdata' and save_path is a directory", {
  p <- make_v8_xpt("DM")
  on.exit(unlink(p))
  expect_error(
    ks_batch_load_from_single_xpt(p, action = "save",
                                   save_type = "rdata",
                                   save_path = tempdir()),
    "must be a file path, not a directory"
  )
})

test_that("stops when save_type='rds' and save_path is an existing file", {
  p    <- make_v8_xpt("DM")
  fpath <- tempfile()
  writeLines("x", fpath)
  on.exit({ unlink(p); unlink(fpath) })
  expect_error(
    ks_batch_load_from_single_xpt(p, action = "save",
                                   save_type = "rds",
                                   save_path = fpath),
    "must be a directory"
  )
})

test_that("stops when save_type='parquet' and arrow is not installed", {
  testthat::skip_if(requireNamespace("arrow", quietly = TRUE),
                    "arrow is installed — skip this error test")
  p <- make_v8_xpt("DM")
  on.exit(unlink(p))
  expect_error(
    ks_batch_load_from_single_xpt(p, action = "save",
                                   save_type = "parquet",
                                   save_path = tempdir()),
    "package 'arrow' is required"
  )
})

## ── Round-trip tests with real haven-written files ───────────────────────────

test_that("ks_xpt_content: correct byte count for a real haven file", {
  testthat::skip_if_not_installed("haven")
  xpt_path <- tempfile(fileext = ".xpt")
  on.exit(unlink(xpt_path))
  haven::write_xpt(data.frame(x = 1:5), xpt_path)

  res  <- ks_xpt_content(xpt_path)
  nm   <- names(res)[[1L]]
  ## With exclusive-upper-bound stop: stop - start must equal bytes from
  ## member start to EOF
  expected_bytes <- file.size(xpt_path) - res[[nm]]["start"] + 1L
  actual_bytes   <- res[[nm]]["stop"] - res[[nm]]["start"]
  expect_equal(unname(actual_bytes), unname(expected_bytes))
})

test_that("ks_extract_single_xpt round-trips a real haven file", {
  testthat::skip_if_not_installed("haven")
  xpt_path <- tempfile(fileext = ".xpt")
  on.exit(unlink(xpt_path))

  orig <- data.frame(id = 1:4L, val = c(1.1, 2.2, 3.3, 4.4))
  haven::write_xpt(orig, xpt_path, name = "MYDS")

  content  <- ks_xpt_content(xpt_path)
  result   <- ks_extract_single_xpt("myds", xpt_path, content)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 4L)
  expect_equal(ncol(result), 2L)
  expect_equal(as.integer(result$id),  1:4L)
  expect_equal(as.numeric(result$val), c(1.1, 2.2, 3.3, 4.4), tolerance = 1e-6)
})

## ── Integration tests (real XPORT v8 file, opt-in via env var) ──────────────

skip_no_xpt <- function() {
  path <- Sys.getenv("KS_TEST_XPT", unset = "")
  if (nchar(path) == 0L)
    testthat::skip("KS_TEST_XPT env var not set — skipping real-file tests")
  path
}

test_that("ks_xpt_content lists members of a real v8 file", {
  path <- skip_no_xpt()
  res  <- ks_xpt_content(path)
  expect_type(res, "list")
  expect_true(length(res) >= 1L)
  for (nm in names(res)) {
    expect_true(res[[nm]]["start"] < res[[nm]]["stop"])
  }
})

test_that("ks_extract_single_xpt reads first member of a real v8 file", {
  testthat::skip_if_not_installed("haven")
  path <- skip_no_xpt()
  cont <- ks_xpt_content(path)
  nm   <- names(cont)[[1L]]
  df   <- ks_extract_single_xpt(nm, path, cont)
  expect_s3_class(df, "data.frame")
  expect_true(nrow(df) >= 0L)
})

test_that("ks_batch_load_from_single_xpt saves rds files for real v8 file", {
  testthat::skip_if_not_installed("haven")
  path    <- skip_no_xpt()
  out_dir <- tempfile("ks_xpt_rds_")
  on.exit(unlink(out_dir, recursive = TRUE))

  res <- ks_batch_load_from_single_xpt(path, action = "save",
                                        save_type = "rds",
                                        save_path = out_dir)

  expect_type(res, "list")
  saved <- list.files(out_dir, pattern = "\\.rds$")
  expect_equal(length(saved), length(res))
})
