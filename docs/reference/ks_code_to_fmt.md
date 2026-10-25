# Build a named format vector from a coded column

Reads a column that contains `"code=label"` entries, splits them on `=`,
and passes the resulting lookup to
[`ksformat::fnew()`](https://crow16384.github.io/ksformat/reference/fnew.html)
as a numeric format.

## Usage

``` r
ks_code_to_fmt(dt, col, name = NULL)
```

## Arguments

- dt:

  A data frame containing the coded column.

- col:

  `<tidy-select>` Bare name of the column with `"code=label"` values.

- name:

  Character scalar. Name to register the format under via
  [`ksformat::fnew()`](https://crow16384.github.io/ksformat/reference/fnew.html).
  Defaults to `"<dt_name>_<col_name>_fmt"`.

## Value

Invisibly returns the result of
[`ksformat::fnew()`](https://crow16384.github.io/ksformat/reference/fnew.html)
(called for its side-effect of registering the format).

## Examples

``` r
if (FALSE) { # \dontrun{
# dt has a column DECODE with entries like "1=Male", "2=Female"
ks_code_to_fmt(dm, DECODE)
} # }
```
