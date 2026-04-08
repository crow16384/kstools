# Backwards-compatible wrapper for `ks_batch_load` with `type = "xlsx"`

Calls
[`ks_batch_load`](https://crow16384.github.io/kstools/reference/ks_batch_load.md)
with `type = "xlsx"`. Provided for compatibility with older scripts that
used the xlsx-specific function name.

## Usage

``` r
ks_batch_load_xlsx(
  data,
  save.path = NULL,
  keep = FALSE,
  save.rdata = NULL,
  recursive = FALSE
)
```

## Arguments

- data:

  Path to a directory or a `.zip` file.

- save.path:

  Optional directory where loaded objects are saved as `.rds`.

- keep:

  If `TRUE`, assign loaded objects into `.GlobalEnv`.

- save.rdata:

  Optional path to a `.RData` file.

- recursive:

  If `TRUE`, search recursively under `data`.

## Value

Named list of loaded objects (see
[`ks_batch_load`](https://crow16384.github.io/kstools/reference/ks_batch_load.md)).

## See also

[`ks_batch_load`](https://crow16384.github.io/kstools/reference/ks_batch_load.md)
