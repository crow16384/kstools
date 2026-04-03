#' @title
#' Coefficient of variation
#' @description
#' Calculates a coefficient of variation for given vector
#' @param x Numeric vector
#' @param na.rm Flag for ignoring NAs. Default = TRUE
#' @examples
#' ks_cv(c(1,2,3,NA,5,NA,7,2,3,2))
#' @name ks_cv
#' @export
ks_cv <- function(x, na.rm = TRUE) sd(x, na.rm = na.rm) * 100 / mean(x, na.rm = na.rm)
