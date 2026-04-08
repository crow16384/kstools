# Analogue of SAS PROC MIANALYZE (Rubin pooling)

Pools point estimates and standard errors across multiple imputations
according to Rubin's rules.

## Usage

``` r
ks_mianalyze(est, err, alpha = 0.05, theta0 = 0, v0)

mianalyze(est, err, alpha = 0.05, theta0 = 0, v0)
```

## Arguments

- est:

  Numeric vector of point estimates from each imputation.

- err:

  Numeric vector of corresponding standard errors.

- alpha:

  Significance level for confidence intervals. Default \code0.05.

- theta0:

  Null value for hypothesis test \eqnH_0: theta = theta_0.

- v0:

  Optional complete-data degrees of freedom used for Barnard-Rubin style
  small-sample df adjustment.

## Value

An object of class \codeks_mianalyze with components: \describe
\itemEstimatePooled estimate. \itemStdErrPooled standard error.
\itemmNumber of imputations. \itemVbBetween-imputation variance.
\itemVwWithin-imputation variance. \itemVtTotal variance. \itemdfDegrees
of freedom. \itemrRelative increase in variance due to nonresponse.
\itemlambdaFraction of missing information. \itemreRelative efficiency.
\itemlcl, uclTwo-sided confidence limits for \codeEstimate.
\itemalphaAlpha used for CI. \itemtheta0Null value used in hypothesis
test. \itemminim, maximMin/max of input \codeest. \itemtTest statistic
for \eqnH_0. \itempvalTwo-sided p-value.

## Details

Let \eqnQ_i and \eqnU_i be estimate and variance from imputation \eqni.
The pooled estimate is \eqn\barQ = m^-1\sum_i Q_i; within variance
\eqn\barU = m^-1\sum_i U_i; between variance \eqnB = (m-1)^-1\sum_i
(Q_i-\barQ)^2; total variance \eqnT = \barU + (1 + 1/m)B.

Degrees of freedom default to Rubin's large-sample expression and can be
adjusted using \codev0.

## References

Rubin, D. B. (1987). \emphMultiple Imputation for Nonresponse in
Surveys. Wiley.

## Examples

``` r
est <- c(0.345, 0.303, 0.298, 0.378)
err <- c(0.056, 0.101, 0.099, 0.034)
out <- mianalyze(est, err)
out
#> 
#> 
#> ***Variance information (4 Imputations)***
#> Between      Within      Total       DF
#> -------      ------      -----       --
#> 0.001426 0.006074    0.007856    58.3
#> 
#> Relative Fraction
#> Increase Missing     Relative
#> in Variance  Information Efficiency
#> -----------  ----------- ----------
#> 0.293488 0.252131    0.940705
#> 
#> ***Parameter estimates (4 Imputations)***
#> Estimate Std Error   95.00% Confidence Limits    DF
#> -------- ---------   ------------------------    --
#> 0.331000 0.088634    0.153597    0.508403    58.3
#> 
#>                      t for H0
#> Minimum      Maximum     Theta0      Parameter=Theta0    Pr>|t|
#> -------      -------     ------      ----------------    ------
#> 0.298000 0.378000    0.00        3.7345          0.0004

## With finite complete-data df adjustment
mianalyze(est, err, v0 = 120)
#> 
#> 
#> ***Variance information (4 Imputations)***
#> Between      Within      Total       DF
#> -------      ------      -----       --
#> 0.001426 0.006074    0.007856    35.6
#> 
#> Relative Fraction
#> Increase Missing     Relative
#> in Variance  Information Efficiency
#> -----------  ----------- ----------
#> 0.293488 0.252131    0.940705
#> 
#> ***Parameter estimates (4 Imputations)***
#> Estimate Std Error   95.00% Confidence Limits    DF
#> -------- ---------   ------------------------    --
#> 0.331000 0.088634    0.151165    0.510835    35.6
#> 
#>                      t for H0
#> Minimum      Maximum     Theta0      Parameter=Theta0    Pr>|t|
#> -------      -------     ------      ----------------    ------
#> 0.298000 0.378000    0.00        3.7345          0.0007
```
