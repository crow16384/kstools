#' @title
#' Confidence interval for median
#' @description
#' Calculate median and different kind of confidence intervals.
#' Possible methods - bootstrap which produces Basic, Normal, Percentile and BCa
#' intervals. Another method is David Olive's simple median.
#' @param x Numeric vector
#' @param na.rm Ignoring NA flag (logical)
#' @param alpha Alpha level
#' @param method CI method. Allowed "boot" or "olive" or "z"
#' @param R Number of repetitions for bootstrap (if "boot")
#' @param seed Seed number for bootstrap (if "boot")
#' @param type Quantile algorithm (SAS = 2, R default = 7). Valid for "z" method only
#' @import boot
#' @examples
#' x <- rnorm(100, 56,2.5)
#' MedianCI(x, method="olive")
#' 
#' vv <- c(8, 11, 12, 13, 15, 17, 19, 20, 21, 21, 22, 23, 25, 26, 28)
#' MedianCI(vv,method = "boot")
#' MedianCI(vv,method = "olive")
#' MedianCI(vv,method = "olive",alpha=0.1)
#' MedianCI(vv,method = "z")
#' ks_median_ci(vv,method = "z", alpha=0.1)
#' @name ks_median_ci
#' @export
ks_median_ci <- function(x, na.rm=TRUE, alpha=0.05, method=c("boot","olive","z"), 
                     R=10000L, seed=0L, type=2) {
  
  require(boot)
  
  method <- match.arg(method)
  
  stopifnot(is.logical(na.rm) & length(na.rm==1))
  
  if(!is.vector(x))
    stop("Input vector is expected")
  
  if (na.rm==TRUE) {
    x <- x[!is.na(x)]
  }
  
  ### Boot
  median.boot <- function(x) {
    require(boot) # Calling boot library
    
    boot.median <- function(x,i) {
      median(x[i])
    }
    
    set.seed(seed)
    med <- boot(x, boot.median, R=R) # applying bootstrap
    boot.ci(med, conf = 1-alpha) -> result
    
    c(Median=median(x),
      Basic.LCI=result$basic[4], Basic.UCI=result$basic[5], 
      Normal.LCI=result$normal[2], Normal.UCI=result$normal[3],
      Percent.LCI=result$percent[4], Percent.UCI=result$percent[5],
      BCa.LCI=result$bca[4], BCa.UCI=result$bca[5])
  }
  
  median.olive <- function(y) {
    #  This procedure implements David Olive's simple
    #  median confidence interval
    #
    #  First, compute the median
    n <- length(y)
    ysort <- sort(y)
    nhalf <- floor(n/2)
    med <- median(y, na.rm=na.rm)
    
    #  Next, compute Olive’s standard error for the median
    Ln <- nhalf - ceiling(sqrt(n/4))
    Un <- n - Ln
    SE <- 0.5*(ysort[Un] - ysort[Ln+1])
    
    #  Compute the confidence interval based on Student’s t-distribution
    #  The degrees of freedom parameter p is discussed in Olive’s paper
    p = Un - Ln - 1
    t = qt(p = 1 - alpha/2, df = p)
    medLCI = med - t * SE
    medUCI = med + t * SE
    
    c(Median=med, Olive.LCI=medLCI, Olive.UCI=medUCI)
  }
  
  median.z <- function(x) {
    n <- length(x)
    q <- 0.5 # quantile
    med <- quantile(x, 0.5, na.rm=na.rm, type=type)[[1]]
    
    k <- qnorm(1-alpha/2)*sqrt(n*q*(1-q))
    
    c(Median=med, z.LCI=n*q-k, z.UCI=n*q+k)
  }
  
  switch(method,
         boot = median.boot(x),
         olive = median.olive(x),
         z = median.z(x))
}
