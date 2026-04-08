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
