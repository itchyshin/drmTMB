# Temporal parameters can reach an interpretability boundary while the
# optimizer, Hessian and standard errors all look regular. These fits must
# report convergence_status() == "boundary" and a temporal_boundary warning.

temporal_boundary_panel <- function(seed, n = 20, times = c(0, 1, 3, 6),
                                    b_sd = 0, ou_sd = 0.8, decay = 0.4,
                                    noise = 0.3) {
  set.seed(seed)
  R <- exp(-decay * abs(outer(times, times, "-")))
  d <- do.call(rbind, lapply(seq_len(n), function(i) {
    data.frame(
      id = sprintf("s%02d", i), t = times, x = stats::rnorm(length(times)),
      z = stats::rnorm(1, sd = b_sd) +
        as.vector(t(chol(R)) %*% stats::rnorm(length(times), sd = ou_sd))
    )
  }))
  d$y <- 0.5 + 0.3 * d$x + d$z + stats::rnorm(nrow(d), sd = noise)
  d
}

fit_temporal_ou_boundary <- function(d) {
  suppressWarnings(drmTMB(
    bf(y ~ x + temporal(1 | id, time = t, structure = "ou"), sigma ~ 1),
    data = d, family = gaussian(), REML = FALSE
  ))
}

boundary_row <- function(fit) {
  rows <- check_drm(fit)
  rows[rows$check == "temporal_boundary", , drop = FALSE]
}

test_that("an OU decay that runs to zero is reported as a boundary fit", {
  # Stable series intercepts with a weak, slowly decaying OU process and no
  # ordinary (1 | id): the OU decay absorbs the intercept and runs to ~0.
  fit <- fit_temporal_ou_boundary(temporal_boundary_panel(
    2, b_sd = 0.6, ou_sd = 0.2, decay = 0.01
  ))
  expect_identical(as.integer(fit$opt$convergence), 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_lt(unname(fit$decaypars$temporal[[1L]]), 1e-6)
  row <- boundary_row(fit)
  expect_identical(row$status, "warning")
  expect_match(row$value, "decay_x_max_span=")
  expect_identical(convergence_status(fit), "boundary")
  expect_true(is_converged(fit))
})

test_that("a healthy OU fit has no temporal boundary row warning", {
  fit <- fit_temporal_ou_boundary(temporal_boundary_panel(1))
  expect_identical(boundary_row(fit)$status, "ok")
  expect_identical(convergence_status(fit), "converged")
})

test_that("each temporal boundary rule fires on its own limit", {
  fit <- fit_temporal_ou_boundary(temporal_boundary_panel(1))
  expect_length(drmTMB:::drm_temporal_boundary_findings(fit), 0L)

  # Residual SD collapsed relative to the response scale.
  tiny_sigma <- fit
  tiny_sigma$model$y <- tiny_sigma$model$y * 1e4
  expect_match(drmTMB:::drm_temporal_boundary_findings(tiny_sigma), "^sigma_ratio=")

  # Decay so fast that correlation is ~0 at the shortest gap (white noise).
  white <- fit
  white$decaypars$temporal[[1L]] <- 40
  expect_match(drmTMB:::drm_temporal_boundary_findings(white), "^decay_x_min_gap=")

  # Decay so slow that correlation is ~1 across the longest span.
  flat <- fit
  flat$decaypars$temporal[[1L]] <- 1e-6
  expect_match(drmTMB:::drm_temporal_boundary_findings(flat), "^decay_x_max_span=")

  # AR1 persistence at +/-1.
  ar1 <- fit
  ar1$model$structured$temporal_mu$structure <- "ar1"
  ar1$corpars$temporal <- c(phi = -0.9995)
  expect_match(drmTMB:::drm_temporal_boundary_findings(ar1), "^phi=")
  ar1$corpars$temporal <- c(phi = 0.99)
  expect_length(drmTMB:::drm_temporal_boundary_findings(ar1), 0L)
})
