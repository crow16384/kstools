#' @title
#' Smoothed Weight of Evidence for factors
#' @description
#' Calculate Smoothed Weight of Evidence for factors (SWOE).
#' Useful for Logistic regression.
#' @param data Source data.frame
#' @param par Parameter to process relative to the response
#' @param resp Response variable
#' @param quoted Are names quoted or not. Default = FALSE
#' @details
#' During a logistic model building sometimes useful to convert factors
#' into continuous variable for the model selection. SWOE is one simple way
#' to do this for factor relative to the response.
#' @examples
#' set.seed(1234)
#' dt <- data.frame(yn = rbinom(50,1,0.3), 
#'                  sex = factor(rbinom(50,1,0.55),
#'                               levels = c(0,1), labels = c("F","M")))
#' SWOE(data=dt, par=sex, resp=yn)
#' ## [1] -1.516347 -1.516347 -1.199417 -1.516347 -1.516347 -1.516347 -1.516347
#' ## ...
#' ## ...
#' ## [50] -1.199417
#' 
#' ks_swoe(data=dt, par="sex", resp="yn", quoted = T)
#' @name ks_swoe
#' @export
ks_swoe <- function(data, par, resp, quoted=FALSE) {
  
  if (quoted==FALSE) {
    deparse(substitute(par)) -> par
    deparse(substitute(resp)) -> resp
  }

  rho1 <- mean(data[,resp])
  events <- tapply(data[,resp], data[,par], sum)
  freq <- tapply(data[,resp], data[,par], function(x) sum(!is.na(x)))
  logit <- log( (events + rho1*24)/(freq - events + (1-rho1)*24) )
  logit.other <- log(rho1/(1-rho1))
  xx <- c(logit,logit.other)
  
  xx[match(data[,par],names(xx))] -> v
  names(v) <- NULL
  v
}
