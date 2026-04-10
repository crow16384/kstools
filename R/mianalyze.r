#' Analogue of SAS PROC MIANALYZE (Rubin pooling)
#'
#' Pools point estimates and standard errors across multiple imputations
#' according to Rubin's rules.
#'
#' @param est Numeric vector of point estimates from each imputation.
#' @param err Numeric vector of corresponding standard errors.
#' @param alpha Significance level for confidence intervals. Default \\code{0.05}.
#' @param theta0 Null value for hypothesis test \\eqn{H_0: theta = theta_0}.
#' @param v0 Optional complete-data degrees of freedom used for Barnard-Rubin
#'   style small-sample df adjustment.
#'
#' @return An object of class \\code{ks_mianalyze} with components:
#' \\describe{
#'   \\item{Estimate}{Pooled estimate.}
#'   \\item{StdErr}{Pooled standard error.}
#'   \\item{m}{Number of imputations.}
#'   \\item{Vb}{Between-imputation variance.}
#'   \\item{Vw}{Within-imputation variance.}
#'   \\item{Vt}{Total variance.}
#'   \\item{df}{Degrees of freedom.}
#'   \\item{r}{Relative increase in variance due to nonresponse.}
#'   \\item{lambda}{Fraction of missing information.}
#'   \\item{re}{Relative efficiency.}
#'   \\item{lcl, ucl}{Two-sided confidence limits for \\code{Estimate}.}
#'   \\item{alpha}{Alpha used for CI.}
#'   \\item{theta0}{Null value used in hypothesis test.}
#'   \\item{minim, maxim}{Min/max of input \\code{est}.}
#'   \\item{t}{Test statistic for \\eqn{H_0}.}
#'   \\item{pval}{Two-sided p-value.}
#' }
#'
#' @details
#' Let \\eqn{Q_i} and \\eqn{U_i} be estimate and variance from imputation \\eqn{i}.
#' The pooled estimate is \\eqn{\\bar{Q} = m^{-1}\\sum_i Q_i};
#' within variance \\eqn{\\bar{U} = m^{-1}\\sum_i U_i};
#' between variance \\eqn{B = (m-1)^{-1}\\sum_i (Q_i-\\bar{Q})^2};
#' total variance \\eqn{T = \\bar{U} + (1 + 1/m)B}.
#'
#' Degrees of freedom default to Rubin's large-sample expression and can be
#' adjusted using \\code{v0}.
#'
#' @references
#' Rubin, D. B. (1987). \\emph{Multiple Imputation for Nonresponse in Surveys}.
#' Wiley.
#'
#' @examples
#' est <- c(0.345, 0.303, 0.298, 0.378)
#' err <- c(0.056, 0.101, 0.099, 0.034)
#' out <- mianalyze(est, err)
#' out
#'
#' ## With finite complete-data df adjustment
#' mianalyze(est, err, v0 = 120)
#' @name ks_mianalyze
#' @importFrom cli cli_abort
#' @importFrom stats pt qt
#' @export
ks_mianalyze <- function(est, err, alpha = 0.05, theta0 = 0, v0) {
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

  has_v0 <- !missing(v0)
  if (has_v0) {
    if (length(v0) != 1L || is.na(v0) || !is.finite(v0) || v0 <= 0)
      cli::cli_abort("{.arg v0} must be a single positive finite value when provided.")
  }

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

  if (has_v0) {
    v_obs <- (1 - gamma) * v0 * (1 + v0) / (v0 + 3)
    df <- if (is.infinite(df)) v_obs else 1 / (1 / df + 1 / v_obs)
  }
  # Pooled Std Error
  err_pool <- sqrt(Vt)
  crit <- stats::qt(1 - alpha / 2, df = df)
  # Relative efficiency
  re <- 1 / (1 + lambda / m)
  # Range
  minim <- min(est)
  maxim <- max(est)

  delta <- Q_bar - theta0
  t_val <- if (err_pool == 0) {
    if (delta == 0) NA_real_ else sign(delta) * Inf
  } else {
    delta / err_pool
  }

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
mianalyze <- function(est, err, alpha = 0.05, theta0 = 0, v0) {
  ks_mianalyze(est = est, err = err, alpha = alpha, theta0 = theta0, v0 = v0)
}


#' @export
print.ks_mianalyze <- function(x, ...) {
  cat(sprintf("\n\n***Variance information (%d Imputations)***\n", x$m))
  cat("Between\t\tWithin\t\tTotal\t\tDF\n")
  cat("-------\t\t------\t\t-----\t\t--\n")
  cat(sprintf("%.6f\t%.6f\t%.6f\t%.1f\n\n", x$Vb, x$Vw, x$Vt, x$df))

  cat("Relative\tFraction\n")
  cat("Increase\tMissing\t\tRelative\n")
  cat("in Variance\tInformation\tEfficiency\n")
  cat("-----------\t-----------\t----------\n")
  cat(sprintf("%.6f\t%.6f\t%.6f\n", x$r, x$lambda, x$re))

  cat(sprintf("\n***Parameter estimates (%d Imputations)***\n", x$m))
  cat(sprintf("Estimate\tStd Error\t%.2f%% Confidence Limits\tDF\n", 100 * (1 - x$alpha)))
  cat("--------\t---------\t------------------------\t--\n")
  cat(sprintf("%.6f\t%.6f\t%.6f\t%.6f\t%.1f\n", x$Estimate, x$StdErr, x$lcl, x$ucl, x$df))

  cat("\n\t\t\t\t\t\tt for H0\n")
  cat("Minimum\t\tMaximum\t\tTheta0\t\tParameter=Theta0\tPr>|t|\n")
  cat("-------\t\t-------\t\t------\t\t----------------\t------\n")
  cat(sprintf("%.6f\t%.6f\t%.2f\t\t%.4f\t\t\t%.4f\n", x$minim, x$maxim, x$theta0, x$t, x$pval))

  invisible(x)
}
