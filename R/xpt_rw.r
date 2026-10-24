#' Read a SAS XPORT (.xpt) file
#'
#' Reads a SAS XPORT v5 or v8/v9 file using a built-in C++ parser. Variable
#' labels, formats, and informats are preserved as column attributes
#' (`"label"`, `"format.sas"`, `"sas.informat"`). Multi-member files are
#' returned as a named list of tibbles, one per dataset.
#'
#' Date and datetime conversion, when enabled, applies the SAS-to-R epoch
#' shift of 3653 days (315,619,200 seconds) and assigns the appropriate
#' `Date` / `POSIXct` class to columns whose SAS format is recognised as a
#' date or datetime format.
#'
#' @param file Path to a SAS XPORT file.
#' @param convert_dates Logical. If `TRUE` (default), columns formatted as
#'   SAS dates or datetimes are converted to R `Date` / `POSIXct`. If `FALSE`,
#'   such columns are returned as numeric SAS day / second values.
#' @param warn Logical. If `TRUE` (default), parser warnings are emitted via
#'   [cli::cli_warn].
#' @param n_threads Integer or `NULL`. Number of decoder threads to use.
#'   `NULL` (default) selects `max(1, parallel::detectCores() - 1)`. Set to
#'   `1L` for fully deterministic single-threaded decoding.
#'
#' @return A tibble for a single-member file, or a named list of tibbles for
#'   a multi-member file.
#'
#' @seealso [ks_write_xpt()], [ks_xpt_labels()], [ks_xpt_formats()],
#'   [ks_set_labels()], [ks_set_formats()]
#' @export
ks_read_xpt <- function(file, convert_dates = TRUE, warn = TRUE, n_threads = NULL) {
  if (!is.character(file) || length(file) != 1L)
    cli::cli_abort("`file` must be a single string.")
  if (!file.exists(file))
    cli::cli_abort("File does not exist: {.path {file}}")
  if (!is.logical(convert_dates) || length(convert_dates) != 1L)
    cli::cli_abort("`convert_dates` must be a single logical value.")
  if (!is.null(n_threads)) {
    if (!is.numeric(n_threads) || length(n_threads) != 1L || n_threads < 1)
      cli::cli_abort("`n_threads` must be a single positive integer or NULL.")
    n_threads <- as.integer(n_threads)
  }

  res <- .rcpp_read_xpt(path.expand(file), isTRUE(convert_dates), n_threads)

  if (warn && length(res$warnings) > 0L) {
    for (w in res$warnings) {
      if (!grepl("trailing byte", w, fixed = TRUE))
        cli::cli_warn(w)
    }
  }

  if (isTRUE(res$multi_member)) {
    out <- lapply(res$data, tibble::as_tibble)
    names(out) <- names(res$data)
    out
  } else {
    tibble::as_tibble(res$data)
  }
}

#' Write a data frame to a SAS XPORT (.xpt) file
#'
#' Writes a data frame to a SAS XPORT V5 or V8 file using a built-in C++
#' writer. Variable labels and SAS formats are taken from per-column
#' attributes (`"label"`, `"format.sas"`) or the optional `labels` /
#' `formats` arguments, which override attributes.
#'
#' Date and datetime conversion, when enabled, applies the R-to-SAS epoch
#' shift to columns of class `Date` or `POSIXct`.
#'
#' @param data A data frame.
#' @param file Output path.
#' @param version Integer 5 or 8. Default `5L` (widest compatibility).
#' @param convert_dates Logical. If `TRUE` (default), `Date` and `POSIXct`
#'   columns are converted to SAS numeric (days / seconds since 1960-01-01).
#' @param dataset_name SAS dataset name. Up to 8 characters for V5,
#'   up to 32 for V8. Defaults to `"DATASET"`.
#' @param dataset_label Up to 40 characters describing the dataset.
#' @param labels Optional named character vector of variable labels keyed
#'   by column name. Overrides per-column `"label"` attributes.
#' @param formats Optional named character vector of SAS formats
#'   (e.g. `"DATE9."`, `"F8.2"`) keyed by column name. Overrides per-column
#'   `"format.sas"` attributes.
#'
#' @return The output file path, invisibly.
#'
#' @seealso [ks_read_xpt()]
#' @export
ks_write_xpt <- function(data,
                         file,
                         version = 5L,
                         convert_dates = TRUE,
                         dataset_name = NULL,
                         dataset_label = NULL,
                         labels = NULL,
                         formats = NULL) {
  if (!is.data.frame(data))
    cli::cli_abort("`data` must be a data frame.")
  if (!is.character(file) || length(file) != 1L)
    cli::cli_abort("`file` must be a single string.")
  if (length(version) != 1L || !version %in% c(5L, 8L, 5, 8))
    cli::cli_abort("`version` must be 5 or 8.")
  if (!is.logical(convert_dates) || length(convert_dates) != 1L)
    cli::cli_abort("`convert_dates` must be a single logical value.")

  ds_name <- if (is.null(dataset_name)) NULL else as.character(dataset_name)[[1L]]
  ds_label <- if (is.null(dataset_label)) NULL else as.character(dataset_label)[[1L]]

  if (!is.null(ds_name)) {
    max_n <- if (version == 8) 32L else 8L
    if (nchar(ds_name) > max_n) {
      cli::cli_warn("`dataset_name` truncated to {max_n} characters.")
      ds_name <- substr(ds_name, 1L, max_n)
    }
  }
  if (!is.null(ds_label) && nchar(ds_label) > 40L) {
    cli::cli_warn("`dataset_label` truncated to 40 characters.")
    ds_label <- substr(ds_label, 1L, 40L)
  }

  # Coerce input to plain data.frame so Rcpp sees a List with column names
  data <- as.data.frame(data, stringsAsFactors = FALSE)

  ## ---- SAS XPORT interoperability limits (abort, not silent truncation) ----
  ## Variable names: <= 8 bytes (v5) / <= 32 bytes (v8). C++ writer would
  ## silently truncate (rcpp_xpt putFixedField), producing duplicate
  ## variables in the output file — reject loudly instead.
  max_name  <- if (version == 8) 32L else 8L
  max_label <- if (version == 8) 256L else 40L
  bad_name  <- nchar(names(data), type = "bytes") > max_name
  if (any(bad_name))
    cli::cli_abort(
      c("Variable name(s) exceed the XPORT v{version} limit of {max_name} bytes:",
        stats::setNames(paste0("\"", names(data)[bad_name], "\" (",
                         nchar(names(data)[bad_name], type = "bytes"), " bytes)"), "*"),
        "i" = "Rename before writing; SAS transport names must fit {max_name} bytes."))
  lab_chr <- if (is.null(labels))
    vapply(data, function(col) {
      l <- attr(col, "label"); if (is.null(l)) "" else as.character(l)
    }, character(1))
  else labels[names(data)]
  bad_lab <- !is.na(lab_chr) & nchar(lab_chr, type = "bytes") > max_label
  if (any(bad_lab))
    cli::cli_abort(
      c("Column labels exceed the XPORT v{version} limit of {max_label} bytes:",
        stats::setNames(paste0(names(data)[bad_lab], " (",
                         nchar(lab_chr[bad_lab], type = "bytes"), " bytes)"), "*")))
  dup_nm <- names(data)[stats::ave(seq_along(names(data)),
                                   tolower(names(data)), FUN = length) > 1L]
  if (length(dup_nm))
    cli::cli_abort(
      c("Variable names collide case-insensitively (SAS requirement): {.val {unique(tolower(dup_nm))}}.",
        "i" = "Rename columns before writing."))
  ## Character byte length: SAS XPORT engine (v5) refuses values/variables
  ## longer than 200 bytes (SAS Tech Note 1528; xportr validates the same);
  ## v8 hard field cap is 32767.
  max_char <- if (version == 8) 32767L else 200L
  char_len <- vapply(data, function(col) {
      if (is.factor(col))
        col <- as.character(levels(col))
      if (is.character(col))
        max(c(0L, nchar(col[!is.na(col)], type = "bytes")))
      else 0L
    }, numeric(1))
  over <- char_len > max_char
  if (any(over))
    cli::cli_abort(
      c("Columns with character data longer than {max_char} bytes are not transportable at version {version}:",
        stats::setNames(paste0(names(data)[over], " (max ", format(char_len[over], scientific = FALSE),
                         " bytes)"), "*"),
        "i" = if (version == 5)
                 "Use version = 8 (max 32767 bytes) or truncate the data explicitly."
               else
                 "Truncate the data explicitly before writing."))

  dest <- path.expand(file)
  tryCatch(
    .rcpp_write_xpt(data,
                    dest,
                    as.integer(version),
                    isTRUE(convert_dates),
                    ds_name,
                    ds_label,
                    labels,
                    formats),
    error = function(e) {
      ## A failed write leaves a truncated/partial transport file behind;
      ## remove it so downstream steps cannot pick up a corrupt artifact.
      unlink(dest)
      stop(e)
    }
  )
  invisible(file)
}
