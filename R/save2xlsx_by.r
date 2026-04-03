#' Save a data frame to an XLSX workbook split by a grouping column
#'
#' Writes \code{data} to an XLSX file, creating one worksheet per unique value
#' of \code{split_col}.  Rows can be colour-highlighted based on the content of
#' a message column (e.g. the output of \code{\link{ks_check_rules}} collapsed
#' with \code{\link{ks_collapse_check_msgs}}) and optionally a status column.
#' Column labels (stored as \code{"label"} attributes) are written as a grey
#' italic row above the data headers when present.
#'
#' @param data A data frame.
#' @param file Character.  Path to the output \code{.xlsx} file.
#' @param colors Named character vector mapping message substrings to hex
#'   colour codes (e.g. \code{c("Error" = "FFCCCC", "OK" = "CCFFCC")}).
#' @param split_col \code{<tidy-select>} Bare name of the column used to split
#'   data into worksheets.  Default \code{type}.
#' @param msg_col \code{<tidy-select>} Bare name of the column that contains
#'   check messages used for row colouring.  Default \code{check_msgs}.
#' @param as_table Logical.  If \code{TRUE}, write each sheet as an Excel
#'   table (\code{wb_add_data_table}).  Default \code{FALSE}.
#' @param na_to_empty Logical.  If \code{TRUE}, replace \code{NA} and
#'   \code{"#N/A"} in character columns with empty strings.  Default
#'   \code{FALSE}.
#' @param status_col \code{<tidy-select>} Optional bare name of a status
#'   column (e.g. from \code{\link{ks_compare_check_state}}) used for a
#'   secondary layer of row colouring that overrides \code{colors}.
#'   Pass \code{NULL} to disable.  Default \code{NULL}.
#' @param status_colors Named character vector mapping status values to hex
#'   colour codes.  Used only when \code{status_col} is not \code{NULL}.
#'
#' @return Invisibly returns \code{NULL}.  The file is written as a side
#'   effect.
#'
#' @examples
#' \dontrun{
#' ks_save2xlsx_by(
#'   results,
#'   file   = "output/checks.xlsx",
#'   colors = c("Error" = "FFCCCC", "Warning" = "FFFF99"),
#'   split_col = type,
#'   msg_col   = check_msgs
#' )
#' }
#'
#' @name ks_save2xlsx_by
#' @importFrom openxlsx2 wb_workbook wb_add_worksheet wb_add_data wb_add_data_table
#'   wb_add_filter wb_set_col_widths wb_add_font wb_add_cell_style wb_add_fill
#'   wb_save wb_dims wb_color
#' @importFrom dplyr filter select mutate across where
#' @importFrom purrr map_chr
#' @importFrom stringr str_detect fixed
#' @export
ks_save2xlsx_by <- function(data, file, colors,
                             split_col    = type,
                             msg_col      = check_msgs,
                             as_table     = FALSE,
                             na_to_empty  = FALSE,
                             status_col   = NULL,
                             status_colors = NULL) {
  split_col_name  <- deparse(substitute(split_col))
  msg_col_name    <- deparse(substitute(msg_col))
  status_col_name <- if (!is.null(substitute(status_col))) deparse(substitute(status_col)) else NULL

  wb <- openxlsx2::wb_workbook()

  for (tp in unique(data[[split_col_name]])) {
    sheet_data <- data %>%
      dplyr::filter({{split_col}} == tp) %>%
      dplyr::select(-{{split_col}})

    nc <- ncol(sheet_data)

    labels <- purrr::map_chr(sheet_data, ~ {
      lbl <- attr(.x, "label")
      if (is.null(lbl)) "" else lbl
    })
    has_labels <- any(labels != "")

    if (na_to_empty) {
      sheet_data <- sheet_data %>%
        dplyr::mutate(
          dplyr::across(
            dplyr::where(is.character),
            ~ replace(.x, .x == "#N/A" | is.na(.x), "")
          )
        )
    }

    row_offset <- if (has_labels) 1L else 0L

    wb <- wb %>%
      openxlsx2::wb_add_worksheet(sheet = tp)

    if (as_table) {
      wb <- wb %>%
        openxlsx2::wb_add_data_table(
          x          = sheet_data,
          start_row  = 1L + row_offset,
          na.strings = if (na_to_empty) "" else NULL
        )
    } else {
      wb <- wb %>%
        openxlsx2::wb_add_data(
          x          = sheet_data,
          start_row  = 1L + row_offset,
          na.strings = if (na_to_empty) "" else NULL
        ) %>%
        openxlsx2::wb_add_filter(rows = 1L + row_offset, cols = 1:nc)
    }

    wb <- wb %>% openxlsx2::wb_set_col_widths(cols = 1:nc, widths = "auto")

    if (has_labels) {
      wb <- wb %>%
        openxlsx2::wb_add_data(
          x          = as.data.frame(t(labels), stringsAsFactors = FALSE),
          col_names  = FALSE,
          start_row  = 1
        ) %>%
        openxlsx2::wb_add_font(
          dims  = openxlsx2::wb_dims(rows = 1, cols = 1:nc),
          italic = TRUE,
          color  = openxlsx2::wb_color("808080")
        ) %>%
        openxlsx2::wb_add_cell_style(
          dims      = openxlsx2::wb_dims(rows = 1, cols = 1:nc),
          wrap_text = TRUE
        )
    }

    for (msg in names(colors)) {
      rows <- which(stringr::str_detect(sheet_data[[msg_col_name]], stringr::fixed(msg))) +
        1L + row_offset
      if (length(rows) > 0) {
        for (r in rows) {
          wb <- wb %>%
            openxlsx2::wb_add_fill(
              dims  = openxlsx2::wb_dims(rows = r, cols = 1:nc),
              color = openxlsx2::wb_color(colors[[msg]])
            )
        }
      }
    }

    if (!is.null(status_col_name) && !is.null(status_colors) &&
        status_col_name %in% names(sheet_data)) {
      for (st in names(status_colors)) {
        rows <- which(sheet_data[[status_col_name]] == st) + 1L + row_offset
        if (length(rows) > 0) {
          for (r in rows) {
            wb <- wb %>%
              openxlsx2::wb_add_fill(
                dims  = openxlsx2::wb_dims(rows = r, cols = 1:nc),
                color = openxlsx2::wb_color(status_colors[[st]])
              )
          }
        }
      }
    }
  }

  wb %>% openxlsx2::wb_save(file)
  invisible(NULL)
}
