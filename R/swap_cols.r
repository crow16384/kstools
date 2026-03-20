#' Swap columns in a data frame
#'
#' Swap pairs of columns by name. Use named arguments: \code{new_a = old_a, new_b = old_b}.
#' Each name can appear only once across all pairs.
#' @param df A data frame.
#' @param ... Named pairs of the form \code{lhs = rhs} (bare column names); columns \code{lhs} and \code{rhs} are swapped.
#' @return The data frame with the specified columns swapped.
#' @name ks_swap_cols
#' @export
ks_swap_cols <- function(df, ...) {
  swaps <- rlang::enquos(...)
  lhs <- names(swaps)

  if (is.null(lhs) || any(lhs == "")) {
    stop("Use named pairs like `USUBJID = SUBJID`.")
  }

  rhs <- vapply(swaps, function(q) {
    expr <- rlang::quo_get_expr(q)
    if (rlang::is_symbol(expr) == FALSE) {
      stop("Each RHS must be a bare column name.")
    }
    rlang::as_name(expr)
  }, character(1))

  missing_cols <- setdiff(c(lhs, rhs), names(df))
  if (length(missing_cols) > 0) {
    stop(sprintf("Column not found: %s", paste(unique(missing_cols), collapse = ", ")))
  }

  # Prevent ambiguous overlapping mappings like A=B, B=C
  if (any(duplicated(c(lhs, rhs)))) {
    stop("Each column can appear only once across all swap pairs.")
  }

  left_idx <- match(lhs, names(df))
  right_idx <- match(rhs, names(df))

  tmp <- df[left_idx]
  df[left_idx] <- df[right_idx]
  df[right_idx] <- tmp
  df
}
