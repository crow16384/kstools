#' kstools: Clinical and Data Science Utilities
#'
#' Utility functions for clinical trials and data science:
#' \itemize{
#'   \item \strong{Descriptive statistics}: \code{\link{ks_summary}} (optional \code{extras}), \code{\link{ks_median_ci}}, \code{\link{ks_geom_mean}}, \code{\link{ks_q1}}, \code{\link{ks_q3}}, \code{\link{ks_cv}}, \code{\link{ks_z_score}}, \code{\link{ks_p_norm}}, \code{\link{ks_n_pct}}
#'   \item \strong{SDTM/ADaM}: \code{\link{ks_dtc2dtn}}, \code{\link{ks_supp_consistency_check}}, \code{\link{ks_supp_merge}}, \code{\link{ks_xpt_content}}, \code{\link{ks_extract_single_xpt}}, \code{\link{ks_batch_load_from_single_xpt}}
#'   \item \strong{Tables}: \code{\link{ks_desc_coded}}
#'   \item \strong{Data loading}: \code{\link{ks_get_data}}, \code{\link{read.csv3}}, \code{\link{ks_batch_load}}, \code{\link{ks_batch_load_xlsx}}
#'   \item \strong{Utilities}: \code{\link{ks_swap_cols}}, \code{\link{ks_del_tmp}}, \code{\link{ks_aligndec}}, \code{\link{ks_sum_na}}, \code{\link{ks_auc}}, \code{\link{ks_swoe}}, \code{\link{ks_simulate_ar1}}, \code{\link{ks_eairdiff_mn}}, \code{\link{ks_eairdiff_strata_mn}}, \code{\link{ks_newcombe_hs}}, \code{\link{ks_newcombe_hs_strata}}, \code{\link{ks_current_filename}}, \code{\link{ks_get_numdec}}
#' }
#' @keywords internal
#' @useDynLib kstools, .registration = TRUE
#' @importFrom Rcpp sourceCpp
"_PACKAGE"

## Suppress R CMD check NOTEs for NSE column references used as function defaults
## or inside dplyr verbs where the binding is established by the calling context.
utils::globalVariables(c(
  ## ks_desc_coded default argument names (NSE)
  "usubjid", "meddra_soc", "meddra_pt",
  ## ks_desc_coded intermediate dplyr mutate columns
  "ord0", "ord", "e",
  ## ks_summary intermediate dplyr mutate columns
  "p.norm", "p.chg.w", "p.chg.t",
  ## ks_code_to_fmt tidyr::separate intermediate columns (NSE)
  "col1", "col2"
))
