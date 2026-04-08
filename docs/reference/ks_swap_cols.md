# Swap pairs of columns in a data frame

Exchanges column contents by name: for each named argument `lhs = rhs`,
the column named `lhs` receives the values that were in `rhs`, and `rhs`
receives the values that were in `lhs`. Multiple independent pairs can
be given in one call.

## Usage

``` r
ks_swap_cols(df, ...)
```

## Arguments

- df:

  A `data.frame`, `tibble`, or other object inheriting from
  `data.frame`.

- ...:

  Named pairs `col_a = col_b` (bare names only). Each name that appears
  on the left or right must be a column of `df`, and each column may
  appear at most once across all pairs (no overlapping swaps).

## Value

`df` with the specified column pairs exchanged (same class as the input
where possible).

## Details

The syntax `USUBJID = SUBJID` swaps the two columns: after the call, the
column still named `USUBJID` holds the former `SUBJID` values and vice
versa. This is useful when harmonising SDTM-style identifiers or fixing
column order after merges.

With zero pairs in `...`, `df` is returned unchanged.

## See also

[`ks_aligndec`](https://crow16384.github.io/kstools/reference/ks_aligndec.md)

## Examples

``` r
d <- data.frame(SUBJID = c("001", "002"), USUBJID = c("01-001", "01-002"))
ks_swap_cols(d, USUBJID = SUBJID)
#>   SUBJID USUBJID
#> 1 01-001     001
#> 2 01-002     002
```
