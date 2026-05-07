# Set SAS variable formats on a data frame

Sets the \`"format.sas"\` attribute of selected columns from a named
character vector.

## Usage

``` r
ks_set_formats(data, formats)
```

## Arguments

- data:

  A data frame or tibble.

- formats:

  Named character vector. Names are column names; values are SAS format
  strings (e.g. \`"DATE9."\`, \`"F8.2"\`, \`"\$20."\`).

## Value

The input \`data\` with \`"format.sas"\` attributes updated.

## See also

\[ks_xpt_formats()\], \[ks_set_labels()\]
