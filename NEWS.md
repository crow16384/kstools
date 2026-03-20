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
