## SAS/STAT 12.3 User's Guide, Chapter 58: The MIANALYZE Procedure
## Compare kstools::mianalyze() against published formulas and examples.

tol <- 1e-10

`%||%` <- function(x, y) if (is.null(x)) y else x

## Absolute agreement helper (PDF tables are rounded).
expect_abs_equal <- function(got, expected, abs_tol, info = NULL) {
  expect_true(
    isTRUE(abs(got - expected) <= abs_tol),
    info = paste0(
      info %||% "",
      if (!is.null(info)) ": ",
      sprintf("got = %.10g, expected = %.10g, abs_tol = %g", got, expected, abs_tol)
    )
  )
}

## Reconstruct estimates/SEs with target between/within variances so we can
## feed mianalyze() when SAS only publishes pooled variance components.
make_mi_from_moments <- function(Qbar, Vb, Vw, m = 5L) {
  z <- seq_len(m) - mean(seq_len(m))
  z <- z / sqrt(sum(z^2) / (m - 1))
  list(est = as.numeric(Qbar + sqrt(Vb) * z), err = rep(sqrt(Vw), m))
}


test_that("SAS Table 58.2 relative efficiencies match RE = 1/(1+lambda/m)", {
  ## SAS/STAT 12.3, Table 58.2 (p. 4845)
  sas_re <- matrix(
    c(
      0.9677, 0.9375, 0.9091, 0.8571, 0.8108,
      0.9804, 0.9615, 0.9434, 0.9091, 0.8772,
      0.9901, 0.9804, 0.9709, 0.9524, 0.9346,
      0.9950, 0.9901, 0.9852, 0.9756, 0.9662
    ),
    nrow = 4L,
    byrow = TRUE,
    dimnames = list(
      m = c("3", "5", "10", "20"),
      lambda = c("10%", "20%", "30%", "50%", "70%")
    )
  )
  m_vals <- as.integer(rownames(sas_re))
  lambda_vals <- c(0.1, 0.2, 0.3, 0.5, 0.7)

  for (i in seq_along(m_vals)) {
    for (j in seq_along(lambda_vals)) {
      expect_abs_equal(
        1 / (1 + lambda_vals[j] / m_vals[i]),
        sas_re[i, j],
        abs_tol = 5e-5,
        info = sprintf("m=%d lambda=%s", m_vals[i], colnames(sas_re)[j])
      )
    }
  }
})


test_that("SAS text example: m=5 and r=10% yields vm = 484", {
  ## SAS/STAT 12.3, p. 4845: "with m = 5 and r = 10%, ... vm = 484"
  m <- 5
  r <- 0.10
  vm <- (m - 1) * (1 + 1 / r)^2
  expect_equal(vm, 484)

  ## Same via mianalyze: choose Vw, Vb so that r = (1+1/m) Vb / Vw = 0.10
  Vw <- 1
  Vb <- r * Vw / (1 + 1 / m)
  d <- make_mi_from_moments(Qbar = 0, Vb = Vb, Vw = Vw, m = m)
  out <- mianalyze(d$est, d$err)
  expect_equal(out$r, r, tolerance = tol)
  expect_equal(out$df, 484, tolerance = tol)
})


test_that("SAS Example 58.1 Oxygen with EDF=30 matches published output", {
  ## Output 58.1.1 inputs (means and SEs); EDF=30 (n=31 means)
  ## Tolerances allow truncated inputs in the PDF tables.
  est <- c(47.0120, 47.2407, 47.4995, 47.1485, 47.0042)
  err <- c(0.95984, 0.93540, 1.00766, 0.95439, 0.96528)
  out <- mianalyze(est, err, edf = 30)

  expect_abs_equal(out$Estimate, 47.180993, 1e-4, "Estimate")
  expect_abs_equal(out$StdErr, 0.990266, 1e-4, "StdErr")
  expect_abs_equal(out$Vb, 0.041478, 1e-4, "Vb")
  expect_abs_equal(out$Vw, 0.930853, 1e-4, "Vw")
  expect_abs_equal(out$Vt, 0.980626, 1e-4, "Vt")
  expect_abs_equal(out$df, 26.298, 5e-3, "df")
  expect_abs_equal(out$r, 0.053471, 1e-4, "r")
  expect_abs_equal(out$lambda, 0.051977, 1e-4, "lambda")
  expect_abs_equal(out$re, 0.989712, 1e-4, "re")
  expect_abs_equal(out$lcl, 45.1466, 1e-3, "lcl")
  expect_abs_equal(out$ucl, 49.2154, 1e-3, "ucl")
  expect_abs_equal(out$t, 47.64, 5e-3, "t")
  expect_lt(out$pval, 1e-4)
})


test_that("SAS Example 58.1 RunTime with EDF=30 matches published output", {
  est <- c(10.4441, 10.5040, 10.5922, 10.5279, 10.4913)
  err <- c(0.28520, 0.26661, 0.26302, 0.26405, 0.27275)
  out <- mianalyze(est, err, edf = 30)

  expect_abs_equal(out$Estimate, 10.511906, 1e-4, "Estimate")
  expect_abs_equal(out$StdErr, 0.276910, 1e-4, "StdErr")
  expect_abs_equal(out$Vb, 0.002948, 1e-4, "Vb")
  expect_abs_equal(out$Vw, 0.073142, 1e-4, "Vw")
  expect_abs_equal(out$Vt, 0.076679, 1e-4, "Vt")
  expect_abs_equal(out$df, 26.503, 5e-3, "df")
  expect_abs_equal(out$r, 0.048365, 1e-4, "r")
  expect_abs_equal(out$lambda, 0.047147, 1e-4, "lambda")
  expect_abs_equal(out$re, 0.990659, 1e-4, "re")
  expect_abs_equal(out$lcl, 9.9432, 1e-3, "lcl")
  expect_abs_equal(out$ucl, 11.0806, 1e-3, "ucl")
  expect_abs_equal(out$t, 37.96, 5e-3, "t")
})


test_that("SAS Example 58.1 RunPulse with EDF=30 matches published output", {
  est <- c(171.216, 171.244, 171.909, 171.146, 172.072)
  err <- c(1.59910, 1.75638, 1.85795, 1.75011, 1.84807)
  out <- mianalyze(est, err, edf = 30)

  expect_abs_equal(out$Estimate, 171.517500, 1e-3, "Estimate")
  expect_abs_equal(out$StdErr, 1.828591, 1e-3, "StdErr")
  expect_abs_equal(out$Vb, 0.191086, 1e-3, "Vb")
  expect_abs_equal(out$Vw, 3.114442, 1e-4, "Vw")
  expect_abs_equal(out$Vt, 3.343744, 1e-3, "Vt")
  expect_abs_equal(out$df, 25.463, 5e-3, "df")
  expect_abs_equal(out$r, 0.073626, 1e-4, "r")
  expect_abs_equal(out$lambda, 0.070759, 1e-4, "lambda")
  expect_abs_equal(out$re, 0.986046, 1e-4, "re")
  expect_abs_equal(out$lcl, 167.7549, 5e-3, "lcl")
  expect_abs_equal(out$ucl, 175.2801, 5e-3, "ucl")
  expect_abs_equal(out$t, 93.80, 5e-3, "t")
})


test_that("SAS Getting Started / Example 58.3 Rubin pooling and EDF=28 df", {
  ## Figure 58.3 / Output 58.3.2 variance information (m = 5).
  ## Per-imputation PARMS are only partially printed; reconstruct moments.
  cases <- list(
    Intercept = list(
      Q = 90.837440, Vb = 45.529229, Vw = 76.543614,
      Vt = 131.178689, r = 0.713777, lambda = 0.461277, re = 0.915537,
      df_rubin = 23.059, df_edf28 = 9.1917, SE = 11.453327,
      lcl_edf28 = 65.01034, ucl_edf28 = 116.6645
    ),
    RunTime = list(
      Q = -3.032870, Vb = 0.019390, Vw = 0.106220,
      Vt = 0.129487, r = 0.219051, lambda = 0.192620, re = 0.962905,
      df_rubin = 123.88, df_edf28 = 18.311, SE = 0.359844,
      lcl_edf28 = -3.78795, ucl_edf28 = -2.2778
    ),
    RunPulse = list(
      Q = -0.068578, Vb = 0.001007, Vw = 0.002537,
      Vt = 0.003746, r = 0.476384, lambda = 0.355376, re = 0.933641,
      df_rubin = 38.419, df_edf28 = 12.137, SE = 0.061204,
      lcl_edf28 = -0.20176, ucl_edf28 = 0.0646
    )
  )

  for (nm in names(cases)) {
    p <- cases[[nm]]
    d <- make_mi_from_moments(p$Q, p$Vb, p$Vw, m = 5L)
    out0 <- mianalyze(d$est, d$err)
    out1 <- mianalyze(d$est, d$err, edf = 28)

    expect_abs_equal(out0$Estimate, p$Q, 1e-8, paste(nm, "Estimate"))
    expect_abs_equal(out0$Vb, p$Vb, 1e-8, paste(nm, "Vb"))
    expect_abs_equal(out0$Vw, p$Vw, 1e-8, paste(nm, "Vw"))
    ## Vt/r/df tolerances reflect SAS print rounding of Vb/Vw (esp. RunPulse).
    expect_abs_equal(out0$Vt, p$Vt, 1e-5, paste(nm, "Vt"))
    expect_abs_equal(out0$StdErr, p$SE, 1e-5, paste(nm, "SE"))
    expect_abs_equal(out0$r, p$r, 1e-4, paste(nm, "r"))
    expect_abs_equal(out0$lambda, p$lambda, 1e-4, paste(nm, "lambda"))
    expect_abs_equal(out0$re, p$re, 1e-4, paste(nm, "re"))
    expect_abs_equal(out0$df, p$df_rubin, 1e-2, paste(nm, "df_rubin"))
    expect_abs_equal(out1$df, p$df_edf28, 1e-2, paste(nm, "df_edf28"))
    expect_abs_equal(out1$lcl, p$lcl_edf28, 5e-3, paste(nm, "lcl"))
    expect_abs_equal(out1$ucl, p$ucl_edf28, 5e-3, paste(nm, "ucl"))
    expect_lt(out1$df, out0$df, label = nm)
  }
})
