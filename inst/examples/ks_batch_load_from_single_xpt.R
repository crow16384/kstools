## ============================================================
## ks_batch_load_from_single_xpt() — multi-member XPT utility
## ============================================================

library(kstools)

## This workflow requires a SAS XPORT v8/v9 file with multiple members.
## Typical path:
##   xpt_file <- "path/to/study_multi_member.xpt"
##   ks_batch_load_from_single_xpt(xpt_file, action = "load")
##
## Save all members as .rds files:
##   out_dir <- file.path(tempdir(), "xpt_rds")
##   ks_batch_load_from_single_xpt(
##     file = xpt_file,
##     action = "save",
##     save_type = "rds",
##     save_path = out_dir
##   )

## Guarded runnable skeleton (replace `xpt_file` with a real file path):
xpt_file <- "path/to/study_multi_member.xpt"
if (file.exists(xpt_file) && requireNamespace("haven", quietly = TRUE)) {
  loaded <- ks_batch_load_from_single_xpt(xpt_file, action = "load")
  print(names(loaded))
}
