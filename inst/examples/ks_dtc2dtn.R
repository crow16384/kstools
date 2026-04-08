## ============================================================
## ks_dtc2dtn() — convert DTC strings to Date
## ============================================================

library(kstools)

dtc <- c(
  "2020",
  "2020-05",
  "2020-05-14",
  "2020-UN",
  "2020-11-UN",
  "2019-NA-NA",
  "bad"
)

data.frame(dtc = dtc, dtn = ks_dtc2dtn(dtc), stringsAsFactors = FALSE)
