## ============================================================
## ks_xpt_content() — inspect datasets in multi-member XPT
## ============================================================

library(kstools)

## Requires a SAS XPORT v8/v9 file containing multiple members.
## Example workflow:
##   xpt_file <- "path/to/study_multi_member.xpt"
##   content <- ks_xpt_content(xpt_file)
##   names(content)
##   content[[1]]
##
## Then extract one dataset:
##   ae <- ks_extract_single_xpt("ae", xpt_file, content)

xpt_file <- "path/to/study_multi_member.xpt"
if (file.exists(xpt_file)) {
  content <- ks_xpt_content(xpt_file)
  print(names(content))
}
