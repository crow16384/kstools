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
    if (!grepl("^#", line) || length(line) == 0) break
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


#' Load domain files into the global environment
#'
#' Reads one or more data files from \code{path} and assigns them to
#' variables in \code{.GlobalEnv} using the file stem (name without extension)
#' as the variable name.
#'
#' Supported formats: \code{.rds} (R native), \code{.xpt} (SAS XPORT),
#' \code{.xlsx} (Microsoft Excel), \code{.csv} (plain CSV),
#' \code{.csv} with KeyStat comments (\code{type = "csvks"}).
#'
#' @details
#' Domain names can be passed as bare names (\code{dm, ae}) or as quoted
#' strings (\code{"dm", "ae"}); both forms are accepted.
#'
#' When \code{type = "auto"} (default), the function scans the directory for
#' files matching the requested domains and determines the format from the
#' extension of the first match.  All requested domains must use the same
#' format.
#'
#' The default search path is read from
#' \code{getOption("path.data", ".")}. Set this option in
#' \code{.Rprofile} to avoid repeating the path in every call:
#' \preformatted{options(path.data = "/my/project/data")}
#'
#' @param ... Unquoted (or quoted) domain names, e.g. \code{dm, ae, lb}.
#' @param path Directory containing the data files.
#'   Defaults to \code{getOption("path.data", ".")}.
#' @param type File type: \code{"auto"} (detect from extension), \code{"rds"},
#'   \code{"xpt"}, \code{"xlsx"}, \code{"csv"}, or \code{"csvks"}
#'   (CSV with KeyStat comment metadata).
#' @return Invisibly returns the character vector of loaded domain names.
#' @seealso \code{\link{ks_batch_load}}, \code{\link{read.csv3}}
#' @examples
#' \dontrun{
#' ## Load dm and ae from the default path set via options()
#' options(path.data = "/project/data")
#' ks_get_data(dm, ae)
#'
#' ## Load from an explicit path (auto-detects file type)
#' ks_get_data(dm, ae, lb, path = "/project/data/xpt")
#'
#' ## Force a specific file type
#' ks_get_data(dm, ae, path = "/project/data", type = "xpt")
#'
#' ## Load CSV files with KeyStat comment headers
#' ks_get_data(dm, ae, path = "/project/data", type = "csvks")
#'
#' ## Quoted strings are also accepted
#' ks_get_data("dm", "ae", path = "/project/data")
#' }
#' @name ks_get_data
#' @importFrom rlang ensyms as_name
#' @importFrom utils read.csv
#' @export
ks_get_data <- function(...,
                        path = getOption("path.data", "."),
                        type = c("auto", "rds", "xpt", "xlsx",
                                 "csv", "csvks")) {

  type <- match.arg(type)

  if (!dir.exists(path))
    stop("Directory not found: ", path)

  nm_vec <- unname(vapply(rlang::ensyms(...), rlang::as_name, character(1L)))

  ## Auto-detect file type from first domain
  if (type == "auto") {
    first <- nm_vec[1L]
    candidates <- c(
      rds  = file.path(path, paste0(first, ".rds")),
      xpt  = file.path(path, paste0(first, ".xpt")),
      xlsx = file.path(path, paste0(first, ".xlsx")),
      csv  = file.path(path, paste0(first, ".csv"))
    )
    found <- vapply(candidates, file.exists, logical(1L))
    if (!any(found))
      stop("No file found for domain '", first, "' in: ", path,
           "\n  Checked: ", paste(basename(candidates), collapse = ", "))
    type <- names(candidates)[which(found)[1L]]
  }

  ## Map type to file extension (csvks uses .csv files)
  ext <- if (type == "csvks") ".csv" else paste0(".", type)

  ## Select reader function
  read_fn <- switch(
    type,
    rds  = readRDS,
    xpt  = {
      if (!requireNamespace("haven", quietly = TRUE))
        stop("package 'haven' is required for XPT loading")
      haven::read_xpt
    },
    xlsx = {
      if (!requireNamespace("openxlsx", quietly = TRUE))
        stop("package 'openxlsx' is required for XLSX loading")
      openxlsx::read.xlsx
    },
    csv   = function(f) read.csv3(f, with_length = FALSE),
    csvks = function(f) read.csv3(f, with_length = TRUE)
  )

  for (nm in nm_vec) {
    fp <- file.path(path, paste0(nm, ext))
    if (!file.exists(fp))
      stop("File not found: ", fp)
    assign(nm, read_fn(fp), envir = .GlobalEnv)
  }

  invisible(nm_vec)
}
