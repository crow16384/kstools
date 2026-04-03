#' Compare validation check state between two runs
#'
#' Compares \code{current} results against a \code{previous} snapshot and
#' adds a \code{status} column indicating whether each row is new, changed,
#' or unchanged relative to the previous run.
#'
#' @param current A data frame from the most recent \code{\link{ks_check_rules}}
#'   run.
#' @param previous A data frame from a previous run, or \code{NULL} (default).
#'   If \code{NULL} or empty, all rows in \code{current} receive
#'   \code{status = "new"}.
#' @param key_cols Character vector of column names used to match rows across
#'   runs.  Default \code{c("center", "patno", "visit", "param")}.
#' @param compare_cols Character vector of column names whose values are used
#'   to detect changes.  Default \code{c("check_msgs", "res")}.
#'
#' @return \code{current} with an additional character column \code{status}:
#'   \describe{
#'     \item{\code{"new"}}{Row key not found in \code{previous}.}
#'     \item{\code{"changed"}}{Row key found but comparison signature
#'       differs.}
#'     \item{\code{""}}{Row is unchanged.}
#'   }
#'
#' @examples
#' \dontrun{
#' result_new <- ks_check_rules(data_new, rules)
#' result_old <- readRDS("previous_check.rds")
#' ks_compare_check_state(result_new, result_old)
#' }
#'
#' @name ks_compare_check_state
#' @export
ks_compare_check_state <- function(current, previous = NULL,
                                   key_cols = c("center", "patno", "visit", "param"),
                                   compare_cols = c("check_msgs", "res")) {
  if (is.null(previous) || nrow(previous) == 0) {
    current$status <- "new"
    return(current)
  }

  current$..row_id.. <- seq_len(nrow(current))

  cur_key  <- do.call(paste, c(current[key_cols],  sep = "|"))
  prev_key <- do.call(paste, c(previous[key_cols], sep = "|"))

  cur_sig  <- do.call(paste, c(current[intersect(compare_cols,  names(current))],  sep = "||"))
  prev_sig <- do.call(paste, c(previous[intersect(compare_cols, names(previous))], sep = "||"))
  names(prev_sig) <- prev_key

  status <- character(nrow(current))
  for (i in seq_along(cur_key)) {
    k <- cur_key[i]
    if (!(k %in% prev_key)) {
      status[i] <- "new"
    } else if (cur_sig[i] != prev_sig[k]) {
      status[i] <- "changed"
    } else {
      status[i] <- ""
    }
  }

  current$status <- status
  current$..row_id.. <- NULL
  current
}
