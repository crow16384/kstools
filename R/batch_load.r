#' Batch load files from a directory or ZIP
#'
#' Loads all files of one type from a directory (or \code{.zip}) in batch.
#' Supported types are \code{csv}, \code{xlsx}, \code{xpt}, and \code{rds}.
#' Results can be returned as a named list, assigned to \code{.GlobalEnv},
#' saved as individual \code{.rds}, and/or saved as one \code{.RData}.
#' @param data Path to a directory or a \code{.zip} file.
#' @param type One of \code{"csv"}, \code{"xlsx"}, \code{"xpt"}, \code{"rds"}.
#' @param save.path Optional directory where loaded objects are saved as \code{.rds}.
#' @param keep If \code{TRUE}, assign loaded objects into \code{.GlobalEnv}.
#' @param save.rdata Optional path to a \code{.RData} file.
#' @param with_length Passed to \code{foreign::read.csv3} for CSV loading.
#' @param recursive If \code{TRUE}, search recursively under \code{data}.
#' @return Named list of loaded objects.
#' @importFrom utils unzip getFromNamespace
#' @name ks_batch_load
#' @export
ks_batch_load <- function(data,
                          type = c("csv", "xlsx", "xpt", "rds"),
                          save.path = NULL,
                          keep = FALSE,
                          save.rdata = NULL,
                          with_length = FALSE,
                          recursive = FALSE) {
  type <- match.arg(type)

  if (!requireNamespace("parallel", quietly = TRUE)) {
    stop("package 'parallel' is required")
  }

  is_zip <- endsWith(tolower(data), ".zip")
  cleanup_dir <- NULL

  if (is_zip) {
    cleanup_dir <- tempfile("ks_batch_load_")
    dir.create(cleanup_dir, recursive = TRUE, showWarnings = FALSE)
    unzip(data, exdir = cleanup_dir, junkpaths = TRUE)
    t.dir <- cleanup_dir
  } else {
    t.dir <- data
  }
  on.exit({
    if (!is.null(cleanup_dir) && dir.exists(cleanup_dir)) {
      unlink(cleanup_dir, recursive = TRUE)
    }
  }, add = TRUE)

  ext <- switch(type,
                csv = "csv",
                xlsx = "xlsx",
                xpt = "xpt",
                rds = "rds")

  files <- list.files(
    t.dir,
    pattern = paste0("\\.", ext, "$"),
    full.names = TRUE,
    recursive = recursive,
    ignore.case = TRUE
  )

  if (length(files) == 0L) {
    stop("No '", ext, "' files found in: ", t.dir)
  }

  nm <- tolower(tools::file_path_sans_ext(basename(files)))
  nm <- make.unique(nm, sep = "_")

  load_one <- switch(
    type,
    csv = function(path) {
      has_csv3 <- requireNamespace("foreign", quietly = TRUE) &&
        exists("read.csv3", envir = asNamespace("foreign"), mode = "function", inherits = FALSE)
      if (has_csv3) {
        getFromNamespace("read.csv3", "foreign")(path, with_length = with_length)
      } else {
        utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
      }
    },
    xlsx = function(path) {
      if (!requireNamespace("openxlsx2", quietly = TRUE)) {
        stop("package 'openxlsx2' is required for xlsx loading")
      }
      openxlsx2::read_xlsx(path)
    },
    xpt = function(path) {
      if (!requireNamespace("haven", quietly = TRUE)) {
        stop("package 'haven' is required for xpt loading")
      }
      haven::read_xpt(path)
    },
    rds = function(path) {
      readRDS(path)
    }
  )

  num_cores <- max(1L, parallel::detectCores())
  if (.Platform$OS.type == "windows") {
    res <- lapply(files, load_one)
  } else {
    res <- parallel::mclapply(
      files,
      load_one,
      mc.silent = TRUE,
      mc.cores = num_cores,
      mc.cleanup = TRUE
    )
  }
  names(res) <- nm

  if (!is.null(save.path)) {
    dir.create(save.path, recursive = TRUE, showWarnings = FALSE)
    mapply(
      function(obj, name) {
        saveRDS(obj, file = file.path(save.path, paste0(name, ".rds")))
        invisible(NULL)
      },
      res,
      names(res)
    )
  }

  if (keep) {
    mapply(
      function(obj, name) {
        assign(name, obj, envir = .GlobalEnv)
        invisible(NULL)
      },
      res,
      names(res)
    )
  }

  if (!is.null(save.rdata)) {
    added_to_global <- setdiff(names(res), ls(envir = .GlobalEnv, all.names = TRUE))
    list2env(res, envir = .GlobalEnv)
    save(list = names(res), file = save.rdata, compress = "xz")
    if (!keep && length(added_to_global) > 0L) {
      rm(list = added_to_global, envir = .GlobalEnv)
    }
  }

  res
}

#' Backwards-compatible wrapper for \code{ks_batch_load} with \code{type = "xlsx"}
#'
#' Calls \code{\link{ks_batch_load}} with \code{type = "xlsx"}.  Provided for
#' compatibility with older scripts that used the xlsx-specific function name.
#' @inheritParams ks_batch_load
#' @return Named list of loaded objects (see \code{\link{ks_batch_load}}).
#' @seealso \code{\link{ks_batch_load}}
#' @name ks_batch_load_xlsx
#' @export
ks_batch_load_xlsx <- function(data,
                                save.path  = NULL,
                                keep       = FALSE,
                                save.rdata = NULL,
                                recursive  = FALSE) {
  ks_batch_load(
    data       = data,
    type       = "xlsx",
    save.path  = save.path,
    keep       = keep,
    save.rdata = save.rdata,
    recursive  = recursive
  )
}
