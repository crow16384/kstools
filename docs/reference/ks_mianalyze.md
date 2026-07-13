# Analogue of SAS PROC MIANALYZE (Rubin pooling)

Pools point estimates and standard errors across multiple imputations
according to Rubin's rules. Degrees of freedom follow the Barnard-Rubin
(1999) small-sample adjustment when complete-data df are supplied via
`edf` (equivalent to the SAS `EDF=` option).

## Usage

``` r
ks_mianalyze(est, err, alpha = 0.05, theta0 = 0, edf = Inf, v0)

mianalyze(est, err, alpha = 0.05, theta0 = 0, edf = Inf, v0)

# S3 method for class 'ks_mianalyze'
summary(object, ...)

# S3 method for class 'ks_mianalyze'
knit_print(x, ...)
```

## Arguments

- est:

  Numeric vector of point estimates from each imputation.

- err:

  Numeric vector of corresponding standard errors.

- alpha:

  Significance level for confidence intervals. Default `0.05`.

- theta0:

  Null value for hypothesis test \\H_0: \theta = \theta_0\\.

- edf:

  Complete-data degrees of freedom (positive numeric scalar or `Inf`).
  Equivalent to the SAS `EDF=` option in `PROC MIANALYZE`. When finite,
  the Barnard-Rubin (1999) adjusted degrees of freedom \\v_m^\*\\ are
  used instead of the Rubin (1987) large-sample \\v_m\\. Default `Inf`
  (no adjustment, Rubin large-sample df).

- v0:

  Deprecated alias for `edf`. Kept for backward compatibility; ignored
  when `edf` is also supplied.

## Value

An object of class `ks_mianalyze` with components:

- Estimate:

  Pooled estimate.

- StdErr:

  Pooled standard error.

- m:

  Number of imputations.

- Vb:

  Between-imputation variance.

- Vw:

  Within-imputation variance.

- Vt:

  Total variance.

- df:

  Degrees of freedom (adjusted when `edf` is finite).

- r:

  Relative increase in variance due to nonresponse.

- lambda:

  Fraction of missing information.

- re:

  Relative efficiency.

- lcl, ucl:

  Two-sided confidence limits for `Estimate`.

- alpha:

  Alpha used for CI.

- theta0:

  Null value used in hypothesis test.

- edf:

  Complete-data degrees of freedom used.

- minim, maxim:

  Min/max of input `est`.

- t:

  Test statistic for \\H_0\\.

- pval:

  Two-sided p-value.

## Details

Let \\Q_i\\ and \\U_i\\ be estimate and variance from imputation \\i\\.
The pooled estimate is \\\bar{Q} = m^{-1}\sum_i Q_i\\; within variance
\\\bar{U} = m^{-1}\sum_i U_i\\; between variance \\B = (m-1)^{-1}\sum_i
(Q_i-\bar{Q})^2\\; total variance \\T = \bar{U} + (1 + 1/m)B\\.

Rubin's (1987) large-sample degrees of freedom are \\v_m = (m-1)(1 +
\bar{U}/((1+m^{-1})B))^2\\. When the complete-data degrees of freedom
\\v_0\\ are small and the fraction of missing information is modest,
\\v_m\\ can greatly exceed \\v_0\\, which is inappropriate. The
Barnard-Rubin (1999) adjustment computes \\v_m^\* = (1/v_m +
1/\hat{v}\_{obs})^{-1}\\ where \\\hat{v}\_{obs} = (1-\gamma) v_0
(v_0+1)/(v_0+3)\\ and \\\gamma = (1+m^{-1})B/T\\.

## References

Barnard, J. and Rubin, D. B. (1999). Small-sample degrees of freedom
with multiple imputation. *Biometrika*, 86, 948–955.

Rubin, D. B. (1987). *Multiple Imputation for Nonresponse in Surveys*.
Wiley.

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

## Barnard-Rubin adjusted df (equivalent to SAS EDF=120)
mianalyze(est, err, edf = 120)
#> 
#> 
#> ***Variance information (4 Imputations)***
#> Between      Within      Total       DF (Barnard-Rubin adjusted)
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
