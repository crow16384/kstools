#' Smoothed weight of evidence (SWOE) for categorical predictors
#'
#' Encodes each level of a categorical variable with a smoothed log-odds of the
#' response, relative to the overall response rate.  Useful as a numeric
#' replacement for a factor when screening logistic-type models. Designed for
#' use inside \code{dplyr::mutate()}.
#'
#' @param x Categorical predictor (factor, character, or other grouping vector).
#' @param y Binary response (numeric 0/1 or logical), same length as \code{x}.
#' @param prior.n Pseudo-count (prior strength) for the empirical-Bayes-style
#'   smoothing in the logit; the original implementation used \code{24}.
#'
#' @details
#' Let \eqn{\rho} be the overall mean of the response and, for each level
#' \eqn{k} of \code{x}, let \eqn{e_k} be the number of events (response = 1)
#' and \eqn{n_k} the number of non-missing responses.  The smoothed logit for
#' level \eqn{k} is
#' \deqn{\log \frac{e_k + \rho \cdot m}{n_k - e_k + (1-\rho)\cdot m}}
#' with \eqn{m = }\code{prior.n}.  A global logit \eqn{\log(\rho/(1-\rho))} is
#' appended internally for completeness; row values are taken by matching each
#' row's \code{x} level to the named level logits.
#'
#' If \eqn{\rho \in \{0,1\}}, the global logit is undefined; the function clamps
#' \eqn{\rho} to \eqn{(\varepsilon, 1-\varepsilon)} for that term only, with a
#' warning.
#'
#' @return A numeric vector of length \code{length(x)} (unnamed), giving the
#'   SWOE score for each row's level of \code{x}.
#'
#' @seealso \code{\link[stats]{glm}} for logistic regression
#' @references
#' The construction follows common “weight of evidence” encodings with
#' Dirichlet-style smoothing; the choice \code{prior.n = 24} matches the
#' historical default in this package.
#'
#' @examples
#' set.seed(1234)
#' dt <- data.frame(
#'   yn  = rbinom(50, 1, 0.3),
#'   sex = factor(rbinom(50, 1, 0.55), levels = c(0, 1), labels = c("F", "M"))
#' )
#' ks_swoe(dt$sex, dt$yn)
#' if (requireNamespace("dplyr", quietly = TRUE)) {
#'   dplyr::mutate(dt, sex_swoe = ks_swoe(sex, yn))
#' }
#' @name ks_swoe
#' @importFrom cli cli_abort cli_warn
#' @export
ks_swoe <- function(x, y, prior.n = 24) {
  if (length(x) != length(y))
    cli::cli_abort("{.arg x} and {.arg y} must have the same length.")

  if (!is.numeric(y) && !is.logical(y))
    cli::cli_abort("{.arg y} must be numeric or logical (typically 0/1).")
  y <- as.numeric(y)

  rho_raw <- mean(y, na.rm = TRUE)
  if (is.na(rho_raw))
    cli::cli_abort("{.arg y} is all {.val NA}.")

  if (rho_raw <= 0 || rho_raw >= 1) {
    cli::cli_warn(c(
      "Overall response mean is {.val {rho_raw}}; global logit is undefined at the boundary.",
      "i" = "Using an epsilon-clamped rate for SWOE (finite scores)."
    ))
  }

  rho1 <- min(max(rho_raw, .Machine$double.eps), 1 - .Machine$double.eps)

  events <- tapply(y, x, sum, na.rm = TRUE)
  freq   <- tapply(y, x, function(z) sum(!is.na(z)))

  logit <- log((events + rho1 * prior.n) / (freq - events + (1 - rho1) * prior.n))
  logit.other <- log(rho1 / (1 - rho1))

  xx <- c(logit, logit.other)
  names(xx)[length(xx)] <- ".global"

  key <- as.character(x)
  v   <- xx[match(key, names(xx))]

  unname(v)
}
