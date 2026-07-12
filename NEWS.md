# kstools 0.5.6

## New features

- `ks_mianalyze()`: added `summary.ks_mianalyze()` method that returns
  structured data frames (`variance`, `diagnostics`, `estimates`, `tests`)
  for programmatic access to results.
- `ks_mianalyze()`: added `knit_print.ks_mianalyze()` method for proper
  rendering in R Markdown and Quarto documents using `knitr::kable()`.
- `ks_mianalyze()`: refactored `print.ks_mianalyze()` to use `summary()`
  internally, eliminating code duplication and following R best practices.

# kstools 0.5.5

## Bug fixes

- `ks_cv()`: returns `NA_real_` instead of `Inf`/`NaN` when the mean of `x`
  is zero or `NA`.
- `ks_z_score()`: returns an all-`NA` vector instead of `NaN` when the
  standard deviation of `x` is zero (constant input).
- `ks_n_pct()` (numeric and data.frame methods): cells whose denominator
  (`totals`) is zero or `NA` are now replaced with `na.rep` rather than
  silently producing `"Inf%"` in the formatted string.
- `ks_get_numdec()`: groups where every value of `var` is `NA` now yield
  `NA_integer_` instead of `-Inf` (double), preserving the integer column
  type of `NUMDEC`.
- `ks_batch_load()` (type `"xpt"`): now calls `ks_read_xpt()` instead of
  `haven::read_xpt()`, restoring date conversion and SAS-attribute handling
  that were bypassed in the previous implementation.
- `ks_williams()`: the treatment-name whitespace check used a
  double-escaped regex (`"\\\\s"`) that matched a literal `\s` instead of
  actual whitespace. Fixed to `"\\s"`.

## Performance

- `ks_newcombe_hs()` and `ks_eairdiff_mn()`: replaced `Vectorize()` wrappers
  with `mapply()` + `do.call(rbind, ...)`, giving a material speedup on
  long input vectors.

---

# kstools 0.5.4

## Bug fixes / behaviour change

- `ks_impute_dtc()`: date-only strings (`"YYYY-MM-DD"`) with
  `direction = "start"` now produce `00:00:00` with `imputation_flag = "H"`
  instead of `00:00:00 / NA`.  Consistent with the `direction = "end"` (Case D)
  behaviour added in v0.5.3.  A ref-date match (Case C) still takes
  priority over this start-of-day fallback (Case E).

---

# kstools 0.5.3

## Bug fixes / behaviour change

- `ks_impute_dtc()`: date-only strings (`"YYYY-MM-DD"`) with
  `direction = "end"` now produce `23:59:00` with `imputation_flag = "H"`
  instead of `00:00:00 / NA`.  A ref-date match (Case C) still takes
  priority over this end-of-day fallback (Case D).

---

# kstools 0.5.2

## New features

- `ks_impute_dtc()`: new function that parses truncated ISO 8601 date/datetime
  strings and imputes missing components.  Accepts `direction = "start"`,
  `"end"`, or `"no"` and an optional `ref` reference date/datetime vector for
  same-period guided imputation (Cases A / B / C).  Returns a
  `tibble(dt = POSIXct, imputation_flag = chr)` for direct use with
  `dplyr::bind_cols()`.

---

# kstools 0.5.1

## Bug fixes

- `rcpp_xpt.cpp`: replaced `<stdexcept>` with `<exception>` (correct header for `std::exception`).

---

# kstools 0.5.0

## Performance

- `ks_read_xpt()` / `ks_write_xpt()`: completely rewritten C++ engine.
  Uses POSIX `mmap` for zero-copy file access, streaming columnar decode
  directly into pre-allocated R vectors, and a multi-threaded worker pool
  for numeric columns (`n_threads` argument, defaults to `hw - 1`).
  A 5 GB XPT file now reads in ~4 s at ~1.3 GB/s with parser scratch
  well below 4 MB (previously > 100 GB RSS). Writer uses a 64 KB output
  buffer with no in-memory row materialisation. Multi-member files are
  handled via in-place mmap offsets (no temp files).

---

# kstools 0.4.1

## New features

- `ks_get_data()`: added `xpt_reader` argument (and global option
  `kstools.xpt.reader`) to select the XPT loading back-end.
  Use `xpt_reader = "internal"` (or `options(kstools.xpt.reader = "internal")`)
  to suppress the *"ignored N trailing byte(s) after row parsing"* warning
  emitted by **haven** on some XPORT files. `"haven"` remains the default.
  When the internal reader is used and the file contains multiple members,
  the domain slot in the output is a named list of tibbles.

---

# kstools 0.4.0

## New features

- `ks_read_xpt()`: read SAS XPORT V5/V8/V9 files into tibbles. Variable labels,
  SAS formats, and informats are preserved as column attributes (`"label"`,
  `"format.sas"`, `"sas.informat"`). Multi-member files are returned as a named
  list of tibbles.
- `ks_write_xpt()`: write a data frame to a SAS XPORT V5 or V8 file. Labels and
  formats can be supplied via column attributes or explicit `labels`/`formats`
  arguments.
- `ks_xpt_labels()` / `ks_xpt_formats()`: extract variable labels and SAS
  formats from a data frame as named character vectors.
- `ks_set_labels()` / `ks_set_formats()`: set `"label"` / `"format.sas"`
  attributes on selected columns from named character vectors.
- Date and datetime epoch conversion between SAS (1960-01-01) and R
  (1970-01-01) is applied automatically; disable with `convert_dates = FALSE`.
- IBM hexadecimal floating-point encoding/decoding and SAS tagged-missing
  values are fully supported.

---

# kstools 0.3.9

## Breaking changes

- `ks_get_data()`: no longer assigns loaded data to `.GlobalEnv`. It now
  **returns** the data directly — a tibble for a single-domain call, or a
  named list of tibbles for multi-domain calls. Migrate
  `ks_get_data(dm)` to `dm <- ks_get_data(dm)` and
  `ks_get_data(dm, ae)` to `dat <- ks_get_data(dm, ae); dm <- dat$dm`.

## New features

- `ks_get_data()`: file lookup against `path` is now **case-insensitive**
  for both stem and extension, so `ks_get_data(dm)` and `ks_get_data(DM)`
  both match `dm.xpt`, `DM.XPT`, `Dm.Xpt`, etc.
- `ks_get_data()`: new global option `kstools.get_data.case` to resolve
  ambiguity when multiple files share the same stem but differ in case.
  Accepted values: `"error"` (default), `"first"`, `"lower"`, `"upper"`.

---

# kstools 0.3.8

## Bug fixes

- `ks_mianalyze()` / `mianalyze()`: aligned degrees-of-freedom handling with SAS `PROC MIANALYZE` behavior by adding `edf` (SAS `EDF=` analogue) and applying Barnard-Rubin small-sample adjustment when finite complete-data df are supplied.
- `ks_mianalyze()` / `mianalyze()`: kept backward compatibility for `v0` while adding input validation for conflicting `edf`/`v0` specifications.

## Documentation

- Updated function docs and examples for the new `edf` argument and SAS-style DF behavior.

---

# kstools 0.3.7

## Bug fixes

- `ks_mianalyze()`: corrected pooled total-variance and Rubin degrees-of-freedom calculations used for multiple-imputation inference.

## Documentation

- Bumped package version metadata and refreshed release documentation.

---

# kstools 0.3.6

## Documentation

- Added pkgdown configuration (`_pkgdown.yml`) and generated docs site workflow.
- Added vignettes: `getting-started` and `clinical-workflows`.
- Expanded `inst/examples` coverage and added `run_all_examples.R` index runner.
- Added CI workflow to keep README version badge synchronized with `DESCRIPTION`.

## New functions

- Added `ks_mianalyze()` / `mianalyze()` (Rubin pooling; SAS MIANALYZE analogue).
- Added `ks_roc()` (correlated ROC AUC comparison with contrast tests).
- Added `ks_williams()` (randomized Williams cross-over design and schedule generator).

## Bug fixes

- `ks_collapse_check_msgs()`: removed unqualified `%>%` dependency so function and vignettes run without attaching dplyr.

---

# kstools 0.3.5

## Performance

- `ks_save2xlsx_by()`: replaced O(N) per-row `wb_add_fill()` loops with Excel
  Conditional Formatting rules (`wb_add_dxfs_style()` +
  `wb_add_conditional_formatting()`).  Fill calls now scale O(1) per colour
  key per sheet regardless of row count — e.g. 3,000 `wb_add_fill()` calls
  for a 1,000-row / 3-colour sheet become 3 CF rules.

## Bug fixes

- `ks_summary()` test: fixed case-insensitive regexp match for the
  "Duplicate names" error so the test no longer fails against the
  capitalised message.

---

# kstools 0.3.4

## Bug fixes

- `ks_z_score()`: fixed inverted formula — was returning `(mean - x) / sd`
  instead of the correct `(x - mean) / sd`.
- `read.csv3()`: fixed potential crash on end-of-file when `readLines()` returns
  `character(0)` — `length()` guard now precedes `grepl()` to avoid a
  zero-length condition in `if()`.
- `ks_compare_check_state()`: removed unused internal `..row_id..` column that
  was allocated and immediately deleted on every call.
- `ks_median_ci()` (`boot` method): guard against `NULL` `$bca` component —
  `boot.ci()` omits BCa for very small samples; bounds now fall back to
  `NA_real_` instead of silently dropping vector elements.
- `ks_save2xlsx_by()`: removed dead `as_table` parameter (implementation was
  already removed in 0.3.3); narrowed status-column fill to the status column
  only (was incorrectly colouring the entire row); added freeze-pane on the
  header row; added thin cell borders on all data cells.

## Minor improvements

- `ks_cv()`, `ks_z_score()`: replaced bare `T` with `TRUE`.
- `ks_del_tmp()`: simplified redundant single-character class `[t]` to `t`.

---

# kstools 0.3.3

## Bug fixes

- Removed unused `labelled` import; `is_missing` is now correctly sourced from `ksformat`.

---

# kstools 0.3.2

## New features

- Added validation workflow helpers: `ks_check_rules()`, `ks_collapse_check_msgs()`, `ks_compare_check_state()`, and `ks_save2xlsx_by()`.
- Added label and coding helpers: `ks_get_labels()` and `ks_code_to_fmt()`.

## Dependencies

- Added imports: `ksformat`, `labelled`, `openxlsx2`, `purrr`, `stringr`, and `tibble`.

---

# kstools 0.3.1

## New features

- **`read.csv3()`**: read a CSV file with optional KeyStat comment headers (`#NAME$type(length)$Label`) for column types and labels.
- **`ks_get_data()`**: new `type` values `"csv"` and `"csvks"` for loading plain CSV and KeyStat-commented CSV domains; `.csv` is also auto-detected.

---

# kstools 0.3.0

## New features
- **`ks_summary()`**: new `numdec = TRUE` parameter appends a `NUMDEC` column with the group-level max decimal places of `var` (via `ks_get_numdec` logic).
- **`ks_current_filename()`**: detect the basename of the running R script (source or Rscript).
- **`ks_get_numdec()`**: compute max decimal places per group and join as `NUMDEC`.
- Second author added: Igor Aleschenkov.

## Improvements

- `R/get_numeric.r` renamed to `R/get_numdec.r` for consistency with the exported function name.

---

# kstools 0.2.0

## New features

- **`ks_summary()`** accepts optional **`extras`**: a named list of functions (`f(x, na.rm)`) for extra per-group statistics; columns appear after the default summary stats and before `cv`.

## Improvements and fixes

- **`ks_simulate_ar1()`**: validation, reproducibility (`seed`), `MASS::` / `stats::` usage, documentation, examples, and tests.
- **`ks_geom_mean()`**, **`ks_median_ci()`**, **`ks_n_pct()`**, **`ks_get_data()`**, **`ks_swap_cols()`**, **`ks_swoe()`**, and related helpers: refactors, bug fixes, and documentation updates (see git history).
- **Newcombe hybrid score** CIs: `ks_newcombe_hs()`, `ks_newcombe_hs_strata()`.
- Removed **`ks_trim`** in favour of **`base::trimws()`**; removed medical-history helpers from earlier versions.

## Documentation

- README and package overview (`?kstools`) updated; broken cross-references in the package index fixed.

---

# kstools 0.1.0

Initial packaged release.
