## ks_get_data — load RDS domain files into the global environment
## ---------------------------------------------------------------

library(kstools)

# Helper: write several small domain files to a temp directory
rds_dir <- tempdir()

saveRDS(data.frame(USUBJID = c("01-001", "01-002"),
                   AGE     = c(45L, 52L),
                   SEX     = c("M", "F")),
        file.path(rds_dir, "dm.rds"))

saveRDS(data.frame(USUBJID = c("01-001", "01-001", "01-002"),
                   AETERM  = c("Headache", "Nausea", "Fatigue"),
                   AESEV   = c("MILD", "MODERATE", "MILD")),
        file.path(rds_dir, "ae.rds"))

saveRDS(data.frame(USUBJID = c("01-001", "01-002"),
                   LBTEST  = c("Haemoglobin", "Haemoglobin"),
                   LBORRES = c("13.2", "14.1")),
        file.path(rds_dir, "lb.rds"))


## 1. Load a single domain (bare name) ----------------------------------------
ks_get_data(dm, path = rds_dir)
head(dm)
# USUBJID AGE SEX
# 01-001   45   M
# 01-002   52   F


## 2. Load multiple domains in one call ----------------------------------------
ks_get_data(ae, lb, path = rds_dir)
nrow(ae)   # 3
nrow(lb)   # 2


## 3. Quoted strings work the same as bare names -------------------------------
ks_get_data("dm", "ae", path = rds_dir)
identical(dm, get("dm", envir = .GlobalEnv))  # TRUE


## 4. Use getOption("path.data.rds") to avoid repeating the path --------------
# Set once in .Rprofile so all scripts share it:
#   options(path.data.rds = "/project/data/rds")

options(path.data.rds = rds_dir)
ks_get_data(dm, ae, lb)   # path is now inferred from option


## 5. Capture the return value (domain names that were loaded) -----------------
loaded <- ks_get_data(dm, ae, path = rds_dir)
loaded  # c("dm", "ae")


## 6. Clear error when the directory is wrong ----------------------------------
tryCatch(
  ks_get_data(dm, path = "/no/such/path"),
  error = function(e) message("Caught: ", conditionMessage(e))
)
# Caught: Directory not found: /no/such/path


## 7. Clear error when a specific file is absent -------------------------------
tryCatch(
  ks_get_data(dm, missing_domain, path = rds_dir),
  error = function(e) message("Caught: ", conditionMessage(e))
)
# Caught: File not found: .../missing_domain.rds


## 8. Load plain CSV domains ---------------------------------------------------
csv_dir <- file.path(tempdir(), "csv_demo")
dir.create(csv_dir, showWarnings = FALSE)

write.csv(data.frame(USUBJID = c("01-001", "01-002"),
                     AGE     = c(45L, 52L),
                     SEX     = c("M", "F")),
          file.path(csv_dir, "dm.csv"), row.names = FALSE)

ks_get_data(dm, path = csv_dir, type = "csv")
head(dm)


## 9. Load CSV with KeyStat comment headers ------------------------------------
ks_csv_dir <- file.path(tempdir(), "csvks_demo")
dir.create(ks_csv_dir, showWarnings = FALSE)

writeLines(c(
  "#USUBJID$character(7)$Subject ID",
  "#AGE$numeric$Age",
  "#SEX$character(1)$Sex",
  "USUBJID,AGE,SEX",
  "01-001,45,M",
  "01-002,52,F"
), file.path(ks_csv_dir, "dm.csv"))

ks_get_data(dm, path = ks_csv_dir, type = "csvks")
head(dm)
attr(dm$USUBJID, "label")  # "Subject ID"


## 10. Use read.csv3() directly ------------------------------------------------
dm2 <- read.csv3(file.path(ks_csv_dir, "dm.csv"), with_length = TRUE)
str(dm2)


## 11. Typical project workflow ------------------------------------------------
## In .Rprofile:
##   options(path.data = file.path(Sys.getenv("PROJECT_ROOT"), "data"))
##
## In analysis script:
##   library(kstools)
##   ks_get_data(dm, ae, lb, ex, vs, cm)   # loads all needed domains
