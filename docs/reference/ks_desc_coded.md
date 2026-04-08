# Summarise hierarchically coded clinical items

Produces a tidy long-format count summary for data coded with a
two-level hierarchy, such as MedDRA System Organ Class / Preferred Term
(adverse events, medical history) or ATC group / drug (medications).

The function counts distinct subjects (`n`) and total events (`e`) at
three levels:

1.  **Overall total** — subjects with at least one record.

2.  **Level-1 total** (e.g. SOC) — subjects in that top-level group.

3.  **Level-2 detail** (e.g. PT) — subjects with that specific
    lower-level code.

The function returns raw counts only; apply
[`ks_n_pct`](https://crow16384.github.io/kstools/reference/ks_n_pct.md)
to the `n` column afterwards to produce formatted `"n (pct%)"` strings.
Rows where `<l2>` is `NA` are header / SOC-total rows (i.e. they would
be rendered bold in a report).

The function is intentionally single-arm: call it once per analysis
population or treatment arm and join the results on the `<l1>`, `<l2>`,
`ord0`, and `ord` key columns.

## Usage

``` r
ks_desc_coded(
  data,
  id = usubjid,
  l1 = meddra_soc,
  l2 = meddra_pt,
  tot_label = "Total subjects"
)
```

## Arguments

- data:

  A data frame or tibble containing the coded event records (one row per
  event, not one row per subject).

- id:

  \<\[\`data-masking\`\]\[dplyr::dplyr_data_masking\]\> Bare name of the
  column holding the unique subject identifier.

- l1:

  \<\[\`data-masking\`\]\[dplyr::dplyr_data_masking\]\> Bare name of the
  top-level code column (e.g. `meddra_soc`).

- l2:

  \<\[\`data-masking\`\]\[dplyr::dplyr_data_masking\]\> Bare name of the
  lower-level code column (e.g. `meddra_pt`).

- tot_label:

  Character string used as the label in the `<l1>` column for the
  overall-total row. Default: `"Total subjects"`.

## Value

A [`tibble`](https://tibble.tidyverse.org/reference/tibble.html) with
one row per display line, ordered by top-level code then lower-level
code:

- `ord0`, `ord`:

  Integer sort keys. `ord0 = 1` / `ord = 1`: overall total; `ord0 = 2` /
  `ord = 2`: level-1 (SOC) total; `ord0 = 2` / `ord = 3`: level-2 (PT)
  detail row.

- `<l1 name>`:

  Top-level code value. Contains `tot_label` for the overall-total row;
  the SOC name for all other rows.

- `<l2 name>`:

  Lower-level code value. `NA` for overall-total and level-1-total rows
  (these are the bold / header rows); PT name for detail rows.

- `n`:

  Distinct subject count for the group.

- `e`:

  Event count (number of source rows for the group).

## See also

[`ks_n_pct`](https://crow16384.github.io/kstools/reference/ks_n_pct.md)
for formatting `n` as `"n (pct%)"` once the population size is known.

## Examples

``` r
ae <- data.frame(
  usubjid = c("01","01","02","03","03","04"),
  soc = c("Cardiac","Cardiac","Nervous","Cardiac","Nervous","Nervous"),
  pt  = c("Palp","Tachy","Head","Palp","Dizzy","Head"),
  stringsAsFactors = FALSE
)

## Raw counts (N unknown at this stage)
res <- ks_desc_coded(ae, id = usubjid, l1 = soc, l2 = pt)
res
#>   ord0            soc ord    pt n e
#> 1    1 Total subjects   1  <NA> 4 6
#> 2    2        Cardiac   2  <NA> 2 3
#> 3    2        Cardiac   3  Palp 2 2
#> 4    2        Cardiac   3 Tachy 1 1
#> 5    2        Nervous   2  <NA> 3 3
#> 6    2        Nervous   3 Dizzy 1 1
#> 7    2        Nervous   3  Head 2 2

## Add formatted value column once pop is known
dplyr::mutate(res, value = ks_n_pct(n, totals = 10))
#>   ord0            soc ord    pt n e      value
#> 1    1 Total subjects   1  <NA> 4 6 4 ( 40.0%)
#> 2    2        Cardiac   2  <NA> 2 3 2 ( 20.0%)
#> 3    2        Cardiac   3  Palp 2 2 2 ( 20.0%)
#> 4    2        Cardiac   3 Tachy 1 1 1 ( 10.0%)
#> 5    2        Nervous   2  <NA> 3 3 3 ( 30.0%)
#> 6    2        Nervous   3 Dizzy 1 1 1 ( 10.0%)
#> 7    2        Nervous   3  Head 2 2 2 ( 20.0%)

## Multi-arm via group_modify(); pop looked up per arm
pop <- c(A = 5, B = 5)
ae$trt <- rep(c("A","B"), each = 3)
ae |>
  dplyr::group_by(trt) |>
  dplyr::group_modify(
    ~ ks_desc_coded(.x, id = usubjid, l1 = soc, l2 = pt) |>
      dplyr::mutate(value = ks_n_pct(n, pop[.y$trt]))
  ) |>
  dplyr::ungroup()
#> # A tibble: 12 × 8
#>    trt    ord0 soc              ord pt        n     e value     
#>    <chr> <int> <chr>          <int> <chr> <int> <int> <chr>     
#>  1 A         1 Total subjects     1 NA        2     3 2 ( 40.0%)
#>  2 A         2 Cardiac            2 NA        1     2 1 ( 20.0%)
#>  3 A         2 Cardiac            3 Palp      1     1 1 ( 20.0%)
#>  4 A         2 Cardiac            3 Tachy     1     1 1 ( 20.0%)
#>  5 A         2 Nervous            2 NA        1     1 1 ( 20.0%)
#>  6 A         2 Nervous            3 Head      1     1 1 ( 20.0%)
#>  7 B         1 Total subjects     1 NA        2     3 2 ( 40.0%)
#>  8 B         2 Cardiac            2 NA        1     1 1 ( 20.0%)
#>  9 B         2 Cardiac            3 Palp      1     1 1 ( 20.0%)
#> 10 B         2 Nervous            2 NA        2     2 2 ( 40.0%)
#> 11 B         2 Nervous            3 Dizzy     1     1 1 ( 20.0%)
#> 12 B         2 Nervous            3 Head      1     1 1 ( 20.0%)
```
