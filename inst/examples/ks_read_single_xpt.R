## ============================================================
## ks_xpt_content() / ks_extract_single_xpt()
##   / ks_batch_load_from_single_xpt()
##
## Utilities for SAS XPORT v8/v9 multi-member files.
## ============================================================
## A SAS XPORT Version 8 file can contain multiple datasets
## (members) stored end-to-end in a single binary file.
## haven::read_xpt() reads the whole file as one dataset and
## cannot isolate individual members.
##
## Workflow:
##   1. ks_xpt_content(file)            → index of member byte ranges
##   2. ks_extract_single_xpt(nm, ...)  → one member as a tibble
##   3. ks_batch_load_from_single_xpt() → all members at once
## ============================================================

library(kstools)

## ------------------------------------------------------------------
## Note: a real XPORT v8 file is required to run most of these
## examples.  The code uses a synthetic binary only for structural
## demos; haven::read_xpt() on synthetic bytes will fail.
## ------------------------------------------------------------------

## Helper used throughout this script ──────────────────────────────
make_v8_xpt <- function(dataset_names, path = tempfile(fileext = ".xpt")) {
  pad80 <- function(s) formatC(s, width = 80L, flag = "-")
  file_hdr <- paste0(
    pad80("HEADER RECORD*******LIBV8   HEADER RECORD!!!!!!!"),
    pad80(""), pad80("")
  )
  member_blocks <- vapply(dataset_names, function(nm) {
    paste0(
      pad80("HEADER RECORD*******MEMBV8  HEADER RECORD!!!!!!!"),
      pad80(""),
      paste0(strrep(" ", 8L), formatC(nm, width = 32L, flag = "-"), strrep(" ", 40L))
    )
  }, character(1L))
  writeBin(charToRaw(paste0(c(file_hdr, member_blocks), collapse = "")), path)
  path
}

## ══════════════════════════════════════════════════════════════════
## 1. List members in a multi-member v8 file
## ══════════════════════════════════════════════════════════════════
cat("=== 1. ks_xpt_content() — scan member headers ===\n\n")

## Synthetic file with five member headers
xpt_path <- make_v8_xpt(c("DM", "AE", "LB", "EX", "CM"))

content <- ks_xpt_content(xpt_path)

cat("Members found:", paste(names(content), collapse = ", "), "\n\n")

for (nm in names(content)) {
  cat(sprintf("  %-6s  start = %5d  stop = %5d  size = %d bytes\n",
              nm,
              content[[nm]]["start"],
              content[[nm]]["stop"],
              content[[nm]]["stop"] - content[[nm]]["start"]))
}

## ══════════════════════════════════════════════════════════════════
## 2. Error handling — non-v8 file
## ══════════════════════════════════════════════════════════════════
cat("\n\n=== 2. Error handling — non-v8 file ===\n\n")

bad_file <- tempfile()
writeLines("This is not a SAS XPORT file.", bad_file)

tryCatch(
  ks_xpt_content(bad_file),
  error = function(e) cat("Caught expected error:", conditionMessage(e), "\n")
)

## haven::write_xpt uses XPORT v8 format — ks_xpt_content accepts these files:
if (requireNamespace("haven", quietly = TRUE)) {
  v8_path <- tempfile(fileext = ".xpt")
  on.exit(unlink(v8_path), add = TRUE)
  haven::write_xpt(data.frame(id = 1:3, val = c(1.1, 2.2, 3.3)), v8_path)
  res_v8 <- ks_xpt_content(v8_path)
  cat("haven-created v8 file — member:", names(res_v8), "\n")
}

## ══════════════════════════════════════════════════════════════════
## 3. Working with a real XPORT v8 file
## (replace 'path_to_study.xpt' with an actual file)
## ══════════════════════════════════════════════════════════════════
cat("\n\n=== 3. Real file workflow (code shown, not executed) ===\n\n")

cat('
## ── Step 1: index the file ───────────────────────────────────────
path    <- "path/to/study.xpt"
content <- ks_xpt_content(path)
cat("Members:", paste(names(content), collapse = ", "), "\\n")

## ── Step 2: extract one member ───────────────────────────────────
ae <- ks_extract_single_xpt("ae", path, content)
str(ae)

dm <- ks_extract_single_xpt("dm", path, content)
str(dm)

## ── Step 3: check a specific member is present ───────────────────
if ("lb" %in% names(content)) {
  lb <- ks_extract_single_xpt("lb", path, content)
  cat("LB rows:", nrow(lb), "\\n")
}
')

## ══════════════════════════════════════════════════════════════════
## 4. Batch load: all members into .GlobalEnv
## ══════════════════════════════════════════════════════════════════
cat("\n=== 4. Batch load — load all into .GlobalEnv (code shown) ===\n\n")

cat('
ks_batch_load_from_single_xpt("study.xpt", action = "load")
## Each member is now available as a variable in .GlobalEnv:
## ls()  →  "dm", "ae", "lb", "ex", "cm", ...
')

## ══════════════════════════════════════════════════════════════════
## 5. Batch save: write each member as an .rds file
## ══════════════════════════════════════════════════════════════════
cat("\n=== 5. Batch save — write .rds files (code shown) ===\n\n")

cat('
out_dir <- "data/sdtm_rds/"
ks_batch_load_from_single_xpt(
  "study.xpt",
  action    = "save",
  save_type = "rds",
  save_path = out_dir
)
## Result: data/sdtm_rds/dm.rds, ae.rds, lb.rds, ...

## Reload later:
ae <- readRDS(file.path(out_dir, "ae.rds"))
')

## ══════════════════════════════════════════════════════════════════
## 6. Batch save: single .RData file
## ══════════════════════════════════════════════════════════════════
cat("\n=== 6. Batch save — single .RData file (code shown) ===\n\n")

cat('
ks_batch_load_from_single_xpt(
  "study.xpt",
  action    = "save",
  save_type = "rdata",
  save_path = "data/study_sdtm"   # .RData extension added automatically
)
## Result: data/study_sdtm.RData (contains all members, xz-compressed)

## Reload:
load("data/study_sdtm.RData")
')

## ══════════════════════════════════════════════════════════════════
## 7. Batch save: Parquet (requires arrow package)
## ══════════════════════════════════════════════════════════════════
cat("\n=== 7. Batch save — Parquet files (code shown) ===\n\n")

cat('
if (requireNamespace("arrow", quietly = TRUE)) {
  ks_batch_load_from_single_xpt(
    "study.xpt",
    action    = "save",
    save_type = "parquet",
    save_path = "data/sdtm_parquet/"
  )
  ## Result: data/sdtm_parquet/dm.parquet, ae.parquet, ...
}
')

## ══════════════════════════════════════════════════════════════════
## 8. Use the invisible return value (named list of all datasets)
## ══════════════════════════════════════════════════════════════════
cat("\n=== 8. Capture return value (code shown) ===\n\n")

cat('
## ks_batch_load_from_single_xpt() invisibly returns a named list
## regardless of action — useful for piping or in-memory use:
sdtm <- ks_batch_load_from_single_xpt("study.xpt", action = "load")
## sdtm$dm, sdtm$ae, sdtm$lb, ...  all accessible without ls()
')

## Clean up temp files
unlink(c(xpt_path, bad_file))
if (exists("v5_path")) unlink(v5_path)
