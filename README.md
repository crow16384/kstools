# kstools

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)

Clinical and data science utilities for R.

**Version:** 0.3.1 (see [`NEWS.md`](NEWS.md) for changes.)

**Repository:** [github.com/crow16384/kstools](https://github.com/crow16384/kstools)

## Installation

From a local checkout (package root):

```r
install.packages(".", repos = NULL, type = "source")
```

From GitHub (requires the [**remotes**](https://cran.r-project.org/package=remotes) package):

```r
remotes::install_github("crow16384/kstools")
```

## Function overview

### Descriptive statistics

| Function | Description |
|----------|-------------|
| `ks_summary()` | Grouped summary: `n`, mean (SD), median, Q1;Q3, min;max, CV; optional `extras` (named list of functions); optional paired p-value |
| `ks_median_ci()` | Median with confidence interval (bootstrap, Olive, or z) |
| `ks_geom_mean()` | Geometric mean and confidence interval |
| `ks_q1()`, `ks_q3()` | 25th and 75th percentiles (SAS type=2 by default) |
| `ks_cv()` | Coefficient of variation |
| `ks_z_score()` | Z-score `(mean(x) - x) / sd(x)` |
| `ks_p_norm()` | Shapiro-Wilk p-value |
| `ks_n_pct()` | Format counts as `n (pct%)` (vector or data.frame) |

### SDTM / ADaM helpers

| Function | Description |
|----------|-------------|
| `ks_dtc2dtn()` | Convert DTC character to `Date` |
| `ks_supp_consistency_check()` | Validate SUPP structure/content |
| `ks_supp_merge()` | Merge SUPP with primary domain |
| `ks_xpt_content()` | List datasets in a multi-member SAS XPORT file |
| `ks_extract_single_xpt()` | Read one dataset from XPORT |
| `ks_batch_load_from_single_xpt()` | Load/save all datasets (RData/rds/parquet) |

### Clinical table builders

| Function | Description |
|----------|-------------|
| `ks_desc_coded()` | Descriptive table for coded / factor variables |

### Data loading

| Function | Description |
|----------|-------------|
| `ks_get_data()` | Load one or more domains (`.rds`, `.xpt`, `.xlsx`, `.csv`) into `.GlobalEnv` |
| `read.csv3()` | Read a CSV file; optionally parse KeyStat comment headers for column types and labels |
| `ks_batch_load()` | Batch-load files by type (e.g. xlsx, csv) |
| `ks_batch_load_xlsx()` | Convenience wrapper: xlsx batch load |

### Utilities

| Function | Description |
|----------|-------------|
| `ks_swap_cols()` | Swap pairs of columns by name |
| `ks_del_tmp()` | Remove temporary objects (`t.*`, `o.*`) from global env |
| `ks_aligndec()` | Align strings by decimal / first space |
| `ks_sum_na()` | Sum ignoring NA |
| `ks_auc()` | Area under curve (trapezoidal or log-trapezoidal) |
| `ks_swoe()` | Smoothed weight of evidence for factors |
| `ks_simulate_ar1()` | Simulate AR(1) longitudinal data |
| `ks_eairdiff_mn()` | Miettinen–Nurminen CI for difference of incidence rates |
| `ks_eairdiff_strata_mn()` | Stratified version |
| `ks_newcombe_hs()` | Newcombe hybrid score CI for difference of proportions |
| `ks_newcombe_hs_strata()` | Stratified version |
| `ks_current_filename()` | Basename of the currently executing R script |
| `ks_get_numdec()` | Max decimal places per group (joins `NUMDEC` column) |

Use base R [`trimws()`](https://stat.ethz.ch/R-manual/R-devel/library/base/html/trimws.html) for leading/trailing whitespace on character vectors (tidyr has no separate trim helper; `stringr::str_trim` is equivalent).

## Dependencies

Declared in `DESCRIPTION`:

- **Imports:** `boot`, `dplyr`, `MASS`, `methods`, `nlme`, `parallel`, `rlang`, `rootSolve`, `tidyr`
- **Suggests:** `arrow`, `foreign`, `haven`, `openxlsx`, `testthat` (≥ 3.0.0)

## License

**GNU General Public License v3.0 (GPL-3.0)**

This package is free software: you can redistribute it and/or modify it under the terms of the [GNU General Public License as published by the Free Software Foundation](https://www.gnu.org/licenses/gpl-3.0.en.html), version 3.

- **SPDX:** `GPL-3.0` — see the `License:` field in [`DESCRIPTION`](DESCRIPTION).
- **Copyright:** Vladimir Larchenko.

A separate `LICENSE` file in the repository is optional; the GPL-3.0 applies as stated in `DESCRIPTION` and here. For the full license text, see the [official GPL-3.0 page](https://www.gnu.org/licenses/gpl-3.0.en.html).
