#' @title
#' Calculate Z score 
#' @description
#' For evaluation of how far a measured value is from the mean
#' (in case of data normality), following formulation used
## ((measured value) - mean)/SD
#' @param x Numeric vector
#' @param na.rm Flag for ignoring NAs. Default = TRUE
#' @details
#' Useful values are  +\/-3.
#' @examples
#' set.seed(345)
#' Zscore(rnorm(10))
#' ## 0.9102967  0.4446436  0.3358703  0.4548544  0.2493297
#' ## 0.7708130  1.0418824 -1.3891393 -1.3375406 -1.4810102
#' @name ks_z_score
#' @export
ks_z_score <- function(x, na.rm=T) {
  (mean(x,na.rm=na.rm)-x)/sd(x,na.rm=na.rm)
}
