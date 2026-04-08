## ============================================================
## ks_sum_na() and %+na% — add while propagating non-missing value
## ============================================================

library(kstools)

## Scalar examples
NA %+na% 10
12.3 %+na% 10
12.3 %+na% NA
NA %+na% NA

## Vectorized examples
c(1, 2, NA, 5) %+na% c(NA, 2, 3, NA)
ks_sum_na(c(1, NA, 3), c(NA, 2, 4))
