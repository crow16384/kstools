# Internal helper: Wilson score CI for a single proportion.
# Returns a named numeric vector: c(l, p, u).
.wilson_ci <- function(x, n, z) {
  p  <- x / n
  dl <- z * sqrt(z^2 + 4 * x * (n - x) / n)
  dn <- 2 * (n + z^2)
  c(l = (2 * x + z^2 - dl) / dn, p = p, u = (2 * x + z^2 + dl) / dn)
}


#' Newcombe Hybrid Score CI for a difference of two proportions
#'
#' Computes a confidence interval for \eqn{p_1 - p_2} using Newcombe's
#' Hybrid Score method (Newcombe, 1998, Method 10).  Each group's proportion
#' is first bounded by its Wilson score interval, and the two intervals are
#' then combined to yield the CI for the difference.
#'
#' @details
#' \strong{Algorithm} (Newcombe, 1998):
#' \enumerate{
#'   \item Compute the Wilson score CI \eqn{[l_i,\, u_i]} for each group at
#'     level \eqn{1-\alpha}:
#'     \deqn{l_i,\, u_i = \frac{2x_i + z^2 \mp z\sqrt{z^2 + 4x_i(n_i-x_i)/n_i}}{2(n_i + z^2)}}
#'   \item Form the CI for \eqn{\delta = p_1 - p_2}:
#'     \deqn{\mathrm{LCL} = \hat\delta - \sqrt{(p_1-l_1)^2 + (u_2-p_2)^2}}
#'     \deqn{\mathrm{UCL} = \hat\delta + \sqrt{(u_1-p_1)^2 + (p_2-l_2)^2}}
#' }
#' The function is vectorised: if vectors of length \eqn{k} are supplied,
#' each corresponding tuple \eqn{(x_{1i}, n_{1i}, x_{2i}, n_{2i})} is
#' processed independently and the result is a \eqn{k \times 3} matrix.
#'
#' @param x1 Integer vector of event counts for group 1 (\eqn{\ge 0}).
#' @param n1 Integer vector of sample sizes for group 1 (\eqn{> 0}).
#' @param x2 Integer vector of event counts for group 2 (\eqn{\ge 0}).
#' @param n2 Integer vector of sample sizes for group 2 (\eqn{> 0}).
#' @param alpha Significance level; scalar in \eqn{(0,1)}.  Defaults to
#'   \code{0.05} (95\% CI).
#' @return A numeric matrix with one row per input pair and three columns:
#'   \describe{
#'     \item{\code{delta}}{Observed difference \eqn{\hat p_1 - \hat p_2}.}
#'     \item{\code{lcl}}{Lower confidence limit.}
#'     \item{\code{ucl}}{Upper confidence limit.}
#'   }
#' @references
#'   Newcombe, R. G. (1998). Interval estimation for the difference between
#'   independent proportions: comparison of eleven methods.
#'   \emph{Statistics in Medicine}, \strong{17}(8), 873--890.
#'   \doi{10.1002/(SICI)1097-0258(19980430)17:8<873::AID-SIM779>3.0.CO;2-I}
#' @seealso \code{\link{ks_newcombe_hs_strata}},
#'   \code{\link{ks_eairdiff_mn}}
#' @examples
#' ## Single comparison
#' ks_newcombe_hs(36L, 54L, 41L, 56L, alpha = 0.10)
#'
#' ## Zero events in one group
#' ks_newcombe_hs(0L, 50L, 10L, 50L)
#'
#' ## Vectorised: three comparisons at once
#' ks_newcombe_hs(
#'   x1 = c(36L, 38L, 3L),
#'   n1 = c(54L, 57L, 86L),
#'   x2 = c(41L, 42L, 3L),
#'   n2 = c(56L, 57L, 93L),
#'   alpha = 0.10
#' )
#' @name ks_newcombe_hs
#' @importFrom cli cli_abort
#' @importFrom stats qnorm
#' @export
ks_newcombe_hs <- function(x1, n1, x2, n2, alpha = 0.05) {
  if (any(n1 <= 0, na.rm = TRUE) || any(n2 <= 0, na.rm = TRUE))
    cli::cli_abort("{.arg n1} and {.arg n2} must be positive.")
  if (any(x1 < 0 | x1 > n1, na.rm = TRUE) || any(x2 < 0 | x2 > n2, na.rm = TRUE))
    cli::cli_abort("{.arg x1} and {.arg x2} must satisfy 0 <= x <= n.")
  if (length(alpha) != 1L || is.na(alpha) || alpha <= 0 || alpha >= 1)
    cli::cli_abort("{.arg alpha} must be a single value in (0, 1).")

  z <- stats::qnorm(1 - alpha / 2)

  ci_one <- function(x1, n1, x2, n2) {
    c1  <- .wilson_ci(x1, n1, z)
    c2  <- .wilson_ci(x2, n2, z)
    d   <- c1["p"] - c2["p"]
    lcl <- d - sqrt((c1["p"] - c1["l"])^2 + (c2["u"] - c2["p"])^2)
    ucl <- d + sqrt((c1["u"] - c1["p"])^2 + (c2["p"] - c2["l"])^2)
    c(delta = unname(d), lcl = unname(lcl), ucl = unname(ucl))
  }

  do.call(rbind, mapply(ci_one, x1, n1, x2, n2,
                        SIMPLIFY = FALSE, USE.NAMES = FALSE))
}


#' Stratified Newcombe Hybrid Score CI for a difference of two proportions
#'
#' Extends Newcombe's Hybrid Score method to stratified data using
#' Mantel-Haenszel harmonic-mean weights.  Within each stratum the Wilson
#' score intervals are computed for both groups; the stratum-level
#' contributions are then pooled via weighted combination to produce a
#' single CI for the overall difference.
#'
#' @details
#' \strong{Algorithm}:
#' \enumerate{
#'   \item Compute Wilson CIs \eqn{[l_{1i},\,u_{1i}]} and
#'     \eqn{[l_{2i},\,u_{2i}]} for each stratum \eqn{i}.
#'   \item Assign stratum weights
#'     \eqn{W_i = n_{1i}\,n_{2i} / (n_{1i} + n_{2i})}
#'     (harmonic-mean / Mantel-Haenszel weights).
#'   \item Pooled point estimate:
#'     \eqn{\hat\delta = \sum W_i (p_{1i}-p_{2i}) / \sum W_i}.
#'   \item Pooled lower limit:
#'     \deqn{\mathrm{LCL} = \hat\delta -
#'       \sqrt{\frac{\sum W_i^2(p_{1i}-l_{1i})^2}{(\sum W_i)^2} +
#'             \frac{\sum W_i^2(u_{2i}-p_{2i})^2}{(\sum W_i)^2}}}
#'   \item Pooled upper limit: analogously.
#' }
#' A single stratum reduces to the un-stratified formula.
#'
#' @param x1 Integer vector of event counts for group 1, one element per
#'   stratum.
#' @param n1 Integer vector of sample sizes for group 1, one element per
#'   stratum (\eqn{> 0}).
#' @param x2 Integer vector of event counts for group 2, one element per
#'   stratum.
#' @param n2 Integer vector of sample sizes for group 2, one element per
#'   stratum (\eqn{> 0}).
#' @param alpha Significance level; scalar in \eqn{(0,1)}.  Defaults to
#'   \code{0.05} (95\% CI).
#' @return A named numeric vector of length 3:
#'   \describe{
#'     \item{\code{delta}}{Weighted pooled point estimate.}
#'     \item{\code{lcl}}{Lower confidence limit.}
#'     \item{\code{ucl}}{Upper confidence limit.}
#'   }
#' @references
#'   Newcombe, R. G. (1998). Interval estimation for the difference between
#'   independent proportions: comparison of eleven methods.
#'   \emph{Statistics in Medicine}, \strong{17}(8), 873--890.
#'   \doi{10.1002/(SICI)1097-0258(19980430)17:8<873::AID-SIM779>3.0.CO;2-I}
#' @seealso \code{\link{ks_newcombe_hs}}
#' @examples
#' ## Two-stratum example
#' ks_newcombe_hs_strata(
#'   x1 = c(36L, 10L), n1 = c(54L, 30L),
#'   x2 = c(41L,  8L), n2 = c(56L, 30L)
#' )
#'
#' ## Single stratum — identical to ks_newcombe_hs()
#' ks_newcombe_hs_strata(36L, 54L, 41L, 56L)
#' ks_newcombe_hs(36L, 54L, 41L, 56L)  # same result
#' @name ks_newcombe_hs_strata
#' @importFrom cli cli_abort
#' @importFrom stats qnorm
#' @export
ks_newcombe_hs_strata <- function(x1, n1, x2, n2, alpha = 0.05) {
  if (any(n1 <= 0, na.rm = TRUE) || any(n2 <= 0, na.rm = TRUE))
    cli::cli_abort("{.arg n1} and {.arg n2} must be positive.")
  if (any(x1 < 0 | x1 > n1, na.rm = TRUE) || any(x2 < 0 | x2 > n2, na.rm = TRUE))
    cli::cli_abort("{.arg x1} and {.arg x2} must satisfy 0 <= x <= n.")
  if (length(alpha) != 1L || is.na(alpha) || alpha <= 0 || alpha >= 1)
    cli::cli_abort("{.arg alpha} must be a single value in (0, 1).")

  z  <- stats::qnorm(1 - alpha / 2)
  c1 <- mapply(.wilson_ci, x1, n1, MoreArgs = list(z = z))  # 3 x k
  c2 <- mapply(.wilson_ci, x2, n2, MoreArgs = list(z = z))

  p1 <- c1["p", ]; l1 <- c1["l", ]; u1 <- c1["u", ]
  p2 <- c2["p", ]; l2 <- c2["l", ]; u2 <- c2["u", ]

  W  <- (n1 * n2) / (n1 + n2)
  SW <- sum(W)

  delta <- sum(W * (p1 - p2)) / SW
  lcl   <- delta - sqrt(sum(W^2 * (p1 - l1)^2) / SW^2 +
                        sum(W^2 * (u2 - p2)^2) / SW^2)
  ucl   <- delta + sqrt(sum(W^2 * (u1 - p1)^2) / SW^2 +
                        sum(W^2 * (p2 - l2)^2) / SW^2)

  c(delta = delta, lcl = lcl, ucl = ucl)
}
