# Check duplicate records by key

Aggregates \`data\` by the supplied key column(s) and emits a
\`\[DUPLICATES\]\` warning when any key group holds more than one
record.

## Usage

``` r
ks_check_duplicates(data, ...)
```

## Arguments

- data:

  A data frame or tibble.

- ...:

  Unquoted (or quoted) column names forming the check key, e.g.
  \`STUDYID, USUBJID, VISIT\` or \`"STUDYID", "USUBJID"\`.

## Value

\`FALSE\` (invisibly) when duplicates were found and a warning was
issued, \`TRUE\` (invisibly) otherwise, so the call can be embedded in
pipeline sanity gates.

## Details

A record is a duplicate only when ALL key columns match (joint key),
mirroring \`dplyr::summarise(.by = c(...))\`. The dataset itself is
never modified and row order is irrelevant. \`NA\` values group like
regular values. The reported count is the number of duplicated KEY
GROUPS, not the number of surplus rows: three identical keys count as
one duplicate.

## Examples

``` r
d <- data.frame(STUDYID = c("A", "A", "B"), USUBJID = c("1", "1", "2"))
suppressWarnings(ks_check_duplicates(d, STUDYID, USUBJID))  # FALSE
suppressWarnings(ks_check_duplicates(d, STUDYID))           # TRUE
```
