## ============================================================
## ks_save2xlsx_by() — split-by-sheet export with highlighting
## ============================================================

library(kstools)

if (requireNamespace("openxlsx2", quietly = TRUE)) {
  dat <- data.frame(
    type = c("DM", "DM", "AE", "AE"),
    USUBJID = c("01-001", "01-002", "01-001", "01-002"),
    check_msgs = c("OK", "Missing AGE", "OK", "Severe AE"),
    status = c("", "changed", "", "new"),
    stringsAsFactors = FALSE
  )

  out_file <- file.path(tempdir(), "checks_demo.xlsx")

  ks_save2xlsx_by(
    data = dat,
    file = out_file,
    colors = c("Missing" = "#FFF2CC", "Severe" = "#F8CBAD", "OK" = "#E2F0D9"),
    split_col = type,
    msg_col = check_msgs,
    status_col = status,
    status_colors = c("new" = "#D9E1F2", "changed" = "#FCE4D6"),
    na_to_empty = TRUE
  )

  file.exists(out_file)
}
