## -- SAS XPORT v8/v9 multi-member file utilities -----------------------------
##
## SAS Transport Version 8 (XPORT v8) allows long variable names (> 8 chars)
## and can store multiple datasets (members) in a single file.
## The standard haven::read_xpt() cannot directly read individual members
## from such files; these utilities handle the low-level byte slicing.
##
## File structure (each record = 80 bytes):
##   File header  : LIBV8  marker + library info + blank      (3 x 80 = 240 B)
##   Per member   : MEMBV8 marker + descriptor + name record  (>= 3 x 80 = 240 B)
##                  followed by variable descriptors and data records
##
## Byte-position convention used throughout:
##   Positions stored in ks_xpt_content() are 1-based file positions
##   (matching grepRaw() output).  haven-facing seek() calls subtract 1
##   to convert to the 0-based offset required by seek().


## XPORT v8 magic strings
.XPT_LIBV8_HDR  <- "HEADER RECORD*******LIBV8   HEADER RECORD!!!!!!!"
.XPT_MEMBV8_HDR <- "HEADER RECORD*******MEMBV8  HEADER RECORD!!!!!!!"

## Byte offset from the start of a MEMBV8 record to the dataset name field
## (8 bytes padding + 32-char name, inside the 3rd 80-byte record of the block)
.XPT_NAME_OFFSET <- 168L
.XPT_NAME_END    <- 199L


#' List datasets inside a SAS XPORT v8/v9 file
#'
#' Scans the raw bytes of a SAS Transport Version 8 file for member
#' (\code{MEMBV8}) headers and returns the byte range of each member.
#'
#' @details
#' The file is read in chunks of \code{chunk_size} bytes (default approximately 400 KB).
#' A \code{MEMBV8} header that spans two adjacent chunks would not be detected;
#' this is exceedingly unlikely for practical SDTM files.
#'
#' @param file Path to a \code{.xpt} or \code{.v9xpt} file.
#' @param chunk_size Number of raw bytes to read per pass. Default \code{5 * 80 * 1024}.
#' @return A named list; each element corresponds to one dataset and contains
#'   a named integer vector \code{c(start = <1-based pos>, stop = <1-based pos>)}.
#' @seealso \code{\link{ks_extract_single_xpt}},
#'   \code{\link{ks_batch_load_from_single_xpt}}
#' @examples
#' \dontrun{
#' ## content <- ks_xpt_content("path/to/study.xpt")
#' ## names(content)          # dataset names (lower-case)
#' ## content[["ae"]]         # byte range for the AE member
#' }
#' @name ks_xpt_content
#' @importFrom cli cli_abort
#' @export
ks_xpt_content <- function(file, chunk_size = 5L * 80L * 1024L) {

  if (!file.exists(file))
    cli::cli_abort("File not found: {.path {file}}.")

  file_size <- file.size(file)

  con <- file(file, "rb")
  on.exit(close(con))

  ## Validate the file-level LIBV8 header (first 80 bytes)
  first_rec <- readBin(con, "raw", 80L)
  idx_lib   <- grepRaw(.XPT_LIBV8_HDR, first_rec, fixed = TRUE, all = FALSE)

  if (length(idx_lib) == 0L || idx_lib[1L] != 1L)
    cli::cli_abort("{.path {file}} does not appear to be a SAS XPORT v8 file.")

  ## Scan for MEMBV8 member headers
  pos       <- 0L
  idxs      <- integer(0L)
  ds_names  <- character(0L)

  while (pos < file_size) {
    seek(con, pos)
    data   <- readBin(con, "raw", chunk_size)
    n_read <- length(data)
    if (n_read == 0L) break

    hits <- grepRaw(.XPT_MEMBV8_HDR, data, fixed = TRUE, all = TRUE)

    if (length(hits) > 0L) {
      ## Extract the 32-byte dataset name field
      ## Name sits at offset .XPT_NAME_OFFSET within the MEMBV8 block
      names_raw <- vapply(hits, function(x) {
        end <- x + .XPT_NAME_END
        if (end > n_read) return(NA_character_)     # header spans chunk boundary
        trimws(rawToChar(data[(x + .XPT_NAME_OFFSET):(x + .XPT_NAME_END)]))
      }, character(1L))

      valid      <- !is.na(names_raw)
      idxs       <- c(idxs,     pos + hits[valid])
      ds_names   <- c(ds_names, names_raw[valid])
    }

    pos <- pos + n_read
  }

  if (length(idxs) == 0L)
    cli::cli_abort("No MEMBV8 member headers found in: {.path {file}}.")

  ds_names <- tolower(ds_names)
  ## stops use an exclusive upper bound: next member's start, or file_size + 1
  ## This ensures stop - start always equals the exact byte count to read.
  stops    <- c(idxs[-1L], file_size + 1L)

  rv         <- Map(function(st, sp) c(start = st, stop = sp), idxs, stops)
  names(rv)  <- ds_names
  rv
}


#' Extract one dataset from a multi-member SAS XPORT v8/v9 file
#'
#' Reads a single member from the file by splicing the file-level header
#' bytes onto the member's raw bytes, then passing the combined buffer to
#' \code{\link[haven]{read_xpt}}.
#'
#' @details
#' A valid XPORT stream requires both the 240-byte file header (three 80-byte
#' LIBV8 records) and the member data.  This function prepends the file header
#' so that \code{haven::read_xpt} can parse the member in isolation.
#'
#' @param name Character name of the member to read (must match a name in
#'   \code{content}, i.e. lower-case).
#' @param file Path to the XPORT file.
#' @param content Named list returned by \code{\link{ks_xpt_content}(file)}.
#' @return A \code{\link[tibble]{tibble}} (as returned by
#'   \code{\link[haven]{read_xpt}}).
#' @seealso \code{\link{ks_xpt_content}},
#'   \code{\link{ks_batch_load_from_single_xpt}}
#' @examples
#' \dontrun{
#' content <- ks_xpt_content("study.xpt")
#' ae      <- ks_extract_single_xpt("ae", "study.xpt", content)
#' }
#' @name ks_extract_single_xpt
#' @importFrom cli cli_abort
#' @export
ks_extract_single_xpt <- function(name, file, content) {

  if (!requireNamespace("haven", quietly = TRUE))
    cli::cli_abort("Package {.pkg haven} is required -- install it with {.code install.packages('haven')}.")

  if (!name %in% names(content))
    cli::cli_abort("Member {.val {name}} not found in content. Available: {.val {names(content)}}.")

  range <- content[[name]]

  con <- file(file, "rb")
  on.exit(close(con))

  ## File-level header: first 240 bytes (3 x 80-byte LIBV8 records)
  header <- readBin(con, "raw", 240L)

  ## Member data: from start of MEMBV8 block to the next member (or EOF)
  ## Stored positions are 1-based; seek() is 0-based -> subtract 1
  seek(con, range[["start"]] - 1L)
  member_data <- readBin(con, "raw", range[["stop"]] - range[["start"]])

  haven::read_xpt(c(header, member_data))
}


#' Load or save all datasets from a multi-member SAS XPORT v8/v9 file
#'
#' Iterates all members found by \code{\link{ks_xpt_content}} and either
#' assigns them into \code{.GlobalEnv} or writes them to disk.
#'
#' @details
#' \describe{
#'   \item{\code{action = "load"}}{Each dataset is assigned into
#'     \code{.GlobalEnv} using its lower-case member name.}
#'   \item{\code{action = "save", save_type = "rdata"}}{All datasets are
#'     saved together into a single \code{.RData} file at \code{save_path}
#'     (the \code{.RData} extension is appended automatically).  The global
#'     environment is \emph{not} modified.}
#'   \item{\code{action = "save", save_type = "rds"}}{Each dataset is saved
#'     as a separate \code{.rds} file inside the \code{save_path} directory.}
#'   \item{\code{action = "save", save_type = "parquet"}}{Each dataset is
#'     saved as a separate Parquet file (requires the \pkg{arrow} package).}
#' }
#'
#' Members are extracted in parallel on non-Windows platforms
#' (\code{\link[parallel]{mclapply}}); \code{\link[base]{lapply}} is used
#' on Windows.
#'
#' @param file Path to the XPORT file.
#' @param action \code{"load"} (assign to \code{.GlobalEnv}) or
#'   \code{"save"} (write to disk).
#' @param save_type For \code{action = "save"}: one of \code{"rdata"},
#'   \code{"rds"}, or \code{"parquet"}.
#' @param save_path For \code{action = "save"}:
#'   \itemize{
#'     \item \code{"rdata"}: path \emph{without} extension (appended automatically).
#'     \item \code{"rds"} / \code{"parquet"}: path to an existing \emph{directory}.
#'   }
#' @return Invisibly returns a named list of all extracted datasets.
#' @seealso \code{\link{ks_xpt_content}}, \code{\link{ks_extract_single_xpt}}
#' @examples
#' \dontrun{
#' ## Load all members into .GlobalEnv
#' ks_batch_load_from_single_xpt("study.xpt", action = "load")
#'
#' ## Save each member as .rds
#' ks_batch_load_from_single_xpt("study.xpt",
#'                                action    = "save",
#'                                save_type = "rds",
#'                                save_path = "data/")
#' }
#' @name ks_batch_load_from_single_xpt
#' @importFrom cli cli_abort
#' @export
ks_batch_load_from_single_xpt <- function(file,
                                           action    = "load",
                                           save_type = NULL,
                                           save_path = NULL) {

  action <- match.arg(action, c("load", "save"))

  if (action == "save") {
    if (is.null(save_type))
      cli::cli_abort(c(
        "{.arg save_type} must be specified when {.code action = 'save'}.",
        "i" = "Choose one of: {.val rdata}, {.val rds}, {.val parquet}."
      ))
    save_type <- match.arg(save_type, c("rdata", "rds", "parquet"))

    if (is.null(save_path))
      cli::cli_abort("{.arg save_path} must be provided when {.code action = 'save'}.")

    if (save_type == "rdata") {
      info <- file.info(save_path)
      if (!is.na(info$isdir) && isTRUE(info$isdir))
        cli::cli_abort("For {.code save_type = 'rdata'}, {.arg save_path} must be a file path, not a directory.")
    }

    if (save_type %in% c("rds", "parquet")) {
      info <- file.info(save_path)
      if (!is.na(info$isdir) && !isTRUE(info$isdir))
        cli::cli_abort("For {.code save_type = 'rds'} or {.code 'parquet'}, {.arg save_path} must be a directory.")
    }

    if (save_type == "parquet" && !requireNamespace("arrow", quietly = TRUE))
      cli::cli_abort("Package {.pkg arrow} is required for parquet export -- install it with {.code install.packages('arrow')}.")
  }

  cont    <- ks_xpt_content(file)
  tnames  <- names(cont)

  ## Extract members -- parallel on non-Windows, sequential on Windows
  num_cores <- max(1L, parallel::detectCores(logical = FALSE))

  res <- if (.Platform$OS.type == "windows") {
    lapply(tnames, ks_extract_single_xpt, file = file, content = cont)
  } else {
    parallel::mclapply(tnames, ks_extract_single_xpt,
                       file       = file,
                       content    = cont,
                       mc.silent  = TRUE,
                       mc.cores   = num_cores,
                       mc.cleanup = TRUE)
  }

  names(res) <- tnames

  ## -- Side effects ------------------------------------------------------
  if (action == "load") {
    for (nm in tnames)
      assign(nm, res[[nm]], envir = .GlobalEnv)

  } else if (save_type == "rdata") {
    ## Write via a temporary environment -- does not touch .GlobalEnv
    save_env <- new.env(parent = emptyenv())
    for (nm in tnames) assign(nm, res[[nm]], envir = save_env)
    out_file <- paste0(save_path, ".RData")
    save(list = tnames, file = out_file, envir = save_env, compress = "xz")

  } else if (save_type == "rds") {
    dir.create(save_path, recursive = TRUE, showWarnings = FALSE)
    for (nm in tnames)
      saveRDS(res[[nm]], file.path(save_path, paste0(nm, ".rds")))

  } else if (save_type == "parquet") {
    dir.create(save_path, recursive = TRUE, showWarnings = FALSE)
    for (nm in tnames)
      arrow::write_parquet(res[[nm]], file.path(save_path, paste0(nm, ".parquet")))
  }

  invisible(stats::setNames(res, tnames))
}
