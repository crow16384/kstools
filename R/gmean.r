#' Geometric mean and confidence interval
#'
#' Computes the geometric mean of a numeric vector and an approximate
#' confidence interval based on the Student \eqn{t}-distribution on the
#' \strong{log scale} (assuming log-transformed values are approximately normal).
#'
#' @param x Numeric vector (non-negative values; see \strong{Details}).
#' @param na.rm Logical. If \code{TRUE}, \code{NA}s are removed first.
#' @param zero.propagate Logical. If \code{TRUE}, the presence of any zero in
#'   \code{x} forces a geometric mean of \code{0} (and \code{NA} confidence
#'   limits). If \code{FALSE}, zeros are excluded from the mean (only strictly
#'   positive values are used).
#' @param alpha Significance level for the two-sided CI (coverage nominal
#'   \eqn{1-\alpha}). Must lie in \eqn{(0, 1)}.
#'
#' @details
#' The geometric mean of positive values \eqn{x_1,\ldots,x_k} is
#' \eqn{\exp(\frac{1}{k}\sum_{i=1}^k \log x_i)}.
#'
#' If \code{zero.propagate = FALSE}, only \eqn{x_i > 0} are used. If there are
#' no positive values, the geometric mean is \code{0} (all zeros) or
#' \code{NA} (empty or invalid input after removing \code{NA}s).
#'
#' Negative values are not allowed: the function returns \code{NaN} for
#' \code{geom.mean} (and \code{CI} components) because the geometric mean is not
#' defined in the reals.
#'
#' The confidence interval is \eqn{\exp(\bar y \pm t_{1-\alpha/2,\,df}\, s/\sqrt{n})}
#' where \eqn{y = \log x} for the positive observations used, \eqn{s} is the
#' sample SD of \eqn{y}, \eqn{n} is their count, and \eqn{df = n-1}.  For
#' \eqn{n < 2} the limits are \code{NA}.
#'
#' @return A list with components:
#'   \describe{
#'     \item{\code{geom.mean}}{Geometric mean (numeric scalar).}
#'     \item{\code{geom.sd}}{Geometric standard deviation,
#'       \eqn{\exp(\mathrm{sd}(\log x))} on the positive data used (same as
#'       common PK notation; \code{NA} if not defined).}
#'     \item{\code{geom.mean.lcl}}{Lower limit of the \eqn{100(1-\alpha)}\% CI.}
#'     \item{\code{geom.mean.ucl}}{Upper limit of the \eqn{100(1-\alpha)}\% CI.}
#'   }
#'
#' @references
#'   Kirkwood, T. B. (1979). Geometric means and measures of dispersion.
#'   \emph{Biometrics}, \strong{35}(4), 908--909.
#'
#' @seealso \code{\link[base]{log}}, \code{\link[stats]{quantile}}
#' @importFrom stats qt sd
#' @examples
#' x <- abs(rnorm(100,10,5))
#' ks_geom_mean(x)
#' @name ks_geom_mean
#' @importFrom cli cli_abort
#' @export
ks_geom_mean <- function(x, na.rm = TRUE, zero.propagate = FALSE, alpha = 0.05) {
  if (!is.numeric(x))
    cli::cli_abort("{.arg x} must be numeric.")
  if (length(alpha) != 1L || is.na(alpha) || alpha <= 0 || alpha >= 1)
    cli::cli_abort("{.arg alpha} must be a single value in (0, 1).")

  nan <- function() list(
    geom.mean = NaN,
    geom.sd   = NaN,
    geom.mean.lcl = NaN,
    geom.mean.ucl = NaN
  )

  if (na.rm)
    x <- x[!is.na(x)]
  else if (anyNA(x))
    cli::cli_abort("Missing values in {.arg x} and {.arg na.rm} is {.val FALSE}.")

  if (!length(x))
    return(list(
      geom.mean = NA_real_, geom.sd = NA_real_,
      geom.mean.lcl = NA_real_, geom.mean.ucl = NA_real_
    ))

  if (any(x < 0, na.rm = TRUE))
    return(nan())

  if (isTRUE(zero.propagate) && any(x == 0, na.rm = FALSE)) {
    return(list(
      geom.mean = 0,
      geom.sd   = NA_real_,
      geom.mean.lcl = NA_real_,
      geom.mean.ucl = NA_real_
    ))
  }

  xp <- x[x > 0]
  if (!length(xp)) {
    return(list(
      geom.mean = 0,
      geom.sd   = NA_real_,
      geom.mean.lcl = NA_real_,
      geom.mean.ucl = NA_real_
    ))
  }

  y  <- log(xp)
  n  <- length(xp)
  gm <- exp(mean(y))

  # Geometric SD: exp(sd(log x)) — Kirkwood / PK convention
  gsd <- if (n >= 2L) exp(stats::sd(y)) else NA_real_

  if (n < 2L) {
    return(list(
      geom.mean = gm,
      geom.sd   = gsd,
      geom.mean.lcl = NA_real_,
      geom.mean.ucl = NA_real_
    ))
  }

  se  <- stats::sd(y) / sqrt(n)
  tq  <- stats::qt(1 - alpha / 2, df = n - 1L)
  lcl <- exp(mean(y) - tq * se)
  ucl <- exp(mean(y) + tq * se)

  list(
    geom.mean = gm,
    geom.sd   = gsd,
    geom.mean.lcl = lcl,
    geom.mean.ucl = ucl
  )
}
