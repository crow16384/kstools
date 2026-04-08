# Get the filename of the currently executing R script

Determines the filename of the currently executing R script by checking
two sources in order:

## Usage

``` r
ks_current_filename()
```

## Value

A character string with the base name of the current script. Returns an
empty string (`""`) if the filename cannot be determined from either
source (e.g. when running interactively in the R console).

## Details

1.  **source() call** — inspects the call stack for the closest
    [`source()`](https://rdrr.io/r/base/source.html) frame and reads its
    `filename` environment variable.

2.  **CLI argument** — inspects the command-line arguments for a `-f` or
    `--file=` flag (as used by `Rscript foo.R` or `R --slave -f foo.R`).

Only the [`basename`](https://rdrr.io/r/base/basename.html) of the
resolved path is returned.

## See also

[`basename`](https://rdrr.io/r/base/basename.html),
[`source`](https://rdrr.io/r/base/source.html),
[`commandArgs`](https://rdrr.io/r/base/commandArgs.html)

## Examples

``` r
if (FALSE) { # \dontrun{
# Inside a sourced file or a script run with Rscript:
ks_current_filename()
#> "my_script.R"

# In an interactive session where no script name is available:
ks_current_filename()
#> ""
} # }
```
