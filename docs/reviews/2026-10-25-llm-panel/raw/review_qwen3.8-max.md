<!-- model=qwen3.8-max attempt=1 thinking=True elapsed=854s usage={"prompt_tokens": 42366, "total_tokens": 78985, "completion_tokens": 36619, "prompt_tokens_details": {"cached_tokens": 0, "text_tokens": 42366}, "completion_tokens_details": {"reasoning_tokens": 32936, "text_tokens": 36619}} -->
## Findings

[SEV: Critical] [ID: K001] `impute_dtc()` discards ISO-8601 zone offsets and treats the wall-clock time as the target timezone
- Location: R/impute_dtc.r:~26
```r
    ")?)?)?)?)?",
    "(?:Z|[+-]\\d{2}:?\\d{2})?$"
  )
```
- Failure scenario: `ks_impute_dtc("2020-01-01T10:00:00+02:00", tz = "UTC")` parses hour/minute but ignores the `+02:00` offset, returning `2020-01-01 10:00:00 UTC` instead of the correct instant `2020-01-01 08:00:00 UTC`. In clinical date arithmetic this silently shifts exposure/event times and can change imputed start/end derivations.
- Fix: Capture the offset and convert to the requested `tz` (preferably UTC), or fail loudly when a zone offset/`Z` is present and unsupported.

[SEV: Critical] [ID: K002] `impute_dtc()` accepts out-of-range date/time components and allows silent rollover
- Location: R/impute_dtc.r:~51
```r
  sc[is.na(sc)] <- 0L

  ## ---- Step 2: Success check -----------------------------------------------
  success <- !is.na(yr) & !is.na(mo) & !is.na(dy) &
    (!has_time | (!is.na(hr) & !is.na(mn)))
```
- Failure scenario: Inputs such as `"2020-13-01"`, `"2020-01-32"`, or `"2020-01-01T24:00"` match the parser, are marked successful, and `lubridate::make_datetime()` normalizes/rolls them forward (e.g., month 13 becomes next year). The function then returns a valid-looking POSIXct with an imputation flag that does not indicate invalid source data.
- Fix: Validate calendar/time ranges (month 1–12, day valid for month/year, hour 0–23, minute/second valid) and either abort or return `NA` with an explicit invalid-input condition.

[SEV: High] [ID: K003] `ks_eairdiff_mn()`/`ks_eairdiff_strata_mn()` search for score roots only on `[-1, 1]`
- Location: R/eair.r:~22
```r
    ci <- rootSolve::uniroot.all(score_eq, c(-1, 1),
                                  n1 = n1, n2 = n2, T1 = T1, T2 = T2)
    if (length(ci) < 2L) {
```
- Failure scenario: Incidence-rate differences are not constrained to `[-1, 1]`; with small person-time or high event rates, the true score CI bounds can lie outside this interval. The function then returns `NA` bounds or incomplete roots, making the interval unusable for legitimate data.
- Fix: Use an adaptive unbounded bracketing/search based on observed rates and standard error, or solve the constrained likelihood over the real line instead of a fixed `[-1,1]` window.

[SEV: High] [ID: K004] Stratified EAIR point estimate is unweighted while the score CI is weighted
- Location: R/eair.r:~88
```r
  c(delta = mean(n1 / T1 - n2 / T2, na.rm = TRUE),
    lcl   = ci[1L],
    ucl   = ci[2L])
```
- Failure scenario: The score equation combines strata using weights `W`, but the returned `delta` is a simple mean of stratum-specific rate differences. With unequal person-time across strata, the reported estimate is not aligned with the CI and can be materially wrong.
- Fix: Return the same weighted estimate used by the score construction (e.g., `sum(W * diff) / sum(W)`) or the MLE/root at the unpenalized score.

[SEV: High] [ID: K005] `ks_mianalyze()` can produce `NaN` CI/p-values in degenerate zero-variance / finite-`edf` cases
- Location: R/mianalyze.r:~78
```r
  if (is.finite(edf)) {
    v_obs <- (1 - gamma) * edf * (edf + 1) / (edf + 3)
    df <- if (is.infinite(df)) v_obs else 1 / (1 / df + 1 / v_obs)
  }
```
- Failure scenario: With `err` all zero but varying `est` (`Vw = 0`, `Vb > 0`) and finite `edf`, `gamma = 1`, so `v_obs = 0` and adjusted `df = 0`; `qt()` and `pt()` then yield `NaN`. Similarly, total variance zero with `theta0 != Q_bar` creates an infinite test statistic path that needs explicit handling.
- Fix: Guard `v_obs <= 0` / `df <= 0` and zero-total-variance cases: either fail loudly with a degenerate-input error or return well-defined limits (`p = 0` for infinite statistic, point CI) rather than `NaN`.

[SEV: Critical] [ID: K006] XPT writer leaves character `NA` slots unfilled, allowing previous-row/garbage bytes to be written
- Location: src/rcpp_xpt.cpp:~570
```cpp
            } else if (colTypes[i] == 2) {
                SEXP s = STRING_ELT(colSexps[i], r);
                if (s == NA_STRING) {
                    
                } else {
```
- Failure scenario: For a character column `c("A", NA, "B")`, the NA row writes nothing into the row buffer. If the buffer is reused, the second row can contain `"A"` or uninitialized bytes instead of blank/missing, causing silent NA corruption in SDTM deliverables. The same applies to factor `NA_INTEGER` paths.
- Fix: Explicitly fill the character slot with blanks (`0x20`) for `NA_STRING` and factor NA before `commitRow()`; ideally clear/initialize each row buffer deterministically.

[SEV: High] [ID: K007] XPT reader decode loops lack visible bounds checks against mapped-file size and row layout
- Location: src/rcpp_xpt.cpp:~170
```cpp
        const std::uint8_t *base = mf.data() + fileBaseOffset;
        for (std::size_t r = 0; r < nrow; ++r) {
            const char *cell = reinterpret_cast<const char *>(base + r * rowLen + off);
```
- Failure scenario: A malformed XPT with inconsistent `rowCount`, `rowLen`, `byteOffset`, or `storageWidth` can cause `base + r * rowLen + off` to read outside the mapped region. This can crash R or expose memory contents, and numeric decoding has the same exposure via `decodeNumericChunk()`.
- Fix: Before decoding, validate checked arithmetic: `fileBaseOffset + nrow * rowLen <= mf.size()` and each variable’s `byteOffset + storageWidth <= rowLen`; abort on violation.

[SEV: High] [ID: K008] XPT writer silently truncates strings longer than 32767 bytes
- Location: src/rcpp_xpt.cpp:~480
```cpp
                    SEXP s = STRING_ELT(col, r);
                    if (s != NA_STRING) {
                        std::size_t L = std::strlen(CHAR(s));
                        if (L > w) w = static_cast<std::uint16_t>(std::min<std::size_t>(L, 32767));
                    }
```
- Failure scenario: A character value longer than 32767 bytes is capped at 32767 for storage width, and the write loop later copies only `min(L, storageWidth)`. This silently truncates long comments/labels/`QVAL`-like content, which is unacceptable for CDISC outputs.
- Fix: Detect values exceeding the maximum allowed width for the selected XPT version and abort with a clear error instead of truncating.

[SEV: High] [ID: K009] `ks_auc()` returns 0 instead of `NA` for all-NA or single-observation groups
- Location: R/auc.r:~11
```r
  trapez <- function(v, t) {
    v_next <- c(v[-1L], NA_real_)
    t_next <- c(t[-1L], NA_real_)
    sum((v + v_next) * (t_next - t) / 2, na.rm = TRUE)
  }
```
- Failure scenario: If a group has one row, or all `val`/`time` values are `NA`, all trapezoid terms are `NA` and `sum(..., na.rm = TRUE)` returns `0`. AUC 0 is clinically meaningful and can be mistaken for a true result rather than insufficient data.
- Fix: Require at least two non-NA ordered points per group and return `NA_real_` (or abort) when not satisfied.

[SEV: Medium] [ID: K010] `ks_hosmer_lemeshow()` can error or produce undefined results with ties/zero expected counts
- Location: R/hosmer_lemeshow.r:~7
```r
  cutyhat <- cut(yhat, breaks = stats::quantile(yhat, probs = seq(0, 1, 1 / g)),
                 include.lowest = TRUE)
  obs    <- stats::xtabs(cbind(1 - y, y) ~ cutyhat)
  expect <- stats::xtabs(cbind(1 - yhat, yhat) ~ cutyhat)
```
- Failure scenario: With many tied `yhat` values, quantile breaks can be duplicated, causing `cut()` to fail. Even when cuts succeed, rows with zero expected counts can produce division by zero, and `df = sum(keep) - 2` can be non-positive, making the p-value undefined.
- Fix: Use unique breaks (or decile binning with tie handling), exclude/merge cells with zero expected counts, and guard `df >= 1` before computing p-values.

[SEV: High] [ID: K011] `ks_supp_merge()` can silently create list-columns or suffixed columns on QNAM collisions/duplicates
- Location: R/supp_merge.r:~49
```r
  supp_t <- supp |>
    dplyr::select(dplyr::all_of(svars)) |>
    tidyr::pivot_wider(names_from = "QNAM", values_from = "QVAL")
```
- Failure scenario: If SUPP contains duplicate rows for the same join keys and `QNAM`, `pivot_wider()` can create list-columns; if a `QNAM` collides with an existing primary-domain column, `left_join()` can rename columns with `.x`/`.y` suffixes. Both change the data contract silently and can corrupt downstream CDISC-derived analyses.
- Fix: Detect duplicate key/QNAM combinations and QNAM collisions with primary columns, then abort unless an explicit overwrite/rename policy is supplied.

[SEV: Medium] [ID: K012] `read.csv3()` label attachment uses `<<-` on a subset expression and may not reliably set column labels
- Location: R/get_data.r:~22
```r
  mapply(function(name, label) {
    attr(data[, name], "label") <<- label
  }, names(data), unlist(labels))
```
- Failure scenario: The superassignment target is a subset/attribute expression; depending on evaluation semantics it may fail to modify the local data frame or assign in an unintended environment. Downstream `ks_get_labels()` can then return `NA` labels despite metadata being present.
- Fix: Use an explicit loop: `for (nm in names(data)) attr(data[[nm]], "label") <- label`.

[SEV: Medium] [ID: K013] `ks_roc()` does not validate predictors as numeric; factor/character predictors can crash after response coercion
- Location: R/roc.r:~24
```r
  z <- as.matrix(data[, c(var, response), drop = FALSE])
  k <- length(var)

  mwcomp <- function(x, ind) {
```
- Failure scenario: If any predictor is factor/character, `as.matrix()` coerces the whole matrix to character, including the 0/1 response. Later `ind <- z[, k + 1L]` is character and `sum(inow)` fails. This is a hard crash rather than a validation error.
- Fix: Validate that all `var` columns are numeric (or coercible without loss) before matrix conversion.

[SEV: Medium] [ID: K014] `ks_batch_load()` can continue after worker read failures and save `try-error` objects as datasets
- Location: R/batch_load.r:~78
```r
    res <- parallel::mclapply(
      files,
      load_one,
      mc.silent = TRUE,
```
- Failure scenario: If one XPT/RDS/CSV file is corrupt, `mclapply()` can return a `try-error` element while other files load successfully. The function then saves/assigns that error object as if it were data, hiding a catastrophic read failure in automated pipelines.
- Fix: After `mclapply()`, check all elements for `inherits(x, "try-error")` and abort with the file name and condition message.

[SEV: Medium] [ID: K015] `ks_n_pct.numeric()` prints truncated counts but computes percentages from untruncated values
- Location: R/n_pct.r:~10
```r
  out         <- sprintf("%d (%5.1f%%)", as.integer(n), n * 100 / totals)
  rep_val     <- if (is.na(na.rep)) NA_character_ else na.rep
  out[is.na(n) | bad_tot] <- rep_val
```
- Failure scenario: `ks_n_pct(1.9, 10)` prints `"1 (19.0%)"`, where the displayed count and percentage are inconsistent. In clinical tables this can create misleading n (%) cells if non-integer counts are accidentally supplied.
- Fix: Validate that `n` is integer-valued, or use the same rounded/truncated count in both the printed count and percentage calculation.

## Confirmed-correct (do not fix)

- Core `ks_mianalyze()` pooling quantities for non-degenerate inputs: `Q_bar`, `Vw`, `Vb`, `Vt`, Rubin old-df, `r`, and lambda paths are consistent with the usual Rubin rules when variances are positive and `df` is finite/Inf as appropriate.
- `ks_newcombe_hs()` and `ks_newcombe_hs_strata()` use the standard Wilson score intervals and Newcombe hybrid difference construction for valid positive denominators.
- `ks_median_ci()` Olive and z order-statistic methods are internally consistent for non-empty numeric input.
- SAS epoch offsets in `src/xpt_epoch.hpp` (`3653` days and `315619200` seconds) are correct for SAS date/datetime conversion to R.
- `ks_swap_cols()` and `ks_vswitch()` input handling and degenerate-path behavior are acceptable for the stated scope.
- `inst/mcp_server.R` does not perform file reads or path-based operations; within the current text-response design, NA/NaN/Inf are emitted as printed text inside a JSON string rather than as invalid bare JSON numbers.

## Baseline

The package is broadly functional on happy paths, but several regulatory-relevant edge cases fail silently or crash: partial-date timezone/invalid-component handling, degenerate MI variance cases, EAIR root bounds/weighting, AUC insufficient-data behavior, SUPP merge name collisions, and XPT writer/reader robustness. The most urgent fixes are K001/K002/K006 because they can silently corrupt dates or missing-value representation in CDISC outputs.