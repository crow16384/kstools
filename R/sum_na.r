#' @title
#' Add two values ignoring NA
#' @description
#' Add two values ignoring NAs. Usually 5.0 + NA gives NA as a result,
#' but here 5.0 \%+na\% NA will give 5.0. NA \%+na\% 5.0 also gives 5.0.
#' Applicable for scalars and vectors.
#' @param x Numeric scalar or vector
#' @param y Numeric scalar or vector
#' @examples
#' NA %+na% 10
#' 12.3 %+na% 10
#' 12.3 %+na% NA
#' SumNA(12.3, NA)
#' NA %+na% NA
#' c(1,2,NA) \%+na\% c(NA,2,3)
#' @name ks_sum_na
#' @export
ks_sum_na <- function(x,y) 
    ifelse( is.na(x), y, ifelse( is.na(y), x, x+y) )

#' @rdname ks_sum_na
#' @export
`%+na%` <- function(x, y) ks_sum_na(x, y)

