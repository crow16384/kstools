#' Format count and percentage pairs
#'
#' Produces formatted \code{"n (xx.x\%)"} strings from absolute counts and
#' denominators.  An S3 generic dispatching on the class of \code{n}:
#' \itemize{
#'   \item \strong{numeric method} — formats a single vector of counts.
#'   \item \strong{data.frame method} — formats one or more named count
#'     columns inside a \code{data.frame} or \code{tibble} simultaneously,
#'     leaving all other columns unchanged.
#' }
#'
#' @param n Numeric (integer) vector of counts, or a \code{data.frame} /
#'   \code{tibble} whose named columns contain counts.
#' @param totals Numeric denominator(s).
#'   \itemize{
#'     \item \emph{numeric method}: a scalar or a numeric vector recycled
#'       against \code{n}.
#'     \item \emph{data.frame method}: a \strong{named} numeric vector whose
#'       names must match column names present in \code{n}.
#'   }
#' @param na.rep Replacement string for \code{NA} counts.
#'   \itemize{
#'     \item \code{NA_character_} (default): propagate \code{NA} in the
#'       output.
#'     \item Any character string, e.g. \code{""} or
#'       \code{"0 (\  0.0\%)"}: substitute missing counts with that string.
#'   }
#' @return
#'   \itemize{
#'     \item \emph{numeric method}: a character vector of the same length as
#'       \code{n}.
#'     \item \emph{data.frame method}: the input \code{data.frame} with the
#'       named count columns replaced by formatted character strings; all
#'       other columns are unchanged.
#'   }
#' @details
#' Counts are converted to integer before formatting so that both integer and
#' whole-number double vectors are accepted.
#'
#' Percentages are formatted as \code{"\%5.1f\%\%"}, giving one decimal place
#' and a minimum field width of 5 characters
#' (e.g. \code{" 5.0\%"}, \code{"100.0\%"}).  The fixed width ensures
#' vertical alignment when columns are printed side-by-side.
#'
#' A warning is issued when any element of \code{totals} is zero, as this
#' produces \code{Inf} in the percentage.
#'
#' @examples
#' ## Numeric method — single total
#' ks_n_pct(c(10L, 20L, 30L), 56L)
#'
#' ## Numeric method — element-wise totals
#' ks_n_pct(c(10L, 20L, 30L), c(34L, 42L, 56L))
#'
#' ## NA propagation (default)
#' ks_n_pct(c(10L, NA_integer_, 30L), 50L)
#'
#' ## Replace NA with an explicit string
#' ks_n_pct(c(10L, NA_integer_, 30L), 50L, na.rep = "0 (  0.0%)")
#'
#' ## Replace NA with an empty string
#' ks_n_pct(c(10L, NA_integer_, 30L), 50L, na.rep = "")
#'
#' ## data.frame method
#' dex <- data.frame(
#'   par       = c("A", "B", "C"),
#'   Therapy_A = c(11L, 23L, 14L),
#'   Therapy_B = c(20L,  1L, NA_integer_)
#' )
#' ks_n_pct(dex, c(Therapy_A = 56L, Therapy_B = 67L))
#'
#' ## data.frame method — keep only one column
#' ks_n_pct(dex, c(Therapy_A = 56L))
#' @name ks_n_pct
#' @export
ks_n_pct <- function(n, totals, na.rep = NA_character_) UseMethod("ks_n_pct")


#' @export
ks_n_pct.numeric <- function(n, totals, na.rep = NA_character_) {
  if (!is.numeric(totals))
    stop("'totals' must be numeric")
  if (any(totals == 0, na.rm = TRUE))
    warning("'totals' contains zero value(s); percentage will be Inf")

  out         <- sprintf("%d (%5.1f%%)", as.integer(n), n * 100 / totals)
  out[is.na(n)] <- if (is.na(na.rep)) NA_character_ else na.rep
  out
}


#' @export
ks_n_pct.data.frame <- function(n, totals, na.rep = NA_character_) {
  if (!is.numeric(totals))
    stop("'totals' must be numeric")
  if (is.null(names(totals)))
    stop("'totals' must be a named vector whose names match column names in 'n'")

  missing_cols <- setdiff(names(totals), names(n))
  if (length(missing_cols) > 0L)
    stop("Column(s) not found in 'n': ", paste(missing_cols, collapse = ", "))

  if (any(totals == 0, na.rm = TRUE))
    warning("'totals' contains zero value(s); percentage will be Inf")

  for (col in names(totals)) {
    vals   <- n[[col]]
    na_idx <- is.na(vals)

    vals_fmt        <- as.integer(vals)
    vals_fmt[na_idx] <- 0L

    fmt            <- sprintf("%d (%5.1f%%)", vals_fmt, vals_fmt * 100 / totals[[col]])
    fmt[na_idx]    <- if (is.na(na.rep)) NA_character_ else na.rep
    n[[col]]       <- fmt
  }
  n
}


#' @export
ks_n_pct.default <- function(n, totals, na.rep = NA_character_) {
  stop("'n' must be a numeric vector or data.frame")
}
