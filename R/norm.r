#' Normality test p-value
#'
#' Wrapper around \code{shapiro.test}; returns the p-value or \code{NA} on error.
#' @param x Numeric vector.
#' @return A single numeric (p-value or NA).
#' @name ks_p_norm
#' @export
ks_p_norm <- function(x)
  tryCatch(shapiro.test(x)$p.value, error = function(e) NA)
