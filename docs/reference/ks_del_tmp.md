# Remove temporary objects from global environment

Removes objects whose names start with `t.` or `o.` (if `o=TRUE`), or
only `t.` (if `o=FALSE`).

## Usage

``` r
ks_del_tmp(o = TRUE)
```

## Arguments

- o:

  If `TRUE`, remove names matching `^[to]\.`; if `FALSE`, only `^t\.`.
