#' Remove temporary objects from global environment
#'
#' Removes objects whose names start with \code{t.} or \code{o.} (if \code{o=TRUE}), or only \code{t.} (if \code{o=FALSE}).
#' @param o If \code{TRUE}, remove names matching \code{^[to]\\.}; if \code{FALSE}, only \code{^t\\.}.
#' @name ks_del_tmp
#' @export
ks_del_tmp <- function(o=TRUE) {
  if (o) {
    l <- ls(pattern = "^[to]\\.",envir = .GlobalEnv)
  } else {
    l <- ls(pattern = "^t\\.", envir = .GlobalEnv)
  }
  rm(list=l, envir = .GlobalEnv)
}