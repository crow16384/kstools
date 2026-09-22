#' Bootstrap confidence interval for a scalar statistic
#'
#' Convenience wrapper around \pkg{boot}: resamples, computes a user
#' statistic, and returns a percentile (BCa when defined) confidence
#' interval plus the point estimate — one line instead of the usual
#' `boot()` / `boot.ci()` plumbing in report code.
#'
#' @param x Data resampled by row: a vector, matrix, or data frame.
#' @param statistic Function with signature `function(data, indices)`
#'   returning a **single numeric value** (scalar). `indices` select rows
#'   of `x`.
#' @param R Number of bootstrap replicates (default `2000`).
#' @param conf Confidence level (default `0.95`).
#' @param seed Integer seed for reproducibility (default `NULL`).
#' @param type Interval type: `"perc"` (percentile, default), `"basic"`,
#'   `"norm"`, or `"bca"`.
#' @return A list with `estimate`, `std.error`, `lcl`, `ucl`, `type`,
#'   `conf.level`, the full `boot.ci` list in `$ci`, and the raw `boot`
#'   object in `$replicates`.
#' @details
#' The statistic must be scalar-valued; `ks_boot_ci()` checks the shape of
#' the replicate matrix and aborts otherwise. BCa can be undefined (e.g.
#' degenerate statistics on small samples) — the function then falls back
#' to the percentile interval with a warning.
#' @examples
#' set.seed(1)
#' x <- rnorm(50, 5, 2)
#' ks_boot_ci(x, function(d, i) mean(d[i]))
#'
#' # ratio of two columns (paired resampling)
#' d <- data.frame(a = rnorm(60, 5, 1), b = rnorm(60, 3, 1))
#' ks_boot_ci(d, function(dd, i) mean(dd$a[i]) / mean(dd$b[i]), R = 999,
#'            seed = 42)
#' @name ks_boot_ci
#' @importFrom boot boot boot.ci
#' @importFrom stats sd
#' @importFrom cli cli_abort cli_warn
#' @export
ks_boot_ci <- function(x, statistic, R = 2000L, conf = 0.95, seed = NULL,
                       type = c("perc", "basic", "norm", "bca")) {
  type <- match.arg(type)
  if (!is.function(statistic)) cli::cli_abort("{.arg statistic} must be a function.")
  if (length(conf) != 1L || conf <= 0 || conf >= 1)
    cli::cli_abort("{.arg conf} must be a single value in (0, 1).")
  if (length(R) != 1L || R < 2L)
    cli::cli_abort("{.arg R} must be a single integer >= 2.")

  if (!is.null(seed)) set.seed(seed)
  b   <- boot::boot(x, statistic, R = as.integer(R))
  if (NCOL(b$t) != 1L || !is.numeric(b$t))
    cli::cli_abort("{.arg statistic} must return a single numeric value (got {NCOL(b$t)} columns).")

  bci <- boot::boot.ci(b, conf = conf, type = c("perc", "bca", "basic", "norm"))

  lcl <- ucl <- NA_real_
  if (type == "perc")       { lcl <- bci$percent[4]; ucl <- bci$percent[5] }
  else if (type == "basic") { lcl <- bci$basic[4];   ucl <- bci$basic[5] }
  else if (type == "norm")  { lcl <- bci$normal[2];  ucl <- bci$normal[3] }
  else if (type == "bca") {
    if (is.null(bci$bca)) {
      cli::cli_warn("BCa undefined; falling back to percentile interval.")
      lcl <- bci$percent[4]; ucl <- bci$percent[5]
    } else { lcl <- bci$bca[4]; ucl <- bci$bca[5] }
  }

  list(estimate   = b$t0,
       std.error  = stats::sd(b$t[, 1L], na.rm = TRUE),
       lcl = unname(lcl), ucl = unname(ucl),
       type = type, conf.level = conf, ci = bci, replicates = b)
}
