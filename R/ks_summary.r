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
#'   \code{p.change}, and \code{extras} in the call, which are keyword-only
#'   arguments (they must always be named).
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
#'   \code{max}, \code{p.chg}) will raise an error.
#'
#' @return A tibble with one row per group and columns \code{n},
#'   \code{mean}, \code{sd}, \code{median}, \code{q1},
#'   \code{q3}, \code{min}, \code{max}, any \code{extras} columns,
#'   \code{cv}, and (if \code{p.change = TRUE}) \code{p.chg}.
#' @seealso \code{\link{ks_q1}}, \code{\link{ks_q3}}
#' @examples
#' d <- data.frame(
#'   grp = rep(c("A", "B"), each = 10),
#'   val = c(rnorm(10, 5), rnorm(10, 8))
#' )
#' ks_summary(d, val, grp)
#'
#' ## With extra statistics
#' ks_summary(d, val, grp,
#'   extras = list(
#'     mad = stats::mad,
#'     sem = function(x, na.rm) sd(x, na.rm = na.rm) / sqrt(sum(!is.na(x)))
#'   )
#' )
#' @name ks_summary
#' @importFrom dplyr group_by summarise mutate left_join select ungroup
#' @importFrom rlang enquo as_name expr
#' @importFrom stats sd median shapiro.test t.test wilcox.test
#' @importFrom rlang .data
#' @importFrom utils globalVariables
#' @export
ks_summary <- function(data, var, ..., na.rm = TRUE, p.change = FALSE,
                       extras = NULL) {

  .na.rm <- na.rm

  .builtin_cols <- c("n", "mean", "sd", "cv", "median", "q1", "q3",
                     "min", "max", "p.chg")

  extra_exprs <- list()
  if (!is.null(extras)) {
    if (!is.list(extras) || length(extras) == 0L)
      stop("'extras' must be a non-empty named list of functions")
    if (is.null(names(extras)) || any(names(extras) == ""))
      stop("every element of 'extras' must be named")
    if (anyDuplicated(names(extras)) > 0L)
      stop("duplicate names in 'extras': ",
           paste(names(extras)[duplicated(names(extras))], collapse = ", "))
    clash <- intersect(names(extras), .builtin_cols)
    if (length(clash) > 0L)
      stop("'extras' name(s) clash with built-in columns: ",
           paste(clash, collapse = ", "))
    if (!all(vapply(extras, is.function, logical(1L))))
      stop("every element of 'extras' must be a function")

    var_nm <- rlang::as_name(rlang::enquo(var))
    extra_exprs <- lapply(extras, function(fn) {
      rlang::expr((!!fn)(.data[[!!var_nm]], na.rm = !!.na.rm))
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
