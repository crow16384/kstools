# Align decimal (or first space) in character vector

Aligns strings so that the decimal point or first space after digits is
vertically aligned. NA values are replaced by `na.rep`.

## Usage

``` r
ks_aligndec(var, na.rep = "")
```

## Arguments

- var:

  Character vector (or coercible to character).

- na.rep:

  String to use for NA values.

## Value

Character vector of the same length, with leading spaces so decimals
align.
