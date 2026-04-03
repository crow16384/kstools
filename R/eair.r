#' Miettinen-Nurminen CI for the difference of two incidence rates
#'
#' Computes the difference (Test \eqn{-} Control) of two exposure-adjusted
#' incidence rates (EAIRs) and its confidence interval using the score-based
#' method of Miettinen & Nurminen (1985).
#'
#' @details
#' The CI is found by inverting the score statistic.  For each candidate
#' rate difference \eqn{\theta}, the pooled estimate
#' \eqn{\tilde\lambda_2} is obtained by solving the MLE equations under
#' the constraint \eqn{\lambda_1 - \lambda_2 = \theta}, and the score
#' chi-squared is compared to \eqn{\chi^2_{1,1-\alpha}}.  The two roots of
#' this equation (found via \code{\link[rootSolve]{uniroot.all}}) are the
#' lower and upper confidence bounds.
#'
#' The search interval for roots is fixed at \code{c(-1, 1)}, appropriate
#' when incidence rates are measured in events per person-time unit and are
#' well below 1.  If rates exceed 1, expand the interval manually by
#' calling \code{\link[rootSolve]{uniroot.all}} directly.
#'
#' The function is vectorised: when \code{n1}, \code{n2}, \code{T1},
#' \code{T2} are vectors of equal length, one row per element is returned.
#'
#' @param n1,n2 Non-negative integer event counts for Test and Control.
#' @param T1,T2 Positive person-time at risk for Test and Control.
#' @param alpha Significance level for the two-sided CI. Default \code{0.05}.
#' @return A matrix with one row per input pair and three named columns:
#'   \code{delta} (point estimate), \code{lcl} (lower bound),
#'   \code{ucl} (upper bound).  Bounds are \code{NA} when the score
#'   equation has fewer than two roots in \code{(-1, 1)}.
#' @references
#'   Miettinen O, Nurminen M (1985). Comparative analysis of two rates.
#'   \emph{Statistics in Medicine}, 4(2), 213–226.
#' @seealso \code{\link{ks_eairdiff_strata_mn}},
#'   \code{\link[rootSolve]{uniroot.all}}
#' @examples
#' ## Single comparison: Test rate = 0.10, Control rate = 0.05
#' ks_eairdiff_mn(n1 = 10, n2 = 5, T1 = 100, T2 = 100)
#'
#' ## Equal rates → delta = 0, CI straddles zero
#' ks_eairdiff_mn(n1 = 5, n2 = 5, T1 = 100, T2 = 100)
#'
#' ## Vectorised over multiple time-point comparisons
#' ks_eairdiff_mn(
#'   n1 = c(10, 20, 8),
#'   n2 = c( 5, 15, 6),
#'   T1 = c(100, 150, 90),
#'   T2 = c(100, 150, 90)
#' )
#'
#' ## 90 %% CI
#' ks_eairdiff_mn(n1 = 10, n2 = 5, T1 = 100, T2 = 100, alpha = 0.10)
#' @name ks_eairdiff_mn
#' @importFrom cli cli_abort cli_warn
#' @importFrom rootSolve uniroot.all
#' @importFrom stats qchisq
#' @export
ks_eairdiff_mn <- function(n1, n2, T1, T2, alpha = 0.05) {

  if (any(T1 <= 0) || any(T2 <= 0))
    cli::cli_abort("{.arg T1} and {.arg T2} must be strictly positive.")
  if (alpha <= 0 || alpha >= 1)
    cli::cli_abort("{.arg alpha} must be in (0, 1).")

  ## Score equation: returns 0 at each CI bound
  score_eq <- function(theta, n1, n2, T1, T2) {
    lambda_bar    <- (n1 + n2) / (T1 + T2)
    lambda_tilda2 <- (lambda_bar - theta +
                        sqrt((lambda_bar - theta)^2 +
                               4 * n2 * theta / (T1 + T2))) / 2
    lambda_tilda1 <- lambda_tilda2 + theta
    V_tilda       <- lambda_tilda1 / T1 + lambda_tilda2 / T2
    stats::qchisq(1 - alpha, df = 1) -
      (n1 / T1 - n2 / T2 - theta)^2 / V_tilda
  }

  ## Per-pair CI (scalar inputs)
  ci_one <- function(n1, n2, T1, T2) {
    ci <- rootSolve::uniroot.all(score_eq, c(-1, 1),
                                  n1 = n1, n2 = n2, T1 = T1, T2 = T2)
    if (length(ci) < 2L) {
      cli::cli_warn("Score equation has fewer than 2 roots; CI bounds set to {.val NA}.")
      ci <- c(NA_real_, NA_real_)
    }
    c(delta = n1 / T1 - n2 / T2, lcl = ci[1L], ucl = ci[2L])
  }

  Vectorize(ci_one)(n1, n2, T1, T2) |> t()
}


#' Stratified Miettinen-Nurminen CI for the difference of incidence rates
#'
#' Stratified version of \code{\link{ks_eairdiff_mn}}: pools evidence
#' across strata using inverse-variance-like weights and returns a single
#' CI for the common rate difference.
#'
#' @details
#' Each stratum \eqn{j} contributes a weight
#' \eqn{W_j = (\tilde\lambda_{1j} / (\tilde\lambda_{2j} T_{1j}) + 1/T_{2j})^{-1}}
#' and the combined score statistic is
#' \eqn{\sum_j W_j^2 V_j^{-1} \cdot (\sum_j W_j (r_{1j} - r_{2j} - \theta))^2}.
#'
#' The point estimate \code{delta} is the unweighted arithmetic mean of the
#' stratum-specific rate differences.
#'
#' Strata with \code{NA} in any of their inputs are silently dropped via
#' \code{na.rm = TRUE} in the stratum sums.
#'
#' @param n1,n2 Numeric vectors of event counts per stratum (Test, Control).
#' @param T1,T2 Numeric vectors of person-time per stratum (Test, Control).
#'   All four vectors must have the same length.
#' @param alpha Significance level for the two-sided CI. Default \code{0.05}.
#' @return A named numeric vector of length 3:
#'   \code{delta} (point estimate), \code{lcl} (lower bound),
#'   \code{ucl} (upper bound).
#' @references
#'   Miettinen O, Nurminen M (1985). Comparative analysis of two rates.
#'   \emph{Statistics in Medicine}, 4(2), 213–226.
#' @seealso \code{\link{ks_eairdiff_mn}}
#' @examples
#' ## Two strata
#' ks_eairdiff_strata_mn(
#'   n1 = c(10,  5),
#'   n2 = c( 5,  3),
#'   T1 = c(100, 80),
#'   T2 = c(100, 70)
#' )
#'
#' ## Single stratum — equivalent to ks_eairdiff_mn() up to point estimate
#' ks_eairdiff_strata_mn(n1 = 10, n2 = 5, T1 = 100, T2 = 100)
#'
#' ## 90 %% CI
#' ks_eairdiff_strata_mn(
#'   n1 = c(10, 5), n2 = c(5, 3),
#'   T1 = c(100, 80), T2 = c(100, 70),
#'   alpha = 0.10
#' )
#' @name ks_eairdiff_strata_mn
#' @importFrom cli cli_abort cli_warn
#' @importFrom rootSolve uniroot.all
#' @importFrom stats qchisq
#' @export
ks_eairdiff_strata_mn <- function(n1, n2, T1, T2, alpha = 0.05) {

  if (length(n1) != length(n2) ||
      length(n1) != length(T1) ||
      length(n1) != length(T2))
    cli::cli_abort("{.arg n1}, {.arg n2}, {.arg T1}, {.arg T2} must all have the same length.")
  if (any(T1 <= 0, na.rm = TRUE) || any(T2 <= 0, na.rm = TRUE))
    cli::cli_abort("{.arg T1} and {.arg T2} must be strictly positive.")
  if (alpha <= 0 || alpha >= 1)
    cli::cli_abort("{.arg alpha} must be in (0, 1).")

  chi_alpha <- stats::qchisq(1 - alpha, df = 1)

  ## Combined score equation across all strata; theta is scalar
  score_strata <- function(theta) {
    lambda_bar    <- (n1 + n2) / (T1 + T2)
    lambda_tilda2 <- (lambda_bar - theta +
                        sqrt((lambda_bar - theta)^2 +
                               4 * n2 * theta / (T1 + T2))) / 2
    lambda_tilda1 <- lambda_tilda2 + theta
    W       <- (lambda_tilda1 / (lambda_tilda2 * T1) + 1 / T2)^(-1)
    V_tilda <- lambda_tilda1 / T1 + lambda_tilda2 / T2
    V       <- sum(V_tilda * W^2, na.rm = TRUE)
    num     <- sum(W * (n1 / T1 - n2 / T2 - theta), na.rm = TRUE)^2
    chi_alpha - num / V
  }

  ## Vectorise over theta for uniroot.all
  score_vec <- function(theta) sapply(theta, score_strata)

  ci <- rootSolve::uniroot.all(score_vec, c(-1, 1))

  if (length(ci) < 2L) {
    cli::cli_warn("Score equation has fewer than 2 roots; CI bounds set to {.val NA}.")
    ci <- c(NA_real_, NA_real_)
  }

  c(delta = mean(n1 / T1 - n2 / T2, na.rm = TRUE),
    lcl   = ci[1L],
    ucl   = ci[2L])
}
