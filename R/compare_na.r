#' NA-aware element-wise comparison
#'
#' Element-wise `==` returns `NA` whenever either side is missing, which makes
#' it unusable for comparing vectors that legitimately contain `NA`.
#' `ks_compare_na()` treats `NA` as an ordinary value, so two missing entries
#' at the same position are considered **equal** — the R twin of SAS's `NULL=`
#' comparison operators.
#'
#' @param x,y Vectors compared element by element; the shorter is recycled.
#'   Works for numeric, character, and factor vectors (levels need not match).
#' @return A logical vector with the common recycled length, never `NA`.
#' @seealso \code{\link{ks_sum_na}} for NA-aware arithmetic.
#' @examples
#' ks_compare_na(c(NA, "A", "B"), c(NA, "A", "C"))
#' ks_compare_na(c(1, NA, 3), c(1, 2, NA))
#' @name ks_compare_na
#' @export
ks_compare_na <- function(x, y) {
  same <- (x == y) | (is.na(x) & is.na(y))
  same[is.na(same)] <- FALSE
  same
}
