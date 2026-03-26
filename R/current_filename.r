#' Get the filename of the currently executing R script
#'
#' Determines the filename of the currently executing R script by checking
#' two sources in order:
#'
#' \enumerate{
#'   \item \strong{source() call} — inspects the call stack for the closest
#'     \code{source()} frame and reads its \code{filename} environment variable.
#'   \item \strong{CLI argument} — inspects the command-line arguments for a
#'     \code{-f} or \code{--file=} flag (as used by \code{Rscript foo.R} or
#'     \code{R --slave -f foo.R}).
#' }
#'
#' Only the \code{\link[base]{basename}} of the resolved path is returned.
#'
#' @return A character string with the base name of the current script.
#'   Returns an empty string (\code{""}) if the filename cannot be determined
#'   from either source (e.g. when running interactively in the R console).
#'
#' @seealso \code{\link[base]{basename}}, \code{\link[base]{source}},
#'   \code{\link[base]{commandArgs}}
#'
#' @examples
#' \dontrun{
#' # Inside a sourced file or a script run with Rscript:
#' ks_current_filename()
#' #> "my_script.R"
#'
#' # In an interactive session where no script name is available:
#' ks_current_filename()
#' #> ""
#' }
#' @name ks_current_filename
#' @importFrom rlang call_name
#' @export
ks_current_filename <- function() {

  .get_stack <- function() {
    stack <- sys.calls()
    envs  <- sys.frames()
    stack <- rev(stack[-length(stack)])
    envs  <- rev(envs[-length(envs)])
    if (length(stack) == 0L) return(NULL)
    Map(
      function(call, env) list(fn_name = rlang::call_name(call), env = env),
      stack, envs
    )
  }

  .closest_source_frame <- function() {
    Find(
      function(f) !is.null(f$fn_name) && f$fn_name == "source",
      .get_stack()
    )
  }

  .current_source_filename <- function() {
    frame <- .closest_source_frame()
    if (is.null(frame)) NULL else frame$env$filename
  }

  .current_cli_filename <- function() {
    args <- rev(commandArgs(FALSE))
    file_index <- grep("^(--file=|-f$)", args)[1L]
    if (is.na(file_index)) {
      NULL
    } else if (args[file_index] == "-f") {
      args[file_index - 1L]
    } else {
      sub("^--file=", "", args[file_index])
    }
  }

  src <- .current_source_filename()
  if (!is.null(src)) return(basename(src))
  cli <- .current_cli_filename()
  if (!is.null(cli)) return(basename(cli))
  ""
}
