#!/usr/bin/env Rscript
# Quick performance/memory benchmark for ks_read_xpt / ks_write_xpt.
#
# Usage:
#   Rscript bench/xpt_bench.R [target_size_gb] [path]
#
# Defaults: 1 GB synthetic file in tempdir().
#
# Asserts:
#   * read time scales linearly with file size
#   * RSS growth during read is bounded (parser scratch ~ MB-scale, not GB)

suppressPackageStartupMessages({
  library(kstools)
})

args <- commandArgs(trailingOnly = TRUE)
target_gb <- if (length(args) >= 1) as.numeric(args[1]) else 1
xpt_path  <- if (length(args) >= 2) args[2] else file.path(tempdir(), "bench.xpt")

# Resolve macOS / Linux RSS sampler.
get_rss_mb <- local({
  if (Sys.info()[["sysname"]] == "Darwin") {
    function() {
      out <- suppressWarnings(system2("ps", c("-o", "rss=", "-p", Sys.getpid()),
                                      stdout = TRUE))
      if (length(out) == 0) NA_real_ else as.numeric(out) / 1024  # KB -> MB
    }
  } else {
    function() {
      f <- sprintf("/proc/%d/status", Sys.getpid())
      if (!file.exists(f)) return(NA_real_)
      lines <- readLines(f, warn = FALSE)
      m <- grep("^VmRSS:", lines, value = TRUE)
      if (!length(m)) return(NA_real_)
      as.numeric(sub(".*?(\\d+).*", "\\1", m)) / 1024
    }
  }
})

# Synthesize a frame with ~ target_gb GB of XPT-on-disk size.
# Per-row layout chosen so 1M rows = ~96 MB on disk.
make_chunk <- function(n) {
  data.frame(
    id   = seq_len(n),
    x    = stats::rnorm(n),
    y    = stats::rnorm(n),
    z    = stats::runif(n, 0, 1e6),
    s    = sprintf("S%07d", seq_len(n)),
    grp  = rep_len(c("AAA", "BBB", "CCC", "DDD"), n),
    d    = as.Date("1990-01-01") + sample.int(20000L, n, replace = TRUE),
    ts   = as.POSIXct("2000-01-01", tz = "UTC") +
           stats::runif(n, 0, 25 * 365 * 86400),
    stringsAsFactors = FALSE
  )
}

bytes_per_row <- 8 * 5 + 8 + 4 + 32  # rough bound, including padding
target_rows   <- as.integer(ceiling(target_gb * 1024^3 / bytes_per_row))
chunk_rows    <- 1e6L

cat(sprintf("Target: %.2f GB ~= %d rows -> %s\n",
            target_gb, target_rows, xpt_path))

# Build and write in chunks to stay below 4 GB R-side RSS during synthesis.
if (!file.exists(xpt_path) || file.size(xpt_path) < target_gb * 0.95 * 1024^3) {
  cat("Generating synthetic data and writing XPT...\n")
  on.exit(if (file.exists(xpt_path)) cat(sprintf("File ready: %.2f GB at %s\n",
                                                  file.size(xpt_path) / 1024^3,
                                                  xpt_path)),
          add = TRUE)
  built <- 0L
  parts <- list()
  while (built < target_rows) {
    n <- min(chunk_rows, target_rows - built)
    parts[[length(parts) + 1L]] <- make_chunk(n)
    built <- built + n
  }
  big <- do.call(rbind, parts)
  rm(parts); invisible(gc(verbose = FALSE))

  t_w <- system.time(ks_write_xpt(big, xpt_path, version = 5L))
  cat(sprintf("Write: %.2fs  (%.1f MB/s)\n",
              t_w[["elapsed"]],
              file.size(xpt_path) / 1024^2 / t_w[["elapsed"]]))
  rm(big); invisible(gc(verbose = FALSE))
} else {
  cat(sprintf("Reusing existing file (%.2f GB)\n",
              file.size(xpt_path) / 1024^3))
}

invisible(gc(verbose = FALSE))
rss_before <- get_rss_mb()
cat(sprintf("RSS before read: %.1f MB\n", rss_before))

t_r <- system.time(df <- kstools::ks_read_xpt(xpt_path, warn = FALSE))
rss_after <- get_rss_mb()
sz_gb     <- file.size(xpt_path) / 1024^3
mbps      <- file.size(xpt_path) / 1024^2 / t_r[["elapsed"]]

cat(sprintf("Read:  %.2fs  (%.1f MB/s)\n", t_r[["elapsed"]], mbps))
cat(sprintf("RSS after read:  %.1f MB  (delta %+.1f MB)\n",
            rss_after, rss_after - rss_before))
cat(sprintf("Rows:  %d   cols: %d\n", nrow(df), ncol(df)))
cat(sprintf("Implied 5 GB read time: %.2fs\n", t_r[["elapsed"]] * 5 / sz_gb))

invisible(NULL)
