---
tags: [review, llm-panel]
date: 2026-10-25
package: kstools 0.5.9
---

# LLM panel review — kstools (2026-10-25)

Panel: `qwen3.8-max` + `deepseek-v4-pro` (token-plan subscription, temperature 0.1).
Two bundles, identical for both models:
- **Panel 1 (R layer + glue + mcp):** `bundle.txt` ~129 KB (roxygen stripped), 47 files → qwen thinking=True 854 s (attempt 1), deepseek thinking=True 271 s.
- **Panel 2 (XPT backend `src/xpt/`, `src/core/`):** 73 KB → deepseek thinking=True 296 s; qwen thinking=True TIMED OUT at 1200 s read budget → **qwen collected as thinking=False, 85 s** (asymmetry recorded in raw headers).

Raw model outputs in `raw/`. Every finding below was verified against the literal source
and/or reproduced empirically before being accepted; model severities were re-rated on one scale.

## CONFIRMED findings (deduplicated, own severity)

| ID | Sev | Finding | Raised by | Evidence (verification) |
|----|-----|---------|-----------|-------------------------|
| A1 | High | `ks_mianalyze(est, err=0…, edf=finite)`: `gamma=1 → v_obs=0 → df=0 → qt()` emits **NaN** CI/p silently (only warning). Trigger matrix: all-zero err + varying est + finite edf; all other degenerate paths sound. | **both** (ds K001 / qwen K005) | R probe: `mianalyze(c(0.3,0.5), c(0,0), edf=50)` → `created NaN`. Guard fix: `v_obs <= 0` → abort or keep Rubin df. |
| A2 | Critical | Writer maps **±Inf → 0.0 silently** (`encodeIbmXport` returns zero-init buffer for Inf; Rcpp glue's NA test catches NA/NaN but not Inf). Regulatory data corruption: file contains 0, both internal reader and haven read 0 back. NaN is safe (→ `.`). | **both** (ds X002 / qwen X003) + empirical | Round-trip `data.frame(x=c(1,Inf,-Inf,2))` → `1 0 0 2` via `ks_read_xpt` AND `haven::read_xpt`. |
| A3 | High | `ks_impute_dtc()` accepts out-of-range components and **silently rolls over**: `2020-13-01`→`2021-01-01`, `2020-02-30`→`2020-03-01`, `T25:70:00`→next day `02:10`. Docs promise NA for non-matching input; rollover is a third, undocumented behavior. | **qwen unique** (K002) | Empirical: `format(ks_impute_dtc(c("2020-13-01","2020-01-32","2020-01-01T25:70:00","2020-02-30"))$dt)` shows all rolled over. Fix: range-validate captured fields → NA. |
| A4 | High | Writer does not enforce **XPT v5 interop limits** (default `version=5L`, "widest compatibility"): character values/width > 200 bytes and column names > 8 bytes are written silently → SAS XPORT engine REFUSES such files (SAS Tech Note 1528; xportr validates `≤200`); two 17-char names sharing first 8 bytes produce a file with **duplicate variable names**. Dataset label/name truncation warns; column name/label truncation does not. | ds X003 + qwen K008/X004 (adjacent) + my probe | Empirical: `longvariablename` → readback `longvari` (both readers); `abcdefgh_1/abcdefgh_2` → haven repair-names `abcdefgh...1/...2`. 500-char string written in v5 without warning. TN 1528 + xportr `xpt_validate` confirm the 200-byte rule. |
| A5 | Medium | `ks_auc()` returns **0** (not NA) for all-NA groups and single-point subjects (`sum(na.rm=TRUE)` of empty set). 0 is a meaningful AUC — indistinguishable from "no data". | **qwen unique** (K009) | Empirical: group with all-NA conc → AUC 0; one-row group → 0. Fix: require ≥2 non-NA points → NA_real_. |
| A6 | Medium | `ks_batch_load()` keeps `try-error` objects as "data" after a corrupt member fails in `mclapply` (one mclapply warning, then the list contains class `try-error`, and `save.path`/`keep` persist it silently downstream). | **qwen unique** (K014) | Empirical: dir with `good.rds` + garbage `broken.rds` → result: `broken → try-error`. Fix: post-check `inherits("try-error")` → abort listing files. |
| A7 | Medium-Low | `ks_roc()` with character/factor predictor: hard crash with cryptic C-level error instead of validation message (`as.matrix()` coerces everything). | **qwen unique** (K013) | Empirical: `wrong 'type' (character)` abort. Fix: validate numeric predictors. |
| A8 | Medium-Low | Reader accepts `storageWidth != 8` for numeric (ntype=1) columns: decode stride = declared width → malformed/hostile files yield shifted garbage, no error (fail-loud rule: should reject). | ds X001 (mechanism overstated as "always 0"; essence confirmed) | Source: `decodeNumericChunk` uses `width = var.storageWidth` (rcpp_xpt.cpp:80,180); parseSchema validates ntype ∈{1,2} (line 424) but never width. |
| A9 | Low | Write failure mid-stream leaves a **partial .xpt on disk** (destructor's `finish()` wrapped in `catch(...)`, nothing unlinks the file). | qwen X012 | Source + behavior; user gets the R error but downstream tools may ingest the corpse file. |
| A10 | Low | Duplicate variable names in input files not warned (qwen X011); multi-thread decode reports only the FIRST error, others dropped (ds X007); `ks_n_pct(1.9,10)` prints `"1 ( 19.0%)"` — count truncated, pct not (qwen K015); SUPP duplicate QNAM → list-cols guarded only by a tidyr warning (qwen K011); embedded NUL in strings silently truncates via `strlen` (ds X008, theoretical). | mixed | each verified in source/probe. |

## REJECTED (with cause) — do NOT "fix" these

| Claim | Raised by | Why rejected |
|-------|-----------|--------------|
| Writer leaves NA string/factor slots unfilled (prev-row leak) | **both**, panel 1 | `XptWriter::commitRow()` memsets whole row buffer to 0x20 after every row (src/xpt/writer.cpp:284, comment explicit). Neither file was in panel-1 bundle — both models extrapolated a missing dependency. |
| Reader OOB: `base + r*rowLen + off` unbounded vs hostile headers | **both**, panels 1+2 (qwen re-issued as X001/X002) | `rowCount = totalBytes/rowLen` from ACTUAL bytes; `byteOffset` is computed cumulative sum (`v.byteOffset = rowLen; rowLen += v.storageWidth`) so `off+width ≤ rowLen` holds by construction; `dataEnd` re-clamped; NAMESTR cursor checks EOF (`readBlock` → parse error). No hostile path. |
| `eairdiff` fixed `[-1,1]` root window | **both** | roxygen documents the window and "expand manually"; NA-bounds path warns. Documented contract → owner-level enhancement only. |
| Strata delta unweighted vs weighted CI inconsistency | **both** | documented: "The point estimate delta is the unweighted arithmetic mean…" |
| Hosmer div-by-zero / non-positive df | **both** | all-zero-expected bin requires ≥1/g ties → `cut()` aborts with 'breaks are not unique' first; quantile bins ⇒ non-empty bins ≥ g-… ⇒ df ≥ 1 (probe). |
| ROC contrast → NaN p | ds | identical constant predictors → clean NA (probe); guard exists. |
| `read.csv3` attr `<<-` doesn't attach labels | qwen | probe: labels present after read (`ks_get_labels` shows them); super-assignment through replacement-function LHS is legal. |
| impute_dtc ignores ISO offsets = bug | qwen | documented: "offsets are accepted but ignored" (SDTM wall-clock convention). |
| 200-variables-per-file v5 limit not enforced (must abort) | ds X004 | not a format constraint (nvar field is 16-bit; haven itself writes 250 cols in v5). Owner decision re SAS submission practice — OPEN, not a defect per se. |
| `rowLen` size_t overflow, blank-row subtraction underflow, PROTECT gap, INT_MAX rownames | qwen panel 2 | all impossible-by-construction (file size bounds 64-bit sums; `countTrailingBlankRows ≤ fullRows`; `cols[i]=s` stores into already-protected Rcpp List with no R allocation between PROTECT/UNPROTECT; R vectors cap long before). Speculative-hardening only. |
| `median_ci` method="z" off-by-one | ds | "rounded inward" is the documented design. |
| `n_pct %5.1f` overflow width | ds | pct ≤ 100 by construction — scenario unreachable. |
| Log-trapezoid linear fallback = bias | ds | documented rule; standard linear/log mixed trapezoid. |

## Model performance report

| | qwen3.8-max | deepseek-v4-pro |
|---|---|---|
| Runs | P1 854 s thinking; P2 TIMEOUT@1200 s → collected thinking-off 85 s | 271 s + 296 s, both thinking |
| Findings | 15 + 12 | 12 + 8 |
| Confirmed (incl. shared) | 8 of 15 (P1 ≈53% precision) | 4 of 12 + 4 of 8 |
| Unique confirmed | A3 (DTC rollover), A5 (AUC 0), A6 (batch_load), A7 (roc validation) | A8 (width≠8), v5 200-byte rule (A4) |
| Style | breadth + documentation-aware framing; P2 thinking-off got shallower and added 4 speculative-hardening FPs | numeric/C-edge instinct, ~50–65% FP in R layer, drifted severities; strong on XPT layer |
| Format adherence | perfect (quotes grep-able, coords within ±5 lines) | perfect |

Key panel lesson (matches prior rounds): both models produced the SAME two false positives aimed at code that was **not in the bundle** (vendored `src/xpt/` writer/parser) — bundling must include the actual implementation, or the split must follow architectural layers. Prompt caching: same-bundle retries were cheap; thinking-off fallback saved the flagship.

## Proposed fix order (owner scope pick required before any edits)

1. **A2** writer ±Inf → abort (recommended; SAS has no Inf) — one-line guard in rcpp glue.
2. **A4** v5 writer validation bundle: name≤8 + label≤40 + char width≤200 (v5) / ≤32767 + reject duplicate truncated names; warn-vs-abort decision gate for 200-byte.
3. **A1** `mianalyze`: guard `v_obs<=0` (abort or keep Rubin df — SAS parity decision).
4. **A3** `impute_dtc`: range checks → NA.
5. **A5** `ks_auc`: NA for <2 points. **A6** `ks_batch_load`: try-error sweep → abort.
6. **A7** roc predictor validation; **A8** reader width≠8 reject.
7. A9–A10 hygiene batch.
