#' Multivariate normality tests (Mardia, energy)
#'
#' Mardia's skewness and kurtosis tests are implemented in base R (verified
#' against `QuantPsyc::mult.norm`); the energy test (`energy::mvnorm.etest`)
#' is attached automatically when the suggested \pkg{energy} package is
#' installed, and silently skipped otherwise.
#'
#' @param x A numeric matrix or data frame (rows = observations). `NA` rows
#'   are dropped.
#' @param R Number of energy-test replicates.
#' @param seed Integer seed for the energy permutation (reproducibility).
#' @return A list with `mardia` (a `2 x 3` matrix: Beta-hat, kappa, p-val;
#'   `NULL` if the sample is too small), `energy` (or `NULL` when the
#'   \pkg{energy} package is missing), and `n`, `p`.
#' @details
#' Mardia: under multivariate normality, `A = n b1_p / 6` is
#' chi-squared with `p(p+1)(p+2)/6` df, and the standardized `b2_p` is
#' standard normal. The energy test is a consistent omnibus alternative;
#' with `n < p + 2` Mardia's test is not defined and `NULL` is returned.
#' @examplesIf requireNamespace("energy", quietly = TRUE)
#' set.seed(0)
#' dat <- data.frame(x1 = rnorm(50), x2 = rnorm(50), x3 = rnorm(50))
#' out <- ks_mv_normality(dat)
#' out$mardia
#' out$energy$statistic
#' @name ks_mv_normality
#' @importFrom stats var na.omit pchisq qchisq pnorm
#' @importFrom cli cli_abort
#' @export
ks_mv_normality <- function(x, R = 999, seed = NULL) {
  x <- stats::na.omit(as.matrix(x))
  if (!is.numeric(x))
    cli::cli_abort("{.arg x} must be numeric.")
  n <- nrow(x); p <- ncol(x)

  mardia <- NULL
  if (n >= p + 2L) {
    s <- stats::var(x)
    dfchi <- p * (p + 1) * (p + 2) / 6
    Q <- diag(n) - matrix(1 / n, n, n)
    g <- Q %*% x %*% solve(s) %*% t(x) %*% Q
    b1p <- sum(g^3) / n^2
    b2p <- sum(diag(g)^2) / n
    k1  <- n * b1p / 6
    k2  <- (b2p - p * (p + 2)) / sqrt(8 * p * (p + 2) / n)
    mardia <- matrix(
      c(b1p, k1, 1 - stats::pchisq(k1, dfchi),
        b2p, k2, 2 * (1 - stats::pnorm(abs(k2)))),
      nrow = 2L, ncol = 3L, byrow = TRUE,
      dimnames = list(c("Skewness", "Kurtosis"), c("Beta-hat", "kappa", "p-val"))
    )
  }

  energy <- NULL
  if (requireNamespace("energy", quietly = TRUE)) {
    if (!is.null(seed)) set.seed(seed)
    energy <- energy::mvnorm.etest(x, R = R)
  }

  list(mardia = mardia, energy = energy, n = n, p = p)
}
