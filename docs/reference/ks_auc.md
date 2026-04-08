# Area Under the Curve (AUC) by the trapezoidal rule

Computes AUC from concentration–time data using the linear or log-linear
trapezoidal method. Handles grouped data via a character vector of
grouping column names.

## Usage

``` r
ks_auc(data, by = NULL, val, time, type = c("trapez", "log-trapez"))
```

## Arguments

- data:

  A data frame or tibble.

- by:

  Character vector of grouping column names, e.g. `c("usubjid", "trt")`.
  `NULL` (default) computes a single AUC across the whole dataset.

- val:

  Unquoted name of the concentration (value) column.

- time:

  Unquoted name of the time column (numeric).

- type:

  AUC method: `"trapez"` (linear, default) or `"log-trapez"`
  (log-linear).

## Value

- When `by = NULL`: a single numeric value.

- When `by` is provided: a `data.frame` with one row per group and an
  `AUC` column appended to the grouping columns.

## Details

**Linear trapezoid** (`type = "trapez"`): \$\$AUC_i = \frac{C_i +
C\_{i+1}}{2} \cdot (t\_{i+1} - t_i)\$\$

**Log-linear trapezoid** (`type = "log-trapez"`): \$\$AUC_i =
\frac{C\_{i+1} - C_i}{\ln C\_{i+1} - \ln C_i} \cdot (t\_{i+1} - t_i)\$\$

The log-linear method is preferred during elimination phases where
concentrations decline exponentially. It requires strictly positive
concentrations; when two consecutive values are equal or one is \\\leq
0\\ the interval automatically falls back to the linear rule.

Rows are sorted by `c(by, time)` before computing so the caller does not
need to pre-sort the data.

## See also

`ks_auc` for the vectorised helper

## Examples

``` r
## Single subject — linear trapezoid
pk1 <- data.frame(conc = c(0, 4, 2, 1), time = c(0, 1, 2, 4))
ks_auc(pk1, val = conc, time = time)
#> [1] 8

## Two subjects — grouped
pk2 <- data.frame(
  id   = c("A","A","A","B","B","B"),
  conc = c(0, 4, 1,  0, 6, 2),
  time = c(0, 1, 2,  0, 1, 2)
)
ks_auc(pk2, by = "id", val = conc, time = time)
#>   id AUC
#> 1  A 4.5
#> 2  B 7.0
```
