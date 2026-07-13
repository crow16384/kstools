## ============================================================
## run_all_examples.R — source all example scripts in logical order
## ============================================================

run_all_examples <- function(continue_on_error = TRUE, verbose = TRUE) {
  ## Resolve examples directory whether run via source() or from project root
  this_file <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NA_character_)
  ex_dir <- if (!is.na(this_file)) dirname(this_file) else file.path(getwd(), "inst", "examples")
  ex_dir <- normalizePath(ex_dir, winslash = "/", mustWork = FALSE)

  if (!dir.exists(ex_dir)) {
    stop("Examples directory not found: ", ex_dir)
  }

  files <- c(
    ## Core descriptive/statistical utilities
    "ks_summary.R",
    "ks_n_pct.R",
    "ks_geom_mean.R",
    "ks_median_ci.R",
    "ks_cv.R",
    "ks_z_score.R",
    "ks_p_norm.R",
    "ks_q1.R",
    "ks_q3.R",
    "ks_auc.R",
    "ks_simulate_ar1.R",
    "ks_mianalyze.R",
    "mianalyze.R",
    "ks_roc.R",
    "ks_eairdiff.R",
    "ks_eairdiff_mn.R",
    "ks_eairdiff_strata_mn.R",
    "ks_newcombe_hs.R",
    "ks_newcombe_hs_strata.R",

    ## Data loading and file I/O
    "read.csv3.R",
    "ks_get_data.R",
    "ks_batch_load.R",
    "ks_batch_load_xlsx.R",
    "ks_xpt_content.R",
    "ks_read_single_xpt.R",
    "ks_batch_load_from_single_xpt.R",

    ## SDTM/clinical helpers
    "ks_dtc2dtn.R",
    "ks_supp_consistency_check.R",
    "ks_supp_merge.R",
    "ks_desc_coded.R",
    "ks_get_labels.R",
    "ks_get_numdec.R",

    ## General utilities
    "ks_sum_na.R",
    "ks_swap_cols.R",
    "ks_aligndec.R",
    "ks_swoe.R",
    "ks_code_to_fmt.R",
    "ks_current_filename.R",
    "ks_del_tmp.R",
    "ks_williams.R"
  )

  existing <- list.files(ex_dir, pattern = "[.]R$", full.names = FALSE)
  missing <- setdiff(files, existing)
  if (length(missing) > 0L) {
    warning("The following scripts were not found and will be skipped: ",
            paste(missing, collapse = ", "))
  }

  run_files <- files[files %in% existing]

  if (verbose) {
    cat("Sourcing", length(run_files), "example scripts from", ex_dir, "\n")
  }

  results <- data.frame(
    file = run_files,
    ok = NA,
    message = NA_character_,
    stringsAsFactors = FALSE
  )

  for (i in seq_along(run_files)) {
    f <- run_files[i]
    path <- file.path(ex_dir, f)

    if (verbose) {
      cat(sprintf("[%02d/%02d] %s ... ", i, length(run_files), f))
    }

    res <- tryCatch({
      source(path, local = .GlobalEnv)
      list(ok = TRUE, message = "OK")
    }, error = function(e) {
      list(ok = FALSE, message = conditionMessage(e))
    })

    results$ok[i] <- res$ok
    results$message[i] <- res$message

    if (verbose) {
      cat(if (res$ok) "OK\n" else "FAILED\n")
    }

    if (!res$ok && !continue_on_error) {
      stop("Stopped on first error in ", f, ": ", res$message)
    }
  }

  n_ok <- sum(results$ok)
  n_fail <- sum(!results$ok)

  if (verbose) {
    cat("\nSummary:\n")
    cat("  Passed:", n_ok, "\n")
    cat("  Failed:", n_fail, "\n")
    if (n_fail > 0L) {
      cat("\nFailures:\n")
      print(results[!results$ok, c("file", "message"), drop = FALSE], row.names = FALSE)
    }
  }

  invisible(results)
}


## If executed directly via source(), run in continue-on-error mode.
run_all_examples(continue_on_error = TRUE, verbose = TRUE)
