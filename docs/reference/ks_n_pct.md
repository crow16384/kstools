# Format count and percentage pairs

Produces formatted `"n (xx.x%)"` strings from absolute counts and
denominators. An S3 generic dispatching on the class of `n`:

- **numeric method** — formats a single vector of counts.

- **data.frame method** — formats one or more named count columns inside
  a `data.frame` or `tibble` simultaneously, leaving all other columns
  unchanged.

## Usage

``` r
ks_n_pct(n, totals, na.rep = NA_character_)
```

## Arguments

- n:

  Numeric (integer) vector of counts, or a `data.frame` / `tibble` whose
  named columns contain counts.

- totals:

  Numeric denominator(s).

  - *numeric method*: a scalar or a numeric vector recycled against `n`.

  - *data.frame method*: a **named** numeric vector whose names must
    match column names present in `n`.

- na.rep:

  Replacement string for `NA` counts.

  - `NA_character_` (default): propagate `NA` in the output.

  - Any character string, e.g. `""` or `"0 (\ 0.0%)"`: substitute
    missing counts with that string.

## Value

- *numeric method*: a character vector of the same length as `n`.

- *data.frame method*: the input `data.frame` with the named count
  columns replaced by formatted character strings; all other columns are
  unchanged.

## Details

Counts are converted to integer before formatting so that both integer
and whole-number double vectors are accepted.

Percentages are formatted as `"%5.1f%%"`, giving one decimal place and a
minimum field width of 5 characters (e.g. `" 5.0%"`, `"100.0%"`). The
fixed width ensures vertical alignment when columns are printed
side-by-side.

A warning is issued when any element of `totals` is zero, as this
produces `Inf` in the percentage.

## Examples

``` r
## Numeric method — single total
ks_n_pct(c(10L, 20L, 30L), 56L)
#> [1] "10 ( 17.9%)" "20 ( 35.7%)" "30 ( 53.6%)"

## Numeric method — element-wise totals
ks_n_pct(c(10L, 20L, 30L), c(34L, 42L, 56L))
#> [1] "10 ( 29.4%)" "20 ( 47.6%)" "30 ( 53.6%)"

## NA propagation (default)
ks_n_pct(c(10L, NA_integer_, 30L), 50L)
#> [1] "10 ( 20.0%)" NA            "30 ( 60.0%)"

## Replace NA with an explicit string
ks_n_pct(c(10L, NA_integer_, 30L), 50L, na.rep = "0 (  0.0%)")
#> [1] "10 ( 20.0%)" "0 (  0.0%)"  "30 ( 60.0%)"

## Replace NA with an empty string
ks_n_pct(c(10L, NA_integer_, 30L), 50L, na.rep = "")
#> [1] "10 ( 20.0%)" ""            "30 ( 60.0%)"

## data.frame method
dex <- data.frame(
  par       = c("A", "B", "C"),
  Therapy_A = c(11L, 23L, 14L),
  Therapy_B = c(20L,  1L, NA_integer_)
)
ks_n_pct(dex, c(Therapy_A = 56L, Therapy_B = 67L))
#>   par   Therapy_A   Therapy_B
#> 1   A 11 ( 19.6%) 20 ( 29.9%)
#> 2   B 23 ( 41.1%)  1 (  1.5%)
#> 3   C 14 ( 25.0%)        <NA>

## data.frame method — keep only one column
ks_n_pct(dex, c(Therapy_A = 56L))
#>   par   Therapy_A Therapy_B
#> 1   A 11 ( 19.6%)        20
#> 2   B 23 ( 41.1%)         1
#> 3   C 14 ( 25.0%)        NA
```
