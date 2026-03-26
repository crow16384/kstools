## ============================================================
## ks_get_numdec() — max decimal places per group
## ============================================================
## Computes the maximum number of decimal digits (up to 4) for a
## numeric column within each group, and joins the result as NUMDEC.
## ============================================================

library(kstools)

## ------------------------------------------------------------------
## 1. Basic grouped usage
## ------------------------------------------------------------------
cat("=== 1. Basic grouped usage ===\n\n")

d <- data.frame(
  param = c("ALT", "ALT", "ALT", "AST", "AST"),
  aval  = c(12.3, 45.67, 8.0, 100.1, 99.999)
)

print(ks_get_numdec(d, "aval", "param"))

## ------------------------------------------------------------------
## 2. Integer values — NUMDEC = 0
## ------------------------------------------------------------------
cat("\n=== 2. Integer values ===\n\n")

d2 <- data.frame(grp = c("X", "X"), val = c(10, 20))
print(ks_get_numdec(d2, "val", "grp"))

## ------------------------------------------------------------------
## 3. NA handling — NAs ignored in max
## ------------------------------------------------------------------
cat("\n=== 3. NA handling ===\n\n")

d3 <- data.frame(
  grp = c("A", "A", "A"),
  val = c(1.23, NA, 4.5)
)
print(ks_get_numdec(d3, "val", "grp"))

## ------------------------------------------------------------------
## 4. Multiple grouping columns
## ------------------------------------------------------------------
cat("\n=== 4. Multiple grouping columns ===\n\n")

d4 <- data.frame(
  trt   = rep(c("Drug", "Placebo"), each = 3),
  visit = rep(c("V1", "V2", "V3"), 2),
  aval  = c(1.1, 2.34, 3.0, 4.567, 5.0, 6.78)
)
print(ks_get_numdec(d4, "aval", c("trt", "visit")))

## ------------------------------------------------------------------
## 5. Practical: format values to group-level precision
## ------------------------------------------------------------------
cat("\n=== 5. Format to group precision ===\n\n")

d5 <- ks_get_numdec(d4, "aval", "trt")
d5$formatted <- mapply(
  function(x, nd) formatC(x, format = "f", digits = nd),
  d5$aval, d5$NUMDEC
)
print(d5)
