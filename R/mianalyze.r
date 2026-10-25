#' Analogue of SAS PROC MIANALYZE (Rubin pooling)
#'
#' Pools point estimates and standard errors across multiple imputations
#' according to Rubin's rules.  Degrees of freedom follow the Barnard-Rubin
#' (1999) small-sample adjustment when complete-data df are supplied via
#' \code{edf} (equivalent to the SAS \code{EDF=} option).
#'
#' @param est Numeric vector of point estimates from each imputation.
#' @param err Numeric vector of corresponding standard errors.
#' @param alpha Significance level for confidence intervals. Default \code{0.05}.
#' @param theta0 Null value for hypothesis test \eqn{H_0: \theta = \theta_0}.
#' @param edf Complete-data degrees of freedom (positive numeric scalar or
#'   \code{Inf}).
#'   Equivalent to the SAS \code{EDF=} option in \code{PROC MIANALYZE}.
#'   When finite, the Barnard-Rubin (1999) adjusted degrees of freedom
#'   \eqn{v_m^*} are used instead of the Rubin (1987) large-sample
#'   \eqn{v_m}.  Default \code{Inf} (no adjustment, Rubin large-sample df).
#' @param v0 Deprecated alias for \code{edf}.  Kept for backward
#'   compatibility; ignored when \code{edf} is also supplied.
#'
#' @return An object of class \code{ks_mianalyze} with components:
#' \describe{
#'   \item{Estimate}{Pooled estimate.}
#'   \item{StdErr}{Pooled standard error.}
#'   \item{m}{Number of imputations.}
#'   \item{Vb}{Between-imputation variance.}
#'   \item{Vw}{Within-imputation variance.}
#'   \item{Vt}{Total variance.}
#'   \item{df}{Degrees of freedom (adjusted when \code{edf} is finite).}
#'   \item{r}{Relative increase in variance due to nonresponse.}
#'   \item{lambda}{Fraction of missing information.}
#'   \item{re}{Relative efficiency.}
#'   \item{lcl, ucl}{Two-sided confidence limits for \code{Estimate}.}
#'   \item{alpha}{Alpha used for CI.}
#'   \item{theta0}{Null value used in hypothesis test.}
#'   \item{edf}{Complete-data degrees of freedom used.}
#'   \item{minim, maxim}{Min/max of input \code{est}.}
#'   \item{t}{Test statistic for \eqn{H_0}.}
#'   \item{pval}{Two-sided p-value.}
#' }
#'
#' @details
#' Let \eqn{Q_i} and \eqn{U_i} be estimate and variance from imputation \eqn{i}.
#' The pooled estimate is \eqn{\bar{Q} = m^{-1}\sum_i Q_i};
#' within variance \eqn{\bar{U} = m^{-1}\sum_i U_i};
#' between variance \eqn{B = (m-1)^{-1}\sum_i (Q_i-\bar{Q})^2};
#' total variance \eqn{T = \bar{U} + (1 + 1/m)B}.
#'
#' Rubin's (1987) large-sample degrees of freedom are
#' \eqn{v_m = (m-1)(1 + \bar{U}/((1+m^{-1})B))^2}.  When the complete-data
#' degrees of freedom \eqn{v_0} are small and the fraction of missing
#' information is modest, \eqn{v_m} can greatly exceed \eqn{v_0}, which is
#' inappropriate.  The Barnard-Rubin (1999) adjustment computes
#' \eqn{v_m^* = (1/v_m + 1/\hat{v}_{obs})^{-1}} where
#' \eqn{\hat{v}_{obs} = (1-\gamma) v_0 (v_0+1)/(v_0+3)} and
#' \eqn{\gamma = (1+m^{-1})B/T}.
#'
#' When the within-imputation variance \eqn{\bar{U}} is exactly zero,
#' \code{df}, \code{r}, \code{lambda}, \code{re}, the confidence limits and
#' the \eqn{t}-test are reported as \code{NA} and a warning is issued.
#' This mirrors \code{PROC MIANALYZE}, which warns per zero standard error
#' and prints \code{"."} for those quantities, computing no inference in
#' that case - with or without \code{EDF=} - even when the
#' between-imputation variance is positive. Validated against a live SAS
#' PROC MIANALYZE run; the probe tooling is deliberately kept outside the
#' package.
#'
#' @references
#' Barnard, J. and Rubin, D. B. (1999). Small-sample degrees of freedom with
#'   multiple imputation. \emph{Biometrika}, 86, 948--955.
#'
#' Rubin, D. B. (1987). \emph{Multiple Imputation for Nonresponse in Surveys}.
#'   Wiley.
#'
#' SAS Institute Inc. (2013). \emph{SAS/STAT 12.3 User's Guide}. Chapter 58,
#'   The MIANALYZE Procedure.
#'
#' @seealso
#' \code{vignette("mianalyze", package = "kstools")} for worked examples and
#' SAS comparisons.
#'
#' @param object A \code{ks_mianalyze} object (\code{summary} method).
#' @param x A \code{ks_mianalyze} object (\code{print} method).
#' @param ... Additional arguments, currently ignored.
#'
#' @examples
#' est <- c(0.345, 0.303, 0.298, 0.378)
#' err <- c(0.056, 0.101, 0.099, 0.034)
#' out <- mianalyze(est, err)
#' out
#'
#' ## Barnard-Rubin adjusted df (equivalent to SAS EDF=120)
#' mianalyze(est, err, edf = 120)
#' @name ks_mianalyze
#' @importFrom cli cli_abort
#' @importFrom stats pt qt
#' @export
ks_mianalyze <- function(est, err, alpha = 0.05, theta0 = 0, edf = Inf, v0) {
  if (!is.numeric(est) || !is.numeric(err))
    cli::cli_abort("{.arg est} and {.arg err} must be numeric vectors.")
  if (length(est) != length(err))
    cli::cli_abort("{.arg est} and {.arg err} must have the same length.")
  if (length(est) < 1L)
    cli::cli_abort("{.arg est} and {.arg err} must have at least one value.")
  if (anyNA(est) || anyNA(err) || any(!is.finite(est)) || any(!is.finite(err)))
    cli::cli_abort("{.arg est} and {.arg err} must contain only finite, non-missing values.")
  if (any(err < 0))
    cli::cli_abort("{.arg err} must be non-negative.")
  if (length(alpha) != 1L || is.na(alpha) || alpha <= 0 || alpha >= 1)
    cli::cli_abort("{.arg alpha} must be a single value in (0, 1).")
  if (length(theta0) != 1L || is.na(theta0) || !is.finite(theta0))
    cli::cli_abort("{.arg theta0} must be a single finite numeric value.")

  # Resolve edf / v0 (backward compatibility)
  if (!missing(v0)) {
    if (!missing(edf) && !identical(edf, Inf))
      cli::cli_abort("Specify either {.arg edf} or {.arg v0}, not both.")
    edf <- v0
  }
  if (length(edf) != 1L || is.na(edf) || edf <= 0)
    cli::cli_abort("{.arg edf} must be a single positive value or {.code Inf}.")

  # number of imputations
  m <- length(est)
  # Q.bar - average of the estimator
  Q_bar <- mean(est)
  # W.bar - within-imputation variance
  Vw <- mean(err^2)
  # Between imputation variance
  Vb <- if (m > 1L) sum((est - Q_bar)^2) / (m - 1) else 0
  # Total variance
  Vt <- Vw + Vb + Vb/m

  # SAS PROC MIANALYZE warns for every imputation whose StdErr is zero
  # (live SAS/STAT 15.3 validation, 2026-10-25; tooling kept off-package).
  zero_se <- which(err == 0)
  if (length(zero_se)) {
    wmsg <- paste0("Within-imputation StdErr is zero for imputation(s) ",
                   paste(zero_se, collapse = ", "), ".")
    if (Vw == 0)
      wmsg <- paste0(wmsg, " The within-imputation variance is 0: degrees of ",
                     "freedom, MI diagnostics and inference are reported as ",
                     "NA, mirroring SAS PROC MIANALYZE (which prints '.' and ",
                     "computes neither, even when the between-imputation ",
                     "variance is positive or EDF= is supplied).")
    cli::cli_warn(wmsg)
  }

  # Rubin's (1987) degrees of freedom
  if (Vb == 0 && Vw == 0) {
    r <- 0
    df <- Inf
  } else {
    # Relative increase in variance
    r <- if (Vw == 0) Inf else (1 + 1 / m) * Vb / Vw
    df <- if (Vb == 0) Inf else (m-1)*(1+(Vw/(Vb+Vb/m)))^2
  }

  # fraction fo missing information
  lambda <- if (is.infinite(r)) {
    1
  } else if (is.infinite(df)) {
    r / (r + 1)
  } else {
    (r + 2 / (df + 3)) / (r + 1)
  }
  # v.obs - for adjusted DF
  gamma <- if (Vt == 0) 0 else (1 + 1 / m) * Vb / Vt

  # Barnard-Rubin (1999) small-sample adjustment (SAS EDF= option)
  if (is.finite(edf)) {
    v_obs <- (1 - gamma) * edf * (edf + 1) / (edf + 3)
    df <- if (is.infinite(df)) v_obs else 1 / (1 / df + 1 / v_obs)
  }
  # Pooled Std Error
  err_pool <- sqrt(Vt)

  # SAS-parity gate: PROC MIANALYZE reports DF, RIVar, FracMiss, RelEff,
  # confidence limits and the t-test as missing (".") whenever the pooled
  # within-imputation variance W is exactly zero - with or without EDF=.
  # Mirror that instead of falling back to the degenerate df = m - 1.
  infer_missing <- (Vw == 0)
  if (infer_missing) {
    df     <- NA_real_
    r      <- NA_real_
    lambda <- NA_real_
  }

  crit <- if (is.na(df)) NA_real_ else stats::qt(1 - alpha / 2, df = df)
  # Relative efficiency
  re <- if (is.na(lambda)) NA_real_ else 1 / (1 + lambda / m)
  # Range
  minim <- min(est)
  maxim <- max(est)

  delta <- Q_bar - theta0
  t_val <- if (infer_missing || err_pool == 0) NA_real_ else delta / err_pool

  p <- if (is.na(t_val)) NA_real_ else 2 * stats::pt(abs(t_val), df = df, lower.tail = FALSE)

  res <- list(
    Estimate = Q_bar,
    StdErr = err_pool,
    m = m,
    Vb = Vb,
    Vw = Vw,
    Vt = Vt,
    df = df,
    r = r,
    lambda = lambda,
    re = re,
    lcl = Q_bar - crit * err_pool,
    ucl = Q_bar + crit * err_pool,
    alpha = alpha,
    theta0 = theta0,
    edf = edf,
    minim = minim,
    maxim = maxim,
    t = t_val,
    pval = p
  )

  class(res) <- c("ks_mianalyze", "list")
  res
}


#' @rdname ks_mianalyze
#' @export
mianalyze <- function(est, err, alpha = 0.05, theta0 = 0, edf = Inf, v0) {
  if (!missing(v0) && !missing(edf) && !identical(edf, Inf))
    cli::cli_abort("Specify either {.arg edf} or {.arg v0}, not both.")
  if (!missing(v0) && missing(edf)) {
    ks_mianalyze(est = est, err = err, alpha = alpha, theta0 = theta0, v0 = v0)
  } else {
    ks_mianalyze(est = est, err = err, alpha = alpha, theta0 = theta0, edf = edf)
  }
}


#' @rdname ks_mianalyze
#' @export
summary.ks_mianalyze <- function(object, ...) {
  variance_tbl <- data.frame(
    Between = object$Vb,
    Within  = object$Vw,
    Total   = object$Vt,
    DF      = object$df,
    check.names = FALSE
  )

  diagnostics_tbl <- data.frame(
    `Relative Increase in Variance` = object$r,
    `Fraction Missing Information`  = object$lambda,
    `Relative Efficiency`           = object$re,
    check.names = FALSE
  )

  estimates_tbl <- data.frame(
    Estimate = object$Estimate,
    `Std Error` = object$StdErr,
    LCL = object$lcl,
    UCL = object$ucl,
    DF = object$df,
    check.names = FALSE
  )

  tests_tbl <- data.frame(
    Minimum = object$minim,
    Maximum = object$maxim,
    Theta0  = object$theta0,
    Statistic = object$t,
    PValue = object$pval,
    check.names = FALSE
  )

  structure(
    list(
      variance = variance_tbl,
      diagnostics = diagnostics_tbl,
      estimates = estimates_tbl,
      tests = tests_tbl,
      m = object$m,
      alpha = object$alpha,
      edf = object$edf
    ),
    class = "summary.ks_mianalyze"
  )
}


#' @export
print.ks_mianalyze <- function(x, ...) {
  s <- summary(x)
  adj <- if (is.finite(s$edf)) " (Barnard-Rubin adjusted)" else ""
  
  cat(sprintf("\n\n***Variance information (%d Imputations)***\n", s$m))
  cat("Between\t\tWithin\t\tTotal\t\tDF", adj, "\n", sep = "")
  cat("-------\t\t------\t\t-----\t\t--\n")
  cat(sprintf("%.6f\t%.6f\t%.6f\t%.1f\n\n", 
      s$variance$Between, s$variance$Within, s$variance$Total, s$variance$DF))

  cat("Relative\tFraction\n")
  cat("Increase\tMissing\t\tRelative\n")
  cat("in Variance\tInformation\tEfficiency\n")
  cat("-----------\t-----------\t----------\n")
  cat(sprintf("%.6f\t%.6f\t%.6f\n", 
      s$diagnostics$`Relative Increase in Variance`,
      s$diagnostics$`Fraction Missing Information`,
      s$diagnostics$`Relative Efficiency`))

  cat(sprintf("\n***Parameter estimates (%d Imputations)***\n", s$m))
  cat(sprintf("Estimate\tStd Error\t%.2f%% Confidence Limits\tDF\n", 100 * (1 - s$alpha)))
  cat("--------\t---------\t------------------------\t--\n")
  cat(sprintf("%.6f\t%.6f\t%.6f\t%.6f\t%.1f\n", 
      s$estimates$Estimate, s$estimates$`Std Error`,
      s$estimates$LCL, s$estimates$UCL, s$estimates$DF))

  cat("\n\t\t\t\t\t\tt for H0\n")
  cat("Minimum\t\tMaximum\t\tTheta0\t\tParameter=Theta0\tPr>|t|\n")
  cat("-------\t\t-------\t\t------\t\t----------------\t------\n")
  cat(sprintf("%.6f\t%.6f\t%.2f\t\t%.4f\t\t\t%.4f\n", 
      s$tests$Minimum, s$tests$Maximum, s$tests$Theta0,
      s$tests$Statistic, s$tests$PValue))

  invisible(x)
}


#' @rdname ks_mianalyze
#' @importFrom knitr knit_print kable
#' @exportS3Method knitr::knit_print
knit_print.ks_mianalyze <- function(x, ...) {
  s <- summary(x)
  
  out <- c(
    sprintf("**Variance Information (%d Imputations)**\n\n", s$m),
    knitr::kable(s$variance, digits = 6),
    
    "\n\n",
    
    "**Missing Data Diagnostics**\n\n",
    knitr::kable(s$diagnostics, digits = 6),
    
    "\n\n",
    
    sprintf("**Parameter Estimates (%d Imputations)**\n\n", s$m),
    knitr::kable(s$estimates, digits = 6),
    
    "\n\n",
    
    "**Hypothesis Test**\n\n",
    knitr::kable(s$tests, digits = 6)
  )

  knitr::asis_output(paste(out, collapse = "\n"))
}
