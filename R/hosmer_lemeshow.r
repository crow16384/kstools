#' Hosmer–Lemeshow goodness-of-fit test
#'
#' Groups fitted probabilities into quantile-based bins, cross-tabulates
#' observed versus expected successes/failures, and returns the chi-squared
#' statistic with `g - 2` degrees of freedom (Hosmer & Lemeshow, 1980).
#' A high p-value indicates no evidence of miscalibration.
#'
#' @param y Binary response (0/1), same length as `yhat`.
#' @param yhat Fitted probabilities from a logistic model.
#' @param g Number of groups (default 10 = deciles).
#' @return A list with components \code{chisq} and \code{p.value}.
#' @references
#' Hosmer, D. and Lemeshow, S. (1980). Goodness of fit tests for the
#' multiple logistic regression model. \emph{Biometrics}, \strong{36},
#' 1045--1054.
#' @examples
#' set.seed(1)
#' d <- data.frame(x = rnorm(200))
#' d$y <- rbinom(200, 1, plogis(0.8 * d$x))
#' m <- glm(y ~ x, binomial, data = d)
#' ks_hosmer_lemeshow(d$y, fitted(m))
#' @name ks_hosmer_lemeshow
#' @importFrom stats quantile pchisq
#' @importFrom cli cli_abort
#' @export
ks_hosmer_lemeshow <- function(y, yhat, g = 10) {
  y <- as.integer(y)
  if (length(y) != length(yhat))
    cli::cli_abort("{.arg y} and {.arg yhat} must have the same length.")
  if (!all(y %in% c(0L, 1L)))
    cli::cli_abort("{.arg y} must be binary (0/1).")
  if (g < 3 || g > length(y))
    cli::cli_abort("{.arg g} must be between 3 and n = {length(y)}.")

  cutyhat <- cut(yhat, breaks = stats::quantile(yhat, probs = seq(0, 1, 1 / g)),
                 include.lowest = TRUE)
  obs    <- stats::xtabs(cbind(1 - y, y) ~ cutyhat)
  expect <- stats::xtabs(cbind(1 - yhat, yhat) ~ cutyhat)
  keep   <- rowSums(obs) > 0
  chisq  <- sum((obs[keep, ] - expect[keep, ])^2 / expect[keep, ])
  df <- sum(keep) - 2L
  list(chisq = unname(chisq), p.value = unname(1 - stats::pchisq(chisq, df)), df = df)
}
