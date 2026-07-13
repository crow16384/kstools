# Package index

## Descriptive Statistics

Summaries and common descriptive estimators.

- [`ks_summary()`](https://crow16384.github.io/kstools/reference/ks_summary.md)
  : Descriptive summary for continuous variables
- [`ks_median_ci()`](https://crow16384.github.io/kstools/reference/ks_median_ci.md)
  : Confidence interval for the median
- [`ks_geom_mean()`](https://crow16384.github.io/kstools/reference/ks_geom_mean.md)
  : Geometric mean and confidence interval
- [`ks_q1()`](https://crow16384.github.io/kstools/reference/ks_q1.md) :
  25th percentile (Q1)
- [`ks_q3()`](https://crow16384.github.io/kstools/reference/ks_q3.md) :
  75th percentile (Q3)
- [`ks_cv()`](https://crow16384.github.io/kstools/reference/ks_cv.md) :
  Coefficient of variation
- [`ks_z_score()`](https://crow16384.github.io/kstools/reference/ks_z_score.md)
  : Calculate Z score
- [`ks_p_norm()`](https://crow16384.github.io/kstools/reference/ks_p_norm.md)
  : Normality test p-value
- [`ks_n_pct()`](https://crow16384.github.io/kstools/reference/ks_n_pct.md)
  : Format count and percentage pairs
- [`ks_get_numdec()`](https://crow16384.github.io/kstools/reference/ks_get_numdec.md)
  : Compute the maximum number of decimal places per group

## Inference and Comparison

Confidence intervals, pooled estimates, and model-comparison helpers.

- [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  [`mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  [`summary(`*`<ks_mianalyze>`*`)`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  [`knit_print(`*`<ks_mianalyze>`*`)`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  : Analogue of SAS PROC MIANALYZE (Rubin pooling)
- [`ks_roc()`](https://crow16384.github.io/kstools/reference/ks_roc.md)
  : Compare correlated ROC curve areas (AUC) via Mann-Whitney contrasts
- [`ks_eairdiff_mn()`](https://crow16384.github.io/kstools/reference/ks_eairdiff_mn.md)
  : Miettinen-Nurminen CI for the difference of two incidence rates
- [`ks_eairdiff_strata_mn()`](https://crow16384.github.io/kstools/reference/ks_eairdiff_strata_mn.md)
  : Stratified Miettinen-Nurminen CI for the difference of incidence
  rates
- [`ks_newcombe_hs()`](https://crow16384.github.io/kstools/reference/ks_newcombe_hs.md)
  : Newcombe Hybrid Score CI for a difference of two proportions
- [`ks_newcombe_hs_strata()`](https://crow16384.github.io/kstools/reference/ks_newcombe_hs_strata.md)
  : Stratified Newcombe Hybrid Score CI for a difference of two
  proportions
- [`ks_auc()`](https://crow16384.github.io/kstools/reference/ks_auc.md)
  : Area Under the Curve (AUC) by the trapezoidal rule

## SDTM and Clinical Data Utilities

SDTM helpers and supplemental-domain workflows.

- [`ks_dtc2dtn()`](https://crow16384.github.io/kstools/reference/ks_dtc2dtn.md)
  : Convert DTC (date-time character) to Date
- [`ks_impute_dtc()`](https://crow16384.github.io/kstools/reference/ks_impute_dtc.md)
  : Impute incomplete ISO 8601 date/datetime strings
- [`ks_supp_consistency_check()`](https://crow16384.github.io/kstools/reference/ks_supp_consistency_check.md)
  : Check SDTM supplemental dataset structure
- [`ks_supp_merge()`](https://crow16384.github.io/kstools/reference/ks_supp_merge.md)
  : Merge an SDTM supplemental domain with its primary domain
- [`ks_desc_coded()`](https://crow16384.github.io/kstools/reference/ks_desc_coded.md)
  : Summarise hierarchically coded clinical items
- [`ks_get_labels()`](https://crow16384.github.io/kstools/reference/ks_get_labels.md)
  : Get variable labels from a data frame

## Data Input and Export

File readers, batch loaders, and report writers.

- [`ks_get_data()`](https://crow16384.github.io/kstools/reference/ks_get_data.md)
  : Load domain files and return them

- [`read.csv3()`](https://crow16384.github.io/kstools/reference/read.csv3.md)
  : Read CSV file with column types and lengths in comments

- [`ks_batch_load()`](https://crow16384.github.io/kstools/reference/ks_batch_load.md)
  : Batch load files from a directory or ZIP

- [`ks_batch_load_xlsx()`](https://crow16384.github.io/kstools/reference/ks_batch_load_xlsx.md)
  :

  Backwards-compatible wrapper for `ks_batch_load` with `type = "xlsx"`

- [`ks_xpt_content()`](https://crow16384.github.io/kstools/reference/ks_xpt_content.md)
  : List datasets inside a SAS XPORT v8/v9 file

- [`ks_extract_single_xpt()`](https://crow16384.github.io/kstools/reference/ks_extract_single_xpt.md)
  : Extract one dataset from a multi-member SAS XPORT v8/v9 file

- [`ks_batch_load_from_single_xpt()`](https://crow16384.github.io/kstools/reference/ks_batch_load_from_single_xpt.md)
  : Load or save all datasets from a multi-member SAS XPORT v8/v9 file

## SAS XPORT Read / Write

Read and write SAS XPORT (XPT) V5/V8 files with label and format
support.

- [`ks_read_xpt()`](https://crow16384.github.io/kstools/reference/ks_read_xpt.md)
  : Read a SAS XPORT (.xpt) file
- [`ks_write_xpt()`](https://crow16384.github.io/kstools/reference/ks_write_xpt.md)
  : Write a data frame to a SAS XPORT (.xpt) file
- [`ks_xpt_labels()`](https://crow16384.github.io/kstools/reference/ks_xpt_labels.md)
  : Get SAS variable labels from a data frame
- [`ks_xpt_formats()`](https://crow16384.github.io/kstools/reference/ks_xpt_formats.md)
  : Get SAS variable formats from a data frame
- [`ks_set_labels()`](https://crow16384.github.io/kstools/reference/ks_set_labels.md)
  : Set SAS variable labels on a data frame
- [`ks_set_formats()`](https://crow16384.github.io/kstools/reference/ks_set_formats.md)
  : Set SAS variable formats on a data frame

## Miscellaneous Utilities

- [`ks_swap_cols()`](https://crow16384.github.io/kstools/reference/ks_swap_cols.md)
  : Swap pairs of columns in a data frame
- [`ks_del_tmp()`](https://crow16384.github.io/kstools/reference/ks_del_tmp.md)
  : Remove temporary objects from global environment
- [`ks_aligndec()`](https://crow16384.github.io/kstools/reference/ks_aligndec.md)
  : Align decimal (or first space) in character vector
- [`ks_sum_na()`](https://crow16384.github.io/kstools/reference/ks_sum_na.md)
  [`` `%+na%` ``](https://crow16384.github.io/kstools/reference/ks_sum_na.md)
  : Add two values ignoring NA
- [`ks_swoe()`](https://crow16384.github.io/kstools/reference/ks_swoe.md)
  : Smoothed weight of evidence (SWOE) for categorical predictors
- [`ks_simulate_ar1()`](https://crow16384.github.io/kstools/reference/ks_simulate_ar1.md)
  : Simulate longitudinal data with AR(1) within-subject errors
- [`ks_current_filename()`](https://crow16384.github.io/kstools/reference/ks_current_filename.md)
  : Get the filename of the currently executing R script
- [`ks_code_to_fmt()`](https://crow16384.github.io/kstools/reference/ks_code_to_fmt.md)
  : Build a named format vector from a coded column
- [`ks_williams()`](https://crow16384.github.io/kstools/reference/ks_williams.md)
  : Build a randomized Williams cross-over design and schedule
