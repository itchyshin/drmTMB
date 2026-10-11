# Response-side damage row for check_drm() (#1335, Dinnage audit A-5).
#
# Every other check_drm() row reads the optimizer, the Hessian, or the design.
# None reads the response, so a frame with a sentinel code (-9999, -5, 999)
# left in `y` returns a clean board even though the scale submodel has bent to
# absorb it. Under the fitted family, quantile residuals are N(0, 1), so the
# number beyond |3| is Binomial(n, 2 * pnorm(-3)). A count that is improbable
# under that law is a data or family problem the user must see before reading
# sigma (or any shape) coefficients.
#
# The quantile residuals use a fixed seed so the row is reproducible for
# discrete and atom families; drm_dunn_smyth_u() restores the caller's RNG
# state. A fit for which quantile residuals are not available (an unsupported
# model type or a residual path that errors) gets no row.
DRM_RESPONSE_OUTLIER_Z <- 3
DRM_RESPONSE_OUTLIER_ALPHA <- 1e-4

check_response_residual_outliers <- function(
  object,
  z = DRM_RESPONSE_OUTLIER_Z,
  alpha = DRM_RESPONSE_OUTLIER_ALPHA
) {
  residuals <- tryCatch(
    suppressWarnings(drm_quantile_residuals(object, seed = 1L)),
    error = function(e) NULL
  )
  if (is.null(residuals)) {
    return(NULL)
  }
  residuals <- as.numeric(residuals)
  residuals <- residuals[!is.na(residuals)]
  n <- length(residuals)
  if (n == 0L) {
    return(NULL)
  }
  n_beyond <- sum(abs(residuals) > z)
  p_beyond <- 2 * stats::pnorm(-z)
  expected <- n * p_beyond
  p_upper <- stats::pbinom(n_beyond - 1L, n, p_beyond, lower.tail = FALSE)
  flagged <- p_upper < alpha
  check_row(
    "response_residual_outliers",
    if (flagged) "warning" else "ok",
    paste0(
      "n=", n,
      "; n_beyond_", format(z), "=", n_beyond,
      "; expected=", format_check_number(expected),
      "; p_upper=", format_check_number(p_upper),
      "; max_abs=", format_check_number(max(abs(residuals)))
    ),
    if (flagged) {
      paste0(
        n_beyond, " of ", n, " quantile residuals lie beyond |", format(z),
        "| (about ", format_check_number(expected), " expected under the ",
        "fitted family). Check the response for sentinel codes such as ",
        "-9999, unit errors, or data-entry errors, or consider a ",
        "heavier-tailed family. Scale and shape coefficients are distorted ",
        "first, even when the mean coefficients still look reasonable."
      )
    } else {
      paste0(
        "The number of quantile residuals beyond |", format(z), "| is ",
        "consistent with the fitted family."
      )
    }
  )
}
