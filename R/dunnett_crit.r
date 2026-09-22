#' Exact Dunnett critical value (multivariate-t)
#'
#' Computes the two- or one-sided Dunnett critical value for `k`
#' comparisons against a common control by inverting the equicorrelated
#' multivariate Student-t CDF (`mnormt::sadmvt` / `mnormt::pmt` via
#' \code{uniroot}). For balanced designs the control-correlation is
#' `rho = 1/2`. Numerically equivalent to `nCDunnett::qNCDun` (2.5067 vs
#' 2.506845 at `p = 0.95, df = 24, k = 3`).
#'
#' @param p Coverage probability (e.g. `0.95`).
#' @param df Error degrees of freedom.
#' @param k Number of treatments compared to the control (`k >= 2`).
#' @param rho Correlation between pairs of contrasts; `1/2` for balanced
#'   Dunnett designs.
#' @param type `"two-sided"` (default) or `"one-sided"`.
#' @return A single numeric critical value.
#' @examplesIf requireNamespace("mnormt", quietly = TRUE)
#' ks_dunnett_crit(p = 0.95, df = 24, k = 3, rho = 0.5)
#' ks_dunnett_crit(p = 0.95, df = 24, k = 3, rho = 0.5, type = "one-sided")
#' @name ks_dunnett_crit
#' @importFrom stats qt uniroot
#' @importFrom cli cli_abort
#' @export
ks_dunnett_crit <- function(p, df, k, rho = 0.5, type = c("two-sided", "one-sided")) {
  type <- match.arg(type)
  if (length(p) != 1L || p <= 0 || p >= 1)
    cli::cli_abort("{.arg p} must be a single value in (0, 1).")
  if (k < 2)
    cli::cli_abort("{.arg k} must be at least 2.")
  if (!requireNamespace("mnormt", quietly = TRUE))
    cli::cli_abort("Package {.pkg mnormt} is required; install it first.")

  alpha <- 1 - p
  S <- matrix(rho, nrow = k, ncol = k) + (1 - rho) * diag(k)

  if (type == "two-sided") {
    alpha <- alpha / 2
    f <- function(d)
      mnormt::sadmvt(df = df, lower = rep(-d, k), upper = rep(d, k),
                     mean = rep(0, k), S = S, maxpts = 2000 * k) - p
  } else {
    f <- function(d) mnormt::pmt(d, S = S, df = df) - p
  }
  stats::uniroot(f, lower = stats::qt(1 - alpha, df),
                 upper = stats::qt(1 - alpha / k, df),
                 tol = .Machine$double.eps, maxiter = 5000)$root
}
