# Bootstrap confidence interval for a scalar statistic

Convenience wrapper around boot: resamples, computes a user statistic,
and returns a percentile (BCa when defined) confidence interval plus the
point estimate — one line instead of the usual \`boot()\` /
\`boot.ci()\` plumbing in report code.

## Usage

``` r
ks_boot_ci(
  x,
  statistic,
  R = 2000L,
  conf = 0.95,
  seed = NULL,
  type = c("perc", "basic", "norm", "bca")
)
```

## Arguments

- x:

  Data resampled by row: a vector, matrix, or data frame.

- statistic:

  Function with signature \`function(data, indices)\` returning a
  \*\*single numeric value\*\* (scalar). \`indices\` select rows of
  \`x\`.

- R:

  Number of bootstrap replicates (default \`2000\`).

- conf:

  Confidence level (default \`0.95\`).

- seed:

  Integer seed for reproducibility (default \`NULL\`).

- type:

  Interval type: \`"perc"\` (percentile, default), \`"basic"\`,
  \`"norm"\`, or \`"bca"\`.

## Value

A list with \`estimate\`, \`std.error\`, \`lcl\`, \`ucl\`, \`type\`,
\`conf.level\`, the full \`boot.ci\` list in \`\$ci\`, and the raw
\`boot\` object in \`\$replicates\`.

## Details

The statistic must be scalar-valued; \`ks_boot_ci()\` checks the shape
of the replicate matrix and aborts otherwise. BCa can be undefined (e.g.
degenerate statistics on small samples) — the function then falls back
to the percentile interval with a warning.

## Examples

``` r
set.seed(1)
x <- rnorm(50, 5, 2)
ks_boot_ci(x, function(d, i) mean(d[i]))
#> $estimate
#> [1] 5.200897
#> 
#> $std.error
#> [1] 0.2339554
#> 
#> $lcl
#> [1] 4.733967
#> 
#> $ucl
#> [1] 5.664849
#> 
#> $type
#> [1] "perc"
#> 
#> $conf.level
#> [1] 0.95
#> 
#> $ci
#> BOOTSTRAP CONFIDENCE INTERVAL CALCULATIONS
#> Based on 2000 bootstrap replicates
#> 
#> CALL : 
#> boot::boot.ci(boot.out = b, conf = conf, type = c("perc", "bca", 
#>     "basic", "norm"))
#> 
#> Intervals : 
#> Level      Normal              Basic         
#> 95%   ( 4.733,  5.651 )   ( 4.737,  5.668 )  
#> 
#> Level     Percentile            BCa          
#> 95%   ( 4.734,  5.665 )   ( 4.654,  5.594 )  
#> Calculations and Intervals on Original Scale
#> 
#> $replicates
#> 
#> ORDINARY NONPARAMETRIC BOOTSTRAP
#> 
#> 
#> Call:
#> boot::boot(data = x, statistic = statistic, R = as.integer(R))
#> 
#> 
#> Bootstrap Statistics :
#>     original      bias    std. error
#> t1* 5.200897 0.008936649   0.2339554
#> 

# ratio of two columns (paired resampling)
d <- data.frame(a = rnorm(60, 5, 1), b = rnorm(60, 3, 1))
ks_boot_ci(d, function(dd, i) mean(dd$a[i]) / mean(dd$b[i]), R = 999,
           seed = 42)
#> $estimate
#> [1] 1.521055
#> 
#> $std.error
#> [1] 0.07443549
#> 
#> $lcl
#> [1] 1.383033
#> 
#> $ucl
#> [1] 1.672262
#> 
#> $type
#> [1] "perc"
#> 
#> $conf.level
#> [1] 0.95
#> 
#> $ci
#> BOOTSTRAP CONFIDENCE INTERVAL CALCULATIONS
#> Based on 999 bootstrap replicates
#> 
#> CALL : 
#> boot::boot.ci(boot.out = b, conf = conf, type = c("perc", "bca", 
#>     "basic", "norm"))
#> 
#> Intervals : 
#> Level      Normal              Basic         
#> 95%   ( 1.373,  1.665 )   ( 1.370,  1.659 )  
#> 
#> Level     Percentile            BCa          
#> 95%   ( 1.383,  1.672 )   ( 1.383,  1.672 )  
#> Calculations and Intervals on Original Scale
#> 
#> $replicates
#> 
#> ORDINARY NONPARAMETRIC BOOTSTRAP
#> 
#> 
#> Call:
#> boot::boot(data = x, statistic = statistic, R = as.integer(R))
#> 
#> 
#> Bootstrap Statistics :
#>     original      bias    std. error
#> t1* 1.521055 0.002006082  0.07443549
#> 
```
