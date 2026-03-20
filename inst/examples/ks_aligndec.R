## ============================================================
## ks_aligndec() — align decimals in a character vector
## ============================================================
## Inserts leading spaces so the decimal point (or the first
## space after digits) lines up vertically in every element.
## Designed for monospaced output: RTF/TXT clinical tables,
## console listings, cat()-based reports.
##
## Alignment anchor:
##   • If the string contains "digits."  → aligns on "."
##   • If the string contains "digits " → aligns on the space
##     (covers "n (pct%)" and "mean (SD)" formats)
##   • Otherwise                         → appends a trailing
##     space so the string sorts last
## ============================================================

library(kstools)

## ------------------------------------------------------------------
## 1. Plain numbers
## ------------------------------------------------------------------
cat("=== 1. Plain numbers ===\n\n")

nums <- c("1.5", "10.25", "100.0", "1000.123")
aligned <- ks_aligndec(nums)

cat(paste0("  [", aligned, "]"), sep = "\n")
cat("\n")

## ------------------------------------------------------------------
## 2. Negative values
## ------------------------------------------------------------------
cat("=== 2. Negative values ===\n\n")

neg <- c("-1.5", "10.2", "-100.0", "3.14")
cat(paste0("  [", ks_aligndec(neg), "]"), sep = "\n")
cat("\n")

## ------------------------------------------------------------------
## 3. NA handling
## ------------------------------------------------------------------
cat("=== 3. NA handling ===\n\n")

with_na <- c("1.2", NA, "10.99", NA, "100.0")

cat("na.rep = '' (default):\n")
cat(paste0("  [", ks_aligndec(with_na), "]"), sep = "\n")

cat("\nna.rep = 'NE':\n")
cat(paste0("  [", ks_aligndec(with_na, na.rep = "NE"), "]"), sep = "\n")
cat("\n")

## ------------------------------------------------------------------
## 4. "n (pct%)" format  — alignment anchor is the space after n
## ------------------------------------------------------------------
cat("=== 4. n (pct%) format ===\n\n")

npct <- c("1 (5.0%)", "12 (60.0%)", "3 (15.5%)", "100 (100.0%)")
cat(paste0("  ", ks_aligndec(npct)), sep = "\n")
cat("\n")

## ------------------------------------------------------------------
## 5. "mean (SD)" format
## ------------------------------------------------------------------
cat("=== 5. mean (SD) format ===\n\n")

mean_sd <- c("1.2 (0.34)", "10.80 (1.234)", "100.0 (12.5)", "0.5 (0.01)")
cat(paste0("  ", ks_aligndec(mean_sd)), sep = "\n")
cat("\n")

## ------------------------------------------------------------------
## 6. Clinical summary table — align every statistic column
## ------------------------------------------------------------------
cat("=== 6. Summary table (two treatment arms) ===\n\n")

tbl <- data.frame(
  Statistic = c("n",   "Mean (SD)",         "Median",
                "Q1",  "Q3",                 "Min",  "Max"),
  Drug_A    = c("60",  "28.4 (7.9)",        "27.5",
                "23.0", "33.0",              "11.0", "49.0"),
  Placebo   = c("60",  "31.7 (9.2)",        "31.0",
                "25.0", "38.5",              "13.0", "55.0"),
  stringsAsFactors = FALSE
)

tbl$Drug_A  <- ks_aligndec(tbl$Drug_A)
tbl$Placebo <- ks_aligndec(tbl$Placebo)

## Print with cat so spaces are preserved (print.data.frame may strip them)
cat(sprintf("  %-14s  %20s  %20s\n", "Statistic", "Drug A", "Placebo"))
cat(strrep("-", 58), "\n")
for (i in seq_len(nrow(tbl))) {
  cat(sprintf("  %-14s  %20s  %20s\n",
              tbl$Statistic[i], tbl$Drug_A[i], tbl$Placebo[i]))
}
cat("\n")

## ------------------------------------------------------------------
## 7. Mixed: some values have no decimal  (no-match behaviour)
## ------------------------------------------------------------------
cat("=== 7. Mixed decimal / integer / text ===\n\n")

mixed <- c("100", "1.5", "NE", "10")
cat(paste0("  [", ks_aligndec(mixed), "]"), sep = "\n")
cat("\n")

## ------------------------------------------------------------------
## 8. Pipe-friendly usage inside mutate()
## ------------------------------------------------------------------
cat("=== 8. dplyr::mutate() integration ===\n\n")

library(dplyr)

stats_df <- data.frame(
  param = c("ALT", "AST", "ALP", "GGT"),
  value = c("8.5 (2.1)", "12.0 (5.34)", "102.0 (31.2)", "24.5 (9.0)"),
  stringsAsFactors = FALSE
)

result <- stats_df |>
  mutate(value_fmt = ks_aligndec(value))

cat(sprintf("  %-6s  %s\n", "param", "value_fmt"))
cat(strrep("-", 30), "\n")
for (i in seq_len(nrow(result))) {
  cat(sprintf("  %-6s  %s\n", result$param[i], result$value_fmt[i]))
}
