# Merge an SDTM supplemental domain with its primary domain

Transposes a SUPP– dataset from long (one row per variable) to wide and
left-joins it onto the primary domain using the appropriate key columns.

## Usage

``` r
ks_supp_merge(primary, supp, mvars = NULL, get_labels = TRUE, rep_na = FALSE)
```

## Arguments

- primary:

  A data frame or tibble: the primary SDTM domain (e.g. `DM`, `EX`).

- supp:

  A data frame or tibble: the corresponding SUPP– domain (e.g. `SUPPDM`,
  `SUPPEX`). Must pass
  [`ks_supp_consistency_check`](https://crow16384.github.io/kstools/reference/ks_supp_consistency_check.md).

- mvars:

  Character vector of `QNAM` values to merge. `NULL` (default) merges
  all available variables.

- get_labels:

  Logical; if `TRUE` (default) attach `QLABEL` values as column
  `"label"` attributes on the merged columns.

- rep_na:

  Logical; if `TRUE` replace `NA` in merged columns with `""`. Default
  `FALSE`.

## Value

The `primary` data frame with SUPP variables added as new columns.

## Details

The merge strategy depends on `IDVAR`/`IDVARVAL`:

- **Subject-level** (`noid = TRUE`):

  All `IDVAR`/`IDVARVAL` are blank. The join key is `STUDYID + USUBJID`.

- **Record-level** (`noid = FALSE`):

  Each row in the SUPP is tied to a specific record in the primary
  domain. `IDVAR` names the primary domain variable (e.g. `EXSEQ`) and
  `IDVARVAL` holds its value. When multiple distinct `IDVAR` values are
  present, each is processed in a separate join pass.

If `get_labels = TRUE` and the primary domain was loaded via `haven` (or
another reader that preserves column `"label"` attributes), the
per-variable labels from `QLABEL` are attached to the newly added
columns.

## See also

[`ks_supp_consistency_check`](https://crow16384.github.io/kstools/reference/ks_supp_consistency_check.md)

## Examples

``` r
dm <- data.frame(
  STUDYID = "S1",
  USUBJID = c("01", "02", "03"),
  AGE     = c(34L, 52L, 47L),
  stringsAsFactors = FALSE
)
suppdm <- data.frame(
  STUDYID  = "S1",
  USUBJID  = c("01", "02", "03"),
  IDVAR    = "",
  IDVARVAL = "",
  QNAM     = "RACE2",
  QLABEL   = "Race (detail)",
  QVAL     = c("Asian", "White", "Asian"),
  stringsAsFactors = FALSE
)
ks_supp_merge(dm, suppdm)
#>   STUDYID USUBJID AGE RACE2
#> 1      S1      01  34 Asian
#> 2      S1      02  52 White
#> 3      S1      03  47 Asian
```
