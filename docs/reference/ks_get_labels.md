# Get variable labels from a data frame

Returns a two-column tibble with variable names and their `"label"`
attributes (as set by labelled, haven, or manual
`attr(x, "label") <- ...` calls). Columns without a label attribute are
returned as `NA_character_`.

## Usage

``` r
ks_get_labels(x)
```

## Arguments

- x:

  A data frame (or tibble) whose column labels you want.

## Value

A [`tibble`](https://tibble.tidyverse.org/reference/tibble.html) with
columns:

- var:

  Character. Column name taken from `names(x)`.

- label:

  Character. Value of the `"label"` attribute, or `NA` if absent.

## Examples

``` r
df <- data.frame(a = 1:3, b = letters[1:3])
attr(df$a, "label") <- "Numeric variable"
ks_get_labels(df)
#> # A tibble: 2 × 2
#>   var   label           
#>   <chr> <chr>           
#> 1 a     Numeric variable
#> 2 b     NA              
```
