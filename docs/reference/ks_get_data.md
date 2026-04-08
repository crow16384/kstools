# Load domain files into the global environment

Reads one or more data files from `path` and assigns them as
[`tibble`](https://tibble.tidyverse.org/reference/tibble.html)s to
variables in `.GlobalEnv` using the file stem (name without extension)
as the variable name.

## Usage

``` r
ks_get_data(
  ...,
  path = getOption("path.data", "."),
  type = c("auto", "rds", "xpt", "xlsx", "csv", "csvks")
)
```

## Arguments

- ...:

  Unquoted (or quoted) domain names, e.g. `dm, ae, lb`.

- path:

  Directory containing the data files. Defaults to
  `getOption("path.data", ".")`.

- type:

  File type: `"auto"` (detect from extension), `"rds"`, `"xpt"`,
  `"xlsx"`, `"csv"`, or `"csvks"` (CSV with KeyStat comment metadata).

## Value

Invisibly returns the character vector of loaded domain names.

## Details

Supported formats: `.rds` (R native), `.xpt` (SAS XPORT), `.xlsx`
(Microsoft Excel), `.csv` (plain CSV), `.csv` with KeyStat comments
(`type = "csvks"`).

Domain names can be passed as bare names (`dm, ae`) or as quoted strings
(`"dm", "ae"`); both forms are accepted.

When `type = "auto"` (default), the function scans the directory for
files matching the requested domains and determines the format from the
extension of the first match. All requested domains must use the same
format.

The default search path is read from `getOption("path.data", ".")`. Set
this option in `.Rprofile` to avoid repeating the path in every call:

    options(path.data = "/my/project/data")

## See also

[`ks_batch_load`](https://crow16384.github.io/kstools/reference/ks_batch_load.md),
[`read.csv3`](https://crow16384.github.io/kstools/reference/read.csv3.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Load dm and ae from the default path set via options()
options(path.data = "/project/data")
ks_get_data(dm, ae)

## Load from an explicit path (auto-detects file type)
ks_get_data(dm, ae, lb, path = "/project/data/xpt")

## Force a specific file type
ks_get_data(dm, ae, path = "/project/data", type = "xpt")

## Load CSV files with KeyStat comment headers
ks_get_data(dm, ae, path = "/project/data", type = "csvks")

## Quoted strings are also accepted
ks_get_data("dm", "ae", path = "/project/data")
} # }
```
