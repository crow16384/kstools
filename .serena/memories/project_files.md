# kstools — R Source File Inventory

All source files live under `R/`. One file per functional area. All public functions are prefixed `ks_`.

## File → Exported Functions

| File | Functions |
|------|-----------|
| `R/aligndec.r` | `ks_aligndec` |
| `R/auc.r` | `ks_auc` |
| `R/batch_load.r` | `ks_batch_load`, `ks_batch_load_xlsx` |
| `R/check_rules.r` | `ks_check_rules` |
| `R/code_to_fmt.r` | `ks_code_to_fmt` |
| `R/collapse_check_msgs.r` | `ks_collapse_check_msgs` |
| `R/compare_check_state.r` | `ks_compare_check_state` |
| `R/current_filename.r` | `ks_current_filename` |
| `R/cv.r` | `ks_cv` |
| `R/del_tmp.r` | `ks_del_tmp` |
| `R/desc_coded.r` | `ks_desc_coded` |
| `R/dtc2dtn.r` | `ks_dtc2dtn` |
| `R/eair.r` | `ks_eairdiff_mn`, `ks_eairdiff_strata_mn` |
| `R/get_data.r` | `read.csv3`, `ks_get_data` |
| `R/get_labels.r` | `ks_get_labels` |
| `R/get_numdec.r` | `ks_get_numdec` |
| `R/gmean.r` | `ks_geom_mean` |
| `R/ks_summary.r` | `ks_summary` |
| `R/kstools-package.R` | *(package-level roxygen stub, no exported functions)* |
| `R/median_ci.r` | `ks_median_ci`; helpers: `.median_boot`, `.median_olive`, `.median_z` |
| `R/n_pct.r` | `ks_n_pct` (S3 generic + methods: `.numeric`, `.data.frame`, `.default`) |
| `R/newcombes_hs.r` | `ks_newcombe_hs`, `ks_newcombe_hs_strata`; helper: `.wilson_ci` |
| `R/norm.r` | `ks_p_norm` |
| `R/q1q3.r` | `ks_q1`, `ks_q3` |
| `R/read_single_xpt.r` | `ks_xpt_content`, `ks_extract_single_xpt`, `ks_batch_load_from_single_xpt` |
| `R/save2xlsx_by.r` | `ks_save2xlsx_by` |
| `R/simulate_ar1.r` | `ks_simulate_ar1` |
| `R/sum_na.r` | `ks_sum_na`, `%+na%` |
| `R/supp_merge.r` | `ks_supp_consistency_check`, `ks_supp_merge` |
| `R/swap_cols.r` | `ks_swap_cols` |
| `R/swoe.r` | `ks_swoe` |
| `R/z_score.r` | `ks_z_score` |

## Notes

- 31 R source files, ~55 indexed symbols total
- Private helpers use `.` prefix (e.g. `.wilson_ci`, `.median_boot`)
- `read_single_xpt.r` also contains SAS XPORT v8/v9 format constants (`.XPT_LIBV8_HDR`, etc.)
- `n_pct.r` uses S3 dispatch; `ks_n_pct` is the generic
- Tests live in `tests/testthat/` covering: `ks_current_filename`, `ks_get_numdec`, `ks_simulate_ar1`, `ks_summary`
