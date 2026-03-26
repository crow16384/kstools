#' Area Under the Curve (AUC) by the trapezoidal rule
#'
#' Computes AUC from concentration–time data using the linear or
#' log-linear trapezoidal method.  Handles grouped data via a character
#' vector of grouping column names.
#'
#' @details
#' \strong{Linear trapezoid} (\code{type = "trapez"}):
#' \deqn{AUC_i = \frac{C_i + C_{i+1}}{2} \cdot (t_{i+1} - t_i)}
#'
#' \strong{Log-linear trapezoid} (\code{type = "log-trapez"}):
#' \deqn{AUC_i = \frac{C_{i+1} - C_i}{\ln C_{i+1} - \ln C_i} \cdot (t_{i+1} - t_i)}
#'
#' The log-linear method is preferred during elimination phases where
#' concentrations decline exponentially.  It requires strictly positive
#' concentrations; when two consecutive values are equal or one is
#' \eqn{\leq 0} the interval automatically falls back to the linear rule.
#'
#' Rows are sorted by \code{c(by, time)} before computing so the caller
#' does not need to pre-sort the data.
#'
#' @param data A data frame or tibble.
#' @param by Character vector of grouping column names, e.g.
#'   \code{c("usubjid", "trt")}.  \code{NULL} (default) computes a
#'   single AUC across the whole dataset.
#' @param val Unquoted name of the concentration (value) column.
#' @param time Unquoted name of the time column (numeric).
#' @param type AUC method: \code{"trapez"} (linear, default) or
#'   \code{"log-trapez"} (log-linear).
#' @return
#'   \itemize{
#'     \item When \code{by = NULL}: a single numeric value.
#'     \item When \code{by} is provided: a \code{data.frame} with one row
#'       per group and an \code{AUC} column appended to the grouping columns.
#'   }
#' @seealso \code{\link{ks_auc}} for the vectorised helper
#' @examples
#' ## Single subject — linear trapezoid
#' pk1 <- data.frame(conc = c(0, 4, 2, 1), time = c(0, 1, 2, 4))
#' ks_auc(pk1, val = conc, time = time)
#'
#' ## Two subjects — grouped
#' pk2 <- data.frame(
#'   id   = c("A","A","A","B","B","B"),
#'   conc = c(0, 4, 1,  0, 6, 2),
#'   time = c(0, 1, 2,  0, 1, 2)
#' )
#' ks_auc(pk2, by = "id", val = conc, time = time)
#' @name ks_auc
#' @importFrom dplyr group_by across all_of summarise
#' @importFrom rlang .data
#' @export
ks_auc <- function(data, by = NULL, val, time,
                   type = c("trapez", "log-trapez")) {

  if (!is.data.frame(data)) stop("'data' must be a data.frame or tibble")

  val_str  <- deparse(substitute(val))
  time_str <- deparse(substitute(time))
  type     <- match.arg(type)

  ## ── Internal AUC helpers ──────────────────────────────────────────────

  trapez <- function(v, t) {
    v_next <- c(v[-1L], NA_real_)
    t_next <- c(t[-1L], NA_real_)
    sum((v + v_next) * (t_next - t) / 2, na.rm = TRUE)
  }

  log_trapez <- function(v, t) {
    v_next <- c(v[-1L], NA_real_)
    t_next <- c(t[-1L], NA_real_)
    dt     <- t_next - t
    dv     <- v_next - v
    dlv    <- log(v_next) - log(v)    # log(v_next / v)
    ## Fall back to linear trapezoid when:
    ##   - v or v_next <= 0  (log undefined  → dlv = ±Inf or NaN)
    ##   - equal consecutive values          (dlv = 0    → 0/0 = NaN)
    use_linear <- !is.finite(dlv) | abs(dlv) < .Machine$double.eps^0.5
    auc_i      <- ifelse(use_linear, (v + v_next) * dt / 2, dv * dt / dlv)
    sum(auc_i, na.rm = TRUE)
  }

  auc_fun <- if (type == "trapez") trapez else log_trapez

  ## ── Sort: group columns first, then time (ensures within-group order) ─
  sort_cols <- c(by, time_str)
  data      <- data[do.call(order, data[sort_cols]), ]

  ## ── Compute ───────────────────────────────────────────────────────────
  if (!is.null(by)) {
    data |>
      dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
      dplyr::summarise(
        AUC     = auc_fun(.data[[val_str]], .data[[time_str]]),
        .groups = "drop"
      ) |>
      as.data.frame()
  } else {
    auc_fun(data[[val_str]], data[[time_str]])
  }
}
