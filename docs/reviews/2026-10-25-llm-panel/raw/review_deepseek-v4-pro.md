<!-- model=deepseek-v4-pro attempt=1 thinking=True elapsed=271s usage={"prompt_tokens": 41874, "total_tokens": 57469, "completion_tokens": 15595, "prompt_tokens_details": {"cached_tokens": 0}, "completion_tokens_details": {"reasoning_tokens": 12515}} -->
## Findings

[SEV: Critical] [ID: K001] mianalyze crashes with df=0 when Vw=0 and finite edf (v_obs=0)
- Location: R/mianalyze.r: lines 45–53 in the Barnard-Rubin adjustment block.
  ```r
  # Barnard-Rubin (1999) small-sample adjustment (SAS EDF= option)
  if (is.finite(edf)) {
    v_obs <- (1 - gamma) * edf * (edf + 1) / (edf + 3)
    df <- if (is.infinite(df)) v_obs else 1 / (1 / df + 1 / v_obs)
  }
  ```
- Failure scenario: With m≥2, all err equal to zero (Vw=0) and est varying (Vb>0), gamma=(1+1/m)*Vb/Vt=1, so v_obs=0. The subsequent expression `1 / (1/df + 1/v_obs)` becomes `1/(Inf)` → 0. Later `qt(1‑alpha/2, df=0)` throws an error and halts the computation.
- Fix: Guard `v_obs <= 0`; if true, skip the adjustment and keep the unadjusted Rubin df.

[SEV: Critical] [ID: K002] XPT writer leaks data across rows for missing string/factor values
- Location: src/rcpp_xpt.cpp: lines in the row‑writing loop for string (`colTypes[i]==2`) and factor (`colTypes[i]==3`) columns.
  ```cpp
  } else if (colTypes[i] == 2) {
      SEXP s = STRING_ELT(colSexps[i], r);
      if (s == NA_STRING) {
          // nothing – slot left unchanged
      } else {
          const char *cstr = CHAR(s);
          ...
      }
  }
  ```
- Failure scenario: When a string/factor column has NA, the corresponding bytes in the XPT row buffer are not initialised; a previous row’s content is written instead. This produces an XPT file whose non‑missing values leak from earlier observations, a catastrophic corruption for CDISC deliverables.
- Fix: For NA entries, fill the slot with spaces (0x20) using `std::memset(slot, 0x20, var.storageWidth)`.

[SEV: High] [ID: K003] Hosmer‑Lemeshow divides by zero when an expected cell count is exactly zero
- Location: R/hosmer_lemeshow.r: line computing the chi‑square statistic.
  ```r
  chisq  <- sum((obs[keep, ] - expect[keep, ])^2 / expect[keep, ])
  ```
- Failure scenario: If some bin has a predicted probability exactly 0 or 1, `expect` can contain a zero. The division yields `Inf` or `NaN`, and the returned `p.value` becomes meaningless, hiding potential model fit issues.
- Fix: Before division, replace zero expectations by a very small positive value (e.g., `.Machine$double.eps`) or skip those bins.

[SEV: High] [ID: K004] ROC contrast test degrades to NaNs when variance‑covariance matrix is the zero matrix
- Location: R/roc.r: lines that compute `lv_ginv` and the overall chi‑square.
  ```r
  lv <- l_mat %*% v_mat %*% t(l_mat)
  lv_ginv <- MASS::ginv(lv)
  chisq <- as.numeric(t(lt) %*% lv_ginv %*% lt)
  df <- as.numeric(sum(diag(lv_ginv %*% lv)))
  ```
- Failure scenario: If `v_mat` is exactly the zero matrix (all predictors perfectly correlated and no variance), `lv` is zero, `ginv` returns a zero matrix, leading to `chisq=0`, `df=0`, and `p = 1 - pchisq(0,0) = NaN`. This could happen with extremely small sample sizes or perfectly tied scores.
- Fix: Check whether `max(abs(lv))` is near zero; if so, return an informative message and set test statistic to `NA`.

[SEV: Medium] [ID: K005] ks_xpt_content may miss MEMBV8 headers that span a chunk boundary
- Location: R/read_single_xpt.r: the while‑loop that scans for `MEMBV8` markers in fixed‑size chunks.
  ```r
  while (pos < file_size) {
    seek(con, pos)
    data   <- readBin(con, "raw", chunk_size)
    …
    hits <- grepRaw(.XPT_MEMBV8_HDR, data, fixed = TRUE, all = TRUE)
    …
    pos <- pos + n_read   # no overlap with previous chunk
  }
  ```
- Failure scenario: If the 80‑byte `MEMBV8` header happens to straddle a 80*5*1024‑byte chunk boundary, `grepRaw` will never see the complete marker, and that dataset member is silently omitted from the content list, leading to an incomplete multi‑member XPT load.
- Fix: Reread the boundary region with a sliding window, or load the whole file into memory for the scan (the files are typically small enough).

[SEV: Medium] [ID: K006] ks_get_data with type="auto" forces all domains to use the first domain’s file type
- Location: R/get_data.r: the `effective_type` determination and subsequent loop.
  ```r
  effective_type <- if (type == "auto") first_res$ext else type
  …
  if (length(nm_vec) > 1L) {
    for (i in seq.int(2L, length(nm_vec))) {
      res <- .ks_resolve_domain_file(nm_vec[i], one_ext, path, strategy)
      out[[i]] <- finalise(read_fn(res$path))
    }
  }
  ```
- Failure scenario: When a user calls `ks_get_data(ae, vs)` and `ae` is an `.xpt` file while `vs` is an `.rds` file, the first match sets `effective_type = "xpt"`. The subsequent lookup for `vs` expects `vs.xpt`, fails to find it, and aborts with an error, even though `vs.rds` exists and would be a valid target for per‑domain auto‑detection.
- Fix: Either resolve each domain independently when `type = "auto"`, or document that mixed formats are unsupported and abort explicitly if the selected extension does not exist for later domains.

[SEV: Medium] [ID: K007] XPT reader relies on schema parser for bounds safety; no redundant guard in column builder
- Location: src/rcpp_xpt.cpp: `buildColumns` accesses `base + r * rowLen + off` without explicit bounds checks.
  ```cpp
  const std::uint8_t *base = mf.data() + fileBaseOffset;
  …
  const char *cell = reinterpret_cast<const char *>(base + r * rowLen + off);
  ```
- Failure scenario: If the `cxpt::parseSchema` stage does not validate that `rowLen * rowCount + max(byteOffset+storageWidth)` stays within the mapped region, a malformed XPT file could cause an out‑of‑bounds memory access (read or write) and crash the R session.
- Fix: Add a pre‑computation of the required data size at the start of `buildColumns` and raise an R error if `fileBaseOffset + rowLen * nrow > mf.size()`.

[SEV: Medium] [ID: K008] ks_eairdiff_mn (Miettinen‑Nurminen) search interval may not contain the CI roots
- Location: R/eair.r: the `uniroot.all` call inside `ci_one`.
  ```r
  ci <- rootSolve::uniroot.all(score_eq, c(-1, 1),
                                n1 = n1, n2 = n2, T1 = T1, T2 = T2)
  ```
- Failure scenario: For extreme incidence rates or very small exposure times, the true confidence limits can lie outside [-1, 1]. The function then finds fewer than two roots, sets the CI bounds to `NA`, and issues a warning, but it does not attempt a wider search interval.
- Fix: Dynamically expand the search interval (e.g., `c(-1e3, 1e3)` or progressively widen until two roots are found) and revert to `NA` only if roots remain elusive.

[SEV: Low] [ID: K009] ks_auc log‑trapezoidal fallback is hard‑coded to linear when dv=0, ignoring zero‑value handling
- Location: R/auc.r: the linear‑fallback condition.
  ```r
  use_linear <- !is.finite(dlv) | abs(dlv) < .Machine$double.eps^0.5
  auc_i <- ifelse(use_linear, (v + v_next) * dt / 2, dv * dt / dlv)
  ```
- Failure scenario: If a subject has a zero concentration followed by a positive one, `dlv` becomes `-Inf` and the code correctly falls back to the linear trapezoidal rule. However, the resulting AUC segment `(0 + v_next)*dt/2` overestimates the area under a log‑linear decline between a zero and a positive value (the true AUC is infinite/infeasible). While this is a modelling choice, it silently introduces a bias in PK AUC calculations.
- Fix: Detect zero‑to‑positive transitions and either extrapolate using a model‑based approach or warn the user that the log‑trapezoidal method is inapplicable.

[SEV: Low] [ID: K010] impute_dtc discards time‑zone offset information
- Location: R/impute_dtc.r: the regex that parses the DTC string.
  ```r
  "(?:Z|[+-]\\d{2}:?\\d{2})?$"
  ```
- Failure scenario: DTC strings containing an explicit UTC offset (e.g., `2021-01-01T12:00+05:00`) are matched, but the offset is neither captured nor applied. The resulting `POSIXct` always uses the `tz` parameter (default `"UTC"`), effectively shifting the true instant. This can break chronological comparisons.
- Fix: Capture the offset, convert it to a valid time‑zone name or numeric shift, and use `force_tz` or `with_tz` to produce the correct UTC‑adjusted time.

[SEV: Low] [ID: K011] ks_n_pct produces misaligned output for very large percentages
- Location: R/n_pct.r: the `sprintf` format string.
  ```r
  out <- sprintf("%d (%5.1f%%)", as.integer(n), n * 100 / totals)
  ```
- Failure scenario: When `n * 100 / totals` exceeds 999.9 (e.g., a 10,000% result), the width‑5 format is overrun, causing the parenthesis and percent sign to shift, breaking downstream table formatting (though not the numeric value).
- Fix: Use a right‑justified dynamic width or replace with `formatC` to ensure the string always has a fixed total length.

[SEV: Low] [ID: K012] ks_median_ci with method="z" uses integer floor/ceiling, risking off-by-one on ties
- Location: R/median_ci.r: the index calculation in `.median_z`.
  ```r
  hw <- zc * sqrt(n) / 2
  i_lo <- max(1L, as.integer(ceiling(n / 2 - hw)))
  i_hi <- min(n, as.integer(floor(n / 2 + hw)))
  ```
- Failure scenario: For small sample sizes or non‑integer `hw`, the combination of `ceiling` and `floor` can select indices that do not bracket the median rank symmetrically, potentially producing a wider interval than intended.
- Fix: Use `round` or a symmetric adjustment to ensure `i_lo` and `i_hi` are equidistant from the median rank.

## Confirmed-correct (do not fix)

- `mianalyze()` alias wrapper over `ks_mianalyze()` – intentional SAS‑style naming.
- `v0` backward compatibility – intentional.
- `knit_print.ks_mianalyze` heading style fixed per commit 58dd353.
- All `RcppExports.R` and `RcppExports.cpp` glue code (generated, matches the interface).
- `callTointerfaces` in C++ (properly handles V5 vs V8 XPT).
- `ks_dunnett_crit` one‑sided / two‑sided logic matches mnormt conventions.
- `ks_boot_ci` fallback from BCa to percentile – correct and warned.
- `ks_simulate_ar1` AR(1) simulation variance scaling – correct.
- `ks_desc_coded` curly‑curly semantics – correct.
- `ks_supp_merge` IDVARVAL coercion and join – designed for SDTM where IDVAR columns are typically character or numeric, not factor; join uses value equality.
- `mcp_server.R` JSON‑RPC responses: all tool outputs are text strings (captured `print` output), so `NaN`/`Inf` never enter the JSON payload as bare numbers; no round‑trip corruption.
- `read.csv3` comment‑header parsing – correctly builds `colClasses`.

## Baseline

- All test pins (not shown) are assumed to cross‑validate critical statistical outputs.
- Package infrastructure (DESCRIPTION, NAMESPACE, Rbuildignore hygiene) out of scope.
- Style, roxygen wording, formatting, test coverage not evaluated.