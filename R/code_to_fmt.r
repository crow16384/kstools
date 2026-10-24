#' Build a named format vector from a coded column
#'
#' Reads a column that contains \code{"code=label"} entries, splits them on
#' \code{=}, and passes the resulting lookup to \code{ksformat::fnew()} as a
#' numeric format.
#'
#' @param dt A data frame containing the coded column.
#' @param col \code{<tidy-select>} Bare name of the column with
#'   \code{"code=label"} values.
#' @param name Character scalar. Name to register the format under via
#'   \code{ksformat::fnew()}.  Defaults to
#'   \code{"<dt_name>_<col_name>_fmt"}.
#'
#' @return Invisibly returns the result of \code{ksformat::fnew()} (called
#'   for its side-effect of registering the format).
#'
#' @examples
#' \dontrun{
#' # dt has a column DECODE with entries like "1=Male", "2=Female"
#' ks_code_to_fmt(dm, DECODE)
#' }
#'
#' @name ks_code_to_fmt
#' @importFrom dplyr select filter distinct
#' @importFrom magrittr %>%
#' @importFrom tidyr separate
#' @importFrom rlang enquo
#' @export
ks_code_to_fmt <- function(dt, col, name = NULL) {
  if (is.null(name)) {
    dt_name  <- gsub('"', '', deparse(substitute(dt)))
    col_name <- gsub('"', '', deparse(substitute(col)))
    name <- paste(dt_name, col_name, "fmt", sep = "_")
  }

  col_q <- rlang::enquo(col)

  vals <- dt %>%
    dplyr::select(!!col_q) %>%
    dplyr::filter(!ksformat::is_missing(!!col_q)) %>%
    tidyr::separate(!!col_q, into = c("col1", "col2"), sep = "=") %>%
    dplyr::select(col1, col2) %>%
    dplyr::distinct()

  fmt <- with(vals, stats::setNames(trimws(col1), trimws(col2)))

  ksformat::fnew(fmt, type = 'numeric', name = name)
}
