# Read CSV file with column types and lengths in comments

Read a single CSV file into R. Optionally parses KeyStat-style comment
headers that encode column type, length (for character variables), and
labels.

## Usage

``` r
read.csv3(file, with_length = FALSE)
```

## Arguments

- file:

  Path to the source CSV file.

- with_length:

  If `TRUE`, the CSV file contains KeyStat metadata comments with types
  and lengths. Default is `FALSE`.

## Value

A data frame with column labels set from the comment metadata (when
available).

## Details

File encoding should be UTF-8. Readable comments in the CSV file:
`#NAME$character(length)|numeric$Label`.

This function was written for correct reading of CSV files. Some CSV
files without metadata in comments cannot be read correctly into R.

## See also

[`ks_get_data`](https://crow16384.github.io/kstools/reference/ks_get_data.md)
