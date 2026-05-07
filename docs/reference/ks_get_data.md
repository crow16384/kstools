# Load domain files and return them

Reads one or more data files from `path` and returns them as
[`tibble`](https://tibble.tidyverse.org/reference/tibble.html)s. A
single-domain call returns a tibble; a multi-domain call returns a named
list of tibbles (names are the lowercased domain names).

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

For a single domain, a tibble. For two or more domains, a named list of
tibbles keyed by the lowercased domain name.

## Details

Supported formats: `.rds` (R native), `.xpt` (SAS XPORT), `.xlsx`
(Microsoft Excel), `.csv` (plain CSV), `.csv` with KeyStat comments
(`type = "csvks"`).

Domain names can be passed as bare names (`dm, ae`) or as quoted strings
(`"dm", "ae"`); both forms are accepted. Lookup against the directory is
**case-insensitive** for both stem and extension, so `ks_get_data(dm)`
and `ks_get_data(DM)` match any of `dm.xpt`, `DM.XPT`, `Dm.Xpt`, etc.

When `type = "auto"` (default), the function scans the directory for
files matching the requested domains and determines the format from the
extension of the first match. All requested domains must use the same
format.

The default search path is read from `getOption("path.data", ".")`. Set
this option in `.Rprofile` to avoid repeating the path in every call:

    options(path.data = "/my/project/data")

When two or more files in `path` share the same stem but differ only in
case (e.g. both `dm.xpt` and `DM.xpt` exist), the resolution strategy is
controlled by the global option `kstools.get_data.case`:

- `"error"`:

  (default) abort with a message listing the candidates.

- `"first"`:

  pick the first match in alphabetical order.

- `"lower"`:

  require the all-lowercase name to exist; otherwise abort.

- `"upper"`:

  require the all-uppercase name to exist; otherwise abort.

## See also

[`ks_batch_load`](https://crow16384.github.io/kstools/reference/ks_batch_load.md),
[`read.csv3`](https://crow16384.github.io/kstools/reference/read.csv3.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Load a single domain
options(path.data = "/project/data")
dm <- ks_get_data(dm)

## Case-insensitive lookup: works whether folder has dm.xpt or DM.XPT
dm <- ks_get_data(DM)

## Load multiple domains: returns a named list
dat <- ks_get_data(dm, ae, lb, path = "/project/data/xpt")
head(dat$dm)

## Force a specific file type
dm <- ks_get_data(dm, path = "/project/data", type = "xpt")

## Resolve case-duplicate filenames
options(kstools.get_data.case = "lower")  # prefer dm.xpt over DM.xpt
dm <- ks_get_data(dm, path = "/project/data")

## Quoted strings are also accepted
dat <- ks_get_data("dm", "ae", path = "/project/data")
} # }
```
