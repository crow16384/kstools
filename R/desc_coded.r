#' @title
#' Summarise hierarchically coded clinical items
#' @description
#' Produces a tidy long-format count summary for data coded with a two-level
#' hierarchy, such as MedDRA System Organ Class / Preferred Term (adverse
#' events, medical history) or ATC group / drug (medications).
#'
#' The function counts distinct subjects (\code{n}) and total events (\code{e})
#' at three levels:
#' \enumerate{
#'   \item \strong{Overall total} — subjects with at least one record.
#'   \item \strong{Level-1 total} (e.g. SOC) — subjects in that top-level
#'         group.
#'   \item \strong{Level-2 detail} (e.g. PT) — subjects with that specific
#'         lower-level code.
#' }
#'
#' The function returns raw counts only; apply \code{\link{ks_n_pct}} to
#' the \code{n} column afterwards to produce formatted \code{"n (pct\%)"} 
#' strings.  Rows where \code{<l2>} is \code{NA} are header / SOC-total rows
#' (i.e. they would be rendered bold in a report).
#'
#' The function is intentionally single-arm: call it once per analysis
#' population or treatment arm and join the results on the \code{<l1>},
#' \code{<l2>}, \code{ord0}, and \code{ord} key columns.
#'
#' @param data A data frame or tibble containing the coded event records (one
#'   row per event, not one row per subject).
#' @param id <[`data-masking`][dplyr::dplyr_data_masking]> Bare name of the
#'   column holding the unique subject identifier.
#' @param l1 <[`data-masking`][dplyr::dplyr_data_masking]> Bare name of the
#'   top-level code column (e.g. \code{meddra_soc}).
#' @param l2 <[`data-masking`][dplyr::dplyr_data_masking]> Bare name of the
#'   lower-level code column (e.g. \code{meddra_pt}).
#' @param tot_label Character string used as the label in the \code{<l1>}
#'   column for the overall-total row.  Default: \code{"Total subjects"}.
#' @return A \code{\link[tibble]{tibble}} with one row per display line,
#'   ordered by top-level code then lower-level code:
#' \describe{
#'   \item{\code{ord0}, \code{ord}}{Integer sort keys.
#'     \code{ord0 = 1} / \code{ord = 1}: overall total;
#'     \code{ord0 = 2} / \code{ord = 2}: level-1 (SOC) total;
#'     \code{ord0 = 2} / \code{ord = 3}: level-2 (PT) detail row.}
#'   \item{\code{<l1 name>}}{Top-level code value. Contains \code{tot_label}
#'     for the overall-total row; the SOC name for all other rows.}
#'   \item{\code{<l2 name>}}{Lower-level code value. \code{NA} for
#'     overall-total and level-1-total rows (these are the bold / header
#'     rows); PT name for detail rows.}
#'   \item{\code{n}}{Distinct subject count for the group.}
#'   \item{\code{e}}{Event count (number of source rows for the group).}
#' }
#' @seealso \code{\link{ks_n_pct}} for formatting \code{n} as
#'   \code{"n (pct\%)"} once the population size is known.
#' @examples
#' ae <- data.frame(
#'   usubjid = c("01","01","02","03","03","04"),
#'   soc = c("Cardiac","Cardiac","Nervous","Cardiac","Nervous","Nervous"),
#'   pt  = c("Palp","Tachy","Head","Palp","Dizzy","Head"),
#'   stringsAsFactors = FALSE
#' )
#'
#' ## Raw counts (N unknown at this stage)
#' res <- ks_desc_coded(ae, id = usubjid, l1 = soc, l2 = pt)
#' res
#'
#' ## Add formatted value column once pop is known
#' dplyr::mutate(res, value = ks_n_pct(n, totals = 10))
#'
#' ## Multi-arm via group_modify(); pop looked up per arm
#' pop <- c(A = 5, B = 5)
#' ae$trt <- rep(c("A","B"), each = 3)
#' ae |>
#'   dplyr::group_by(trt) |>
#'   dplyr::group_modify(
#'     ~ ks_desc_coded(.x, id = usubjid, l1 = soc, l2 = pt) |>
#'       dplyr::mutate(value = ks_n_pct(n, pop[.y$trt]))
#'   ) |>
#'   dplyr::ungroup()
#' @name ks_desc_coded
#' @importFrom dplyr summarise mutate bind_rows arrange select n_distinct n
#' @importFrom rlang ":="
#' @export
ks_desc_coded <- function(data,
                          id        = usubjid,
                          l1        = meddra_soc,
                          l2        = meddra_pt,
                          tot_label = "Total subjects") {

  if (!is.data.frame(data)) stop("'data' must be a data.frame or tibble")

  ## Level-1 (SOC) totals: distinct subjects and event count per l1
  t_soc <- data |>
    dplyr::summarise(.by     = {{ l1 }},
                     n       = dplyr::n_distinct({{ id }}),
                     e       = dplyr::n()) |>
    dplyr::mutate(ord0 = 2L, ord = 2L, "{{l2}}" := "")

  ## Level-2 (PT) detail: distinct subjects and event count per l1 x l2
  t_pt <- data |>
    dplyr::summarise(.by = c({{ l1 }}, {{ l2 }}),
                     n   = dplyr::n_distinct({{ id }}),
                     e   = dplyr::n()) |>
    dplyr::mutate(ord0 = 2L, ord = 3L)

  ## Overall total: distinct subjects and event count across the whole dataset
  t_total <- data |>
    dplyr::summarise(n = dplyr::n_distinct({{ id }}), e = dplyr::n()) |>
    dplyr::mutate(ord0 = 1L, ord = 1L,
                  "{{l1}}" := tot_label, "{{l2}}" := "")

  dplyr::bind_rows(t_total, t_soc, t_pt) |>
    dplyr::arrange(ord0, {{ l1 }}, ord, {{ l2 }}) |>
    ## Replace empty l2 with tot_label sentinel, then convert to NA
    dplyr::mutate("{{l2}}" := ifelse({{ l2 }} == "", tot_label, {{ l2 }})) |>
    dplyr::mutate("{{l2}}" := ifelse({{ l2 }} == tot_label, NA_character_,
                                     {{ l2 }})) |>
    dplyr::select(ord0, {{ l1 }}, ord, {{ l2 }}, n, e)
}
