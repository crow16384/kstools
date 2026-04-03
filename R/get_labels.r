#' Get variable labels from a data frame
#'
#' Returns a two-column tibble with variable names and their \code{"label"}
#' attributes (as set by \pkg{labelled}, \pkg{haven}, or manual
#' \code{attr(x, "label") <- ...} calls).  Columns without a label attribute
#' are returned as \code{NA_character_}.
#'
#' @param x A data frame (or tibble) whose column labels you want.
#'
#' @return A \code{\link[tibble]{tibble}} with columns:
#' \describe{
#'   \item{var}{Character. Column name taken from \code{names(x)}.}
#'   \item{label}{Character. Value of the \code{"label"} attribute, or
#'     \code{NA} if absent.}
#' }
#'
#' @examples
#' df <- data.frame(a = 1:3, b = letters[1:3])
#' attr(df$a, "label") <- "Numeric variable"
#' ks_get_labels(df)
#'
#' @name ks_get_labels
#' @importFrom tibble tibble
#' @importFrom purrr map_chr
#' @export
ks_get_labels <- function(x) {
  tibble(
    var   = names(x),
    label = purrr::map_chr(x, ~ {
      lbl <- attr(.x, "label")
      if (is.null(lbl)) NA_character_ else as.character(lbl)
    })
  )
}
