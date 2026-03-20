#' @title
#' 25th percentile (Q1)
#' @description
#' Computes the 25th percentile using \code{\link[stats]{quantile}}.
#'
#' The quantile algorithm type can be set globally via
#' \code{options(kstools.quantile.type = <1..9>)} (e.g. in \file{.Rprofile}).
#' Type 2 matches SAS default; type 7 is the R default.
#' When the option is not set the package default of \code{2} is used.
#' @param x Numeric vector.
#' @param na.rm Logical; remove \code{NA}s before computing. Default \code{TRUE}.
#' @param type Integer (1–9); quantile algorithm passed to
#'   \code{\link[stats]{quantile}}. Defaults to \code{getOption("kstools.quantile.type", 2L)}.
#' @seealso \code{\link{ks_q3}}, \code{\link[stats]{quantile}}
#' @examples
#' ## Use R default algorithm for this call
#' ks_q1(rnorm(100), type = 7)
#'
#' ## Set package-wide default (e.g. in .Rprofile)
#' old <- options(kstools.quantile.type = 7L)
#' ks_q1(rnorm(100))   # now uses type 7
#' options(old)         # restore
#' @name ks_q1
#' @importFrom stats quantile
#' @export
ks_q1 <- function(x, na.rm = TRUE,
                   type = getOption("kstools.quantile.type", default = 2L)) {
  stats::quantile(x, 0.25, na.rm = na.rm, type = type)
}

#' @title
#' 75th percentile (Q3)
#' @description
#' Computes the 75th percentile using \code{\link[stats]{quantile}}.
#'
#' The quantile algorithm type can be set globally via
#' \code{options(kstools.quantile.type = <1..9>)} (e.g. in \file{.Rprofile}).
#' Type 2 matches SAS default; type 7 is the R default.
#' When the option is not set the package default of \code{2} is used.
#' @param x Numeric vector.
#' @param na.rm Logical; remove \code{NA}s before computing. Default \code{TRUE}.
#' @param type Integer (1–9); quantile algorithm passed to
#'   \code{\link[stats]{quantile}}. Defaults to \code{getOption("kstools.quantile.type", 2L)}.
#' @seealso \code{\link{ks_q1}}, \code{\link[stats]{quantile}}
#' @examples
#' ## Use SAS-compatible algorithm for this call
#' ks_q3(rnorm(100), type = 2)
#'
#' ## Set package-wide default (e.g. in .Rprofile)
#' old <- options(kstools.quantile.type = 7L)
#' ks_q3(rnorm(100))   # now uses type 7
#' options(old)         # restore
#' @name ks_q3
#' @importFrom stats quantile
#' @export
ks_q3 <- function(x, na.rm = TRUE,
                   type = getOption("kstools.quantile.type", default = 2L)) {
  stats::quantile(x, 0.75, na.rm = na.rm, type = type)
}
