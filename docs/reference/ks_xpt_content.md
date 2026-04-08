# List datasets inside a SAS XPORT v8/v9 file

Scans the raw bytes of a SAS Transport Version 8 file for member
(`MEMBV8`) headers and returns the byte range of each member.

## Usage

``` r
ks_xpt_content(file, chunk_size = 5L * 80L * 1024L)
```

## Arguments

- file:

  Path to a `.xpt` or `.v9xpt` file.

- chunk_size:

  Number of raw bytes to read per pass. Default `5 * 80 * 1024`.

## Value

A named list; each element corresponds to one dataset and contains a
named integer vector `c(start = <1-based pos>, stop = <1-based pos>)`.

## Details

The file is read in chunks of `chunk_size` bytes (default approximately
400 KB). A `MEMBV8` header that spans two adjacent chunks would not be
detected; this is exceedingly unlikely for practical SDTM files.

## See also

[`ks_extract_single_xpt`](https://crow16384.github.io/kstools/reference/ks_extract_single_xpt.md),
[`ks_batch_load_from_single_xpt`](https://crow16384.github.io/kstools/reference/ks_batch_load_from_single_xpt.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## content <- ks_xpt_content("path/to/study.xpt")
## names(content)          # dataset names (lower-case)
## content[["ae"]]         # byte range for the AE member
} # }
```
