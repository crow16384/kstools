## Tests for ks_auc()

tol <- 1e-6

## ─────────────────────────────────────────────────────────────────────────────
## Input validation
## ─────────────────────────────────────────────────────────────────────────────

test_that("stops when data is not a data.frame", {
  expect_error(ks_auc(list(c = 1:3, t = 0:2), val = c, time = t),
               "'data' must be a data.frame or tibble")
})

test_that("stops on unknown type", {
  df <- data.frame(c = 1:3, t = 0:2)
  expect_error(ks_auc(df, val = c, time = t, type = "simpson"))
})

## ─────────────────────────────────────────────────────────────────────────────
## Linear trapezoid — ungrouped
## ─────────────────────────────────────────────────────────────────────────────

test_that("returns a single numeric scalar when by = NULL", {
  df <- data.frame(c = c(0, 4, 2, 1, 0), t = c(0, 1, 2, 4, 8))
  res <- ks_auc(df, val = c, time = t)
  expect_true(is.numeric(res))
  expect_length(res, 1L)
})

test_that("linear trapezoid: ramp 0 to 4 over t = 0:4 gives AUC = 8", {
  df <- data.frame(c = 0:4, t = 0:4)
  expect_equal(ks_auc(df, val = c, time = t), 8, tolerance = tol)
})

test_that("linear trapezoid: constant = 2 over t = 0:3 gives AUC = 6", {
  df <- data.frame(c = rep(2, 4L), t = 0:3)
  expect_equal(ks_auc(df, val = c, time = t), 6, tolerance = tol)
})

test_that("linear trapezoid: 5-point profile gives AUC = 10", {
  ## conc 0,4,2,1,0 at t 0,1,2,4,8
  ## intervals: 2 + 3 + 3 + 2 = 10
  df <- data.frame(conc = c(0, 4, 2, 1, 0), time = c(0, 1, 2, 4, 8))
  expect_equal(ks_auc(df, val = conc, time = time), 10, tolerance = tol)
})

test_that("linear trapezoid: two-point single interval", {
  ## (4 + 2) / 2 * 3 = 9
  df <- data.frame(c = c(4, 2), t = c(0, 3))
  expect_equal(ks_auc(df, val = c, time = t), 9, tolerance = tol)
})

test_that("linear trapezoid: single data point gives AUC = 0", {
  df <- data.frame(c = 5, t = 1)
  expect_equal(ks_auc(df, val = c, time = t), 0, tolerance = tol)
})

## ─────────────────────────────────────────────────────────────────────────────
## Log-linear trapezoid — ungrouped
## ─────────────────────────────────────────────────────────────────────────────

test_that("log-linear trapezoid: two-point single interval", {
  ## (2 - 4) * 3 / (log(2) - log(4)) = -6 / log(0.5) = 8.656
  df  <- data.frame(c = c(4, 2), t = c(0, 3))
  ref <- (2 - 4) * 3 / (log(2) - log(4))
  expect_equal(ks_auc(df, val = c, time = t, type = "log-trapez"), ref,
               tolerance = tol)
})

test_that("log-linear trapezoid: exact on a true exponential decline", {
  ## C(t) = 4 * exp(-0.5*t); AUC(0→4) = 4/0.5 * (1 - exp(-2)) ≈ 6.9173
  pk <- data.frame(conc = 4 * exp(-0.5 * c(0, 1, 2, 4)), time = c(0, 1, 2, 4))
  ref <- 4 / 0.5 * (1 - exp(-2))
  expect_equal(ks_auc(pk, val = conc, time = time, type = "log-trapez"), ref,
               tolerance = tol)
})

test_that("log-linear is closer than linear to analytic AUC on exponential decline", {
  pk    <- data.frame(conc = 4 * exp(-0.5 * c(0, 1, 2, 4)), time = c(0, 1, 2, 4))
  ref   <- 4 / 0.5 * (1 - exp(-2))
  err_log  <- abs(ks_auc(pk, val = conc, time = time, type = "log-trapez") - ref)
  err_lin  <- abs(ks_auc(pk, val = conc, time = time, type = "trapez")     - ref)
  expect_lt(err_log, err_lin)
})

## ─────────────────────────────────────────────────────────────────────────────
## Bug-fix: log-linear fallback for equal and zero concentrations
## ─────────────────────────────────────────────────────────────────────────────

test_that("log-linear: equal consecutive values fall back to linear (no NaN)", {
  ## c = 2,2,4,4 at t = 0,1,2,3
  ## equal intervals use linear: (2+2)*1/2=2, (4+4)*1/2=4
  ## rising interval uses log:   (4-2)*1/log(2) = 2/0.6931 = 2.885
  ## total ≈ 8.885
  df  <- data.frame(c = c(2, 2, 4, 4), t = 0:3)
  ref <- 2 + (4 - 2) * 1 / (log(4) - log(2)) + 4
  expect_equal(ks_auc(df, val = c, time = t, type = "log-trapez"), ref,
               tolerance = 1e-4)
  ## Must not be what the naive 0/0=NaN implementation returns (≈ 2.885)
  expect_gt(ks_auc(df, val = c, time = t, type = "log-trapez"), 5)
})

test_that("log-linear: zero concentration uses linear fallback, not 0", {
  ## c = 0,2,4,2 at t = 0,1,2,3
  ## zero interval  → linear: (0+2)*1/2  = 1.0
  ## rising interval → log:   (4-2)*1/log(2)   = 2.885
  ## falling interval → log:  (2-4)*1/(log(2)-log(4)) = 2.885
  ## total ≈ 6.771
  df  <- data.frame(c = c(0, 2, 4, 2), t = 0:3)
  ref <- (0 + 2) / 2 +
    (4 - 2) * 1 / (log(4) - log(2)) +
    (2 - 4) * 1 / (log(2) - log(4))
  expect_equal(
    suppressWarnings(ks_auc(df, val = c, time = t, type = "log-trapez")),
    ref, tolerance = 1e-4
  )
  ## Must be clearly more than 0 (the buggy value from log(0)→−Inf was 5.77)
  expect_gt(
    suppressWarnings(ks_auc(df, val = c, time = t, type = "log-trapez")),
    6.5
  )
})

## ─────────────────────────────────────────────────────────────────────────────
## Grouped output
## ─────────────────────────────────────────────────────────────────────────────

test_that("grouped result is a data.frame with grouping + AUC columns", {
  df  <- data.frame(id = c("A","A","B","B"), c = c(0,4,0,6), t = c(0,1,0,1))
  res <- ks_auc(df, by = "id", val = c, time = t)
  expect_s3_class(res, "data.frame")
  expect_true(all(c("id", "AUC") %in% names(res)))
  expect_equal(nrow(res), 2L)
})

test_that("grouped: one row per unique group", {
  df  <- data.frame(id = rep(c("A","B","C"), each = 3L),
                    c  = c(0,4,2, 0,6,3, 0,2,1),
                    t  = rep(c(0,1,2), times = 3L))
  res <- ks_auc(df, by = "id", val = c, time = t)
  expect_equal(nrow(res), 3L)
  expect_setequal(res$id, c("A","B","C"))
})

test_that("grouped AUC values are correct", {
  ## A: (0+4)*1/2 + (4+1)*1/2 = 2 + 2.5 = 4.5
  ## B: (0+6)*1/2 + (6+2)*1/2 = 3 + 4.0 = 7.0
  df  <- data.frame(id   = c("A","A","A","B","B","B"),
                    conc = c(0, 4, 1,  0, 6, 2),
                    time = c(0, 1, 2,  0, 1, 2))
  res <- ks_auc(df, by = "id", val = conc, time = time)
  expect_equal(res$AUC[res$id == "A"], 4.5, tolerance = tol)
  expect_equal(res$AUC[res$id == "B"], 7.0, tolerance = tol)
})

test_that("two grouping variables produce one row per unique combination", {
  df <- data.frame(
    id  = c("S1","S1","S2","S2"),
    trt = c("A", "A", "B", "B"),
    c   = c(0, 4, 0, 6),
    t   = c(0, 1, 0, 1)
  )
  res <- ks_auc(df, by = c("id", "trt"), val = c, time = t)
  expect_equal(nrow(res), 2L)
  expect_true(all(c("id", "trt", "AUC") %in% names(res)))
})

## ─────────────────────────────────────────────────────────────────────────────
## Sorting robustness
## ─────────────────────────────────────────────────────────────────────────────

test_that("unsorted input gives same AUC as sorted input", {
  df_sorted   <- data.frame(c = c(0, 4, 2), t = c(0, 1, 2))
  df_unsorted <- df_sorted[c(3L, 1L, 2L), ]
  expect_equal(ks_auc(df_unsorted, val = c, time = t),
               ks_auc(df_sorted,   val = c, time = t),
               tolerance = tol)
})

test_that("grouped with interleaved subject rows sorts correctly", {
  ## Rows alternate between subjects: s2-t1, s1-t0, s2-t3, s1-t2
  ## s1: c=4,2 at t=0,2  → (4+2)*2/2 = 6
  ## s2: c=3,1 at t=1,3  → (3+1)*2/2 = 4
  df <- data.frame(id = c("s2","s1","s2","s1"),
                   c  = c(3,   4,   1,   2),
                   t  = c(1,   0,   3,   2))
  res <- ks_auc(df, by = "id", val = c, time = t)
  expect_equal(res$AUC[res$id == "s1"], 6, tolerance = tol)
  expect_equal(res$AUC[res$id == "s2"], 4, tolerance = tol)
})

## ─────────────────────────────────────────────────────────────────────────────
## Tibble input
## ─────────────────────────────────────────────────────────────────────────────

test_that("accepts tibble input", {
  df <- tibble::tibble(c = c(0, 4, 2), t = c(0, 1, 2))
  expect_equal(ks_auc(df, val = c, time = t), 5, tolerance = tol)
})

## ─────────────────────────────────────────────────────────────────────────────
## Non-uniform time intervals
## ─────────────────────────────────────────────────────────────────────────────

test_that("handles non-uniform time intervals correctly", {
  ## (0+4)*1/2 + (4+2)*1/2 + (2+1)*2/2 + (1+0)*4/2 = 2+3+3+2 = 10
  df <- data.frame(conc = c(0, 4, 2, 1, 0), time = c(0, 1, 2, 4, 8))
  expect_equal(ks_auc(df, val = conc, time = time), 10, tolerance = tol)
})

## ─────────────────────────────────────────────────────────────────────────────
## Default type is "trapez"
## ─────────────────────────────────────────────────────────────────────────────

test_that("default type is 'trapez' (linear trapezoidal)", {
  df <- data.frame(c = 0:4, t = 0:4)
  expect_equal(ks_auc(df, val = c, time = t),
               ks_auc(df, val = c, time = t, type = "trapez"),
               tolerance = tol)
})
