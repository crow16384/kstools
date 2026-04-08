# Load or save all datasets from a multi-member SAS XPORT v8/v9 file

Iterates all members found by
[`ks_xpt_content`](https://crow16384.github.io/kstools/reference/ks_xpt_content.md)
and either assigns them into `.GlobalEnv` or writes them to disk.

## Usage

``` r
ks_batch_load_from_single_xpt(
  file,
  action = "load",
  save_type = NULL,
  save_path = NULL
)
```

## Arguments

- file:

  Path to the XPORT file.

- action:

  `"load"` (assign to `.GlobalEnv`) or `"save"` (write to disk).

- save_type:

  For `action = "save"`: one of `"rdata"`, `"rds"`, or `"parquet"`.

- save_path:

  For `action = "save"`:

  - `"rdata"`: path *without* extension (appended automatically).

  - `"rds"` / `"parquet"`: path to an existing *directory*.

## Value

Invisibly returns a named list of all extracted datasets.

## Details

- `action = "load"`:

  Each dataset is assigned into `.GlobalEnv` using its lower-case member
  name.

- `action = "save", save_type = "rdata"`:

  All datasets are saved together into a single `.RData` file at
  `save_path` (the `.RData` extension is appended automatically). The
  global environment is *not* modified.

- `action = "save", save_type = "rds"`:

  Each dataset is saved as a separate `.rds` file inside the `save_path`
  directory.

- `action = "save", save_type = "parquet"`:

  Each dataset is saved as a separate Parquet file (requires the arrow
  package).

Members are extracted in parallel on non-Windows platforms
([`mclapply`](https://rdrr.io/r/parallel/mclapply.html));
[`lapply`](https://rdrr.io/r/base/lapply.html) is used on Windows.

## See also

[`ks_xpt_content`](https://crow16384.github.io/kstools/reference/ks_xpt_content.md),
[`ks_extract_single_xpt`](https://crow16384.github.io/kstools/reference/ks_extract_single_xpt.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Load all members into .GlobalEnv
ks_batch_load_from_single_xpt("study.xpt", action = "load")

## Save each member as .rds
ks_batch_load_from_single_xpt("study.xpt",
                               action    = "save",
                               save_type = "rds",
                               save_path = "data/")
} # }
```
