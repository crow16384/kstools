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
