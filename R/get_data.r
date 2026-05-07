#' Read CSV file with column types and lengths in comments
#'
#' Read a single CSV file into R. Optionally parses KeyStat-style comment
#' headers that encode column type, length (for character variables), and
#' labels.
#'
#' @param file Path to the source CSV file.
#' @param with_length If \code{TRUE}, the CSV file contains KeyStat metadata
#'   comments with types and lengths.
#'   Default is \code{FALSE}.
#' @details
#' File encoding should be UTF-8.
#' Readable comments in the CSV file:
#' \code{#NAME$character(length)|numeric$Label}.
#'
#' This function was written for correct reading of CSV files. Some CSV files
#' without metadata in comments cannot be read correctly into R.
#' @return A data frame with column labels set from the comment metadata
#'   (when available).
#' @seealso \code{\link{ks_get_data}}
#' @export
read.csv3 <- function(file, with_length = FALSE) {
  classes <- list()
  labels  <- list()

  con <- file(file, "r", encoding = "UTF-8")
  on.exit(close(con))
  while (TRUE) {
    line <- readLines(con, n = 1)
    if (length(line) == 0 || !grepl("^#", line)) break
    line  <- gsub("^#", "", line)
    sline <- strsplit(line, "\\$")
    vclass <- tolower(sline[[1]][2])
    if (with_length) {
      vclass <- gsub("\\(\\d+\\)", "", vclass)
    }
    classes <- append(classes, vclass)
    labels  <- append(labels, sline[[1]][3])
  }

  data <- read.csv(file = file, header = TRUE, comment.char = "#",
                   fileEncoding = "UTF-8", colClasses = unlist(classes))

  mapply(function(name, label) {
    attr(data[, name], "label") <<- label
  }, names(data), unlist(labels))

  data
}


## Resolve a data file in `path` whose stem matches `stem` (case-insensitive)
## and whose extension is among `exts` (case-insensitive, without leading dot).
## Returns a list(path, ext) where `ext` is the matched extension lowercased.
## Ambiguity (more than one match) is handled via `strategy`.
.ks_resolve_domain_file <- function(stem, exts, path, strategy) {
  files <- list.files(path, full.names = FALSE, no.. = TRUE)
  if (!length(files))
    cli::cli_abort(c(
      "No file found for domain {.val {stem}} in: {.path {path}}.",
      "i" = "Directory is empty."
    ))

  file_stem <- tools::file_path_sans_ext(files)
  file_ext  <- tolower(tools::file_ext(files))

  ok <- tolower(file_stem) == tolower(stem) & file_ext %in% tolower(exts)
  cand <- files[ok]

  if (!length(cand))
    cli::cli_abort(c(
      "No file found for domain {.val {stem}} in: {.path {path}}.",
      "i" = "Looked for extensions: {.val {exts}} (case-insensitive)."
    ))

  if (length(cand) == 1L) {
    return(list(path = file.path(path, cand),
                ext  = tolower(tools::file_ext(cand))))
  }

  chosen <- switch(
    strategy,
    error = cli::cli_abort(c(
      "Multiple files match domain {.val {stem}} in: {.path {path}}.",
      "i" = "Found: {.file {cand}}.",
      "i" = paste0("Set {.code options(kstools.get_data.case = ",
                   "\"first\" | \"lower\" | \"upper\")} to resolve.")
    )),
    first = sort(cand)[1L],
    lower = {
      low <- paste0(tolower(stem), ".", tolower(tools::file_ext(cand)))
      hit <- cand[cand %in% low]
      if (!length(hit))
        cli::cli_abort(c(
          "No all-lowercase file for domain {.val {stem}} in: {.path {path}}.",
          "i" = "Found: {.file {cand}}."
        ))
      hit[1L]
    },
    upper = {
      up <- paste0(toupper(stem), ".", toupper(tools::file_ext(cand)))
      hit <- cand[cand %in% up]
      if (!length(hit))
        cli::cli_abort(c(
          "No all-uppercase file for domain {.val {stem}} in: {.path {path}}.",
          "i" = "Found: {.file {cand}}."
        ))
      hit[1L]
    }
  )

  list(path = file.path(path, chosen),
       ext  = tolower(tools::file_ext(chosen)))
}


#' Load domain files and return them
#'
#' Reads one or more data files from \code{path} and returns them as
#' \code{\link[dplyr]{tibble}}s. A single-domain call returns a tibble; a
#' multi-domain call returns a named list of tibbles (names are the
#' lowercased domain names).
#'
#' Supported formats: \code{.rds} (R native), \code{.xpt} (SAS XPORT),
#' \code{.xlsx} (Microsoft Excel), \code{.csv} (plain CSV),
#' \code{.csv} with KeyStat comments (\code{type = "csvks"}).
#'
#' @details
#' Domain names can be passed as bare names (\code{dm, ae}) or as quoted
#' strings (\code{"dm", "ae"}); both forms are accepted. Lookup against the
#' directory is \strong{case-insensitive} for both stem and extension, so
#' \code{ks_get_data(dm)} and \code{ks_get_data(DM)} match any of
#' \code{dm.xpt}, \code{DM.XPT}, \code{Dm.Xpt}, etc.
#'
#' When \code{type = "auto"} (default), the function scans the directory for
#' files matching the requested domains and determines the format from the
#' extension of the first match. All requested domains must use the same
#' format.
#'
#' The default search path is read from
#' \code{getOption("path.data", ".")}. Set this option in
#' \code{.Rprofile} to avoid repeating the path in every call:
#' \preformatted{options(path.data = "/my/project/data")}
#'
#' For \code{.xpt} (SAS XPORT) files, the reader is selected by the
#' \code{xpt_reader} argument (default from option
#' \code{kstools.xpt.reader}, fallback \code{"haven"}):
#' \describe{
#'   \item{\code{"haven"}}{(default) use \code{haven::read_xpt()}.}
#'   \item{\code{"internal"}}{use the package-internal
#'     \code{\link{ks_read_xpt}()} parser. This avoids the
#'     \dQuote{ignored N trailing byte(s) after row parsing} warning emitted
#'     by \pkg{haven} on some XPORT files. For multi-member XPORT files,
#'     the domain slot will contain a named list of tibbles (one per
#'     member).}
#' }
#'
#' When two or more files in \code{path} share the same stem but differ only
#' in case (e.g. both \code{dm.xpt} and \code{DM.xpt} exist), the resolution
#' strategy is controlled by the global option \code{kstools.get_data.case}:
#' \describe{
#'   \item{\code{"error"}}{(default) abort with a message listing the
#'     candidates.}
#'   \item{\code{"first"}}{pick the first match in alphabetical order.}
#'   \item{\code{"lower"}}{require the all-lowercase name to exist; otherwise
#'     abort.}
#'   \item{\code{"upper"}}{require the all-uppercase name to exist; otherwise
#'     abort.}
#' }
#'
#' @param ... Unquoted (or quoted) domain names, e.g. \code{dm, ae, lb}.
#' @param path Directory containing the data files.
#'   Defaults to \code{getOption("path.data", ".")}.
#' @param type File type: \code{"auto"} (detect from extension), \code{"rds"},
#'   \code{"xpt"}, \code{"xlsx"}, \code{"csv"}, or \code{"csvks"}
#'   (CSV with KeyStat comment metadata).
#' @param xpt_reader Reader to use for \code{.xpt} files: \code{"haven"}
#'   (default) or \code{"internal"} (use \code{\link{ks_read_xpt}}).
#'   Defaults to \code{getOption("kstools.xpt.reader", "haven")}.
#' @return For a single domain, a tibble. For two or more domains, a named
#'   list of tibbles keyed by the lowercased domain name.
#' @seealso \code{\link{ks_batch_load}}, \code{\link{read.csv3}}
#' @examples
#' \dontrun{
#' ## Load a single domain
#' options(path.data = "/project/data")
#' dm <- ks_get_data(dm)
#'
#' ## Case-insensitive lookup: works whether folder has dm.xpt or DM.XPT
#' dm <- ks_get_data(DM)
#'
#' ## Load multiple domains: returns a named list
#' dat <- ks_get_data(dm, ae, lb, path = "/project/data/xpt")
#' head(dat$dm)
#'
#' ## Force a specific file type
#' dm <- ks_get_data(dm, path = "/project/data", type = "xpt")
#'
#' ## Resolve case-duplicate filenames
#' options(kstools.get_data.case = "lower")  # prefer dm.xpt over DM.xpt
#' dm <- ks_get_data(dm, path = "/project/data")
#'
#' ## Quoted strings are also accepted
#' dat <- ks_get_data("dm", "ae", path = "/project/data")
#'
#' ## Use the internal XPT reader to avoid haven's trailing-byte warning
#' options(kstools.xpt.reader = "internal")
#' dm <- ks_get_data(dm, type = "xpt")
#'
#' ## Or override per call without changing the global option
#' dm <- ks_get_data(dm, type = "xpt", xpt_reader = "internal")
#' }
#' @name ks_get_data
#' @importFrom cli cli_abort
#' @importFrom rlang ensyms as_name
#' @importFrom utils read.csv
#' @export
ks_get_data <- function(...,
                        path = getOption("path.data", "."),
                        type = c("auto", "rds", "xpt", "xlsx",
                                 "csv", "csvks"),
                        xpt_reader = getOption("kstools.xpt.reader",
                                               "haven")) {

  type <- match.arg(type)

  if (!is.character(xpt_reader) || length(xpt_reader) != 1L ||
      !xpt_reader %in% c("haven", "internal"))
    cli::cli_abort(c(
      "Invalid {.arg xpt_reader}: {.val {xpt_reader}}.",
      "i" = "Must be one of: {.val {c(\"haven\", \"internal\")}}."
    ))

  if (!dir.exists(path))
    cli::cli_abort("Directory not found: {.path {path}}.")

  nm_vec <- unname(vapply(rlang::ensyms(...), rlang::as_name, character(1L)))
  if (!length(nm_vec))
    cli::cli_abort("At least one domain name is required.")

  strategy <- getOption("kstools.get_data.case", "error")
  allowed  <- c("error", "first", "lower", "upper")
  if (!is.character(strategy) || length(strategy) != 1L ||
      !strategy %in% allowed)
    cli::cli_abort(c(
      "Invalid {.code kstools.get_data.case}: {.val {strategy}}.",
      "i" = "Must be one of: {.val {allowed}}."
    ))

  ## Candidate extensions for auto-detection; otherwise a single extension.
  auto_exts <- c("rds", "xpt", "xlsx", "csv")
  exts_for_lookup <- if (type == "auto") {
    auto_exts
  } else if (type == "csvks") {
    "csv"
  } else {
    type
  }

  ## Resolve the first domain — this also fixes the file type for auto.
  first_res <- .ks_resolve_domain_file(nm_vec[1L], exts_for_lookup,
                                       path, strategy)

  effective_type <- if (type == "auto") first_res$ext else type

  ## Select reader function based on the effective type.
  read_fn <- switch(
    effective_type,
    rds  = readRDS,
    xpt  = if (xpt_reader == "internal") {
      ks_read_xpt
    } else {
      if (!requireNamespace("haven", quietly = TRUE))
        cli::cli_abort("Package {.pkg haven} is required for XPT loading.")
      haven::read_xpt
    },
    xlsx = {
      if (!requireNamespace("openxlsx2", quietly = TRUE))
        cli::cli_abort("Package {.pkg openxlsx2} is required for XLSX loading.")
      openxlsx2::read_xlsx
    },
    csv   = function(f) read.csv3(f, with_length = FALSE),
    csvks = function(f) read.csv3(f, with_length = TRUE)
  )

  ## Single extension to use for remaining domains (lowercased).
  one_ext <- if (effective_type == "csvks") "csv" else effective_type

  ## Wrap a reader's output: tibbles are normalised; lists (multi-member
  ## XPORT from ks_read_xpt) are returned as-is so the caller can inspect
  ## individual members.
  finalise <- function(x) {
    if (is.data.frame(x)) dplyr::as_tibble(x) else x
  }

  out <- vector("list", length(nm_vec))
  names(out) <- tolower(nm_vec)
  out[[1L]] <- finalise(read_fn(first_res$path))

  if (length(nm_vec) > 1L) {
    for (i in seq.int(2L, length(nm_vec))) {
      res <- .ks_resolve_domain_file(nm_vec[i], one_ext, path, strategy)
      out[[i]] <- finalise(read_fn(res$path))
    }
  }

  if (length(out) == 1L) out[[1L]] else out
}
