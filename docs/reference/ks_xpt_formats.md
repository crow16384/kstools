# Get SAS variable formats from a data frame

Returns the \`"format.sas"\` attribute of each column as a named
character vector. Columns without a \`"format.sas"\` attribute are
reported as the empty string.

## Usage

``` r
ks_xpt_formats(data)
```

## Arguments

- data:

  A data frame or tibble.

## Value

Named character vector of SAS format strings (one entry per column).

## See also

\[ks_set_formats()\], \[ks_xpt_labels()\], \[ks_read_xpt()\],
\[ks_write_xpt()\]
