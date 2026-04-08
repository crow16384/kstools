## ============================================================
## ks_batch_load() — batch import from directory/zip
## ============================================================

library(kstools)

src <- file.path(tempdir(), "ks_batch_load_demo")
dir.create(src, recursive = TRUE, showWarnings = FALSE)

## Prepare RDS and CSV payloads
saveRDS(data.frame(id = 1:3, val = c("A", "B", "C")), file.path(src, "dm.rds"))
saveRDS(data.frame(id = 1:2, flag = c(TRUE, FALSE)), file.path(src, "adsl.rds"))
write.csv(data.frame(id = 1:2, trt = c("Drug", "Placebo")), file.path(src, "trt.csv"), row.names = FALSE)

## 1) Load all RDS as a named list
res_rds <- ks_batch_load(src, type = "rds")
names(res_rds)

## 2) Load CSV files
res_csv <- ks_batch_load(src, type = "csv")
names(res_csv)

## 3) Keep in .GlobalEnv (lower-case object names)
ks_batch_load(src, type = "rds", keep = TRUE)
exists("dm", envir = .GlobalEnv)

## 4) Save loaded objects as per-object RDS
save_dir <- file.path(tempdir(), "ks_batch_load_saved")
ks_batch_load(src, type = "rds", save.path = save_dir)
list.files(save_dir, pattern = "\\.rds$", full.names = FALSE)

## 5) Save as one .RData
rdata_path <- file.path(tempdir(), "ks_batch_objects.RData")
ks_batch_load(src, type = "rds", save.rdata = rdata_path)
file.exists(rdata_path)
