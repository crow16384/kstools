#' Impute incomplete ISO 8601 date/datetime strings
#'
#' Parses truncated ISO 8601 date or datetime character strings and imputes
#' missing components according to the chosen direction, returning a
#' \code{tibble} with the resulting \code{POSIXct} and an imputation flag.
#'
#' @details
#' ## Parsing
#'
#' Each element of \code{x} is matched against a regular expression that
#' captures year, month, day, hour, minute, and second independently.
#' The date-time separator may be \code{T} or a single space.  Trailing
#' timezone designators (\code{Z}, \code{+HH:MM}, \code{-HHMM}) are
#' silently stripped; all output is placed in the timezone given by
#' \code{tz}.  Elements that do not match the pattern produce
#' \code{dt = NA} and \code{imputation_flag = NA}.
#'
#' ## Completeness and imputation flags
#'
#' A string is considered \emph{complete} when year, month, and day are all
#' present, and — if a time separator (\code{T} or space) is present —
#' hour and minute are also present.  Complete strings are assembled
#' directly without imputation (flag \code{NA}), \emph{except} for
#' date-only strings under \code{direction = "end"} (Case D, see below).
#'
#' The \code{imputation_flag} records the most significant component that
#' was imputed:
#'
#' \tabular{ll}{
#'   \strong{Flag} \tab \strong{Meaning} \cr
#'   \code{"M"}    \tab Month was imputed (year was the only component present). \cr
#'   \code{"D"}    \tab Day was imputed (year and month were present). \cr
#'   \code{"H"}    \tab Hour (and minute) were imputed. \cr
#'   \code{"S"}    \tab Minute was imputed (hour was already present). \cr
#'   \code{NA}     \tab No imputation was performed. \cr
#' }
#'
#' ## Direction
#'
#' \describe{
#'   \item{\code{"start"}}{Each missing component is filled with the
#'     \emph{earliest} plausible value: month \eqn{\to} 1, day \eqn{\to} 1,
#'     hour \eqn{\to} 0, minute \eqn{\to} 0.}
#'   \item{\code{"end"}}{Each missing component is filled with the
#'     \emph{latest} plausible value: month \eqn{\to} 12, day \eqn{\to} last
#'     day of that month (correctly handling leap years), hour \eqn{\to} 23,
#'     minute \eqn{\to} 59.}
#'   \item{\code{"no"}}{No imputation is performed.  Incomplete strings
#'     return \code{dt = NA} and \code{imputation_flag = NA}.}
#' }
#'
#' ## Date-only strings with a directional imputation (Cases D and E)
#'
#' A date-only string such as \code{"2020-04-06"} contains no time
#' separator and is otherwise complete.  Because the time was not recorded,
#' it is always considered imputed when \code{direction != "no"}:
#'
#' \describe{
#'   \item{\strong{Case D} (\code{direction = "end"})}{Time is imputed as
#'     \code{23:59:00}.  Flag: \code{"H"}.}
#'   \item{\strong{Case E} (\code{direction = "start"})}{Time is imputed as
#'     \code{00:00:00}.  Flag: \code{"H"}.}
#' }
#'
#' A reference-date match (Case C) overrides both Case D and Case E.
#'
#' ## Reference-guided imputation
#'
#' When \code{ref} is provided and \code{direction != "no"}, the function
#' first checks whether the parsed year (and optionally month and day)
#' match the corresponding reference value before applying the directional
#' fallback.  Cases are evaluated in priority order:
#'
#' \describe{
#'   \item{\strong{Case A} — day missing, year + month match ref}{
#'     When the day (and time) are absent but year and month equal the
#'     reference, day, hour, and minute are taken from \code{ref}.
#'     Directional start/end values are \emph{not} used.
#'     Typical flag: \code{"D"}.}
#'   \item{\strong{Case B} — month missing, year matches ref}{
#'     When month (and therefore day and time) are absent but the year
#'     equals the reference year, month, day, hour, and minute are all
#'     taken from \code{ref}.
#'     Typical flag: \code{"M"}.}
#'   \item{\strong{Case C} — date complete, time absent, full date matches ref}{
#'     A date-only string whose year, month, \emph{and} day all equal the
#'     reference has its time filled from \code{ref}.  This takes priority
#'     over the Case D / Case E directional time fallback.
#'     Flag: \code{"H"}.}
#'   \item{\strong{Fallback}}{
#'     If none of Cases A–C applies — because \code{ref} is \code{NULL},
#'     the year does not match, or the month does not match — the
#'     directional start/end values are used as described above.}
#' }
#'
#' \code{ref} is recycled to \code{length(x)} via \code{rep_len()}.
#' A \code{Date} ref is coerced to \code{POSIXct} in timezone \code{tz}
#' before its components are extracted.
#'
#' @name ks_impute_dtc
#'
#' @param x Character vector of ISO 8601 truncated date/datetime strings.
#'   Accepted formats: \code{"YYYY"}, \code{"YYYY-MM"}, \code{"YYYY-MM-DD"},
#'   \code{"YYYY-MM-DDTHH"}, \code{"YYYY-MM-DDTHH:MM"},
#'   \code{"YYYY-MM-DDTHH:MM:SS"}.  A space may replace \code{T} as the
#'   date-time separator.  Trailing timezone designators (\code{Z},
#'   \code{+HH:MM}, \code{-HH:MM}) are accepted but ignored; the \code{tz}
#'   argument governs the output timezone.
#' @param direction One of \code{"no"}, \code{"start"}, or \code{"end"}.
#'   Controls how missing components are filled.  Validated via
#'   \code{\link[base]{match.arg}}.
#' @param tz IANA timezone string applied to the output \code{POSIXct} values.
#'   Defaults to \code{"UTC"}.
#' @param ref \code{NULL} (default), or a \code{Date}, \code{POSIXct}, or
#'   \code{POSIXlt} reference vector recycled to \code{length(x)}.  When
#'   provided, missing components whose year (and optionally month) match the
#'   corresponding reference are filled from that reference rather than using
#'   the directional fallback.
#'
#' @return A \code{\link[tibble:tibble]{tibble}} with one row per element of
#'   \code{x} and two columns:
#'   \describe{
#'     \item{\code{dt}}{\code{POSIXct} in timezone \code{tz}, or \code{NA}
#'       when the year is absent or imputation could not be completed.}
#'     \item{\code{imputation_flag}}{\code{character}; the highest-priority
#'       component that was imputed: \code{"M"} (month), \code{"D"} (day),
#'       \code{"H"} (hour), \code{"S"} (minute).  \code{NA} when no imputation
#'       was performed.}
#'   }
#'
#' @export
#'
#' @importFrom lubridate days_in_month make_datetime year month day hour minute
#' @importFrom dplyr case_when
#' @importFrom tibble tibble
#' @importFrom cli cli_abort
#'
#' @examples
#' # --- direction = "no" -------------------------------------------------------
#' # Complete datetime — no imputation, flag NA
#' ks_impute_dtc("2020-03-15T10:30:00", "no")
#'
#' # Truncated with direction = "no" — returns NA (nothing to impute)
#' ks_impute_dtc("2020-03", "no")
#'
#' # Invalid string
#' ks_impute_dtc("not-a-date", "no")
#'
#' # --- direction = "start" ----------------------------------------------------
#' # Year only → 2020-01-01 00:00:00, flag "M"
#' ks_impute_dtc("2020", "start")
#'
#' # Year-month → first day of month, flag "D"
#' ks_impute_dtc("2020-03", "start")
#'
#' # Date-only + end → end-of-day 23:59, flag "H" (Case D)
#' ks_impute_dtc("2020-03-15", "end")
#'
#' # Date-only + start → midnight 00:00, flag "H" (Case E)
#' ks_impute_dtc("2020-03-15", "start")
#'
#' # --- direction = "end" ------------------------------------------------------
#' # End of February in a leap year → 2020-02-29 23:59:00, flag "D"
#' ks_impute_dtc("2020-02", "end")
#'
#' # End of March → 2020-03-31 23:59:00, flag "D"
#' ks_impute_dtc("2020-03", "end")
#'
#' # --- ref: same-period guided imputation ------------------------------------
#' ref <- as.POSIXct("2020-03-15 10:30:00", tz = "UTC")
#'
#' # Case A — day missing, year+month match ref → take day/time from ref
#' ks_impute_dtc("2020-03", "start", ref = ref)
#'
#' # Case C overrides D — date matches ref → take time from ref, not 23:59
#' ks_impute_dtc("2020-03-15", "end", ref = ref)
#'
#' # ref year/month mismatch → directional fallback used instead
#' ks_impute_dtc("2020-04", "start", ref = ref)
#'
#' # --- Vectorised with dplyr::bind_cols() ------------------------------------
#' \dontrun{
#' library(dplyr)
#' df <- tibble::tibble(
#'   dtc = c("2020-03-15T08:00", "2020-03-15", "2020-03", "2020", "bad"),
#'   ref = as.POSIXct(c(NA, "2020-03-15 14:30:00",
#'                      "2020-03-10 08:00:00", "2020-05-01 00:00:00", NA),
#'                    tz = "UTC")
#' )
#' dplyr::bind_cols(df, ks_impute_dtc(df$dtc, "start", ref = df$ref))
#' }
ks_impute_dtc <- function(x, direction = "no", tz = "UTC", ref = NULL) {

  ## ---- Input validation ---------------------------------------------------
  if (!is.character(x)) {
    cli::cli_abort("{.arg x} must be a character vector.")
  }
  if (!is.null(ref) && !inherits(ref, c("Date", "POSIXct", "POSIXlt"))) {
    cli::cli_abort(
      "{.arg ref} must be {.code NULL} or a Date/POSIXct/POSIXlt vector."
    )
  }
  direction <- match.arg(direction, c("no", "start", "end"))

  n <- length(x)

  ## ---- Step 1: Parse -------------------------------------------------------
  pattern <- paste0(
    "^(\\d{4})",
    "(?:-(\\d{2})",
    "(?:-(\\d{2})",
    "(?:[T ](\\d{2})",
    "(?::(\\d{2})",
    "(?::(\\d{2})",
    "(?:\\.\\d+)?",
    ")?)?)?)?)?",
    "(?:Z|[+-]\\d{2}:?\\d{2})?$"
  )

  x_safe           <- x
  x_safe[is.na(x)] <- ""
  has_time         <- grepl("[T ]", x_safe)

  m <- regmatches(x_safe, regexec(pattern, x_safe, perl = TRUE))

  .grp <- function(grp_idx) {
    vapply(m, function(r) {
      v <- r[grp_idx + 1L]
      if (length(v) == 0L || is.na(v) || v == "") NA_integer_ else as.integer(v)
    }, integer(1L))
  }

  yr <- .grp(1L)
  mo <- .grp(2L)
  dy <- .grp(3L)
  hr <- .grp(4L)
  mn <- .grp(5L)
  sc <- .grp(6L)
  sc[is.na(sc)] <- 0L

  ## ---- Step 2: Success check -----------------------------------------------
  success <- !is.na(yr) & !is.na(mo) & !is.na(dy) &
    (!has_time | (!is.na(hr) & !is.na(mn)))

  ## ---- Step 3: Imputation flag ---------------------------------------------
  flag <- dplyr::case_when(
    is.na(yr) | direction == "no"  ~ NA_character_,
    success & has_time             ~ NA_character_,
    success & !has_time            ~ "H",
    is.na(mo)                      ~ "M",
    is.na(dy)                      ~ "D",
    is.na(hr) & has_time           ~ "H",
    TRUE                           ~ "S"
  )

  ## ---- Step 4: Reference extraction ----------------------------------------
  needs <- !success & !is.na(yr) & direction != "no"

  ref_yr <- rep(NA_integer_, n)
  ref_mo <- rep(NA_integer_, n)
  ref_dy <- rep(NA_integer_, n)
  ref_hr <- rep(NA_integer_, n)
  ref_mn <- rep(NA_integer_, n)

  if (!is.null(ref) && direction != "no") {
    ref_r   <- rep_len(ref, n)
    ref_pct <- as.POSIXct(ref_r, tz = tz)
    ref_yr  <- as.integer(lubridate::year(ref_pct))
    ref_mo  <- as.integer(lubridate::month(ref_pct))
    ref_dy  <- as.integer(lubridate::day(ref_pct))
    ref_hr  <- as.integer(lubridate::hour(ref_pct))
    ref_mn  <- as.integer(lubridate::minute(ref_pct))
  }

  ## ---- Step 5: Imputation --------------------------------------------------
  mo_f <- mo
  dy_f <- dy
  hr_f <- hr
  mn_f <- mn

  if (any(needs)) {

    ## Case A — day missing, month present, year+month matches reference
    caseA <- needs & !is.na(ref_yr) &
      !is.na(mo_f) & is.na(dy_f) &
      !is.na(yr) & yr == ref_yr & mo_f == ref_mo
    dy_f[caseA] <- ref_dy[caseA]
    hr_f[caseA] <- ref_hr[caseA]
    mn_f[caseA] <- ref_mn[caseA]

    ## Case B — month missing, year matches reference
    caseB <- needs & !is.na(ref_yr) &
      is.na(mo_f) & !is.na(yr) & yr == ref_yr
    mo_f[caseB] <- ref_mo[caseB]
    dy_f[caseB] <- ref_dy[caseB]
    hr_f[caseB] <- ref_hr[caseB]
    mn_f[caseB] <- ref_mn[caseB]

    ## Fallback — neither Case A nor Case B
    fallback <- needs & !caseA & !caseB

    ## "start" fallback
    fb_st <- fallback & direction == "start"
    mo_f[fb_st & is.na(mo_f)] <- 1L
    dy_f[fb_st & is.na(dy_f)] <- 1L
    hr_f[fb_st & is.na(hr_f)] <- 0L
    mn_f[fb_st & is.na(mn_f)] <- 0L

    ## "end" fallback
    fb_en <- fallback & direction == "end"
    mo_f[fb_en & is.na(mo_f)] <- 12L

    dy_na <- fb_en & is.na(dy_f)
    if (any(dy_na)) {
      tmp        <- lubridate::make_date(yr[dy_na], mo_f[dy_na], 1L)
      dy_f[dy_na] <- as.integer(unname(lubridate::days_in_month(tmp)))
    }

    hr_f[fb_en & is.na(hr_f)] <- 23L
    mn_f[fb_en & is.na(mn_f)] <- 59L
  }

  ## ---- Step 6: Assemble POSIXct --------------------------------------------
  dt <- structure(rep(NA_real_, n), class = c("POSIXct", "POSIXt"), tzone = tz)

  ok <- success
  if (any(ok)) {
    dt[ok] <- lubridate::make_datetime(
      year  = yr[ok],
      month = mo[ok],
      day   = dy[ok],
      hour  = ifelse(has_time[ok], hr[ok], 0L),
      min   = ifelse(has_time[ok], mn[ok], 0L),
      sec   = sc[ok],
      tz    = tz
    )
  }

  can_build <- needs & !is.na(mo_f) & !is.na(dy_f) & !is.na(hr_f) & !is.na(mn_f)
  if (any(can_build)) {
    dt[can_build] <- lubridate::make_datetime(
      year  = yr[can_build],
      month = mo_f[can_build],
      day   = dy_f[can_build],
      hour  = hr_f[can_build],
      min   = mn_f[can_build],
      sec   = sc[can_build],
      tz    = tz
    )
  }

  flag[needs & !can_build] <- NA_character_

  ## Case D: date-only success rows with direction = "end" and no ref match
  ## → end-of-day 23:59; flag already set to "H" in Step 3
  caseD <- ok & !has_time & direction == "end"
  if (any(caseD)) {
    dt[caseD] <- lubridate::make_datetime(
      year  = yr[caseD],
      month = mo[caseD],
      day   = dy[caseD],
      hour  = 23L,
      min   = 59L,
      sec   = 0L,
      tz    = tz
    )
  }

  ## Case C: date-only success rows whose full date matches the reference
  ## → take hour and minute from reference; flag = "H"
  caseC <- ok & !has_time & direction != "no" & !is.na(ref_yr) &
    yr == ref_yr & mo == ref_mo & dy == ref_dy
  if (any(caseC)) {
    dt[caseC] <- lubridate::make_datetime(
      year  = yr[caseC],
      month = mo[caseC],
      day   = dy[caseC],
      hour  = ref_hr[caseC],
      min   = ref_mn[caseC],
      sec   = 0L,
      tz    = tz
    )
    flag[caseC] <- "H"
  }

  tibble::tibble(dt = dt, imputation_flag = flag)
}
