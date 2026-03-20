#' Simulate longitudinal data with AR(1) within-subject errors
#'
#' Generates a random sample of subjects with random intercepts and slopes,
#' irregular observation times, and Gaussian AR(1) serially correlated residuals.
#' The result is an \code{\link[nlme]{groupedData}} object suitable for
#' exploratory plots or simulation studies.
#'
#' @param n Number of subjects (\eqn{\ge 1}).
#' @param beta0 Population mean intercept (fixed effect on the log-time scale).
#' @param beta1 Population mean slope (coefficient of \eqn{\log(\mathrm{obs})}).
#' @param ar.val Autoregressive coefficient \eqn{\phi} for the within-subject
#'   errors (must lie strictly between \eqn{-1} and \eqn{1}).
#' @param sigma Marginal standard deviation of the AR(1) error (after the
#'   scaling described in \strong{Details}).
#' @param tau0,tau1 Standard deviations of random intercept and random slope.
#' @param tau01 Correlation between random intercept and slope (in \eqn{[-1,1]}).
#' @param m Maximum possible number of visits per subject (must be \eqn{\ge 4}).
#'   Each subject receives between 4 and \code{m} observations, always including
#'   time \code{obs = 1}.
#'
#' @details
#' Observation counts \eqn{p_i} are uniform on \eqn{\{4,\ldots,m\}} (rounded
#' from continuous uniforms).  Observation times are \eqn{1} plus a random
#' subset of \eqn{\{2,\ldots,m\}} of size \eqn{p_i-1}.
#'
#' Random effects \eqn{(b_{0i}, b_{1i})'} are bivariate normal with mean zero,
#' SDs \code{tau0}, \code{tau1} and correlation \code{tau01}.  Outcomes are
#' \deqn{y_{ij} = (\beta_0 + b_{0i}) + (\beta_1 + b_{1i})\log(t_{ij}) + \varepsilon_{ij}}
#' with \eqn{\varepsilon_{i\cdot}} an AR(1) Gaussian series.  Innovations are
#' scaled so that the marginal residual SD is \code{sigma}:
#' \code{arima.sim(...)} is multiplied by \eqn{\sigma\sqrt{1-\phi^2}}.
#'
#' @param seed Optional integer; if not \code{NULL}, passed to
#'   \code{\link[base]{set.seed}} before random draws (reproducibility).
#'
#' @return An \code{\link[nlme]{groupedData}} object (also inherits from
#'   \code{data.frame}) with columns \code{id}, \code{obs}, and \code{y}.
#'
#' @seealso \code{\link[stats]{arima.sim}}, \code{\link[MASS]{mvrnorm}},
#'   \code{\link[nlme]{groupedData}}
#' @importFrom stats arima.sim runif
#' @importFrom MASS mvrnorm
#' @examples
#' set.seed(1)
#' dt <- ks_simulate_ar1(
#'   n = 10, beta0 = 5, beta1 = 1, ar.val = 0.4, sigma = 2,
#'   tau0 = 1, tau1 = 0.5, tau01 = 0.2, m = 8, seed = 1L
#' )
#' head(dt)
#' @name ks_simulate_ar1
#' @export
ks_simulate_ar1 <- function(n,
                            beta0,
                            beta1,
                            ar.val = 0.4,
                            sigma,
                            tau0,
                            tau1,
                            tau01 = 0.3,
                            m,
                            seed = NULL) {

  if (!is.null(seed))
    set.seed(seed)

  if (length(n) != 1L || n < 1L)
    stop("'n' must be a positive integer")
  if (length(m) != 1L || m < 4L)
    stop("'m' must be an integer >= 4 (need at least 4 possible observation times)")
  if (abs(ar.val) >= 1)
    stop("'ar.val' must lie strictly between -1 and 1 for a stationary AR(1)")
  if (sigma <= 0 || tau0 < 0 || tau1 < 0)
    stop("'sigma', 'tau0', and 'tau1' must be non-negative ('sigma' strictly positive)")
  if (abs(tau01) > 1)
    stop("'tau01' must lie in [-1, 1]")

  ## number of observations per subject (uniform on 4..m)
  p <- round(stats::runif(n, min = 4, max = m))

  ## observation times: always 1, plus (p-1) distinct times from 2..m
  obs <- unlist(lapply(p, function(x) {
    c(1L, sort(sample(2:m, size = x - 1L, replace = FALSE)))
  }), use.names = FALSE)

  dat <- data.frame(id = rep(seq_len(n), times = p), obs = obs)

  mu <- c(0, 0)
  R  <- matrix(c(1, tau01, tau01, 1), nrow = 2L, ncol = 2L)
  tau_vec <- c(tau0, tau1)
  Sigma <- diag(tau_vec, nrow = 2L) %*% R %*% diag(tau_vec, nrow = 2L)
  U <- MASS::mvrnorm(n, mu = mu, Sigma = Sigma)

  scale_eps <- sqrt(1 - ar.val^2) * sigma
  dat$eij <- unlist(lapply(p, function(x) {
    stats::arima.sim(model = list(ar = ar.val), n = x) * scale_eps
  }), use.names = FALSE)

  dat$y <- (beta0 + rep(U[, 1L], times = p)) +
    (beta1 + rep(U[, 2L], times = p)) * log(dat$obs) +
    dat$eij

  dat$eij <- NULL

  nlme::groupedData(y ~ obs | id, data = dat)
}
