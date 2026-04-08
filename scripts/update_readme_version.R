#!/usr/bin/env Rscript

# Update README version badge from DESCRIPTION Version field.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grep("^--file=", args)]

if (length(file_arg) == 1L) {
  script_path <- sub("^--file=", "", file_arg)
  root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = FALSE)
} else {
  root <- normalizePath(getwd(), mustWork = FALSE)
}

desc_path <- file.path(root, "DESCRIPTION")
readme_path <- file.path(root, "README.md")

if (!file.exists(desc_path) || !file.exists(readme_path)) {
  stop("DESCRIPTION or README.md not found in repository root.")
}

ver <- read.dcf(desc_path, fields = "Version")[1, 1]

badge_line <- sprintf(
  "[![Version](https://img.shields.io/badge/version-%s-blue)](https://github.com/crow16384/kstools/releases/latest)",
  ver
)

txt <- readLines(readme_path, warn = FALSE, encoding = "UTF-8")
start <- grep("<!-- version-badge:start -->", txt, fixed = TRUE)
end <- grep("<!-- version-badge:end -->", txt, fixed = TRUE)

if (length(start) != 1L || length(end) != 1L || end <= start) {
  stop("README.md must contain a single valid version badge marker block.")
}

new_txt <- c(
  txt[seq_len(start)],
  badge_line,
  txt[end:length(txt)]
)

if (!identical(txt, new_txt)) {
  writeLines(new_txt, readme_path, useBytes = TRUE)
  cat("README version badge updated to", ver, "\n")
} else {
  cat("README version badge already up to date (", ver, ").\n", sep = "")
}
