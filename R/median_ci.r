#' Confidence interval for the median
#'
#' Computes the sample median and a confidence interval using one of three
#' approaches: bootstrap (\pkg{boot}), Olive's simple median interval, or a
#' normal approximation based on the binomial distribution of ranks (the
#' \code{"z"} method).
#'
#' @param x Numeric vector.
#' @param na.rm Logical. If \code{TRUE}, \code{NA}s are removed before
#'   computing (default \code{TRUE}).
#' @param alpha Significance level; the interval has nominal coverage
#'   \eqn{1 - \alpha}. Must be in \eqn{(0, 1)}.
#' @param method Character: \code{"boot"} (default), \code{"olive"}, or
#'   \code{"z"}. See \strong{Details}.
#' @param R Number of bootstrap replicates when \code{method = "boot"}.
#' @param seed Integer passed to \code{\link[base]{set.seed}} immediately
#'   before bootstrap resampling (for reproducibility). The default \code{0L}
#'   fixes the RNG state; use another integer for a different stream.
#' @param type Integer \code{1}--\code{9}: quantile definition for the
#'   reported median when \code{method = "z"} (passed to
#'   \code{\link[stats]{quantile}}). Default \code{2} matches SAS \code{PROC
#'   UNIVARIATE} / Hyndman & Fan type 2.
#'
#' @details
#' \describe{
#'   \item{\code{boot}}{Uses \code{\link[boot]{boot}} with the sample median as
#'     the statistic and \code{\link[boot]{boot.ci}} to produce Basic, Normal,
#'     percentile, and BCa intervals (when BCa is defined).}
#'   \item{\code{olive}}{Implements David Olive's simple median CI (order
#'     statistics with a \eqn{t}-based multiplier). Requires at least two
#'     non-missing observations.}
#'   \item{\code{z}}{Approximate CI from the normal approximation to the
#'     binomial number of observations below the population median: bounds are
#'     the order statistics with ranks \eqn{n/2 \pm z_{1-\alpha/2}\sqrt{n}/2}
#'     (rounded inward). The reported \code{Median} uses \code{quantile(...,
#'     type)}.}
#' }
#'
#' @return A named numeric vector. The first element is always \code{Median}.
#'   Remaining elements depend on \code{method}:
#'   \describe{
#'     \item{\code{boot}}{\code{Basic.LCI}, \code{Basic.UCI}, \code{Normal.LCI},
#'       \code{Normal.UCI}, \code{Percent.LCI}, \code{Percent.UCI},
#'       \code{BCa.LCI}, \code{BCa.UCI} (BCa may be \code{NA} in small samples).}
#'     \item{\code{olive}}{\code{Olive.LCI}, \code{Olive.UCI}.}
#'     \item{\code{z}}{\code{z.LCI}, \code{z.UCI} (limits are order statistics
#'       of the sorted data).}
#'   }
#'
#' @references
#' Olive, D. J. (2005). \emph{Applied robust statistics}. Preprint.
#' (median CI procedure.)
#'
#' Davison, A. C. and Hinkley, D. V. (1997). \emph{Bootstrap Methods and Their
#' Applications}. Cambridge University Press.
#'
#' @seealso \code{\link[stats]{median}}, \code{\link[stats]{quantile}}
#' @importFrom stats median quantile qt qnorm
#' @importFrom boot boot boot.ci
#' @examples
#' x <- rnorm(100, 56, 2.5)
#' ks_median_ci(x, method = "olive")
#'
#' vv <- c(8, 11, 12, 13, 15, 17, 19, 20, 21, 21, 22, 23, 25, 26, 28)
#' ks_median_ci(vv, method = "boot", R = 1000, seed = 1L)
#' ks_median_ci(vv, method = "olive")
#' ks_median_ci(vv, method = "olive", alpha = 0.1)
#' ks_median_ci(vv, method = "z")
#' ks_median_ci(vv, method = "z", alpha = 0.1)
#' @name ks_median_ci
#' @importFrom cli cli_abort
#' @export
ks_median_ci <- function(x,
                         na.rm = TRUE,
                         alpha = 0.05,
                         method = c("boot", "olive", "z"),
                         R = 10000L,
                         seed = 0L,
                         type = 2L) {

  method <- match.arg(method)

  if (length(alpha) != 1L || is.na(alpha) || alpha <= 0 || alpha >= 1)
    cli::cli_abort("{.arg alpha} must be a single value in (0, 1).")
  if (!is.logical(na.rm) || length(na.rm) != 1L)
    cli::cli_abort("{.arg na.rm} must be a single logical value.")
  if (method == "boot" && (!is.numeric(R) || length(R) != 1L || R < 1L))
    cli::cli_abort("{.arg R} must be a positive integer.")
  if (!is.numeric(type) || length(type) != 1L || type < 1L || type > 9L)
    cli::cli_abort("{.arg type} must be a single integer from 1 to 9.")

  if (!is.numeric(x))
    cli::cli_abort("{.arg x} must be numeric.")
  if (!na.rm && anyNA(x))
    cli::cli_abort("Missing values in {.arg x} and {.arg na.rm} is {.val FALSE}.")

  if (na.rm)
    x <- x[!is.na(x)]

  if (!length(x))
    cli::cli_abort("No non-missing observations in {.arg x}.")

  switch(method,
         boot   = .median_boot(x, alpha = alpha, R = as.integer(R), seed = seed),
         olive  = .median_olive(x, na.rm = na.rm, alpha = alpha),
         z      = .median_z(x, na.rm = na.rm, alpha = alpha, type = as.integer(type)))
}


.median_boot <- function(x, alpha, R, seed) {
  boot.median <- function(data, indices) {
    stats::median(data[indices])
  }

  set.seed(seed)
  med <- boot::boot(x, boot.median, R = R)
  result <- boot::boot.ci(med, conf = 1 - alpha)

  bca_lcl <- if (!is.null(result$bca)) result$bca[4L] else NA_real_
  bca_ucl <- if (!is.null(result$bca)) result$bca[5L] else NA_real_
  c(
    Median      = stats::median(x),
    Basic.LCI   = result$basic[4L],
    Basic.UCI   = result$basic[5L],
    Normal.LCI  = result$normal[2L],
    Normal.UCI  = result$normal[3L],
    Percent.LCI = result$percent[4L],
    Percent.UCI = result$percent[5L],
    BCa.LCI     = bca_lcl,
    BCa.UCI     = bca_ucl
  )
}


.median_olive <- function(y, na.rm, alpha) {
  n <- length(y)
  if (n < 2L)
    cli::cli_abort('Method {.val olive} requires at least two non-missing observations.')

  ysort <- sort(y)
  nhalf <- floor(n / 2)
  med   <- stats::median(y, na.rm = na.rm)

  Ln <- nhalf - ceiling(sqrt(n / 4))
  Un <- n - Ln
  SE <- 0.5 * (ysort[Un] - ysort[Ln + 1L])

  p  <- Un - Ln - 1L
  tq <- stats::qt(p = 1 - alpha / 2, df = p)
  c(
    Median    = med,
    Olive.LCI = med - tq * SE,
    Olive.UCI = med + tq * SE
  )
}


.median_z <- function(x, na.rm, alpha, type) {
  xs  <- sort(as.numeric(x))
  n   <- length(xs)
  med <- as.numeric(stats::quantile(x, probs = 0.5, na.rm = na.rm, type = type, names = FALSE))

  zc <- stats::qnorm(1 - alpha / 2)
  hw <- zc * sqrt(n) / 2
  i_lo <- max(1L, as.integer(ceiling(n / 2 - hw)))
  i_hi <- min(n, as.integer(floor(n / 2 + hw)))

  if (i_lo > i_hi) {
    j <- (n + 1L) %/% 2L
    i_lo <- max(1L, j)
    i_hi <- min(n, j + 1L)
  }

  c(Median = med, z.LCI = xs[i_lo], z.UCI = xs[i_hi])
}
