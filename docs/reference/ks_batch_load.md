# Batch load files from a directory or ZIP

Loads all files of one type from a directory (or `.zip`) in batch.
Supported types are `csv`, `xlsx`, `xpt`, and `rds`. Results can be
returned as a named list, assigned to `.GlobalEnv`, saved as individual
`.rds`, and/or saved as one `.RData`.

## Usage

``` r
ks_batch_load(
  data,
  type = c("csv", "xlsx", "xpt", "rds"),
  save.path = NULL,
  keep = FALSE,
  save.rdata = NULL,
  with_length = FALSE,
  recursive = FALSE
)
```

## Arguments

- data:

  Path to a directory or a `.zip` file.

- type:

  One of `"csv"`, `"xlsx"`, `"xpt"`, `"rds"`.

- save.path:

  Optional directory where loaded objects are saved as `.rds`.

- keep:

  If `TRUE`, assign loaded objects into `.GlobalEnv`.

- save.rdata:

  Optional path to a `.RData` file.

- with_length:

  Passed to `foreign::read.csv3` for CSV loading.

- recursive:

  If `TRUE`, search recursively under `data`.

## Value

Named list of loaded objects.
