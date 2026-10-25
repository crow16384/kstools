# Calculate Z score

For evaluation of how far a measured value is from the mean (in case of
data normality), following formulation used

## Usage

``` r
ks_z_score(x, na.rm = TRUE)
```

## Arguments

- x:

  Numeric vector

- na.rm:

  Flag for ignoring NAs. Default = TRUE

## Details

Useful values are +\\/-3.

## Examples

``` r
set.seed(345)
ks_z_score(rnorm(10))
#>  [1] -0.9102967 -0.4446436 -0.3358703 -0.4548544 -0.2493297 -0.7708130
#>  [7] -1.0418824  1.3891393  1.3375406  1.4810102
## -0.9102967 -0.4446436 -0.3358703 -0.4548544 -0.2493297
## -0.7708130 -1.0418824  1.3891393  1.3375406  1.4810102
```
