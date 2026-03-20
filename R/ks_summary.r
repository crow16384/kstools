#' Descriptive summary for continuous variables
#'
#' Computes n, mean, SD, CV, median, Q1, Q3, min, max by group.
#' Optionally adds a p-value for change from zero (paired t-test or
#' Wilcoxon signed-rank, chosen by Shapiro-Wilk normality test).
#'
#' Q1 and Q3 use \code{\link{ks_q1}} / \code{\link{ks_q3}}, whose
#' \code{type} argument defaults to
#' \code{getOption("kstools.quantile.type", 2L)} (SAS-compatible).
#' Set that option in \file{.Rprofile} to change the algorithm globally.
#'
#' @param data A data frame or tibble.
#' @param var Unquoted name of the numeric variable to summarise.
#' @param na.rm Logical; remove \code{NA}s before computing. Default \code{TRUE}.
#' @param p.change Logical; if \code{TRUE}, append a \code{p.chg} column
#'   (p-value for paired change, chosen by normality). Default \code{FALSE}.
#' @param ... Unquoted grouping variables. Must come before \code{na.rm}
#'   and \code{p.change} in the call, which are keyword-only arguments
#'   (they must always be named: \code{na.rm = FALSE}, \code{p.change = TRUE}).
#' @return A tibble with one row per group and columns \code{n},
#'   \code{mean}, \code{sd}, \code{cv}, \code{median}, \code{q1},
#'   \code{q3}, \code{min}, \code{max}, and (if \code{p.change = TRUE})
#'   \code{p.chg}.
#' @seealso \code{\link{ks_q1}}, \code{\link{ks_q3}}
#' @name ks_summary
#' @importFrom dplyr group_by summarise mutate left_join select ungroup
#' @importFrom stats sd median shapiro.test t.test wilcox.test
#' @export
ks_summary <- function(data, var, ..., na.rm = TRUE, p.change = FALSE) {

  ## .na.rm shields `na.rm` from dplyr's data-masking lookup
  .na.rm <- na.rm

  res <- data |>
    dplyr::group_by(...) |>
    dplyr::summarise(
      n      = sum(!is.na({{ var }})),
      mean   = mean({{ var }}, na.rm = .na.rm),
      sd     = stats::sd({{ var }}, na.rm = .na.rm),
      median = stats::median({{ var }}, na.rm = .na.rm),
      q1     = ks_q1({{ var }}, na.rm = .na.rm),
      q3     = ks_q3({{ var }}, na.rm = .na.rm),
      min    = min({{ var }}, na.rm = .na.rm),
      max    = max({{ var }}, na.rm = .na.rm),
      .groups = "drop"
    ) |>
    dplyr::mutate(cv = sd * 100 / mean)

  if (!p.change) return(res)

  p_chg <- suppressWarnings(
    data |>
      dplyr::group_by(...) |>
      dplyr::summarise(
        p.norm  = tryCatch(stats::shapiro.test({{ var }})$p.value,
                           error = \(e) NA_real_),
        p.chg.t = stats::t.test({{ var }})$p.value,
        p.chg.w = stats::wilcox.test({{ var }})$p.value,
        .groups = "drop"
      ) |>
      dplyr::mutate(
        p.chg = ifelse(is.na(p.norm) | p.norm <= 0.05, p.chg.w, p.chg.t)
      ) |>
      dplyr::select(-p.norm, -p.chg.t, -p.chg.w)
  )

  by_cols <- sapply(rlang::ensyms(...), as.character)
  dplyr::left_join(res, p_chg, by = by_cols)
}
