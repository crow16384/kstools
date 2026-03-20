#' Smoothed weight of evidence (SWOE) for categorical predictors
#'
#' Encodes each level of a categorical variable with a smoothed log-odds of the
#' response, relative to the overall response rate.  Useful as a numeric
#' replacement for a factor when screening logistic-type models.
#'
#' @param data A \code{data.frame} (or \code{tibble}).
#' @param par Name of the predictor column (factor or coercible to grouping
#'   variable).  With \code{quoted = FALSE}, pass the column name unquoted
#'   (\code{ks_swoe(dt, sex, yn)}).
#' @param resp Name of the binary response column (0/1 or logical).  Unquoted
#'   unless \code{quoted = TRUE}.
#' @param quoted If \code{FALSE} (default), \code{par} and \code{resp} are
#'   captured with \code{substitute} and converted to column names.  If
#'   \code{TRUE}, \code{par} and \code{resp} must be character strings.
#' @param prior.n Pseudo-count (prior strength) for the empirical-Bayes-style
#'   smoothing in the logit; the original implementation used \code{24}.
#'
#' @details
#' Let \eqn{\rho} be the overall mean of the response and, for each level
#' \eqn{k} of \code{par}, let \eqn{e_k} be the number of events (response = 1)
#' and \eqn{n_k} the number of non-missing responses.  The smoothed logit for
#' level \eqn{k} is
#' \deqn{\log \frac{e_k + \rho \cdot m}{n_k - e_k + (1-\rho)\cdot m}}
#' with \eqn{m = }\code{prior.n}.  A global logit \eqn{\log(\rho/(1-\rho))} is
#' appended internally for completeness; row values are taken by matching each
#' row's \code{par} level to the named level logits.
#'
#' If \eqn{\rho \in \{0,1\}}, the global logit is undefined; the function clamps
#' \eqn{\rho} to \eqn{(\varepsilon, 1-\varepsilon)} for that term only, with a
#' warning.
#'
#' @return A numeric vector of length \code{nrow(data)} (unnamed), giving the
#'   SWOE score for each row's level of \code{par}.
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
#' ks_swoe(dt, sex, yn)
#' ks_swoe(dt, par = "sex", resp = "yn", quoted = TRUE)
#' @name ks_swoe
#' @export
ks_swoe <- function(data, par, resp, quoted = FALSE, prior.n = 24) {
  if (!inherits(data, "data.frame"))
    stop("'data' must be a data.frame or tibble")

  if (!quoted) {
    par  <- deparse(substitute(par))
    resp <- deparse(substitute(resp))
  }

  if (!par %in% names(data))
    stop("Column not found in 'data': ", par)
  if (!resp %in% names(data))
    stop("Column not found in 'data': ", resp)

  y <- data[[resp]]
  f <- data[[par]]

  if (!is.numeric(y) && !is.logical(y))
    stop("'resp' must be numeric or logical (typically 0/1)")
  y <- as.numeric(y)

  rho_raw <- mean(y, na.rm = TRUE)
  if (is.na(rho_raw))
    stop("response '", resp, "' is all NA")

  if (rho_raw <= 0 || rho_raw >= 1) {
    warning(
      "Overall response mean is ",
      rho_raw,
      "; global logit is undefined at the boundary. ",
      "Using an epsilon-clamped rate for SWOE (finite scores)."
    )
  }

  rho1 <- min(max(rho_raw, .Machine$double.eps), 1 - .Machine$double.eps)

  events <- tapply(y, f, sum, na.rm = TRUE)
  freq   <- tapply(y, f, function(x) sum(!is.na(x)))

  logit <- log((events + rho1 * prior.n) / (freq - events + (1 - rho1) * prior.n))
  logit.other <- log(rho1 / (1 - rho1))

  xx <- c(logit, logit.other)
  names(xx)[length(xx)] <- ".global"

  key <- as.character(f)
  v   <- xx[match(key, names(xx))]

  unname(v)
}
