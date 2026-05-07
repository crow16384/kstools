# Set SAS variable labels on a data frame

Sets the \`"label"\` attribute of selected columns from a named
character vector. Names of \`labels\` must match column names in
\`data\`. Unknown names are warned about and skipped.

## Usage

``` r
ks_set_labels(data, labels)
```

## Arguments

- data:

  A data frame or tibble.

- labels:

  Named character vector. Names are column names; values are labels. Use
  \`NA\` or empty string to keep an existing label.

## Value

The input \`data\` with \`"label"\` attributes updated.

## See also

\[ks_xpt_labels()\], \[ks_set_formats()\]
