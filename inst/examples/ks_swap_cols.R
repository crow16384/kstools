## ks_swap_cols — swap two or more column pairs in a data.frame
## -------------------------------------------------------------

library(kstools)

## 1. Single pair: exchange SUBJID and USUBJID
subj <- data.frame(
  SUBJID   = c("001", "002", "003"),
  USUBJID  = c("STUDY01-001", "STUDY01-002", "STUDY01-003"),
  AGE      = c(45, 52, 61)
)
ks_swap_cols(subj, USUBJID = SUBJID)


## 2. Two independent pairs in one call
wide <- data.frame(w1 = 1:3, w2 = 4:6, x1 = 7:9, x2 = 10:12)
ks_swap_cols(wide, w1 = w2, x1 = x2)


## 3. With tibble (class preserved)
if (requireNamespace("tibble", quietly = TRUE)) {
  tb <- tibble::tibble(a = 1:2, b = 3:4)
  ks_swap_cols(tb, a = b)
}


## 4. No-op: empty ... returns the input unchanged
d0 <- data.frame(z = 1)
identical(d0, ks_swap_cols(d0))


## 5. Always assign the return value (clearer than relying on replacement in place)
df <- data.frame(left = 1:3, right = 4:6)
df <- ks_swap_cols(df, left = right)
df
