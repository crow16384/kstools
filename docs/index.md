# kstools

[![License:
GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![Docs and
Site](https://github.com/crow16384/kstools/actions/workflows/docs-site.yml/badge.svg)](https://github.com/crow16384/kstools/actions/workflows/docs-site.yml)
[![pkgdown
site](https://img.shields.io/badge/pkgdown-site-2A7FFF)](https://crow16384.github.io/kstools/)
[![Version](https://img.shields.io/badge/version-0.5.2-blue)](https://github.com/crow16384/kstools/releases/latest)

Clinical and data science utilities for R.

Current package version is maintained in
[DESCRIPTION](https://crow16384.github.io/kstools/DESCRIPTION); detailed
release history is in
[NEWS.md](https://crow16384.github.io/kstools/NEWS.md).

Repository:
[github.com/crow16384/kstools](https://github.com/crow16384/kstools)

## Installation

From a local checkout (package root):

``` r

install.packages(".", repos = NULL, type = "source")
```

From GitHub:

``` r

remotes::install_github("crow16384/kstools")
```

## Key Features

### Descriptive Statistics

- [`ks_summary()`](https://crow16384.github.io/kstools/reference/ks_summary.md)
  grouped summary table with optional custom statistics (`extras`)
- [`ks_median_ci()`](https://crow16384.github.io/kstools/reference/ks_median_ci.md),
  [`ks_geom_mean()`](https://crow16384.github.io/kstools/reference/ks_geom_mean.md),
  [`ks_q1()`](https://crow16384.github.io/kstools/reference/ks_q1.md),
  [`ks_q3()`](https://crow16384.github.io/kstools/reference/ks_q3.md),
  [`ks_cv()`](https://crow16384.github.io/kstools/reference/ks_cv.md),
  [`ks_z_score()`](https://crow16384.github.io/kstools/reference/ks_z_score.md),
  [`ks_p_norm()`](https://crow16384.github.io/kstools/reference/ks_p_norm.md),
  [`ks_n_pct()`](https://crow16384.github.io/kstools/reference/ks_n_pct.md)
- [`ks_get_numdec()`](https://crow16384.github.io/kstools/reference/ks_get_numdec.md)
  for decimal precision tracking

### Inference and Comparative Methods

- [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  /
  [`mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  Rubin pooling across multiple imputations (SAS MIANALYZE analogue)
- [`ks_roc()`](https://crow16384.github.io/kstools/reference/ks_roc.md)
  correlated ROC AUC comparison using Mann-Whitney components and
  contrast tests
- [`ks_eairdiff_mn()`](https://crow16384.github.io/kstools/reference/ks_eairdiff_mn.md)
  /
  [`ks_eairdiff_strata_mn()`](https://crow16384.github.io/kstools/reference/ks_eairdiff_strata_mn.md)
  incidence-rate difference CIs
- [`ks_newcombe_hs()`](https://crow16384.github.io/kstools/reference/ks_newcombe_hs.md)
  /
  [`ks_newcombe_hs_strata()`](https://crow16384.github.io/kstools/reference/ks_newcombe_hs_strata.md)
  difference-in-proportion CIs
- [`ks_auc()`](https://crow16384.github.io/kstools/reference/ks_auc.md)
  linear/log-linear trapezoidal AUC

### SDTM / ADaM Helpers

- [`ks_dtc2dtn()`](https://crow16384.github.io/kstools/reference/ks_dtc2dtn.md)
  DTC to `Date`
- [`ks_supp_consistency_check()`](https://crow16384.github.io/kstools/reference/ks_supp_consistency_check.md)
  and
  [`ks_supp_merge()`](https://crow16384.github.io/kstools/reference/ks_supp_merge.md)
  for SUPP domains
- [`ks_xpt_content()`](https://crow16384.github.io/kstools/reference/ks_xpt_content.md),
  [`ks_extract_single_xpt()`](https://crow16384.github.io/kstools/reference/ks_extract_single_xpt.md),
  [`ks_batch_load_from_single_xpt()`](https://crow16384.github.io/kstools/reference/ks_batch_load_from_single_xpt.md)
  for multi-member XPT workflows
- [`ks_desc_coded()`](https://crow16384.github.io/kstools/reference/ks_desc_coded.md)
  clinical coded-summary table builder

### Data Loading and Export

- [`ks_get_data()`](https://crow16384.github.io/kstools/reference/ks_get_data.md)
  and
  [`read.csv3()`](https://crow16384.github.io/kstools/reference/read.csv3.md)
- [`ks_batch_load()`](https://crow16384.github.io/kstools/reference/ks_batch_load.md)
  and
  [`ks_batch_load_xlsx()`](https://crow16384.github.io/kstools/reference/ks_batch_load_xlsx.md)
- [`ks_save2xlsx_by()`](https://crow16384.github.io/kstools/reference/ks_save2xlsx_by.md)
  split-by-sheet XLSX export with conditional formatting

### Utility Functions

- [`ks_swap_cols()`](https://crow16384.github.io/kstools/reference/ks_swap_cols.md),
  [`ks_del_tmp()`](https://crow16384.github.io/kstools/reference/ks_del_tmp.md),
  [`ks_aligndec()`](https://crow16384.github.io/kstools/reference/ks_aligndec.md),
  [`ks_sum_na()`](https://crow16384.github.io/kstools/reference/ks_sum_na.md),
  `%+na%`
- [`ks_swoe()`](https://crow16384.github.io/kstools/reference/ks_swoe.md),
  [`ks_simulate_ar1()`](https://crow16384.github.io/kstools/reference/ks_simulate_ar1.md),
  [`ks_current_filename()`](https://crow16384.github.io/kstools/reference/ks_current_filename.md),
  [`ks_code_to_fmt()`](https://crow16384.github.io/kstools/reference/ks_code_to_fmt.md),
  [`ks_get_labels()`](https://crow16384.github.io/kstools/reference/ks_get_labels.md),
  [`ks_compare_check_state()`](https://crow16384.github.io/kstools/reference/ks_compare_check_state.md),
  [`ks_check_rules()`](https://crow16384.github.io/kstools/reference/ks_check_rules.md),
  [`ks_collapse_check_msgs()`](https://crow16384.github.io/kstools/reference/ks_collapse_check_msgs.md)
- [`ks_williams()`](https://crow16384.github.io/kstools/reference/ks_williams.md)
  randomized Williams design and schedule generation

## Examples

- Runnable per-function scripts are in
  [inst/examples](https://crow16384.github.io/kstools/inst/examples).
- Run all examples in a defined sequence:

``` r

source("inst/examples/run_all_examples.R")
```

## Documentation Workflow

From the package root:

``` r

# 1) Regenerate Rd files and NAMESPACE from roxygen comments
roxygen2::roxygenise()

# 2) Build vignettes
devtools::build_vignettes()

# 3) Build package site (pkgdown)
pkgdown::build_site()
```

The pkgdown configuration is in
[\_pkgdown.yml](https://crow16384.github.io/kstools/_pkgdown.yml), and
vignettes are in
[vignettes](https://crow16384.github.io/kstools/vignettes).

## Serena (AI Code Navigation)

This repo is configured for [Serena](https://github.com/oraios/serena)
semantic code navigation. VS Code launches the Serena MCP server
automatically via `.vscode/mcp.json`.

### Initial setup

``` sh
# Re-index project or run a health-check
./scripts/start-serena.sh
```

That script creates `.serena/project.yml` if missing, runs
`serena project index`, and runs `serena project health-check`.

### Troubleshooting

#### “No active project” / MCP tools fail

Activate the project from the agent/chat session:

    activate_project("/Users/meguty/Develop/R/kstools")

Or from the terminal:

``` sh
cd /path/to/kstools
serena project activate --name kstools
serena project health-check "$PWD"
```

#### Health-check fails on vignettes or test helpers

Non-R files (`.Rmd`) and symbol-less bootstrap files confuse the R LSP.\
They are excluded in
[.serena/project.yml](https://crow16384.github.io/kstools/.serena/project.yml)
via `ignored_paths`:

``` yaml
ignored_paths:
  - "vignettes/*.Rmd"
  - "tests/**"
```

If a new non-R file triggers a failure, add it to `ignored_paths` in the
same way.

#### Re-index after large changes

``` sh
serena project index . --name kstools --language r
```

## Dependencies

Primary imports and suggested packages are declared in
[DESCRIPTION](https://crow16384.github.io/kstools/DESCRIPTION).

## License

GNU General Public License v3.0 (GPL-3).

See [DESCRIPTION](https://crow16384.github.io/kstools/DESCRIPTION) and
the [GPL-3.0 text](https://www.gnu.org/licenses/gpl-3.0.en.html).
