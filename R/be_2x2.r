#' Bioequivalence: 2x2 crossover analysis
#'
#' Fits the standard two-period, two-sequence crossover model
#' `response ~ sequence + treatment + period` (subject nested in sequence
#' in the random term, `random = ~ seq | subject`) and returns the
#' test-minus-reference treatment difference with its confidence interval.
#' The sequence main effect absorbs carryover. This is the R twin of the
#' SAS `PROC MIXED` bioequivalence analysis in the R tricks article
#' (verified: estimate 0.0145, SE 0.0142, df 7, matching SAS `CL=DF=7`).
#'
#' @param data Data frame with one row per subject-period.
#' @param response Unquoted name of the numeric response column.
#' @param trt Unquoted name of the treatment column (factor with exactly
#'   the two levels named in `test` and `reference`).
#' @param test,reference Character labels of the test and reference
#'   treatment levels (e.g. `"T"`, `"R"`).
#' @param seq,period,subject Unquoted names of sequence, period, and
#'   subject columns.
#' @param log Apply `log()` to the response before fitting (default
#'   `TRUE`, standard for BE on concentration data). Requires all
#'   responses positive.
#' @param conf.level Confidence level; BE conventionally uses `0.90`.
#' @return A list with `estimate`, `se`, `df`, `t`, `p.value`, `lcl`,
#'   `ucl` (log scale when `log = TRUE`), plus `ratio`, `ratio.lcl`,
#'   `ratio.ucl` on the original scale when `log = TRUE`.
#' @examplesIf requireNamespace("nlme", quietly = TRUE)
#' cross <- data.frame(
#'   per = as.factor(rep(c(1, 2), 9)),
#'   trt = as.factor(c(rep(c("T", "R"), 4), rep(c("R", "T"), 5))),
#'   seq = as.factor(c(rep(1, 8), rep(2, 10))),
#'   cow = as.factor(rep(1:9, each = 2)),
#'   my  = c(29.9, 27.8, 54.0, 49.7, 41.6, 38.4, 28.5, 26.5, 22.2,
#'           21.4, 55.5, 49.1, 43.5, 41.3, 33.2, 34.3, 18.2, 17.1))
#' fit <- ks_be_2x2(cross, response = my, trt = trt, test = "T",
#'                  reference = "R", seq = seq, period = per, subject = cow)
#' c(TvR_log = fit$estimate, ratio = fit$ratio,
#'   lcl = fit$ratio.lcl, ucl = fit$ratio.ucl)
#' @name ks_be_2x2
#' @importFrom rlang as_name enquo
#' @importFrom stats as.formula qt
#' @importFrom cli cli_abort
#' @export
ks_be_2x2 <- function(data, response, trt, test, reference,
                      seq, period, subject,
                      log = TRUE, conf.level = 0.90) {
  resp <- rlang::as_name(rlang::enquo(response))
  trtc <- rlang::as_name(rlang::enquo(trt))
  seqc <- rlang::as_name(rlang::enquo(seq))
  perc <- rlang::as_name(rlang::enquo(period))
  subc <- rlang::as_name(rlang::enquo(subject))

  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  cols <- c(resp, trtc, seqc, perc, subc)
  if (!all(cols %in% names(data)))
    cli::cli_abort("All analysis columns must exist in {.arg data}: {.val {setdiff(cols, names(data))}}.")
  if (!is.character(test) || length(test) != 1L ||
      !is.character(reference) || length(reference) != 1L)
    cli::cli_abort("{.arg test} and {.arg reference} must be single strings.")
  if (identical(test, reference))
    cli::cli_abort("{.arg test} and {.arg reference} must differ.")

  d <- data
  for (cc in c(trtc, seqc, perc, subc)) d[[cc]] <- factor(as.character(d[[cc]]))
  if (!is.numeric(d[[resp]])) cli::cli_abort("{.arg response} must be numeric.")
  if (!all(c(test, reference) %in% levels(d[[trtc]])))
    cli::cli_abort("{.arg test}/{.arg reference} must be levels of {.arg trt}.")

  # contr.SAS puts 1 on the FIRST level and estimates level1 - level2:
  # ordering (test, reference) makes the coefficient exactly T - R
  d[[trtc]] <- factor(as.character(d[[trtc]]), levels = c(test, reference))

  yname <- resp
  if (isTRUE(log)) {
    if (any(d[[resp]] <= 0, na.rm = TRUE))
      cli::cli_abort("Non-positive values in {.arg response} with {.arg log} = TRUE.")
    yname <- ".be_response."
    d[[yname]] <- log(d[[resp]])
  }

  m <- nlme::lme(stats::as.formula(paste(yname, "~", seqc, "+", trtc, "+", perc)),
                 random = stats::as.formula(paste("~", seqc, "|", subc)),
                 data = d,
                 contrasts = stats::setNames(rep(list("contr.SAS"), 3L), c(trtc, seqc, perc)))
  tt <- summary(m)$tTable
  coef_row <- paste0(trtc, test)
  if (!coef_row %in% rownames(tt))
    cli::cli_abort("Treatment coefficient {.val {coef_row}} not found; check the design.")

  est <- tt[coef_row, "Value"]; se <- tt[coef_row, "Std.Error"]; df <- tt[coef_row, "DF"]
  tq  <- stats::qt(1 - (1 - conf.level) / 2, df = df)
  out <- list(estimate = est, se = se, df = df,
              t = est / se, p.value = tt[coef_row, "p-value"],
              lcl = est - tq * se, ucl = est + tq * se,
              conf.level = conf.level)
  if (isTRUE(log)) {
    out$ratio     <- exp(est)
    out$ratio.lcl <- exp(out$lcl)
    out$ratio.ucl <- exp(out$ucl)
  }
  out
}
