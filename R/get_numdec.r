#' Compute the maximum number of decimal places per group
#'
#' For each group defined by \code{by}, determines the maximum number of
#' decimal digits observed in \code{var} (after rounding to 4 decimal places)
#' and joins the result back as a new column \code{NUMDEC}.
#'
#' The decimal-digit count is derived by formatting the rounded value with
#' \code{format(scientific = FALSE)}, stripping trailing zeros, and counting
#' characters after the decimal point.  \code{NA} values in \code{var} are
#' ignored when computing the group maximum.
#'
#' @param data A data frame or tibble.
#' @param var Character string naming the numeric column to inspect.
#' @param by Character vector of grouping column names.
#'
#' @return \code{data} with an additional integer column \code{NUMDEC}
#'   giving the group-level maximum decimal count.
#'
#' @examples
#' d <- data.frame(
#'   grp = c("A", "A", "B", "B"),
#'   val = c(1.1, 2.34, 3.0, 4.567)
#' )
#' ks_get_numdec(d, "val", "grp")
#'
#' @name ks_get_numdec
#' @importFrom cli cli_abort
#' @importFrom dplyr group_by mutate summarise across all_of select left_join
#' @importFrom rlang .data
#' @export
ks_get_numdec <- function(data, var, by) {

  if (!inherits(data, "data.frame"))
    cli::cli_abort("{.arg data} must inherit from {.cls data.frame}.")
  if (!is.character(var) || length(var) != 1L)
    cli::cli_abort("{.arg var} must be a single character string.")
  if (!is.character(by) || length(by) == 0L)
    cli::cli_abort("{.arg by} must be a character vector of column names.")
  missing <- setdiff(c(var, by), names(data))
  if (length(missing) > 0L)
    cli::cli_abort("Column{?s} not found in data: {.val {missing}}.")

  ndec <- data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
    dplyr::mutate(
      NUMDEC = ifelse(
        !is.na(.data[[var]]),
        nchar(sub(
          "^[-]?\\d*\\.?", "",
          trimws(sub("0+$", "",
                     format(round(.data[[var]], digits = 4L),
                            scientific = FALSE)))
        )),
        NA_integer_
      )
    ) |>
    dplyr::summarise(NUMDEC = max(.data[["NUMDEC"]], na.rm = TRUE),
                     .groups = "drop") |>
    dplyr::select(dplyr::all_of(c(by, "NUMDEC")))

  dplyr::left_join(data, ndec, by = by)
}
