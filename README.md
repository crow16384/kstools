# kstools

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![Docs and Site](https://github.com/crow16384/kstools/actions/workflows/docs-site.yml/badge.svg)](https://github.com/crow16384/kstools/actions/workflows/docs-site.yml)
[![pkgdown site](https://img.shields.io/badge/pkgdown-site-2A7FFF)](https://crow16384.github.io/kstools/)
<!-- version-badge:start -->
[![Version](https://img.shields.io/badge/version-0.3.8-blue)](https://github.com/crow16384/kstools/releases/latest)
<!-- version-badge:end -->

Clinical and data science utilities for R.

Current package version is maintained in [DESCRIPTION](DESCRIPTION); detailed release history is in [NEWS.md](NEWS.md).

Repository: [github.com/crow16384/kstools](https://github.com/crow16384/kstools)

## Installation

From a local checkout (package root):

```r
install.packages(".", repos = NULL, type = "source")
```

From GitHub:

```r
remotes::install_github("crow16384/kstools")
```

## Key Features

### Descriptive Statistics

- `ks_summary()` grouped summary table with optional custom statistics (`extras`)
- `ks_median_ci()`, `ks_geom_mean()`, `ks_q1()`, `ks_q3()`, `ks_cv()`, `ks_z_score()`, `ks_p_norm()`, `ks_n_pct()`
- `ks_get_numdec()` for decimal precision tracking

### Inference and Comparative Methods

- `ks_mianalyze()` / `mianalyze()` Rubin pooling across multiple imputations (SAS MIANALYZE analogue)
- `ks_roc()` correlated ROC AUC comparison using Mann-Whitney components and contrast tests
- `ks_eairdiff_mn()` / `ks_eairdiff_strata_mn()` incidence-rate difference CIs
- `ks_newcombe_hs()` / `ks_newcombe_hs_strata()` difference-in-proportion CIs
- `ks_auc()` linear/log-linear trapezoidal AUC

### SDTM / ADaM Helpers

- `ks_dtc2dtn()` DTC to `Date`
- `ks_supp_consistency_check()` and `ks_supp_merge()` for SUPP domains
- `ks_xpt_content()`, `ks_extract_single_xpt()`, `ks_batch_load_from_single_xpt()` for multi-member XPT workflows
- `ks_desc_coded()` clinical coded-summary table builder

### Data Loading and Export

- `ks_get_data()` and `read.csv3()`
- `ks_batch_load()` and `ks_batch_load_xlsx()`
- `ks_save2xlsx_by()` split-by-sheet XLSX export with conditional formatting

### Utility Functions

- `ks_swap_cols()`, `ks_del_tmp()`, `ks_aligndec()`, `ks_sum_na()`, `%+na%`
- `ks_swoe()`, `ks_simulate_ar1()`, `ks_current_filename()`, `ks_code_to_fmt()`, `ks_get_labels()`, `ks_compare_check_state()`, `ks_check_rules()`, `ks_collapse_check_msgs()`
- `ks_williams()` randomized Williams design and schedule generation

## Examples

- Runnable per-function scripts are in [inst/examples](inst/examples).
- Run all examples in a defined sequence:

```r
source("inst/examples/run_all_examples.R")
```

## Documentation Workflow

From the package root:

```r
# 1) Regenerate Rd files and NAMESPACE from roxygen comments
roxygen2::roxygenise()

# 2) Build vignettes
devtools::build_vignettes()

# 3) Build package site (pkgdown)
pkgdown::build_site()
```

The pkgdown configuration is in [_pkgdown.yml](_pkgdown.yml), and vignettes are in [vignettes](vignettes).

## Serena (AI Code Navigation)

This repo is configured for [Serena](https://github.com/oraios/serena) semantic code navigation.
VS Code launches the Serena MCP server automatically via `.vscode/mcp.json`.

### Initial setup

```sh
# Re-index project or run a health-check
./scripts/start-serena.sh
```

That script creates `.serena/project.yml` if missing, runs `serena project index`, and runs `serena project health-check`.

### Troubleshooting

#### "No active project" / MCP tools fail

Activate the project from the agent/chat session:

```
activate_project("/Users/meguty/Develop/R/kstools")
```

Or from the terminal:

```sh
cd /path/to/kstools
serena project activate --name kstools
serena project health-check "$PWD"
```

#### Health-check fails on vignettes or test helpers

Non-R files (`.Rmd`) and symbol-less bootstrap files confuse the R LSP.  
They are excluded in [.serena/project.yml](.serena/project.yml) via `ignored_paths`:

```yaml
ignored_paths:
  - "vignettes/*.Rmd"
  - "tests/**"
```

If a new non-R file triggers a failure, add it to `ignored_paths` in the same way.

#### Re-index after large changes

```sh
serena project index . --name kstools --language r
```

## Dependencies

Primary imports and suggested packages are declared in [DESCRIPTION](DESCRIPTION).

## License

GNU General Public License v3.0 (GPL-3).

See [DESCRIPTION](DESCRIPTION) and the [GPL-3.0 text](https://www.gnu.org/licenses/gpl-3.0.en.html).
