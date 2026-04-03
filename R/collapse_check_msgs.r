#' Collapse list-column of check messages to a character column
#'
#' Converts the list-column produced by \code{\link{ks_check_rules}} into a
#' plain character column by pasting multiple messages together with a
#' separator.
#'
#' @param data A data frame containing a list-column of check messages.
#' @param sep Character scalar.  Separator used when collapsing multiple
#'   messages.  Default \code{"; "}.
#' @param col \code{<tidy-select>} Bare name of the list-column to collapse.
#'   Must be provided explicitly.
#'
#' @return \code{data} with \code{col} replaced by a character column.
#'
#' @examples
#' \dontrun{
#' df_checked <- ks_check_rules(data, rules, mode = "all")
#' ks_collapse_check_msgs(df_checked)
#' }
#'
#' @name ks_collapse_check_msgs
#' @importFrom cli cli_abort
#' @importFrom dplyr mutate
#' @importFrom purrr map_chr
#' @export
ks_collapse_check_msgs <- function(data, sep = "; ", col) {
  if (missing(col)) {
    cli::cli_abort("{.arg col} must be provided.")
  }
  data %>%
    dplyr::mutate({{col}} := purrr::map_chr({{col}}, ~ paste(.x, collapse = sep)))
}
