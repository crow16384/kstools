#' @title
#' Geometric mean
#' @description
#' Calculates a geometric mean for given vector
#' @param x Numeric vector
#' @param na.rm Flag for ignoring NAs. Default = TRUE
#' @param zero.propagate Propagate NAs with zeros. Default = FALSE
#' @param alpha Alpha level for the confidence interval calculation
#' @author Initial author is Paul McMurdie (http://stackoverflow.com/posts/25555105/revisions)
#' @details I think some of the comments are related to a false-equivalency of
#' NA values in the data and zeros. In the application I had in mind they are 
#' the same, but of course this is not generally true. Thus, if you want to 
#' include optional propagation of zeros, and treat the length(x) differently
#' in the case of NA removal, the following is a slightly longer alternative
#' to the function above.
#' @note Note that it also checks for any negative values, and returns a more 
#' informative and appropriate NaN respecting that geometric mean is not defined
#' for negative values (but is for zeros).
#' @examples
#' ks_geom_mean(abs(rnorm(100,10,5)))
#' @name ks_geom_mean
#' @export
ks_geom_mean = function(x, na.rm=TRUE, zero.propagate = FALSE, alpha=0.05){
  # GMean is not possible for vector with negative digit(s)
  if(any(x < 0, na.rm = TRUE)){
    return(NaN)
  }
  
  result <- list(geom.mean=NA, geom.sd=NA, geom.mean.lcl=NA, geom.mean.ucl=NA)
  
  # also "0" is not acceptable too, so "0" will be returned
  if(zero.propagate){
    if(any(x == 0, na.rm = TRUE)){
      return(0)
    }
    
    result$geom.mean <- exp(mean(log(x), na.rm = na.rm))
  } else {
    n <- length(x)
    result$geom.mean <- exp(sum(log(x[x > 0]), na.rm=na.rm) / n)
  }
  
  # calculate CI for given alpha
  result$geom.sd <- exp(var(log(x), na.rm = TRUE))
  t <- qt(1-alpha/2, n-1)
  k <- result$geom.sd^(t/sqrt(n))
  
  result$geom.mean.lcl <- result$geom.mean/k
  result$geom.mean.ucl <- result$geom.mean*k
  
  result
}
