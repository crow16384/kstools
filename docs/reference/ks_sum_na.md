# Add two values ignoring NA

Add two values ignoring NAs. Usually 5.0 + NA gives NA as a result, but
here 5.0 %+na% NA will give 5.0. NA %+na% 5.0 also gives 5.0. Applicable
for scalars and vectors.

## Usage

``` r
ks_sum_na(x, y)

x %+na% y
```

## Arguments

- x:

  Numeric scalar or vector

- y:

  Numeric scalar or vector

## Examples

``` r
NA %+na% 10
#> [1] 10
12.3 %+na% 10
#> [1] 22.3
12.3 %+na% NA
#> [1] 12.3
ks_sum_na(12.3, NA)
#> [1] 12.3
NA %+na% NA
#> [1] NA
c(1,2,NA) %+na% c(NA,2,3)
#> [1] 1 4 3
```
