# Compute the maximum number of decimal places per group

For each group defined by `by`, determines the maximum number of decimal
digits observed in `var` (after rounding to 4 decimal places) and joins
the result back as a new column `NUMDEC`.

## Usage

``` r
ks_get_numdec(data, var, by)
```

## Arguments

- data:

  A data frame or tibble.

- var:

  Character string naming the numeric column to inspect.

- by:

  Character vector of grouping column names.

## Value

`data` with an additional integer column `NUMDEC` giving the group-level
maximum decimal count.

## Details

The decimal-digit count is derived by formatting the rounded value with
`format(scientific = FALSE)`, stripping trailing zeros, and counting
characters after the decimal point. `NA` values in `var` are ignored
when computing the group maximum.

## Examples

``` r
d <- data.frame(
  grp = c("A", "A", "B", "B"),
  val = c(1.1, 2.34, 3.0, 4.567)
)
ks_get_numdec(d, "val", "grp")
#>   grp   val NUMDEC
#> 1   A 1.100      2
#> 2   A 2.340      2
#> 3   B 3.000      3
#> 4   B 4.567      3
```
