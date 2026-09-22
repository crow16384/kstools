#' Vectorized switch (SAS select-when maps)
#'
#' Looks up each element of `x` among the named values of `...` — a
#' `switch()` that works on a whole vector at once, like SAS
#' `select(when ...)` or a format-driven recode.
#'
#' @param .x A vector of lookup keys (character, factor, or numeric;
#'   coerced with \code{as.character()} for matching).
#' @param ... Named values of a **single common type** — the names are keys,
#'   the values are results. `vapply()` errors when the types disagree.
#' @param .na Value returned where `x` is `NA`; defaults to an `NA` of the
#'   same type as the first value of `...`.
#' @param .default Value returned for keys present in `x` but absent from
#'   `...`; defaults to an `NA` of the same type as the first value of `...`.
#' @return A vector the same length as `.x` with the storage type of the
#'   values in `...`.  The key argument is named `.x` (leading dot) so
#'   that bare case names like `x = ...` in dots cannot collide with it.
#' @examples
#' ks_vswitch(c("a", "b", "a", NA, "zz"), a = 10L, b = 20L)
#' ks_vswitch(c("a", "b", NA, "zz"), a = 10L, b = 20L, .na = 0L, .default = -1L)
#' ks_vswitch(factor(c("x", "y")), x = 1.5, y = 2.5)
#' @name ks_vswitch
#' @importFrom cli cli_abort
#' @export
ks_vswitch <- function(.x, ..., .na = NULL, .default = NULL) {
  args <- list(...)
  if (!length(args))
    cli::cli_abort("At least one named value is required in {.arg ...}.")
  if (is.null(names(args)) || any(names(args) == ""))
    cli::cli_abort("All values in {.arg ...} must be named.")

  proto <- args[[1L]]
  miss  <- if (is.null(.default)) proto[NA_integer_] else .default
  nat   <- if (is.null(.na))      proto[NA_integer_] else .na

  keys <- as.character(.x)
  vapply(seq_along(.x), function(i) {
    if (is.na(.x[i])) return(nat)
    key <- keys[i]
    if (key %in% names(args)) args[[key]] else miss
  }, FUN.VALUE = proto)
}
