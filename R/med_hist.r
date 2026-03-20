#' @title
#' Medical History descriptive statistics
#' @description
#' Function for producing descriptive statistics (complete formatted table)
#' for Medical History typical data.
#' @param data Source data frame
#' @param patient Patient unique ID
#' @param trt Column name defining treatment
#' @param soc Column name for SOC (System Organ Class). Default="soc"
#' @param pt Column name for PT (Preferred Term). Default="pt"
#' @param pop Named vector of treatment counts.
#' @param total.string Upper string in the table with total amount of patients.
#' Default "Patients with medical history diseases"
#' @param rename Rename columns (for back compatibility) in output or not. Default = TRUE
#' @param strata Strata, if any
#' @param strata.name Column name for strata. Rename should be set to TRUE
#' @details
#' Columns for returned data.frame could be renamed and data.frame is ready to be printed
#' @examples
#' data(pill)
#' t.all <- pill
#' t.all$group <- "Total"
#'
#' t.pill <- rbind(pill, t.all)
#' rm(t.all)
#'
#' trt.n <- data.frame(trt=c("Test","Control","Total"), freq=c(56, 61, 117))
#'
#' ks_med_hist(data=t.pill, patient="patid", trt="group",
#' soc="SOC", pt="PT", pop=c(Test=56,Control=61,Total=117)) -> o.out
#' @name ks_med_hist
#' @export
ks_med_hist <- function(data, patient = "patid", trt, soc = "soc",
                        pt = "pt", pop, total.string = "Patients with medical history diseases",
                        rename = TRUE, strata = NULL, strata.name = NULL) {

  stopifnot(is.data.frame(data))
  my.data <- as.data.frame(data, stringsAsFactors = FALSE)
  my.data[[".v."]] <- "freq"

  ## --- Unique patients with medical history by treatment (and strata) ---
  agg_vars <- c(patient, trt)
  if (!is.null(strata)) agg_vars <- c(agg_vars, strata)

  f <- stats::as.formula(paste(".v. ~", paste(agg_vars, collapse = "+")))
  o.pats <- stats::aggregate(f, my.data, table)
  o.pats[[".v."]][o.pats[[".v."]] > 0] <- 1

  sum_vars <- c(trt)
  if (!is.null(strata)) sum_vars <- c(sum_vars, strata)

  f1 <- stats::as.formula(paste(".v. ~", paste(sum_vars, collapse = "+")))
  o.pats <- stats::aggregate(f1, o.pats, sum)

  id_pats <- if (is.null(strata)) character(0) else strata
  o.pats <- tidyr::pivot_wider(o.pats, id_cols = dplyr::all_of(id_pats),
                                names_from = dplyr::all_of(trt),
                                values_from = ".v.")
  o.pats <- as.data.frame(o.pats, stringsAsFactors = FALSE)
  o.pats[[soc]] <- total.string

  ## --- SOC-level counts ---
  soc_vars <- c(soc, trt)
  v.soc    <- c(patient, ".v.", soc, trt)
  if (!is.null(strata)) {
    soc_vars <- c(soc_vars, strata)
    v.soc    <- c(v.soc, strata)
  }

  f.soc <- stats::as.formula(paste(".v. ~", paste(soc_vars, collapse = "+")))
  o.soc <- stats::aggregate(f.soc, unique(my.data[, v.soc, drop = FALSE]), table)

  id_soc <- if (is.null(strata)) soc else c(strata, soc)
  o.soc <- tidyr::pivot_wider(o.soc, id_cols = dplyr::all_of(id_soc),
                               names_from = dplyr::all_of(trt),
                               values_from = ".v.")
  o.soc <- as.data.frame(o.soc, stringsAsFactors = FALSE)
  o.soc[[pt]] <- "Total"

  ## --- PT-level counts ---
  pt_vars <- c(soc, pt, trt)
  v.pt    <- c(patient, ".v.", soc, pt, trt)
  if (!is.null(strata)) {
    pt_vars <- c(pt_vars, strata)
    v.pt    <- c(v.pt, strata)
  }

  f.pt <- stats::as.formula(paste(".v. ~", paste(pt_vars, collapse = "+")))
  o.pt <- stats::aggregate(f.pt, unique(my.data[, v.pt, drop = FALSE]), table)

  id_pt <- if (is.null(strata)) c(soc, pt) else c(strata, soc, pt)
  o.pt <- tidyr::pivot_wider(o.pt, id_cols = dplyr::all_of(id_pt),
                              names_from = dplyr::all_of(trt),
                              values_from = ".v.")
  o.pt <- as.data.frame(o.pt, stringsAsFactors = FALSE)

  ## --- Combine ---
  o.pats$ord <- 0
  o.soc$ord  <- 1
  o.pt$ord   <- 2
  o.pats[[pt]] <- ""

  o.mh <- dplyr::bind_rows(o.soc, o.pt, o.pats)

  v.sel <- c(soc, pt, "ord")
  if (!is.null(strata)) v.sel <- c(v.sel, strata)

  t.v <- setdiff(names(o.mh), v.sel)

  o.mh[, t.v][is.na(o.mh[, t.v])] <- 0

  o.mh[, t.v] <- ks_n_pct(o.mh[, t.v], pop)

  o.mh
}

#' Previous therapy table (wrapper around ks_med_hist)
#'
#' Builds a "previous therapy" summary table using \code{\link{ks_med_hist}} with ATC/drug columns.
#' @param data Source data frame.
#' @param patient,trt,soc,pt Patient ID and treatment columns; \code{atc.group} and \code{drug} map to SOC/PT.
#' @param atc.group Column for ATC group (SOC).
#' @param drug Column for drug (PT).
#' @param trt.counts Named vector of treatment counts (same as \code{pop} in \code{\link{ks_med_hist}}).
#' @param total.string Title row string.
#' @param ... Passed to \code{\link{ks_med_hist}}.
#' @name ks_prev_therapy
#' @export
ks_prev_therapy <- function(data, patient = "patid", trt, atc.group = "atc3",
                            drug, trt.counts, total.string = "Patients with previous therapy", ...) {
  ks_med_hist(data, patient = patient, trt, soc = atc.group, pt = drug,
              pop = trt.counts, total.string = total.string, ...)
}

#' Concomitant therapy table (wrapper around ks_med_hist)
#'
#' Same as \code{\link{ks_prev_therapy}} with a different default \code{total.string}.
#' @param data,patient,trt,atc.group,drug,trt.counts,... See \code{\link{ks_prev_therapy}}.
#' @param total.string Title row string.
#' @name ks_concom_therapy
#' @export
ks_concom_therapy <- function(data, patient = "patid", trt, atc.group = "atc3",
                              drug, trt.counts, total.string = "Patients with concomitant therapy", ...) {
  ks_med_hist(data, patient = patient, trt, soc = atc.group, pt = drug,
              pop = trt.counts, total.string = total.string, ...)
}
