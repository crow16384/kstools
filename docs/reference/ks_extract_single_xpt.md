# Extract one dataset from a multi-member SAS XPORT v8/v9 file

Reads a single member from the file by splicing the file-level header
bytes onto the member's raw bytes, then passing the combined buffer to
`read_xpt`.

## Usage

``` r
ks_extract_single_xpt(name, file, content)
```

## Arguments

- name:

  Character name of the member to read (must match a name in `content`,
  i.e. lower-case).

- file:

  Path to the XPORT file.

- content:

  Named list returned by
  [`ks_xpt_content`](https://crow16384.github.io/kstools/reference/ks_xpt_content.md)`(file)`.

## Value

A [`tibble`](https://tibble.tidyverse.org/reference/tibble.html) (as
returned by `read_xpt`).

## Details

A valid XPORT stream requires both the 240-byte file header (three
80-byte LIBV8 records) and the member data. This function prepends the
file header so that `haven::read_xpt` can parse the member in isolation.

## See also

[`ks_xpt_content`](https://crow16384.github.io/kstools/reference/ks_xpt_content.md),
[`ks_batch_load_from_single_xpt`](https://crow16384.github.io/kstools/reference/ks_batch_load_from_single_xpt.md)

## Examples

``` r
if (FALSE) { # \dontrun{
content <- ks_xpt_content("study.xpt")
ae      <- ks_extract_single_xpt("ae", "study.xpt", content)
} # }
```
