## ============================================================
## ks_get_labels() — list variable labels
## ============================================================

library(kstools)

df <- data.frame(
  USUBJID = c("01-001", "01-002"),
  AGE = c(45, 52),
  SEX = c("M", "F"),
  stringsAsFactors = FALSE
)

attr(df$USUBJID, "label") <- "Unique subject identifier"
attr(df$AGE, "label") <- "Age in years"

ks_get_labels(df)
