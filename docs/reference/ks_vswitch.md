# Vectorized switch (SAS select-when maps)

Looks up each element of \`x\` among the named values of \`...\` — a
\`switch()\` that works on a whole vector at once, like SAS
\`select(when ...)\` or a format-driven recode.

## Usage

``` r
ks_vswitch(.x, ..., .na = NULL, .default = NULL)
```

## Arguments

- .x:

  A vector of lookup keys (character, factor, or numeric; coerced with
  [`as.character()`](https://rdrr.io/r/base/character.html) for
  matching).

- ...:

  Named values of a \*\*single common type\*\* — the names are keys, the
  values are results. \`vapply()\` errors when the types disagree.

- .na:

  Value returned where \`x\` is \`NA\`; defaults to an \`NA\` of the
  same type as the first value of \`...\`.

- .default:

  Value returned for keys present in \`x\` but absent from \`...\`;
  defaults to an \`NA\` of the same type as the first value of \`...\`.

## Value

A vector the same length as \`.x\` with the storage type of the values
in \`...\`. The key argument is named \`.x\` (leading dot) so that bare
case names like \`x = ...\` in dots cannot collide with it.

## Examples

``` r
ks_vswitch(c("a", "b", "a", NA, "zz"), a = 10L, b = 20L)
#> [1] 10 20 10 NA NA
ks_vswitch(c("a", "b", NA, "zz"), a = 10L, b = 20L, .na = 0L, .default = -1L)
#> [1] 10 20  0 -1
ks_vswitch(factor(c("x", "y")), x = 1.5, y = 2.5)
#> [1] 1.5 2.5
```
