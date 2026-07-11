#' Apply a list of validation rules to a data frame
#'
#' Evaluates each rule formula against \code{data} and records a message for
#' every row that violates a rule.  Two modes are supported:
#' \describe{
#'   \item{\code{"first"}}{Each row gets the message of the \emph{first} rule
#'     it fails; subsequent rules are not evaluated for that row.}
#'   \item{\code{"all"}}{All rules are evaluated for every row; the row
#'     receives a list of all messages for rules it fails.}
#' }
#'
#' @param data A data frame.
#' @param rules A named list of rule objects, each with two fields:
#'   \describe{
#'     \item{\code{expr}}{A one-sided formula whose RHS is a logical
#'       expression (evaluated with \code{rlang::eval_tidy()}) that is
#'       \code{TRUE} for \emph{failing} rows.}
#'     \item{\code{msg}}{Character scalar.  Message written to failing rows.}
#'   }
#' @param mode Character.  Either \code{"first"} (default) or \code{"all"}.
#'
#' @return \code{data} with an additional list-column \code{check_msgs}.
#'   In \code{"first"} mode each element is a single string (\code{"OK"} for
#'   passing rows).  In \code{"all"} mode each element is a character vector
#'   of all violated messages (or \code{"OK"}).
#'
#' @examples
#' \dontrun{
#' rules <- list(
#'   list(expr = ~ AGE < 0,  msg = "Negative age"),
#'   list(expr = ~ is.na(SEX), msg = "Missing sex")
#' )
#' ks_check_rules(adsl, rules, mode = "all")
#' }
#'
#' @name ks_check_rules
#' @importFrom rlang eval_tidy f_rhs
#' @export
ks_check_rules <- function(data, rules, mode = c("first", "all")) {
  mode <- match.arg(mode)
  n <- nrow(data)

  if (length(rules) == 0L) {
    data$check_msgs <- rep(list("OK"), n)
    return(data)
  }

  rule_exprs <- lapply(rules, function(rule) rlang::f_rhs(rule$expr))
  rule_msgs <- vapply(
    rules,
    function(rule) as.character(rule$msg)[1],
    character(1),
    USE.NAMES = FALSE
  )

  if (mode == "first") {
    result_msgs <- rep("OK", n)
    pending_idx <- seq_len(n)

    for (i in seq_along(rule_exprs)) {
      if (!length(pending_idx)) break

      hit <- rlang::eval_tidy(
        rule_exprs[[i]],
        data = data[pending_idx, , drop = FALSE]
      )
      hit <- !is.na(hit) & hit
      if (!any(hit)) next

      failed_idx <- pending_idx[hit]
      result_msgs[failed_idx] <- rule_msgs[[i]]
      pending_idx <- pending_idx[!hit]
    }

    data$check_msgs <- as.list(result_msgs)
    return(data)

  } else {
    result_msgs <- vector("list", n)

    for (i in seq_along(rule_exprs)) {
      hit <- rlang::eval_tidy(rule_exprs[[i]], data = data)
      hit <- !is.na(hit) & hit
      failed <- which(hit)
      if (!length(failed)) next

      msg <- rule_msgs[[i]]
      for (j in failed) {
        result_msgs[[j]] <- c(result_msgs[[j]], msg)
      }
    }

    for (j in seq_len(n)) {
      if (length(result_msgs[[j]]) == 0L) result_msgs[[j]] <- "OK"
    }

    data$check_msgs <- result_msgs
  }

  data
}
