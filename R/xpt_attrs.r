#' Get SAS variable labels from a data frame
#'
#' Returns the `"label"` attribute of each column as a named character vector.
#' Columns without a `"label"` attribute are reported as the empty string.
#'
#' @param data A data frame or tibble.
#'
#' @return Named character vector of variable labels (one entry per column).
#'
#' @seealso [ks_set_labels()], [ks_xpt_formats()], [ks_read_xpt()], [ks_write_xpt()]
#' @export
ks_xpt_labels <- function(data) {
  if (!is.data.frame(data)) cli::cli_abort("`data` must be a data frame.")
  vapply(data,
         function(x) {
           v <- attr(x, "label", exact = TRUE)
           if (is.null(v)) "" else as.character(v)[[1L]]
         },
         character(1L))
}

#' Get SAS variable formats from a data frame
#'
#' Returns the `"format.sas"` attribute of each column as a named character vector.
#' Columns without a `"format.sas"` attribute are reported as the empty string.
#'
#' @param data A data frame or tibble.
#'
#' @return Named character vector of SAS format strings (one entry per column).
#'
#' @seealso [ks_set_formats()], [ks_xpt_labels()], [ks_read_xpt()], [ks_write_xpt()]
#' @export
ks_xpt_formats <- function(data) {
  if (!is.data.frame(data)) cli::cli_abort("`data` must be a data frame.")
  vapply(data,
         function(x) {
           v <- attr(x, "format.sas", exact = TRUE)
           if (is.null(v)) "" else as.character(v)[[1L]]
         },
         character(1L))
}

#' Set SAS variable labels on a data frame
#'
#' Sets the `"label"` attribute of selected columns from a named character vector.
#' Names of `labels` must match column names in `data`. Unknown names are warned
#' about and skipped.
#'
#' @param data A data frame or tibble.
#' @param labels Named character vector. Names are column names; values are labels.
#'   Use `NA` or empty string to keep an existing label.
#'
#' @return The input `data` with `"label"` attributes updated.
#'
#' @seealso [ks_xpt_labels()], [ks_set_formats()]
#' @export
ks_set_labels <- function(data, labels) {
  if (!is.data.frame(data)) cli::cli_abort("`data` must be a data frame.")
  if (length(labels) == 0L) return(data)
  if (is.null(names(labels))) cli::cli_abort("`labels` must be a named character vector.")
  unknown <- setdiff(names(labels), names(data))
  if (length(unknown) > 0L) {
    cli::cli_warn("Unknown columns ignored: {.var {unknown}}")
  }
  for (nm in intersect(names(labels), names(data))) {
    v <- labels[[nm]]
    if (is.na(v)) next
    attr(data[[nm]], "label") <- as.character(v)
  }
  data
}

#' Set SAS variable formats on a data frame
#'
#' Sets the `"format.sas"` attribute of selected columns from a named character vector.
#'
#' @param data A data frame or tibble.
#' @param formats Named character vector. Names are column names; values are
#'   SAS format strings (e.g. `"DATE9."`, `"F8.2"`, `"$20."`).
#'
#' @return The input `data` with `"format.sas"` attributes updated.
#'
#' @seealso [ks_xpt_formats()], [ks_set_labels()]
#' @export
ks_set_formats <- function(data, formats) {
  if (!is.data.frame(data)) cli::cli_abort("`data` must be a data frame.")
  if (length(formats) == 0L) return(data)
  if (is.null(names(formats))) cli::cli_abort("`formats` must be a named character vector.")
  unknown <- setdiff(names(formats), names(data))
  if (length(unknown) > 0L) {
    cli::cli_warn("Unknown columns ignored: {.var {unknown}}")
  }
  for (nm in intersect(names(formats), names(data))) {
    v <- formats[[nm]]
    if (is.na(v)) next
    attr(data[[nm]], "format.sas") <- as.character(v)
  }
  data
}
