#' @title
#' Simulate AR(1) data
#' @description
#' Simulate AR(1) data. Useful for developing methodology of analysis,
#' producing graphic examples for SAP etc.
#' @param n Number of subjects
#' @param beta0 Average intercept
#' @param beta1 Average slope
#' @param ar.val True autocorrelation. Default = 0.4
#' @param sigma True error SD
#' @param tau0 True intercept SD
#' @param tau1 True slope SD
#' @param tau01 Intercept-slope correlation. Default=0.3
#' @param m Maximal number of time observations per subject
#' @details
#' Produces data.frame with simulated ARIMA(1) data for defined intercept, slope, correlation etc.
#' \code{plot(data)} produces groupedData plot from \code{nlme} package.
#' @author Wolfgang (https://stats.stackexchange.com/users/1934/wolfgang)
#' @note \code{arima.sim(model=list(ar=ar.val), n=x) * sqrt(1-ar.val^2) * sigma},
#' so that the true error SD is equal to sigma
#' @section Warnings: This is an AR(1) model. Please don't mix it with other more difficult
#' time series
#' @examples
#' dt <- SimulateAR1(n=10, beta0=5, beta1=4.56, ar.val=.4, sigma=3.4,
#' tau0=2.45, tau1=1.13, tau01=.3, m=6)
#' plot(dt)
#' @name ks_simulate_ar1
#' @export
ks_simulate_ar1 <- function(n,           ## number of subjects
                        beta0,       ## average intercept
                        beta1,       ## average slope
                        ar.val=.4,   ## true autocorrelation
                        sigma,       ## true error SD
                        tau0,        ## true intercept SD
                        tau1,        ## true slope SD
                        tau01=.3,    ## intercept-slope correlation
                        m )          ## maximal number of time observations per subject
{
  require(MASS)
  
  ### simulate number of observations for each individual
  p <- round(runif(n,4,m))

  ### simulate observation moments (assume everybody has 1st obs)
  obs <- unlist(sapply(p, function(x) c(1, sort(sample(2:m, x-1, replace=FALSE)))))

   ### set up data frame
   dat <- data.frame(id=rep(1:n, times=p), obs=obs)

   ### simulate (correlated) random effects for intercepts and slopes
   mu  <- c(0,0)
   S   <- matrix(c(1, tau01, tau01, 1), nrow=2)
   tau <- c(tau0, tau1)
   S   <- diag(tau) %*% S %*% diag(tau)
   U   <- mvrnorm(n, mu=mu, Sigma=S)

   ### simulate AR(1) errors and then the actual outcomes
   dat$eij <- unlist(sapply(p, function(x) arima.sim(model=list(ar=ar.val), n=x) * sqrt(1-ar.val^2) * sigma))
   dat$y <- (beta0 + rep(U[,1], times=p)) + (beta1 + rep(U[,2], times=p)) * log(dat$obs) + dat$eij

   ### note: use arima.sim(model=list(ar=ar.val), n=x) * sqrt(1-ar.val^2) * sigma
   ### construction, so that the true error SD is equal to sigma

   dat$eij <- NULL
   
   ### create grouped data object
   dat <- nlme::groupedData(y ~ obs | id, data=dat)
   dat
}
