# Write a data frame to a SAS XPORT (.xpt) file

Writes a data frame to a SAS XPORT V5 or V8 file using a built-in C++
writer. Variable labels and SAS formats are taken from per-column
attributes (\`"label"\`, \`"format.sas"\`) or the optional \`labels\` /
\`formats\` arguments, which override attributes.

## Usage

``` r
ks_write_xpt(
  data,
  file,
  version = 5L,
  convert_dates = TRUE,
  dataset_name = NULL,
  dataset_label = NULL,
  labels = NULL,
  formats = NULL
)
```

## Arguments

- data:

  A data frame.

- file:

  Output path.

- version:

  Integer 5 or 8. Default \`5L\` (widest compatibility).

- convert_dates:

  Logical. If \`TRUE\` (default), \`Date\` and \`POSIXct\` columns are
  converted to SAS numeric (days / seconds since 1960-01-01).

- dataset_name:

  SAS dataset name. Up to 8 characters for V5, up to 32 for V8. Defaults
  to \`"DATASET"\`.

- dataset_label:

  Up to 40 characters describing the dataset.

- labels:

  Optional named character vector of variable labels keyed by column
  name. Overrides per-column \`"label"\` attributes.

- formats:

  Optional named character vector of SAS formats (e.g. \`"DATE9."\`,
  \`"F8.2"\`) keyed by column name. Overrides per-column
  \`"format.sas"\` attributes.

## Value

The output file path, invisibly.

## Details

Date and datetime conversion, when enabled, applies the R-to-SAS epoch
shift to columns of class \`Date\` or \`POSIXct\`.

## See also

\[ks_read_xpt()\]
