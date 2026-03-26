## ============================================================
## ks_current_filename() — detect the name of the running script
## ============================================================
## Returns basename of the current script (via source() or Rscript).
## Returns "" in an interactive session.
## ============================================================

library(kstools)

## ------------------------------------------------------------------
## 1. Interactive session — no script name available
## ------------------------------------------------------------------
cat("=== 1. Interactive call ===\n\n")

cat("filename:", sQuote(ks_current_filename()), "\n")
# Expected: ''

## ------------------------------------------------------------------
## 2. Inside a source()'d file
## ------------------------------------------------------------------
cat("\n=== 2. Via source() ===\n\n")

tf <- tempfile("demo_script_", fileext = ".R")
writeLines('cat("source():", sQuote(ks_current_filename()), "\\n")', tf)
source(tf)
unlink(tf)

## ------------------------------------------------------------------
## 3. Typical usage — conditional log header
## ------------------------------------------------------------------
cat("\n=== 3. Typical usage ===\n\n")

script <- ks_current_filename()
header <- if (nzchar(script)) script else "(interactive)"
cat("Running:", header, "\n")
