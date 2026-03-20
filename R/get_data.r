#' Load RDS domain files into the global environment
#'
#' Reads one or more \code{.rds} files from \code{path} and assigns them to
#' variables in \code{.GlobalEnv} using the file stem (name without \code{.rds})
#' as the variable name.
#'
#' @details
#' Domain names can be passed as bare names (\code{dm, ae}) or as quoted
#' strings (\code{"dm", "ae"}); both forms are accepted.
#'
#' The default search path is read from
#' \code{getOption("path.data.rds", ".")}. Set this option in
#' \code{.Rprofile} to avoid repeating the path in every call:
#' \preformatted{options(path.data.rds = "/my/project/data/rds")}
#'
#' @param ... Unquoted (or quoted) domain names, e.g. \code{dm, ae, lb}.
#' @param path Directory containing the \code{.rds} files.
#'   Defaults to \code{getOption("path.data.rds", ".")}.
#' @return Invisibly returns the character vector of loaded domain names.
#' @seealso \code{\link{ks_batch_load}}
#' @examples
#' \dontrun{
#' ## Load dm and ae from the default path set via options()
#' options(path.data.rds = "/project/data/rds")
#' ks_get_data(dm, ae)
#'
#' ## Load from an explicit path
#' ks_get_data(dm, ae, lb, path = "/project/data/rds")
#'
#' ## Quoted strings are also accepted
#' ks_get_data("dm", "ae", path = "/project/data/rds")
#' }
#' @name ks_get_data
#' @importFrom rlang ensyms as_name
#' @export
ks_get_data <- function(..., path = getOption("path.data.rds", ".")) {

  if (!dir.exists(path))
    stop("Directory not found: ", path)

  nm_vec <- unname(vapply(rlang::ensyms(...), rlang::as_name, character(1L)))

  for (nm in nm_vec) {
    fp <- file.path(path, paste0(nm, ".rds"))
    if (!file.exists(fp))
      stop("File not found: ", fp)
    assign(nm, readRDS(fp), envir = .GlobalEnv)
  }

  invisible(nm_vec)
}
