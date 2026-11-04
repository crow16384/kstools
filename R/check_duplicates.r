#' Check duplicate records by key
#'
#' Aggregates `data` by the supplied key column(s) and emits a `[DUPLICATES]`
#' warning when any key group holds more than one record.
#'
#' @details
#' A record is a duplicate only when ALL key columns match (joint key),
#' mirroring `dplyr::summarise(.by = c(...))`. The dataset itself is never
#' modified and row order is irrelevant. `NA` values group like regular
#' values. The reported count is the number of duplicated KEY GROUPS, not
#' the number of surplus rows: three identical keys count as one duplicate.
#'
#' @param data A data frame or tibble.
#' @param ... Unquoted (or quoted) column names forming the check key,
#'   e.g. `STUDYID, USUBJID, VISIT` or `"STUDYID", "USUBJID"`.
#' @return `FALSE` (invisibly) when duplicates were found and a warning was
#'   issued, `TRUE` (invisibly) otherwise, so the call can be embedded in
#'   pipeline sanity gates.
#' @examples
#' d <- data.frame(STUDYID = c("A", "A", "B"), USUBJID = c("1", "1", "2"))
#' suppressWarnings(ks_check_duplicates(d, STUDYID, USUBJID))  # FALSE
#' suppressWarnings(ks_check_duplicates(d, STUDYID))           # TRUE
#' @export
ks_check_duplicates <- function(data, ...) {
  grouped <- data |>
    summarise(.by = c(...), n = n())

  dup_groups <- sum(grouped$n > 1L)

  if (dup_groups > 0L) {
    key_names <- names(grouped)[-ncol(grouped)]
    msg <- paste0(
      cli::bg_red(cli::col_white(cli::style_bold(" [DUPLICATES] "))), " ",
      cli::col_yellow(cli::style_bold(paste0(
        "\nFound duplicates: ", dup_groups,
        "\nKeys: ", paste(key_names, collapse = ", "))))
    )
    warning(msg, call. = FALSE)
    return(invisible(FALSE))
  }

  invisible(TRUE)
}
