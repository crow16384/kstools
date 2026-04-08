# Convert DTC (date-time character) to Date

Parses ISO-like date strings (YYYY, YYYY-MM, YYYY-MM-DD) with optional
NA/UN for month or day, and converts to `Date`. Missing month/day become
1.

## Usage

``` r
ks_dtc2dtn(x)
```

## Arguments

- x:

  Character vector of date strings (e.g. `"2020-01-15"`, `"2020-UN"`).

## Value

A `Date` vector.
