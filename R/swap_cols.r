#' Swap pairs of columns in a data frame
#'
#' Exchanges column contents by name: for each named argument \code{lhs = rhs},
#' the column named \code{lhs} receives the values that were in \code{rhs},
#' and \code{rhs} receives the values that were in \code{lhs}.  Multiple
#' independent pairs can be given in one call.
#'
#' @param df A \code{data.frame}, \code{tibble}, or other object inheriting
#'   from \code{data.frame}.
#' @param ... Named pairs \code{col_a = col_b} (bare names only).  Each name
#'   that appears on the left or right must be a column of \code{df}, and each
#'   column may appear at most once across all pairs (no overlapping swaps).
#'
#' @details
#' The syntax \code{USUBJID = SUBJID} swaps the two columns: after the call,
#' the column still named \code{USUBJID} holds the former \code{SUBJID} values
#' and vice versa.  This is useful when harmonising SDTM-style identifiers or
#' fixing column order after merges.
#'
#' With zero pairs in \code{...}, \code{df} is returned unchanged.
#'
#' @return \code{df} with the specified column pairs exchanged (same class as
#'   the input where possible).
#'
#' @seealso \code{\link{ks_aligndec}}
#' @examples
#' d <- data.frame(SUBJID = c("001", "002"), USUBJID = c("01-001", "01-002"))
#' ks_swap_cols(d, USUBJID = SUBJID)
#' @name ks_swap_cols
#' @importFrom rlang enquos quo_get_expr is_symbol as_name
#' @export
ks_swap_cols <- function(df, ...) {
  if (!inherits(df, "data.frame"))
    stop("'df' must inherit from \"data.frame\"")

  swaps <- rlang::enquos(...)
  lhs   <- names(swaps)

  if (length(swaps) == 0L)
    return(df)

  if (is.null(lhs) || length(lhs) != length(swaps) || any(lhs == ""))
    stop("Use named pairs like `USUBJID = SUBJID`.")

  rhs <- vapply(swaps, function(q) {
    expr <- rlang::quo_get_expr(q)
    if (!rlang::is_symbol(expr))
      stop("Each RHS must be a bare column name.")
    rlang::as_name(expr)
  }, character(1L), USE.NAMES = FALSE)

  missing_cols <- setdiff(c(lhs, rhs), names(df))
  if (length(missing_cols) > 0L)
    stop("Column not found: ", paste(unique(missing_cols), collapse = ", "))

  if (anyDuplicated(c(lhs, rhs)) > 0L)
    stop("Each column can appear only once across all swap pairs.")

  left_idx  <- match(lhs, names(df))
  right_idx <- match(rhs, names(df))

  tmp <- df[left_idx]
  df[left_idx]  <- df[right_idx]
  df[right_idx] <- tmp
  df
}
