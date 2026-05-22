# Read a SAS XPORT (.xpt) file

Reads a SAS XPORT v5 or v8/v9 file using a built-in C++ parser. Variable
labels, formats, and informats are preserved as column attributes
(\`"label"\`, \`"format.sas"\`, \`"sas.informat"\`). Multi-member files
are returned as a named list of tibbles, one per dataset.

## Usage

``` r
ks_read_xpt(file, convert_dates = TRUE, warn = TRUE, n_threads = NULL)
```

## Arguments

- file:

  Path to a SAS XPORT file.

- convert_dates:

  Logical. If \`TRUE\` (default), columns formatted as SAS dates or
  datetimes are converted to R \`Date\` / \`POSIXct\`. If \`FALSE\`,
  such columns are returned as numeric SAS day / second values.

- warn:

  Logical. If \`TRUE\` (default), parser warnings are emitted via
  \[cli::cli_warn\].

- n_threads:

  Integer or \`NULL\`. Number of decoder threads to use. \`NULL\`
  (default) selects \`max(1, parallel::detectCores() - 1)\`. Set to
  \`1L\` for fully deterministic single-threaded decoding.

## Value

A tibble for a single-member file, or a named list of tibbles for a
multi-member file.

## Details

Date and datetime conversion, when enabled, applies the SAS-to-R epoch
shift of 3653 days (315,619,200 seconds) and assigns the appropriate
\`Date\` / \`POSIXct\` class to columns whose SAS format is recognised
as a date or datetime format.

## See also

\[ks_write_xpt()\], \[ks_xpt_labels()\], \[ks_xpt_formats()\],
\[ks_set_labels()\], \[ks_set_formats()\]
