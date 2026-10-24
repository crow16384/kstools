## Tests for LLM panel review round 1 (docs/reviews/2026-10-25-llm-panel)
## Fix IDs A2..A10 reference the COMPARISON.md table;
## A1 (SAS-parity W=0) is tested in test-ks_mianalyze.R against the live probe.

test_that("A2: non-finite numerics are written as SAS missing, not 0", {
  skip_on_cran()
  df <- data.frame(ID = 1:4, X = c(1, Inf, -Inf, 2))
  tmp <- tempfile(fileext = ".xpt")
  on.exit(unlink(tmp), add = TRUE)

  ks_write_xpt(df, tmp)
  back <- suppressWarnings(ks_read_xpt(tmp, warn = FALSE))
  expect_equal(as.numeric(back$X), c(1, NA_real_, NA_real_, 2))

  # NaN already mapped to NA before this round - keep it pinned
  df2 <- data.frame(ID = 1L, X = NaN)
  tmp2 <- tempfile(fileext = ".xpt")
  on.exit(unlink(tmp2), add = TRUE)
  ks_write_xpt(df2, tmp2)
  expect_true(is.na(suppressWarnings(ks_read_xpt(tmp2, warn = FALSE))$X))
})

test_that("A4: v5 transport limits abort instead of silent truncation", {
  skip_on_cran()
  # names longer than 8 bytes
  expect_error(
    ks_write_xpt(data.frame(longvariablename = 1), tempfile(fileext = ".xpt")),
    "limit of 8 bytes"
  )
  # two 17-char names sharing the first 8 bytes no longer produce a
  # duplicate-variable file: the write aborts on the first violation set.
  expect_error(
    ks_write_xpt(data.frame(abcdefgh_1 = 1, abcdefgh_2 = 2),
                 tempfile(fileext = ".xpt")),
    "limit of 8 bytes"
  )
  # character data > 200 bytes is not transportable in v5 (SAS TN 1528)
  expect_error(
    ks_write_xpt(data.frame(q = strrep("x", 500)), tempfile(fileext = ".xpt")),
    "not transportable at version 5"
  )
  # column labels > 40 bytes
  df <- data.frame(a = 1)
  attr(df$a, "label") <- strrep("L", 41)
  expect_error(ks_write_xpt(df, tempfile(fileext = ".xpt")),
               "labels exceed the XPORT v5 limit of 40 bytes")

  # v8 tolerates the same data (within its own limits)
  tmp8 <- tempfile(fileext = ".xpt")
  on.exit(unlink(tmp8), add = TRUE)
  expect_no_error(ks_write_xpt(data.frame(q = strrep("x", 500)), tmp8, version = 8L))

  # v8 rejects names beyond 32 bytes
  long33 <- paste0(rep("z", 33), collapse = "")
  expect_error(
    ks_write_xpt(setNames(data.frame(1), long33), tempfile(fileext = ".xpt"),
                 version = 8L),
    "limit of 32 bytes"
  )
})

test_that("A4: case-insensitive name collisions abort", {
  expect_error(
    ks_write_xpt(data.frame(Abc = 1, aBC = 2), tempfile(fileext = ".xpt")),
    "collide case-insensitively"
  )
})

test_that("A9: a failed write leaves no partial transport file", {
  bad <- file.path(tempdir(), "definitely-not-here-42", "x.xpt")
  expect_error(ks_write_xpt(data.frame(a = 1), bad), regexp = ".")
  expect_false(file.exists(bad))
})

test_that("A5: ks_auc returns NA (not 0) for groups with < 2 usable points", {
  d_all_na <- data.frame(grp = c("A", "A", "B", "B"),
                         t   = c(0, 1, 0, 1),
                         v   = NA_real_)
  r1 <- ks_auc(d_all_na, by = "grp", val = v, time = t)
  expect_true(all(is.na(r1$AUC)))

  d_single <- data.frame(grp = c("A", "B", "B"), t = c(0, 0, 1), v = c(5, 2, 4))
  r2 <- ks_auc(d_single, by = "grp", val = v, time = t)
  expect_true(is.na(r2$AUC[r2$grp == "A"]))
  expect_equal(r2$AUC[r2$grp == "B"], 3)

  # ungrouped single point
  expect_true(is.na(ks_auc(data.frame(t = 0, v = 5), val = v, time = t)))
  # log-trapezoid path uses the same rule
  expect_true(is.na(ks_auc(d_single, by = "grp", val = v, time = t,
                           type = "log-trapez")$AUC[1]))
})

test_that("A6: ks_batch_load aborts when any member fails to read", {
  skip_on_cran()
  skip_if(.Platform$OS.type == "windows", "mclapply path not exercised here")
  td <- tempfile(); dir.create(td); on.exit(unlink(td, recursive = TRUE), add = TRUE)
  saveRDS(data.frame(a = 1), file.path(td, "good.rds"))
  writeBin(charToRaw("definitely not an rds"), file.path(td, "broken.rds"))

  expect_error(ks_batch_load(td, type = "rds"), "failed to load")
  # and it aborts before anything is saved through save.path
  sp <- file.path(td, "out"); dir.create(sp)
  expect_error(ks_batch_load(td, type = "rds", save.path = sp), "failed to load")
  expect_length(list.files(sp), 0L)
})

test_that("A7: ks_roc rejects non-numeric predictors with a clear error", {
  d <- data.frame(y = c(0, 0, 1, 1), f = factor(c("a", "b", "a", "b")))
  expect_error(ks_roc(d, var = "f", response = "y"), "must be numeric")
  d2 <- data.frame(y = c(0, 0, 1, 1), s = c("a", "b", "a", "b"))
  expect_error(ks_roc(d2, var = "s", response = "y"), "must be numeric")
})

test_that("A8: numeric variable with storageWidth != 8 is rejected, not garbage", {
  skip_on_cran()
  tmp <- tempfile(fileext = ".xpt")
  on.exit(unlink(tmp), add = TRUE)
  ks_write_xpt(data.frame(ZZZVAR99 = c(1, 2, 3)), tmp)

  bytes <- readBin(tmp, "raw", file.size(tmp))
  vs    <- as.integer(bytes)
  sig   <- c(utf8ToInt("ZZZVAR99"), rep(32L, 24L))   # name[8] + start of blank label[40]
  cands <- which(vs == 90L)
  hits  <- cands[cands + 31L <= length(vs) &
                 vapply(cands, function(s) all(vs[s + 0:31] == sig), logical(1))]
  expect_gte(length(hits), 1L)
  # Entry layout (custom of this writer/parser, parseNameStr):
  #   ns+0 ntype(2) ns+4 storageWidth(2) ns+6 varNumber(2) ns+8 name(8) ns+16 label(40)
  # off below is the 0-based offset of the first byte of the name field = ns+8.
  off <- hits[1L] - 1L
  # 0-based ns = off - 8 -> R 1-based index of ns+p is (off - 8 + p) + 1 = off + p - 7
  expect_equal(as.integer(bytes[off - 7L]), 0L)   # ntype hi
  expect_equal(as.integer(bytes[off - 6L]), 1L)   # ntype lo = 1 (numeric)
  expect_equal(as.integer(bytes[off - 3L]), 0L)   # storageWidth hi
  expect_equal(as.integer(bytes[off - 2L]), 8L)   # storageWidth lo = 8

  bytes[off - 3L] <- as.raw(0x00)
  bytes[off - 2L] <- as.raw(0x04)                 # claim storageWidth 4
  bad <- tempfile(fileext = ".xpt")
  on.exit(unlink(bad), add = TRUE)
  writeBin(bytes, bad)
  expect_error(suppressWarnings(ks_read_xpt(bad, warn = FALSE)),
               "must be exactly 8 bytes")
})

test_that("A3: ks_impute_dtc rejects out-of-range components instead of rolling over", {
  bad <- c("2020-13-01", "2020-01-32", "2020-01-01T25:70:00", "2020-02-30",
           "2021-02-29", "2020-01-01T10:30:60")
  res <- ks_impute_dtc(bad)
  expect_true(all(is.na(res$dt)))
  expect_true(all(is.na(res$imputation_flag)))

  # valid dates keep working (leap day in a leap year)
  ok <- ks_impute_dtc(c("2020-02-29", "2020-01-01T23:59:59"))
  expect_equal(as.POSIXct(ok$dt, origin = "1970-01-01"),
               as.POSIXct(c("2020-02-29 00:00:00", "2020-01-01 23:59:59"), tz = "UTC"))

  # partial dates + imputation unaffected
  p <- suppressWarnings(ks_impute_dtc(c("2020-03", "2020"), direction = "start"))
  expect_equal(as.numeric(p$dt),
               as.numeric(as.POSIXct(c("2020-03-01 00:00:00", "2020-01-01 00:00:00"),
                                     tz = "UTC")))
  expect_equal(p$imputation_flag, c("D", "M"))

  # malformed element is not imputed from ref either
  ref <- as.POSIXct("2020-03-15 10:30:00", tz = "UTC")
  m <- ks_impute_dtc("2020-13-01", direction = "start", ref = ref)
  expect_true(is.na(m$dt))
})

test_that("A10: ks_n_pct truncates consistently and warns on fractional counts", {
  expect_warning(out <- ks_n_pct(1.9, 10), "non-integer")
  expect_equal(out, "1 ( 10.0%)")
  expect_equal(ks_n_pct(2, 10), "2 ( 20.0%)")
})
test_that("A10: ks_supp_merge aborts on duplicate keys and QNAM collisions", {
  dm <- data.frame(STUDYID = "S1", USUBJID = c("01", "02"), AGE = c(34L, 52L),
                   stringsAsFactors = FALSE)
  supp_dup <- data.frame(
    STUDYID = "S1", USUBJID = c("01", "01"), IDVAR = "", IDVARVAL = "",
    QNAM = "RACE2", QLABEL = "Race", QVAL = c("Asian", "White"),
    stringsAsFactors = FALSE
  )
  expect_error(ks_supp_merge(dm, supp_dup), "duplicate QNAM records")

  supp_coll <- data.frame(
    STUDYID = "S1", USUBJID = "01", IDVAR = "", IDVARVAL = "",
    QNAM = "AGE", QLABEL = "Age again", QVAL = "99",
    stringsAsFactors = FALSE
  )
  expect_error(ks_supp_merge(dm, supp_coll), "collide with variables")

  # clean merge still works
  supp_ok <- data.frame(
    STUDYID = "S1", USUBJID = c("01", "02"), IDVAR = "", IDVARVAL = "",
    QNAM = "RACE2", QLABEL = "Race", QVAL = c("Asian", "White"),
    stringsAsFactors = FALSE
  )
  ok_res <- ks_supp_merge(dm, supp_ok)
  expect_equal(nrow(ok_res), 2L)
  expect_true("RACE2" %in% names(ok_res))
})
