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
#' @param ... Unquoted grouping variables. Must come before \code{na.rm},
#'   \code{p.change}, \code{extras}, and \code{numdec} in the call, which
#'   are keyword-only arguments (they must always be named).
#' @param na.rm Logical; remove \code{NA}s before computing. Default \code{TRUE}.
#' @param p.change Logical; if \code{TRUE}, append a \code{p.chg} column
#'   (p-value for paired change, chosen by normality). Default \code{FALSE}.
#' @param extras An optional \strong{named list} of functions for additional
#'   per-group statistics.  Each function is called as
#'   \code{f(x, na.rm = na.rm)} where \code{x} is the numeric vector of
#'   \code{var} for that group.  Each function must return a single scalar
#'   value.  The list names become column names in the result.
#'
#'   Example: \code{extras = list(mad = stats::mad, sem = function(x, na.rm)
#'   sd(x, na.rm = na.rm) / sqrt(sum(!is.na(x))))}
#'
#'   Names that clash with built-in columns (\code{n}, \code{mean},
#'   \code{sd}, \code{cv}, \code{median}, \code{q1}, \code{q3}, \code{min},
#'   \code{max}, \code{p.chg}, \code{NUMDEC}) will raise an error.
#' @param numdec Logical; if \code{TRUE} (the default), append a
#'   \code{NUMDEC} column giving the maximum number of decimal places
#'   observed in \code{var} within each group (via
#'   \code{\link{ks_get_numdec}} logic, capped at 4).  Set to \code{FALSE}
#'   to suppress.
#'
#' @return A tibble with one row per group and columns \code{n},
#'   \code{mean}, \code{sd}, \code{median}, \code{q1},
#'   \code{q3}, \code{min}, \code{max}, any \code{extras} columns,
#'   \code{cv}, (if \code{numdec = TRUE}) \code{NUMDEC}, and
#'   (if \code{p.change = TRUE}) \code{p.chg}.
#' @seealso \code{\link{ks_q1}}, \code{\link{ks_q3}},
#'   \code{\link{ks_get_numdec}}
#' @examples
#' d <- data.frame(
#'   grp = rep(c("A", "B"), each = 10),
#'   val = c(rnorm(10, 5), rnorm(10, 8))
#' )
#' ks_summary(d, val, grp)
#'
#' ## Without NUMDEC
#' ks_summary(d, val, grp, numdec = FALSE)
#'
#' ## With extra statistics
#' ks_summary(d, val, grp,
#'   extras = list(
#'     mad = stats::mad,
#'     sem = function(x, na.rm) sd(x, na.rm = na.rm) / sqrt(sum(!is.na(x)))
#'   )
#' )
#' @name ks_summary
#' @importFrom cli cli_abort
#' @importFrom dplyr group_by summarise mutate left_join select ungroup
#' @importFrom rlang enquo as_name expr ensyms
#' @importFrom stats sd median shapiro.test t.test wilcox.test
#' @importFrom rlang .data
#' @importFrom utils globalVariables
#' @export
ks_summary <- function(data, var, ..., na.rm = TRUE, p.change = FALSE,
                       extras = NULL, numdec = TRUE) {

  .na.rm  <- na.rm
  var_quo <- rlang::enquo(var)
  var_chr <- rlang::as_name(var_quo)

  .builtin_cols <- c("n", "mean", "sd", "cv", "median", "q1", "q3",
                     "min", "max", "p.chg", "NUMDEC")

  extra_exprs <- list()
  if (!is.null(extras)) {
    if (!is.list(extras) || length(extras) == 0L)
      cli::cli_abort("{.arg extras} must be a non-empty named list of functions.")
    if (is.null(names(extras)) || any(names(extras) == ""))
      cli::cli_abort("Every element of {.arg extras} must be named.")
    if (anyDuplicated(names(extras)) > 0L)
      cli::cli_abort("Duplicate names in {.arg extras}: {.val {names(extras)[duplicated(names(extras))]}}.")  
    clash <- intersect(names(extras), .builtin_cols)
    if (length(clash) > 0L)
      cli::cli_abort("{.arg extras} name{?s} clash with built-in column{?s}: {.val {clash}}.")
    if (!all(vapply(extras, is.function, logical(1L))))
      cli::cli_abort("Every element of {.arg extras} must be a function.")

    extra_exprs <- lapply(extras, function(fn) {
      rlang::expr((!!fn)(.data[[!!var_chr]], na.rm = !!.na.rm))
    })
  }

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
      !!!extra_exprs,
      .groups = "drop"
    ) |>
    dplyr::mutate(cv = sd * 100 / mean)

  if (numdec) {
    by_nms <- vapply(rlang::ensyms(...), as.character, character(1L))
    if (length(by_nms) > 0L) {
      ndec <- ks_get_numdec(data, var_chr, by_nms)
      ndec <- unique(ndec[, c(by_nms, "NUMDEC"), drop = FALSE])
      res  <- dplyr::left_join(res, ndec, by = by_nms)
    } else {
      vals <- data[[var_chr]]
      vals <- vals[!is.na(vals)]
      nd <- if (length(vals) == 0L) {
        NA_integer_
      } else {
        max(nchar(sub(
          "^[-]?\\d*\\.?", "",
          trimws(sub("0+$", "",
                     format(round(vals, digits = 4L), scientific = FALSE)))
        )))
      }
      res <- dplyr::mutate(res, NUMDEC = nd)
    }
  }

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
