test_that("qq_plot() warns when non-finite quantile residuals are dropped (#1460)", {
  drmTMB:::drm_reset_adequacy_warning_state()
  set.seed(2026111801L)
  n <- 40L
  dat <- data.frame(
    y = stats::rnorm(n, 2, 0.4),
    x = stats::rnorm(n)
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  z <- drmTMB:::drm_quantile_residuals(fit)
  z[1L] <- Inf
  z[2L] <- -Inf
  mock <- function(object, seed = NULL, nsim = 1L, response = NULL) {
    zmat <- matrix(z, ncol = 1L)
    cols <- lapply(seq_len(ncol(zmat)), function(j) {
      finite <- is.finite(zmat[, j])
      if (any(!finite)) {
        drmTMB:::drm_warn_adequacy_nonfinite_quantile(
          sum(!finite),
          length(finite),
          object$model$model_type
        )
      }
      zz <- sort(zmat[finite, j])
      m <- length(zz)
      data.frame(
        sim = j,
        rank = seq_len(m),
        theoretical = stats::qnorm(stats::ppoints(m)),
        sample = zz
      )
    })
    out <- do.call(rbind, cols)
    out$deviation <- out$sample - out$theoretical
    out
  }
  expect_warning(
    mock(fit),
    regexp = "dropped from the.*qq_plot"
  )
})