## ============================================================
## ks_batch_load_xlsx() — compatibility wrapper around ks_batch_load
## ============================================================

library(kstools)

if (requireNamespace("openxlsx2", quietly = TRUE)) {
  xdir <- file.path(tempdir(), "ks_xlsx_demo")
  dir.create(xdir, recursive = TRUE, showWarnings = FALSE)

  wb1 <- openxlsx2::wb_workbook() |>
    openxlsx2::wb_add_worksheet("Sheet1") |>
    openxlsx2::wb_add_data(data.frame(id = 1:3, arm = c("A", "B", "A")))
  openxlsx2::wb_save(wb1, file.path(xdir, "adsl.xlsx"))

  wb2 <- openxlsx2::wb_workbook() |>
    openxlsx2::wb_add_worksheet("Sheet1") |>
    openxlsx2::wb_add_data(data.frame(id = 1:3, aval = c(10.1, 11.2, 9.9)))
  openxlsx2::wb_save(wb2, file.path(xdir, "adlb.xlsx"))

  x <- ks_batch_load_xlsx(xdir)
  names(x)
}
