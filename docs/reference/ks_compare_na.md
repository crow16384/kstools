# NA-aware element-wise comparison

Element-wise \`==\` returns \`NA\` whenever either side is missing,
which makes it unusable for comparing vectors that legitimately contain
\`NA\`. \`ks_compare_na()\` treats \`NA\` as an ordinary value, so two
missing entries at the same position are considered \*\*equal\*\* — the
R twin of SAS's \`NULL=\` comparison operators.

## Usage

``` r
ks_compare_na(x, y)
```

## Arguments

- x, y:

  Vectors compared element by element; the shorter is recycled. Works
  for numeric, character, and factor vectors (levels need not match).

## Value

A logical vector with the common recycled length, never \`NA\`.

## See also

[`ks_sum_na`](https://crow16384.github.io/kstools/reference/ks_sum_na.md)
for NA-aware arithmetic.

## Examples

``` r
ks_compare_na(c(NA, "A", "B"), c(NA, "A", "C"))
#> [1]  TRUE  TRUE FALSE
ks_compare_na(c(1, NA, 3), c(1, 2, NA))
#> [1]  TRUE FALSE FALSE
```
