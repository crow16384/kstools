## ============================================================
## read.csv3() — read CSV with KeyStat-style metadata comments
## ============================================================

library(kstools)

csv_file <- file.path(tempdir(), "dm_meta.csv")

writeLines(c(
  "#USUBJID$character(7)$Subject identifier",
  "#AGE$numeric$Age in years",
  "#SEX$character(1)$Sex",
  "USUBJID,AGE,SEX",
  "01-001,45,M",
  "01-002,52,F"
), csv_file)

dm <- read.csv3(csv_file, with_length = TRUE)
dm
attr(dm$USUBJID, "label")
