# Check SDTM supplemental dataset structure

Validates that a SUPP– domain data frame has the required SDTM structure
and internally consistent `IDVAR`/`IDVARVAL` columns.

## Usage

``` r
ks_supp_consistency_check(data)
```

## Arguments

- data:

  A data frame or tibble representing a SUPP– domain.

## Value

A named logical vector of length 3:

- `isvalid`:

  Dataset passes structural checks.

- `noid`:

  `TRUE` when all `IDVAR`/`IDVARVAL` are blank — merge key is `USUBJID`
  only.

- `multid`:

  `TRUE` when more than one distinct non-blank `IDVAR` value is present.

## Details

Two structural rules are enforced:

1.  All seven standard SUPP columns must be present: `STUDYID`,
    `USUBJID`, `IDVAR`, `IDVARVAL`, `QNAM`, `QLABEL`, `QVAL`.

2.  Every one of those seven columns must be of type `character`.

If both rules pass, the function further inspects `IDVAR`/`IDVARVAL`:

- **All blank** (empty string or `NA`): the merge key is `USUBJID` alone
  (`noid = TRUE`).

- **All non-blank**: a record-level key is available (`noid = FALSE`).

- **Mixed**: considered invalid — `isvalid` is set to `FALSE`.

## See also

[`ks_supp_merge`](https://crow16384.github.io/kstools/reference/ks_supp_merge.md)

## Examples

``` r
supp <- data.frame(
  STUDYID  = "S1",
  USUBJID  = c("01", "02"),
  IDVAR    = "",
  IDVARVAL = "",
  QNAM     = "RACE2",
  QLABEL   = "Race (detail)",
  QVAL     = c("Asian", "White"),
  stringsAsFactors = FALSE
)
ks_supp_consistency_check(supp)
#> isvalid    noid  multid 
#>    TRUE    TRUE   FALSE 

## Invalid: missing required column
bad <- supp[, -which(names(supp) == "QLABEL")]
ks_supp_consistency_check(bad)
#> isvalid    noid  multid 
#>   FALSE      NA      NA 
```
