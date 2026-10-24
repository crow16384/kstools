#' Compare correlated ROC curve areas (AUC) via Mann-Whitney contrasts
#'
#' R analogue of the classic SAS ROC macro: computes AUC estimates for
#' multiple predictors measured on the same subjects, estimates their
#' covariance matrix using Mann-Whitney components with pairwise deletion,
#' and performs Wald-style tests for user-specified linear contrasts.
#'
#' @param data A data frame containing predictors and the binary response.
#' @param var Character vector of predictor column names.
#' @param response Single character scalar naming the binary response column
#'   coded as 0/1.
#' @param contrast Optional numeric contrast matrix. Columns must match
#'   \code{length(var)}. If \code{NULL} (default), all pairwise contrasts
#'   \code{AUC_i - AUC_j} for \code{i < j} are generated.
#' @param details Logical; if \code{TRUE}, include intermediate matrices
#'   (\code{t}, \code{v}, \code{nx}, \code{ny}, \code{lv}) in output.
#' @param alpha Significance level for two-sided confidence intervals.
#'
#' @return A list with elements:
#' \describe{
#'   \item{areas}{Data frame with AUC, standard error, and confidence bounds.}
#'   \item{contrasts}{Data frame with contrast estimates, SE, CI, chi-square,
#'     and p-value (1 df each row).}
#'   \item{contrast_coefficients}{Contrast matrix used in the analysis.}
#'   \item{overall_test}{Named numeric vector: chi-square, df, p-value for
#'     simultaneous contrast test.}
#'   \item{pvalue}{Overall contrast-test p-value (same as
#'     \code{overall_test[["p_value"]]}).}
#'   \item{details}{Only when \code{details = TRUE}: list of intermediate
#'     matrices \code{t}, \code{v}, \code{nx}, \code{ny}, \code{lv}.}
#' }
#' @name ks_roc
#' @importFrom cli cli_abort
#' @importFrom stats pchisq qnorm
#' @export
ks_roc <- function(data,
                   var,
                   response,
                   contrast = NULL,
                   details = FALSE,
                   alpha = 0.05) {

  if (!is.data.frame(data))
    cli::cli_abort("{.arg data} must be a {.cls data.frame} or {.cls tibble}.")
  if (!is.character(var) || length(var) < 1L)
    cli::cli_abort("{.arg var} must be a non-empty character vector of predictor names.")
  if (!is.character(response) || length(response) != 1L)
    cli::cli_abort("{.arg response} must be a single character column name.")
  if (!all(var %in% names(data)))
    cli::cli_abort("All {.arg var} names must exist in {.arg data}.")
  if (!response %in% names(data))
    cli::cli_abort("{.arg response} must exist in {.arg data}.")
  non_num <- var[!vapply(data[var], function(x) is.numeric(x) || is.logical(x), logical(1))]
  if (length(non_num))
    cli::cli_abort(
      "{.arg var} predictor columns must be numeric: {.val {non_num}}.")
  if (length(alpha) != 1L || is.na(alpha) || alpha <= 0 || alpha >= 1)
    cli::cli_abort("{.arg alpha} must be a single value in (0, 1).")

  y <- data[[response]]
  if (anyNA(y) || any(!(y %in% c(0, 1))))
    cli::cli_abort("{.arg response} must contain only 0/1 values with no missing values.")

  z <- as.matrix(data[, c(var, response), drop = FALSE])
  k <- length(var)

  mwcomp <- function(x, ind) {
    rz <- rank(x, ties.method = "average")
    nx <- sum(ind)
    ny <- length(ind) - nx

    psi <- numeric(length(ind))
    loc_x <- which(ind == 1)
    loc_y <- which(ind == 0)

    psi[loc_x] <- (rz[loc_x] - rank(x[loc_x], ties.method = "average")) / ny
    psi[loc_y] <- (nx + rank(x[loc_y], ties.method = "average") - rz[loc_y]) / nx
    psi
  }

  t_mat <- matrix(0, nrow = k, ncol = k, dimnames = list(var, var))
  v_mat <- matrix(0, nrow = k, ncol = k, dimnames = list(var, var))
  nx_mat <- matrix(0, nrow = k, ncol = k, dimnames = list(var, var))
  ny_mat <- matrix(0, nrow = k, ncol = k, dimnames = list(var, var))
  ind <- z[, k + 1L]

  for (i in seq_len(k)) {
    for (j in seq_len(i)) {
      who <- which(!is.na(z[, i]) & !is.na(z[, j]))
      inow <- ind[who]
      m <- sum(inow)
      n <- length(inow) - m

      if (m < 2L || n < 2L) {
        cli::cli_abort(
          "Each predictor pair must have at least 2 observations per response class after pairwise deletion."
        )
      }

      psii <- mwcomp(z[who, i], inow)
      psij <- mwcomp(z[who, j], inow)

      nx_mat[i, j] <- m
      ny_mat[i, j] <- n
      nx_mat[j, i] <- m
      ny_mat[j, i] <- n

      mi <- sum(psii * inow) / m
      mj <- sum(psij * inow) / m
      t_mat[i, j] <- mi
      t_mat[j, i] <- mj

      psii <- psii - mi
      psij <- psij - mj
      v_ij <- sum(psii * psij * inow) / (m * (m - 1)) +
        sum(psii * psij * (1 - inow)) / (n * (n - 1))

      v_mat[i, j] <- v_ij
      v_mat[j, i] <- v_ij
    }
  }

  manwhit <- diag(t_mat)

  if (is.null(contrast)) {
    if (k == 1L) {
      l_mat <- matrix(1, nrow = 1L, ncol = 1L, dimnames = list("Row1", var))
    } else {
      pairs <- utils::combn(k, 2)
      l_mat <- matrix(0, nrow = ncol(pairs), ncol = k)
      for (r in seq_len(ncol(pairs))) {
        l_mat[r, pairs[1L, r]] <- 1
        l_mat[r, pairs[2L, r]] <- -1
      }
      rownames(l_mat) <- paste0("Row", seq_len(nrow(l_mat)))
      colnames(l_mat) <- var
    }
  } else {
    if (!is.matrix(contrast))
      contrast <- as.matrix(contrast)
    if (!is.numeric(contrast) || ncol(contrast) != k)
      cli::cli_abort("{.arg contrast} must be a numeric matrix with one column per predictor in {.arg var}.")
    l_mat <- contrast
    if (is.null(rownames(l_mat))) rownames(l_mat) <- paste0("Row", seq_len(nrow(l_mat)))
    colnames(l_mat) <- var
  }

  lt <- as.vector(l_mat %*% manwhit)
  lv <- l_mat %*% v_mat %*% t(l_mat)

  lv_ginv <- MASS::ginv(lv)
  chisq <- as.numeric(t(lt) %*% lv_ginv %*% lt)
  df <- as.numeric(sum(diag(lv_ginv %*% lv)))
  p <- 1 - stats::pchisq(chisq, df = df)

  z_alpha <- stats::qnorm(1 - alpha / 2)

  stderr <- sqrt(pmax(diag(v_mat), 0))
  arealcl <- manwhit - z_alpha * stderr
  areaucl <- manwhit + z_alpha * stderr

  area_tab <- data.frame(
    predictor = var,
    roc_area = manwhit,
    std_error = stderr,
    lcl = arealcl,
    ucl = areaucl,
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  sediff <- sqrt(pmax(diag(lv), 0))
  difflcl <- lt - z_alpha * sediff
  diffucl <- lt + z_alpha * sediff
  diffchi <- ifelse(diag(lv) <= 0, NA_real_, (lt^2) / diag(lv))
  diffp <- 1 - stats::pchisq(diffchi, df = 1)

  diff_tab <- data.frame(
    contrast = rownames(l_mat),
    estimate = lt,
    std_error = sediff,
    lcl = difflcl,
    ucl = diffucl,
    chi_square = diffchi,
    p_value = diffp,
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  out <- list(
    areas = area_tab,
    contrasts = diff_tab,
    contrast_coefficients = l_mat,
    overall_test = c(chi_square = chisq, df = df, p_value = p),
    pvalue = p
  )

  if (isTRUE(details)) {
    out$details <- list(
      t = t_mat,
      v = v_mat,
      nx = nx_mat,
      ny = ny_mat,
      lv = lv
    )
  }

  out
}