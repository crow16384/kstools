#' @title
#' Trim spaces
#' @description
#' Trim spaces in the beginning and end of line. Vectorized function
#' @param x Character vector to trim
#' @examples
#' ks_trim(c("  A  ","A  ","  S  d A","   B "," B    ","B"))
#' @name ks_trim
#' @export
ks_trim <- function(x) {
    gsub("(^[[:space:]]+|[[:space:]]+$)","",x)
}
