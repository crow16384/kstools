#' Convert DTC (date-time character) to Date
#'
#' Parses ISO-like date strings (YYYY, YYYY-MM, YYYY-MM-DD) with optional
#' NA/UN for month or day, and converts to \code{Date}. Missing month/day become 1.
#' @param x Character vector of date strings (e.g. \code{"2020-01-15"}, \code{"2020-UN"}).
#' @return A \code{Date} vector.
#' @name ks_dtc2dtn
#' @export
ks_dtc2dtn <- function(x) {
  m <- regexec("^(\\d{4})(-(\\d{1,2}|NA|UN))?(-(\\d{1,2}|NA|UN)?)?$", x)
  parts <- do.call(rbind,
                   lapply(regmatches(x, m), `[`, c(2L, 4L, 6L)))
  colnames(parts) <- c("year","month","day")
  parts <- apply(parts, 2, as.numeric)

  parts[is.na(parts[,"month"]),"month"] <- 1
  parts[is.na(parts[,"day"]),"day"] <- 1

  dtc__ <- sprintf("%04d-%02d-%02d",parts[,"year"],parts[,"month"],parts[,"day"])
  as.Date(dtc__,"%Y-%m-%d",optional=T)
}