#' Build paired bivariate sampling covariance
#'
#' `meta_vcov_bivariate()` builds a dense row-paired sampling covariance matrix
#' for bivariate meta-analysis. It is a convenience helper for constructing the
#' known `V` matrix used by [meta_known_V()] in complete-row bivariate Gaussian
#' meta-analysis.
#'
#' The returned matrix uses row-paired stacking:
#' `y1[1], y2[1], y1[2], y2[2], ..., y1[n], y2[n]`. Each study contributes
#' one `2` by `2` block with diagonal entries `v1[i]` and `v2[i]` and
#' off-diagonal entries `cov12[i]`. If `cor12` is supplied, the covariance is
#' computed as `cor12 * sqrt(v1 * v2)`.
#'
#' In a bivariate Gaussian fit, this known sampling covariance is added to the
#' fitted residual covariance from `sigma1`, `sigma2`, and `rho12`. The fitted
#' `rho12` therefore remains the residual covariance component after accounting
#' for known within-study sampling covariance. A separate study-level random
#' effect would be needed to label a correlation as a study-level correlation.
#'
#' @param v1,v2 Numeric vectors of known sampling variances for response 1 and
#'   response 2.
#' @param cov12 Optional known sampling covariance between the two response
#'   estimates within each study. May be length one or the same length as
#'   `v1`.
#' @param cor12 Optional known sampling correlation between the two response
#'   estimates within each study. May be length one or the same length as
#'   `v1`. Supply at most one of `cov12` and `cor12`.
#'
#' @return A dense `2 * length(v1)` by `2 * length(v1)` covariance matrix with
#'   class `"drm_meta_vcov_bivariate"`.
#' @export
#'
#' @examples
#' V <- meta_vcov_bivariate(
#'   v1 = c(0.04, 0.03),
#'   v2 = c(0.05, 0.02),
#'   cor12 = c(0.4, 0.2)
#' )
#' dim(V)
meta_vcov_bivariate <- function(v1, v2, cov12 = NULL, cor12 = NULL) {
  v1 <- validate_meta_variance_vector(v1, "v1")
  v2 <- validate_meta_variance_vector(v2, "v2")

  if (length(v1) != length(v2)) {
    cli::cli_abort("{.arg v1} and {.arg v2} must have the same length.")
  }
  n <- length(v1)
  if (n == 0L) {
    cli::cli_abort("{.arg v1} and {.arg v2} must contain at least one study.")
  }

  if (!is.null(cov12) && !is.null(cor12)) {
    cli::cli_abort("Supply only one of {.arg cov12} or {.arg cor12}.")
  }

  if (is.null(cov12) && is.null(cor12)) {
    cov12 <- rep(0, n)
  } else if (!is.null(cor12)) {
    cor12 <- validate_meta_pair_vector(cor12, "cor12", n)
    if (any(abs(cor12) > 1)) {
      cli::cli_abort("{.arg cor12} must lie between -1 and 1.")
    }
    cov12 <- cor12 * sqrt(v1 * v2)
  } else {
    cov12 <- validate_meta_pair_vector(cov12, "cov12", n)
  }

  max_cov <- sqrt(v1 * v2)
  tolerance <- sqrt(.Machine$double.eps)
  if (any(abs(cov12) - max_cov > tolerance)) {
    cli::cli_abort(c(
      "Each bivariate sampling covariance block must be positive semidefinite.",
      "x" = "{.arg cov12} must satisfy {.code abs(cov12) <= sqrt(v1 * v2)} for every study."
    ))
  }

  out <- matrix(0, nrow = 2L * n, ncol = 2L * n)
  i1 <- seq.int(1L, by = 2L, length.out = n)
  i2 <- i1 + 1L

  out[cbind(i1, i1)] <- v1
  out[cbind(i2, i2)] <- v2
  out[cbind(i1, i2)] <- cov12
  out[cbind(i2, i1)] <- cov12

  pair_names <- names(v1)
  if (is.null(pair_names)) {
    pair_names <- names(v2)
  }
  if (!is.null(pair_names) && length(pair_names) == n && all(nzchar(pair_names))) {
    dimnames(out) <- list(
      as.vector(rbind(paste0(pair_names, ":y1"), paste0(pair_names, ":y2"))),
      as.vector(rbind(paste0(pair_names, ":y1"), paste0(pair_names, ":y2")))
    )
  }

  structure(out, class = c("drm_meta_vcov_bivariate", "matrix"))
}

validate_meta_variance_vector <- function(x, name) {
  if (!is.numeric(x) || is.matrix(x) || is.array(x)) {
    cli::cli_abort("{.arg {name}} must be a numeric vector of known sampling variances.")
  }
  if (any(!is.finite(x) | is.na(x))) {
    cli::cli_abort("{.arg {name}} must contain only finite values.")
  }
  if (any(x < 0)) {
    cli::cli_abort("{.arg {name}} must contain non-negative known sampling variances.")
  }
  out <- as.numeric(x)
  names(out) <- names(x)
  out
}

validate_meta_pair_vector <- function(x, name, n) {
  if (!is.numeric(x) || is.matrix(x) || is.array(x)) {
    cli::cli_abort("{.arg {name}} must be a numeric vector.")
  }
  if (!(length(x) %in% c(1L, n))) {
    cli::cli_abort("{.arg {name}} must have length 1 or the same length as {.arg v1}.")
  }
  if (any(!is.finite(x) | is.na(x))) {
    cli::cli_abort("{.arg {name}} must contain only finite values.")
  }
  rep(as.numeric(x), length.out = n)
}
