#' Check SDTM supplemental dataset structure
#'
#' Validates that a SUPP-- domain data frame has the required SDTM structure
#' and internally consistent \code{IDVAR}/\code{IDVARVAL} columns.
#'
#' @details
#' Two structural rules are enforced:
#' \enumerate{
#'   \item All seven standard SUPP columns must be present:
#'     \code{STUDYID}, \code{USUBJID}, \code{IDVAR}, \code{IDVARVAL},
#'     \code{QNAM}, \code{QLABEL}, \code{QVAL}.
#'   \item Every one of those seven columns must be of type \code{character}.
#' }
#'
#' If both rules pass, the function further inspects
#' \code{IDVAR}/\code{IDVARVAL}:
#' \itemize{
#'   \item \strong{All blank} (empty string or \code{NA}): the merge key is
#'     \code{USUBJID} alone (\code{noid = TRUE}).
#'   \item \strong{All non-blank}: a record-level key is available
#'     (\code{noid = FALSE}).
#'   \item \strong{Mixed}: considered invalid — \code{isvalid} is set to
#'     \code{FALSE}.
#' }
#'
#' @param data A data frame or tibble representing a SUPP-- domain.
#' @return A named logical vector of length 3:
#' \describe{
#'   \item{\code{isvalid}}{Dataset passes structural checks.}
#'   \item{\code{noid}}{\code{TRUE} when all \code{IDVAR}/\code{IDVARVAL}
#'     are blank — merge key is \code{USUBJID} only.}
#'   \item{\code{multid}}{\code{TRUE} when more than one distinct non-blank
#'     \code{IDVAR} value is present.}
#' }
#' @seealso \code{\link{ks_supp_merge}}
#' @examples
#' supp <- data.frame(
#'   STUDYID  = "S1",
#'   USUBJID  = c("01", "02"),
#'   IDVAR    = "",
#'   IDVARVAL = "",
#'   QNAM     = "RACE2",
#'   QLABEL   = "Race (detail)",
#'   QVAL     = c("Asian", "White"),
#'   stringsAsFactors = FALSE
#' )
#' ks_supp_consistency_check(supp)
#'
#' ## Invalid: missing required column
#' bad <- supp[, -which(names(supp) == "QLABEL")]
#' ks_supp_consistency_check(bad)
#' @name ks_supp_consistency_check
#' @export
ks_supp_consistency_check <- function(data) {

  rep <- c(isvalid = NA, noid = NA, multid = NA)

  exp_names <- c("STUDYID", "USUBJID", "IDVAR", "IDVARVAL",
                 "QNAM", "QLABEL", "QVAL")

  ## Rule 1: all required columns present
  has_cols <- all(exp_names %in% names(data))

  ## Rule 2: all required columns are character (only checked when columns exist)
  has_char <- has_cols &&
    all(vapply(data[exp_names], is.character, logical(1L)))

  rep["isvalid"] <- has_cols && has_char

  if (!rep["isvalid"]) return(rep)

  ## IDVAR / IDVARVAL consistency
  ## SDTM mandates empty string for "no value"; guard against NA too
  blank <- function(x) is.na(x) | x == ""

  idvar_blank    <- blank(data$IDVAR)
  idvarval_blank <- blank(data$IDVARVAL)

  if (all(idvar_blank) && all(idvarval_blank)) {
    rep["noid"]   <- TRUE
    rep["multid"] <- FALSE
  } else if (any(idvar_blank) || any(idvarval_blank)) {
    ## Mixed blank / non-blank — internally inconsistent
    rep["isvalid"] <- FALSE
  } else {
    rep["noid"]   <- FALSE
    rep["multid"] <- dplyr::n_distinct(data$IDVAR) > 1L
  }

  rep
}


#' Merge an SDTM supplemental domain with its primary domain
#'
#' Transposes a SUPP-- dataset from long (one row per variable) to wide and
#' left-joins it onto the primary domain using the appropriate key columns.
#'
#' @details
#' The merge strategy depends on \code{IDVAR}/\code{IDVARVAL}:
#' \describe{
#'   \item{\strong{Subject-level} (\code{noid = TRUE})}{All
#'     \code{IDVAR}/\code{IDVARVAL} are blank. The join key is
#'     \code{STUDYID + USUBJID}.}
#'   \item{\strong{Record-level} (\code{noid = FALSE})}{Each row in the SUPP
#'     is tied to a specific record in the primary domain.  \code{IDVAR}
#'     names the primary domain variable (e.g. \code{EXSEQ}) and
#'     \code{IDVARVAL} holds its value.  When multiple distinct
#'     \code{IDVAR} values are present, each is processed in a separate
#'     join pass.}
#' }
#'
#' If \code{get_labels = TRUE} and the primary domain was loaded via
#' \code{haven} (or another reader that preserves column \code{"label"}
#' attributes), the per-variable labels from \code{QLABEL} are attached to the
#' newly added columns.
#'
#' @param primary A data frame or tibble: the primary SDTM domain
#'   (e.g. \code{DM}, \code{EX}).
#' @param supp A data frame or tibble: the corresponding SUPP-- domain
#'   (e.g. \code{SUPPDM}, \code{SUPPEX}).  Must pass
#'   \code{\link{ks_supp_consistency_check}}.
#' @param mvars Character vector of \code{QNAM} values to merge. \code{NULL}
#'   (default) merges all available variables.
#' @param get_labels Logical; if \code{TRUE} (default) attach \code{QLABEL}
#'   values as column \code{"label"} attributes on the merged columns.
#' @param rep_na Logical; if \code{TRUE} replace \code{NA} in merged columns
#'   with \code{""}.  Default \code{FALSE}.
#' @return The \code{primary} data frame with SUPP variables added as new
#'   columns.
#' @seealso \code{\link{ks_supp_consistency_check}}
#' @examples
#' dm <- data.frame(
#'   STUDYID = "S1",
#'   USUBJID = c("01", "02", "03"),
#'   AGE     = c(34L, 52L, 47L),
#'   stringsAsFactors = FALSE
#' )
#' suppdm <- data.frame(
#'   STUDYID  = "S1",
#'   USUBJID  = c("01", "02", "03"),
#'   IDVAR    = "",
#'   IDVARVAL = "",
#'   QNAM     = "RACE2",
#'   QLABEL   = "Race (detail)",
#'   QVAL     = c("Asian", "White", "Asian"),
#'   stringsAsFactors = FALSE
#' )
#' ks_supp_merge(dm, suppdm)
#' @name ks_supp_merge
#' @importFrom cli cli_abort
#' @importFrom dplyr select filter distinct pull left_join mutate across all_of n_distinct
#' @importFrom rlang .data
#' @importFrom tidyr pivot_wider
#' @importFrom methods as
#' @export
ks_supp_merge <- function(primary, supp,
                           mvars      = NULL,
                           get_labels = TRUE,
                           rep_na     = FALSE) {

  res <- primary

  chk <- ks_supp_consistency_check(supp)
  if (!chk["isvalid"])
    cli::cli_abort("{.val {deparse(substitute(supp))}} is not a valid supplemental dataset.")

  svars <- c("STUDYID", "USUBJID", "IDVAR", "IDVARVAL", "QNAM", "QVAL")
  if (chk[["noid"]])
    svars <- setdiff(svars, c("IDVAR", "IDVARVAL"))

  ## SDTM: each (key, QNAM) combination must be unique. Duplicate records
  ## make pivot_wider() silently build list-columns; abort with a pointer.
  key_cols <- setdiff(svars, "QVAL")
  keys     <- do.call(paste, c(supp[key_cols], list(sep = " | ")))
  dup_i    <- which(duplicated(keys))
  if (length(dup_i)) {
    cli::cli_abort(c(
      "SUPP dataset has duplicate QNAM records for the same key ({length(dup_i)} affected row(s); SDTM requires uniqueness):",
      stats::setNames(utils::head(unique(keys[dup_i]), 5L), "*"),
      "i" = "Deduplicate the SUPP dataset before merging."
    ))
  }

  ## QNAM must not collide with existing primary-domain variable names:
  ## left_join() would silently create .x/.y suffixed columns.
  qnams    <- unique(supp[["QNAM"]])
  collide  <- intersect(qnams, names(primary))
  if (length(collide)) {
    cli::cli_abort(c(
      "QNAM value(s) {.val {collide}} collide with variables already present in the primary domain.",
      "i" = "Rename the SUPP QNAM values before merging."
    ))
  }

  ## Transpose SUPP to wide format (one column per QNAM)
  supp_t <- supp |>
    dplyr::select(dplyr::all_of(svars)) |>
    tidyr::pivot_wider(names_from = "QNAM", values_from = "QVAL")

  qnams <- unique(supp[["QNAM"]])

  ## Attach QLABEL as column "label" attribute on the widened columns
  if (get_labels) {
    ## First QLABEL per QNAM (SDTM mandates a single label per QNAM)
    label_map <- stats::setNames(
      supp$QLABEL[match(qnams, supp$QNAM)],
      qnams
    )
    for (qn in intersect(names(supp_t), names(label_map))) {
      attr(supp_t[[qn]], "label") <- label_map[[qn]]
    }
  }

  ## Resolve which QNAMs to actually merge
  resolve_mvars <- function(candidates) {
    if (!is.null(mvars) && length(mvars) > 0L) {
      m <- intersect(candidates, mvars)
      if (length(m) == 0L)
        cli::cli_abort("None of the specified {.arg mvars} exist in the SUPP domain.")
      m
    } else {
      candidates
    }
  }

  if (chk["noid"]) {
    ## ── Subject-level merge ─────────────────────────────────────────────
    merge_vars <- resolve_mvars(qnams)

    supp_sel <- supp_t |>
      dplyr::select("STUDYID", "USUBJID", dplyr::all_of(merge_vars))

    res <- res |>
      dplyr::left_join(supp_sel, by = c("STUDYID", "USUBJID"))

    if (rep_na) {
      res <- res |>
        dplyr::mutate(dplyr::across(
          dplyr::all_of(merge_vars),
          \(x) ifelse(is.na(x), "", x)
        ))
    }

  } else {
    ## ── Record-level merge (one pass per distinct IDVAR) ────────────────
    for (id in unique(supp_t$IDVAR)) {

      vars_for_id <- supp |>
        dplyr::filter(.data$IDVAR == id) |>
        dplyr::distinct(.data$QNAM) |>
        dplyr::pull("QNAM")

      merge_vars <- resolve_mvars(vars_for_id)

      tmp_supp <- supp_t |>
        dplyr::filter(.data$IDVAR == id) |>
        dplyr::select("STUDYID", "USUBJID", "IDVARVAL",
                      dplyr::all_of(merge_vars))

      ## IDVARVAL is always character in SDTM; coerce to match the primary
      ## domain column type (e.g. numeric EXSEQ)
      if (!identical(class(tmp_supp$IDVARVAL), class(res[[id]]))) {
        tmp_supp$IDVARVAL <- methods::as(tmp_supp$IDVARVAL,
                                          Class = class(res[[id]])[[1L]])
      }

      ## Join: primary[[id]] == supp_t[["IDVARVAL"]]
      by_cols <- c("STUDYID", "USUBJID", stats::setNames("IDVARVAL", id))

      res <- res |>
        dplyr::left_join(tmp_supp, by = by_cols)

      if (rep_na) {
        res <- res |>
          dplyr::mutate(dplyr::across(
            dplyr::all_of(merge_vars),
            \(x) ifelse(is.na(x), "", x)
          ))
      }
    }
  }

  res
}
