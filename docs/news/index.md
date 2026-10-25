# Changelog

## kstools 0.6.0

### Bug fixes and behavior changes (LLM panel review round 1, docs/reviews/2026-10-25-llm-panel)

- [`ks_write_xpt()`](https://crow16384.github.io/kstools/reference/ks_write_xpt.md):
  non-finite numeric values (`Inf`, `-Inf`) were silently written as
  `0`. They are now mapped to SAS missing (`.`) like `NA_real_` and
  `NaN` (round-1 A2).
- [`ks_write_xpt()`](https://crow16384.github.io/kstools/reference/ks_write_xpt.md):
  SAS XPORT interoperability limits now abort instead of silently
  truncating: variable names must be \<= 8 bytes (v5) / \<= 32 bytes
  (v8), column labels \<= 40 / 256 bytes, and character data must fit
  200 bytes at version 5 (SAS XPORT engine limit, Tech Note 1528) and
  32767 bytes at version 8. Case-insensitive name collisions are
  rejected (round-1 A4).
- [`ks_write_xpt()`](https://crow16384.github.io/kstools/reference/ks_write_xpt.md):
  a failed write no longer leaves a partial `.xpt` file behind (round-1
  A9).
- String widths on write are computed in bytes via `LENGTH()`; embedded
  NUL bytes no longer truncate the stored value silently (round-1 A10).
- [`ks_read_xpt()`](https://crow16384.github.io/kstools/reference/ks_read_xpt.md)
  (internal parser): files declaring a numeric variable with a storage
  width other than 8 bytes are now rejected with a clear error instead
  of silently decoding shifted garbage (round-1 A8).
- [`ks_impute_dtc()`](https://crow16384.github.io/kstools/reference/ks_impute_dtc.md):
  out-of-range components (`month 13`, day beyond month length
  incl. leap years, `hour 24-25`, minute/second \> 59) were silently
  rolled over by `make_datetime()` (`2020-13-01` -\> `2021-01-01`). Such
  elements now follow the documented non-matching contract: `NA` value
  and `NA` imputation flag, never imputed from `ref` (round-1 A3).
- [`ks_auc()`](https://crow16384.github.io/kstools/reference/ks_auc.md):
  groups with fewer than two concurrent non-`NA` (value, time) points
  now return `NA_real_` instead of a misleading `0` (round-1 A5).
- [`ks_batch_load()`](https://crow16384.github.io/kstools/reference/ks_batch_load.md):
  if any file fails to load, the function aborts and reports the
  offending paths (previously `try-error` objects were kept in the
  returned list and persisted by `save.path`/`keep`) (round-1 A6).
- [`ks_roc()`](https://crow16384.github.io/kstools/reference/ks_roc.md):
  non-numeric predictor columns are rejected with a clear message
  instead of a cryptic internal type error (round-1 A7).
- [`ks_n_pct()`](https://crow16384.github.io/kstools/reference/ks_n_pct.md):
  numeric method warns on fractional counts and computes count and
  percentage from the same truncated integer (the data-frame method
  already behaved this way) (round-1 A10).
- [`ks_supp_merge()`](https://crow16384.github.io/kstools/reference/ks_supp_merge.md):
  duplicate `(key, QNAM)` records (which `pivot_wider()` would silently
  turn into list-columns) and QNAM values colliding with primary-domain
  variable names now abort with SDTM-oriented messages (round-1 A10).
- XPT parallel decode errors now concatenate all worker messages instead
  of reporting only the first (round-1 A10).
- [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md):
  SAS PROC MIANALYZE parity for a zero within-imputation variance (live
  probe, `scripts/sas/mianalyze_zero_withinvar_probe.sas`): a warning is
  issued per zero standard error, and when the pooled within variance is
  0 the degrees of freedom, MI diagnostics (r, FMI, RE), confidence
  limits and t-test are `NA` - previously a degenerate finite
  `df = m - 1` (and an `NA`-producing
  [`qt()`](https://rdrr.io/r/stats/TDist.html) call with `EDF=`) was
  reported. SAS prints “.” for these values with or without `EDF=`;
  estimate, pooled SE, B, T and the ranges remain reported (round-1 A1,
  closed).

## kstools 0.5.9

### New features

- [`ks_compare_na()`](https://crow16384.github.io/kstools/reference/ks_compare_na.md):
  NA-aware element-wise comparison (SAS `NULL=` twin).
- [`ks_vswitch()`](https://crow16384.github.io/kstools/reference/ks_vswitch.md):
  vectorized switch over named cases (SAS select-when map), with `.na` /
  `.default` fallbacks.
- [`ks_hosmer_lemeshow()`](https://crow16384.github.io/kstools/reference/ks_hosmer_lemeshow.md):
  Hosmer-Lemeshow goodness-of-fit for logistic models.
- [`ks_dunnett_crit()`](https://crow16384.github.io/kstools/reference/ks_dunnett_crit.md):
  exact Dunnett critical value by inverting the equicorrelated
  multivariate-t (`mnormt`, Suggests-guarded).
- [`ks_mv_normality()`](https://crow16384.github.io/kstools/reference/ks_mv_normality.md):
  Mardia skewness/kurtosis in base R (agrees with
  [`QuantPsyc::mult.norm`](https://rdrr.io/pkg/QuantPsyc/man/mult.norm.html)) +
  optional energy test (`energy`, Suggests).
- [`ks_boot_ci()`](https://crow16384.github.io/kstools/reference/ks_boot_ci.md):
  one-line percentile/BCa bootstrap CI over `boot`.
- [`ks_be_2x2()`](https://crow16384.github.io/kstools/reference/ks_be_2x2.md):
  2x2 crossover bioequivalence via
  [`nlme::lme`](https://rdrr.io/pkg/nlme/man/lme.html) with `contr.SAS`
  (T-R on the log scale, 90% CI, ratio interval).

## kstools 0.5.8

### Breaking changes

- [`ks_swoe()`](https://crow16384.github.io/kstools/reference/ks_swoe.md):
  vector API — call as `ks_swoe(x, y)` (e.g. inside
  `dplyr::mutate(SEX_SWOE = ks_swoe(SEX, RESPONSE))`). The previous
  data-frame + NSE / `quoted` interface is removed.

### Documentation

- Improved Mermaid diagram contrast in the `mianalyze` vignette for dark
  RStudio themes.

## kstools 0.5.7

### Breaking changes

- Removed functions: `ks_check_rules()`, `ks_collapse_check_msgs()`,
  `ks_compare_check_state()`, `ks_save2xlsx_by()`.
- Updated vignettes and documentation to remove references to deleted
  functions.

### Documentation

- Added vignette `mianalyze`: Rubin’s rules, Barnard-Rubin `edf`, and
  numerical comparison with SAS `PROC MIANALYZE` (SAS/STAT 12.3 Examples
  58.1 / 58.3 and Table 58.2).
- Added SAS-aligned unit tests in
  `tests/testthat/test-ks_mianalyze-sas.R`.
- Expanded `inst/examples` for
  [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  /
  [`mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  with SAS Example 58.1 inputs.

## kstools 0.5.6

### New features

- [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md):
  added
  [`summary.ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  method that returns structured data frames (`variance`, `diagnostics`,
  `estimates`, `tests`) for programmatic access to results.
- [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md):
  added
  [`knit_print.ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  method for proper rendering in R Markdown and Quarto documents using
  [`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html).
- [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md):
  refactored `print.ks_mianalyze()` to use
  [`summary()`](https://rdrr.io/r/base/summary.html) internally,
  eliminating code duplication and following R best practices.

## kstools 0.5.5

### Bug fixes

- [`ks_cv()`](https://crow16384.github.io/kstools/reference/ks_cv.md):
  returns `NA_real_` instead of `Inf`/`NaN` when the mean of `x` is zero
  or `NA`.
- [`ks_z_score()`](https://crow16384.github.io/kstools/reference/ks_z_score.md):
  returns an all-`NA` vector instead of `NaN` when the standard
  deviation of `x` is zero (constant input).
- [`ks_n_pct()`](https://crow16384.github.io/kstools/reference/ks_n_pct.md)
  (numeric and data.frame methods): cells whose denominator (`totals`)
  is zero or `NA` are now replaced with `na.rep` rather than silently
  producing `"Inf%"` in the formatted string.
- [`ks_get_numdec()`](https://crow16384.github.io/kstools/reference/ks_get_numdec.md):
  groups where every value of `var` is `NA` now yield `NA_integer_`
  instead of `-Inf` (double), preserving the integer column type of
  `NUMDEC`.
- [`ks_batch_load()`](https://crow16384.github.io/kstools/reference/ks_batch_load.md)
  (type `"xpt"`): now calls
  [`ks_read_xpt()`](https://crow16384.github.io/kstools/reference/ks_read_xpt.md)
  instead of
  [`haven::read_xpt()`](https://haven.tidyverse.org/reference/read_xpt.html),
  restoring date conversion and SAS-attribute handling that were
  bypassed in the previous implementation.
- [`ks_williams()`](https://crow16384.github.io/kstools/reference/ks_williams.md):
  the treatment-name whitespace check used a double-escaped regex
  (`"\\\\s"`) that matched a literal `\s` instead of actual whitespace.
  Fixed to `"\\s"`.

### Performance

- [`ks_newcombe_hs()`](https://crow16384.github.io/kstools/reference/ks_newcombe_hs.md)
  and
  [`ks_eairdiff_mn()`](https://crow16384.github.io/kstools/reference/ks_eairdiff_mn.md):
  replaced [`Vectorize()`](https://rdrr.io/r/base/Vectorize.html)
  wrappers with [`mapply()`](https://rdrr.io/r/base/mapply.html) +
  `do.call(rbind, ...)`, giving a material speedup on long input
  vectors.

------------------------------------------------------------------------

## kstools 0.5.4

### Bug fixes / behaviour change

- [`ks_impute_dtc()`](https://crow16384.github.io/kstools/reference/ks_impute_dtc.md):
  date-only strings (`"YYYY-MM-DD"`) with `direction = "start"` now
  produce `00:00:00` with `imputation_flag = "H"` instead of
  `00:00:00 / NA`. Consistent with the `direction = "end"` (Case D)
  behaviour added in v0.5.3. A ref-date match (Case C) still takes
  priority over this start-of-day fallback (Case E).

------------------------------------------------------------------------

## kstools 0.5.3

### Bug fixes / behaviour change

- [`ks_impute_dtc()`](https://crow16384.github.io/kstools/reference/ks_impute_dtc.md):
  date-only strings (`"YYYY-MM-DD"`) with `direction = "end"` now
  produce `23:59:00` with `imputation_flag = "H"` instead of
  `00:00:00 / NA`. A ref-date match (Case C) still takes priority over
  this end-of-day fallback (Case D).

------------------------------------------------------------------------

## kstools 0.5.2

### New features

- [`ks_impute_dtc()`](https://crow16384.github.io/kstools/reference/ks_impute_dtc.md):
  new function that parses truncated ISO 8601 date/datetime strings and
  imputes missing components. Accepts `direction = "start"`, `"end"`, or
  `"no"` and an optional `ref` reference date/datetime vector for
  same-period guided imputation (Cases A / B / C). Returns a
  `tibble(dt = POSIXct, imputation_flag = chr)` for direct use with
  [`dplyr::bind_cols()`](https://dplyr.tidyverse.org/reference/bind_cols.html).

------------------------------------------------------------------------

## kstools 0.5.1

### Bug fixes

- `rcpp_xpt.cpp`: replaced `<stdexcept>` with `<exception>` (correct
  header for `std::exception`).

------------------------------------------------------------------------

## kstools 0.5.0

### Performance

- [`ks_read_xpt()`](https://crow16384.github.io/kstools/reference/ks_read_xpt.md)
  /
  [`ks_write_xpt()`](https://crow16384.github.io/kstools/reference/ks_write_xpt.md):
  completely rewritten C++ engine. Uses POSIX `mmap` for zero-copy file
  access, streaming columnar decode directly into pre-allocated R
  vectors, and a multi-threaded worker pool for numeric columns
  (`n_threads` argument, defaults to `hw - 1`). A 5 GB XPT file now
  reads in ~4 s at ~1.3 GB/s with parser scratch well below 4 MB
  (previously \> 100 GB RSS). Writer uses a 64 KB output buffer with no
  in-memory row materialisation. Multi-member files are handled via
  in-place mmap offsets (no temp files).

------------------------------------------------------------------------

## kstools 0.4.1

### New features

- [`ks_get_data()`](https://crow16384.github.io/kstools/reference/ks_get_data.md):
  added `xpt_reader` argument (and global option `kstools.xpt.reader`)
  to select the XPT loading back-end. Use `xpt_reader = "internal"` (or
  `options(kstools.xpt.reader = "internal")`) to suppress the *“ignored
  N trailing byte(s) after row parsing”* warning emitted by **haven** on
  some XPORT files. `"haven"` remains the default. When the internal
  reader is used and the file contains multiple members, the domain slot
  in the output is a named list of tibbles.

------------------------------------------------------------------------

## kstools 0.4.0

### New features

- [`ks_read_xpt()`](https://crow16384.github.io/kstools/reference/ks_read_xpt.md):
  read SAS XPORT V5/V8/V9 files into tibbles. Variable labels, SAS
  formats, and informats are preserved as column attributes (`"label"`,
  `"format.sas"`, `"sas.informat"`). Multi-member files are returned as
  a named list of tibbles.
- [`ks_write_xpt()`](https://crow16384.github.io/kstools/reference/ks_write_xpt.md):
  write a data frame to a SAS XPORT V5 or V8 file. Labels and formats
  can be supplied via column attributes or explicit `labels`/`formats`
  arguments.
- [`ks_xpt_labels()`](https://crow16384.github.io/kstools/reference/ks_xpt_labels.md)
  /
  [`ks_xpt_formats()`](https://crow16384.github.io/kstools/reference/ks_xpt_formats.md):
  extract variable labels and SAS formats from a data frame as named
  character vectors.
- [`ks_set_labels()`](https://crow16384.github.io/kstools/reference/ks_set_labels.md)
  /
  [`ks_set_formats()`](https://crow16384.github.io/kstools/reference/ks_set_formats.md):
  set `"label"` / `"format.sas"` attributes on selected columns from
  named character vectors.
- Date and datetime epoch conversion between SAS (1960-01-01) and R
  (1970-01-01) is applied automatically; disable with
  `convert_dates = FALSE`.
- IBM hexadecimal floating-point encoding/decoding and SAS
  tagged-missing values are fully supported.

------------------------------------------------------------------------

## kstools 0.3.9

### Breaking changes

- [`ks_get_data()`](https://crow16384.github.io/kstools/reference/ks_get_data.md):
  no longer assigns loaded data to `.GlobalEnv`. It now **returns** the
  data directly — a tibble for a single-domain call, or a named list of
  tibbles for multi-domain calls. Migrate `ks_get_data(dm)` to
  `dm <- ks_get_data(dm)` and `ks_get_data(dm, ae)` to
  `dat <- ks_get_data(dm, ae); dm <- dat$dm`.

### New features

- [`ks_get_data()`](https://crow16384.github.io/kstools/reference/ks_get_data.md):
  file lookup against `path` is now **case-insensitive** for both stem
  and extension, so `ks_get_data(dm)` and `ks_get_data(DM)` both match
  `dm.xpt`, `DM.XPT`, `Dm.Xpt`, etc.
- [`ks_get_data()`](https://crow16384.github.io/kstools/reference/ks_get_data.md):
  new global option `kstools.get_data.case` to resolve ambiguity when
  multiple files share the same stem but differ in case. Accepted
  values: `"error"` (default), `"first"`, `"lower"`, `"upper"`.

------------------------------------------------------------------------

## kstools 0.3.8

### Bug fixes

- [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  /
  [`mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md):
  aligned degrees-of-freedom handling with SAS `PROC MIANALYZE` behavior
  by adding `edf` (SAS `EDF=` analogue) and applying Barnard-Rubin
  small-sample adjustment when finite complete-data df are supplied.
- [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  /
  [`mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md):
  kept backward compatibility for `v0` while adding input validation for
  conflicting `edf`/`v0` specifications.

### Documentation

- Updated function docs and examples for the new `edf` argument and
  SAS-style DF behavior.

------------------------------------------------------------------------

## kstools 0.3.7

### Bug fixes

- [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md):
  corrected pooled total-variance and Rubin degrees-of-freedom
  calculations used for multiple-imputation inference.

### Documentation

- Bumped package version metadata and refreshed release documentation.

------------------------------------------------------------------------

## kstools 0.3.6

### Documentation

- Added pkgdown configuration (`_pkgdown.yml`) and generated docs site
  workflow.
- Added vignettes: `getting-started` and `clinical-workflows`.
- Expanded `inst/examples` coverage and added `run_all_examples.R` index
  runner.
- Added CI workflow to keep README version badge synchronized with
  `DESCRIPTION`.

### New functions

- Added
  [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  /
  [`mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  (Rubin pooling; SAS MIANALYZE analogue).
- Added
  [`ks_roc()`](https://crow16384.github.io/kstools/reference/ks_roc.md)
  (correlated ROC AUC comparison with contrast tests).
- Added
  [`ks_williams()`](https://crow16384.github.io/kstools/reference/ks_williams.md)
  (randomized Williams cross-over design and schedule generator).

### Bug fixes

- `ks_collapse_check_msgs()`: removed unqualified `%>%` dependency so
  function and vignettes run without attaching dplyr.

------------------------------------------------------------------------

## kstools 0.3.5

### Performance

- `ks_save2xlsx_by()`: replaced O(N) per-row `wb_add_fill()` loops with
  Excel Conditional Formatting rules (`wb_add_dxfs_style()` +
  `wb_add_conditional_formatting()`). Fill calls now scale O(1) per
  colour key per sheet regardless of row count — e.g. 3,000
  `wb_add_fill()` calls for a 1,000-row / 3-colour sheet become 3 CF
  rules.

### Bug fixes

- [`ks_summary()`](https://crow16384.github.io/kstools/reference/ks_summary.md)
  test: fixed case-insensitive regexp match for the “Duplicate names”
  error so the test no longer fails against the capitalised message.

------------------------------------------------------------------------

## kstools 0.3.4

### Bug fixes

- [`ks_z_score()`](https://crow16384.github.io/kstools/reference/ks_z_score.md):
  fixed inverted formula — was returning `(mean - x) / sd` instead of
  the correct `(x - mean) / sd`.
- [`read.csv3()`](https://crow16384.github.io/kstools/reference/read.csv3.md):
  fixed potential crash on end-of-file when
  [`readLines()`](https://rdrr.io/r/base/readLines.html) returns
  `character(0)` — [`length()`](https://rdrr.io/r/base/length.html)
  guard now precedes [`grepl()`](https://rdrr.io/r/base/grep.html) to
  avoid a zero-length condition in `if()`.
- `ks_compare_check_state()`: removed unused internal `..row_id..`
  column that was allocated and immediately deleted on every call.
- [`ks_median_ci()`](https://crow16384.github.io/kstools/reference/ks_median_ci.md)
  (`boot` method): guard against `NULL` `$bca` component — `boot.ci()`
  omits BCa for very small samples; bounds now fall back to `NA_real_`
  instead of silently dropping vector elements.
- `ks_save2xlsx_by()`: removed dead `as_table` parameter (implementation
  was already removed in 0.3.3); narrowed status-column fill to the
  status column only (was incorrectly colouring the entire row); added
  freeze-pane on the header row; added thin cell borders on all data
  cells.

### Minor improvements

- [`ks_cv()`](https://crow16384.github.io/kstools/reference/ks_cv.md),
  [`ks_z_score()`](https://crow16384.github.io/kstools/reference/ks_z_score.md):
  replaced bare `T` with `TRUE`.
- [`ks_del_tmp()`](https://crow16384.github.io/kstools/reference/ks_del_tmp.md):
  simplified redundant single-character class `[t]` to `t`.

------------------------------------------------------------------------

## kstools 0.3.3

### Bug fixes

- Removed unused `labelled` import; `is_missing` is now correctly
  sourced from `ksformat`.

------------------------------------------------------------------------

## kstools 0.3.2

### New features

- Added validation workflow helpers: `ks_check_rules()`,
  `ks_collapse_check_msgs()`, `ks_compare_check_state()`, and
  `ks_save2xlsx_by()`.
- Added label and coding helpers:
  [`ks_get_labels()`](https://crow16384.github.io/kstools/reference/ks_get_labels.md)
  and
  [`ks_code_to_fmt()`](https://crow16384.github.io/kstools/reference/ks_code_to_fmt.md).

### Dependencies

- Added imports: `ksformat`, `labelled`, `openxlsx2`, `purrr`,
  `stringr`, and `tibble`.

------------------------------------------------------------------------

## kstools 0.3.1

### New features

- **[`read.csv3()`](https://crow16384.github.io/kstools/reference/read.csv3.md)**:
  read a CSV file with optional KeyStat comment headers
  (`#NAME$type(length)$Label`) for column types and labels.
- **[`ks_get_data()`](https://crow16384.github.io/kstools/reference/ks_get_data.md)**:
  new `type` values `"csv"` and `"csvks"` for loading plain CSV and
  KeyStat-commented CSV domains; `.csv` is also auto-detected.

------------------------------------------------------------------------

## kstools 0.3.0

### New features

- **[`ks_summary()`](https://crow16384.github.io/kstools/reference/ks_summary.md)**:
  new `numdec = TRUE` parameter appends a `NUMDEC` column with the
  group-level max decimal places of `var` (via `ks_get_numdec` logic).
- **[`ks_current_filename()`](https://crow16384.github.io/kstools/reference/ks_current_filename.md)**:
  detect the basename of the running R script (source or Rscript).
- **[`ks_get_numdec()`](https://crow16384.github.io/kstools/reference/ks_get_numdec.md)**:
  compute max decimal places per group and join as `NUMDEC`.
- Second author added: Igor Aleschenkov.

### Improvements

- `R/get_numeric.r` renamed to `R/get_numdec.r` for consistency with the
  exported function name.

------------------------------------------------------------------------

## kstools 0.2.0

### New features

- **[`ks_summary()`](https://crow16384.github.io/kstools/reference/ks_summary.md)**
  accepts optional **`extras`**: a named list of functions
  (`f(x, na.rm)`) for extra per-group statistics; columns appear after
  the default summary stats and before `cv`.

### Improvements and fixes

- **[`ks_simulate_ar1()`](https://crow16384.github.io/kstools/reference/ks_simulate_ar1.md)**:
  validation, reproducibility (`seed`), `MASS::` / `stats::` usage,
  documentation, examples, and tests.
- **[`ks_geom_mean()`](https://crow16384.github.io/kstools/reference/ks_geom_mean.md)**,
  **[`ks_median_ci()`](https://crow16384.github.io/kstools/reference/ks_median_ci.md)**,
  **[`ks_n_pct()`](https://crow16384.github.io/kstools/reference/ks_n_pct.md)**,
  **[`ks_get_data()`](https://crow16384.github.io/kstools/reference/ks_get_data.md)**,
  **[`ks_swap_cols()`](https://crow16384.github.io/kstools/reference/ks_swap_cols.md)**,
  **[`ks_swoe()`](https://crow16384.github.io/kstools/reference/ks_swoe.md)**,
  and related helpers: refactors, bug fixes, and documentation updates
  (see git history).
- **Newcombe hybrid score** CIs:
  [`ks_newcombe_hs()`](https://crow16384.github.io/kstools/reference/ks_newcombe_hs.md),
  [`ks_newcombe_hs_strata()`](https://crow16384.github.io/kstools/reference/ks_newcombe_hs_strata.md).
- Removed **`ks_trim`** in favour of
  **[`base::trimws()`](https://rdrr.io/r/base/trimws.html)**; removed
  medical-history helpers from earlier versions.

### Documentation

- README and package overview
  ([`?kstools`](https://crow16384.github.io/kstools/reference/kstools-package.md))
  updated; broken cross-references in the package index fixed.

------------------------------------------------------------------------

## kstools 0.1.0

Initial packaged release.
