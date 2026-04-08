## ============================================================
## ks_williams() — randomized Williams design and schedule
## ============================================================

library(kstools)

## Example 1: 3 treatments (odd => 2*t sequences)
w3 <- ks_williams(
  tmts_num = 3,
  tmt_names = c("TestDrg", "ActCtrl", "Placebo"),
  sample_size = 18,
  seed_num = 20260408
)

w3$design
head(w3$schedule)

## Example 2: 4 treatments (even => t sequences)
w4 <- ks_williams(
  tmts_num = 4,
  tmt_names = c("Drug1A", "Drug2B", "ActCtrl", "Placebo"),
  sample_size = 24,
  seed_num = 20260408
)

w4$design
table(w4$schedule$Sequence)

## Optional RTF report
rtf_file <- file.path(tempdir(), "williams_design.rtf")
ks_williams(4, c("Drug1A", "Drug2B", "ActCtrl", "Placebo"), 24, out_rtf = rtf_file)
file.exists(rtf_file)
