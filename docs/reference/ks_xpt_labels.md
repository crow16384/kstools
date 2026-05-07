# Get SAS variable labels from a data frame

Returns the \`"label"\` attribute of each column as a named character
vector. Columns without a \`"label"\` attribute are reported as the
empty string.

## Usage

``` r
ks_xpt_labels(data)
```

## Arguments

- data:

  A data frame or tibble.

## Value

Named character vector of variable labels (one entry per column).

## See also

\[ks_set_labels()\], \[ks_xpt_formats()\], \[ks_read_xpt()\],
\[ks_write_xpt()\]
