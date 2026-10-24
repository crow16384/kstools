tol <- 1e-10


test_that("mianalyze computes Rubin pooled quantities", {
  est <- c(0.345, 0.303, 0.298, 0.378)
  err <- c(0.056, 0.101, 0.099, 0.034)

  out <- mianalyze(est, err)

  m <- length(est)
  Qbar <- mean(est)
  Vw <- mean(err^2)
  Vb <- sum((est - Qbar)^2) / (m - 1)
  Vt <- Vw + (1 + 1 / m) * Vb
  r <- (1 + 1 / m) * Vb / Vw
  df <- (m - 1) * (1 + 1 / r)^2

  expect_s3_class(out, "ks_mianalyze")
  expect_equal(out$Estimate, Qbar, tolerance = tol)
  expect_equal(out$Vw, Vw, tolerance = tol)
  expect_equal(out$Vb, Vb, tolerance = tol)
  expect_equal(out$Vt, Vt, tolerance = tol)
  expect_equal(out$df, df, tolerance = tol)
  expect_equal(out$StdErr, sqrt(Vt), tolerance = tol)

  crit <- stats::qt(1 - 0.05 / 2, df = df)
  expect_equal(out$lcl, Qbar - crit * sqrt(Vt), tolerance = tol)
  expect_equal(out$ucl, Qbar + crit * sqrt(Vt), tolerance = tol)
})


test_that("mianalyze validates inputs", {
  expect_error(mianalyze(c(1, 2), c(0.1)), regexp = "same length")
  expect_error(mianalyze(c(1, 2), c(0.1, -0.2)), regexp = "non-negative")
  expect_error(mianalyze(c(1, NA), c(0.1, 0.2)), regexp = "finite")
  expect_error(mianalyze(c(1, 2), c(0.1, 0.2), alpha = 1), regexp = "\u00280, 1\u0029")
  expect_error(mianalyze(c(1, 2), c(0.1, 0.2), v0 = 0), regexp = "positive")
  expect_error(mianalyze(c(1, 2), c(0.1, 0.2), edf = 0), regexp = "positive")
  expect_error(mianalyze(c(1, 2), c(0.1, 0.2), edf = 10, v0 = 10), regexp = "edf.*v0")
})


test_that("mianalyze handles m = 1", {
  out <- mianalyze(est = 2.5, err = 0.4)

  expect_equal(out$m, 1)
  expect_equal(out$Vb, 0)
  expect_equal(out$Vw, 0.16, tolerance = tol)
  expect_equal(out$Vt, 0.16, tolerance = tol)
  expect_true(is.infinite(out$df))
})


test_that("mianalyze applies Barnard-Rubin df adjustment via edf", {
  est <- c(0.345, 0.303, 0.298, 0.378)
  err <- c(0.056, 0.101, 0.099, 0.034)

  out0 <- mianalyze(est, err)
  out1 <- mianalyze(est, err, edf = 120)
  out2 <- mianalyze(est, err, v0 = 120)

  expect_true(is.finite(out1$df))
  expect_lt(out1$df, out0$df)
  expect_equal(out1$df, out2$df, tolerance = tol)
  expect_equal(out1$edf, 120)
  expect_true(is.infinite(out0$edf))

  # Verify Barnard-Rubin formula directly
  m <- length(est)
  Qbar <- mean(est)
  Vw <- mean(err^2)
  Vb <- sum((est - Qbar)^2) / (m - 1)
  Vt <- Vw + (1 + 1 / m) * Vb
  vm <- (m - 1) * (1 + Vw / ((1 + 1 / m) * Vb))^2
  gamma_val <- (1 + 1 / m) * Vb / Vt
  v_obs <- (1 - gamma_val) * 120 * 121 / 123
  df_adj <- 1 / (1 / vm + 1 / v_obs)
  expect_equal(out1$df, df_adj, tolerance = tol)
})


test_that("mianalyze returns two-sided p-value by absolute t", {
  out_pos <- mianalyze(est = c(1.0, 1.1, 0.9), err = c(0.1, 0.1, 0.1), theta0 = 0)
  out_neg <- mianalyze(est = c(-1.0, -1.1, -0.9), err = c(0.1, 0.1, 0.1), theta0 = 0)

  expect_equal(out_pos$pval, out_neg$pval, tolerance = tol)
  expect_true(out_pos$pval >= 0 && out_pos$pval <= 1)
})


test_that("mianalyze mirrors SAS PROC MIANALYZE when W = 0 (A1 live probe)", {
  # SAS C1/C2: W=0 -> warns per zero StdErr; DF, RIVar, FracMiss, RelEff,
  # CI and t/p all printed as "." -> kstools reports NA, keeps the
  # estimable quantities (Qbar, SE, B, T, min, max).
  w <- NULL
  out <- withCallingHandlers(
    mianalyze(est = c(1, 2, 3), err = c(0, 0, 0)),
    warning = function(x) {
      w[[length(w) + 1L]] <<- conditionMessage(x)
      invokeRestart("muffleWarning")
    })
  expect_match(paste(w, collapse = " "), "Within-imputation StdErr is zero")
  expect_false(is.na(w[[1]]))
  expect_true(is.na(out$df) && is.na(out$r) && is.na(out$lambda) && is.na(out$re))
  expect_true(is.na(out$lcl) && is.na(out$ucl))
  expect_true(is.na(out$t) && is.na(out$pval))
  expect_equal(out$Estimate, 2)
  expect_equal(out$Vw, 0)
  expect_equal(out$Vt, out$Vb * (1 + 1 / 3))
  expect_equal(c(out$minim, out$maxim), c(1, 3))

  # SAS C1: finite EDF does not rescue inference; no NaN/qt(df=0) warning
  out_edf <- suppressWarnings(mianalyze(c(0.3, 0.5), c(0, 0), edf = 50))
  expect_true(is.na(out_edf$df) && is.na(out_edf$lcl) && is.na(out_edf$pval))
  expect_equal(out_edf$Estimate, 0.4)
  expect_equal(out_edf$StdErr, sqrt(0.03))

  # SAS C4: THETA0 at the estimate still yields '.' inference when W = 0
  out_t0 <- suppressWarnings(mianalyze(c(0.3, 0.5), c(0, 0), edf = 50, theta0 = 0.4))
  expect_true(is.na(out_t0$t) && is.na(out_t0$pval))

  # SAS C3: W = 0 and B = 0 -> estimate/SE reported, inference missing
  out_c3 <- suppressWarnings(mianalyze(c(0.3, 0.3), c(0, 0), edf = 50))
  expect_equal(out_c3$Estimate, 0.3)
  expect_equal(out_c3$StdErr, 0)
  expect_true(is.na(out_c3$lcl) && is.na(out_c3$t))

  # Mixed zero StdErr with W > 0: SAS warns but computes normally here.
  w2 <- NULL
  out3 <- withCallingHandlers(mianalyze(c(0.5, 1.0), c(0, 0.1)),
    warning = function(x) {
      w2[[length(w2) + 1L]] <<- conditionMessage(x)
      invokeRestart("muffleWarning")
    })
  expect_match(paste(w2, collapse = " "), "imputation\\(s\\) 1")
  expect_true(is.finite(out3$df))
  expect_false(is.na(out3$lcl))

  # SAS C5 anchor (EDF=120): live MIANALYZE printed
  # DF=35.564  LCL=0.151165  UCL=0.510835  t=3.73  p=0.0007
  anchor <- mianalyze(c(0.345, 0.303, 0.298, 0.378),
                      c(0.056, 0.101, 0.099, 0.034), edf = 120)
  expect_equal(anchor$df, 35.564, tolerance = 5e-4)
  expect_equal(anchor$lcl, 0.151165, tolerance = 1e-5)
  expect_equal(anchor$ucl, 0.510835, tolerance = 1e-5)
  expect_equal(anchor$t, 3.73, tolerance = 1e-2)
  expect_lte(abs(anchor$pval - 0.0007), 5e-5)
})
