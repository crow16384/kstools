#' Align decimal (or first space) in character vector
#'
#' Aligns strings so that the decimal point or first space after digits is vertically aligned.
#' NA values are replaced by \code{na.rep}.
#' @param var Character vector (or coercible to character).
#' @param na.rep String to use for NA values.
#' @return Character vector of the same length, with leading spaces so decimals align.
#' @name ks_aligndec
#' @export
ks_aligndec <- function(var, na.rep="") {
  var <- as.character(var)
  var[is.na(var)] <- na.rep

  if (length(var) == 0L) {
    return(var)
  }

  pattern <- "^[\\[\\]()A-Za-zА-Яа-я+\\-= ]*\\d+(?:\\.| )"
  match_start <- regexpr(pattern, var, perl = TRUE)
  match_length <- attr(match_start, "match.length")
  match_end <- ifelse(match_start > 0L, match_start + match_length - 1L, NA_integer_)

  no_match <- is.na(match_end)
  var[no_match] <- paste0(var[no_match], " ")

  n <- nchar(var, type = "chars")
  anchor <- ifelse(is.na(match_end), n, match_end)

  left <- substring(var, 1L, anchor)
  right <- substring(var, anchor + 1L)
  left_width <- max(nchar(left, type = "chars"), na.rm = TRUE)

  out <- sprintf("%s%s", format(left, width = left_width, justify = "right"), right)
  trimws(out, which = "right")
}
