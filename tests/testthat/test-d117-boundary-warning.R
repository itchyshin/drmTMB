# D-43 panel finding #6: is there a user-facing warning when a profile
# interval for a random-effect SD pins against the [0, inf) boundary?
#
# This reproduces the exact D-117 10-group profile gate cell 4
# (n_groups = 10, n_per = 4, sd_mu = 0.5; docs/dev-log/simulation-artifacts/
# 2026-08-04-d117-10group-profile-gate/d117_profile_gate.R) at the two seeds
# the S0 smoke already characterized: seed 20660728 (attempt r = 1) lands at
# the SD boundary (profile_boundary = TRUE, profile_lower = 0,
# estimate_sd = 0.1919612); seed 20660729 (attempt r = 2) does not
# (profile_boundary = FALSE). `warn_profile_boundary()` already has unit
# coverage (data-frame level) and one integration test through a `sigma`
# structured random effect; this test locks in the same behaviour on the
# `mu` location random-intercept target the gate itself measures, through
# the exact `confint()` call a user makes.

new_d117_gate_cell4_data <- function(seed) {
  true_beta <- 0.5
  true_sigma <- 0.7
  n_groups <- 10L
  n_per <- 4L
  sd_mu <- 0.5
  set.seed(seed)
  g <- factor(rep(seq_len(n_groups), each = n_per))
  x <- stats::rnorm(length(g))
  u <- stats::rnorm(n_groups, 0, sd_mu)
  y <- 1 + true_beta * x + u[as.integer(g)] + stats::rnorm(length(g), 0, true_sigma)
  data.frame(y = y, x = x, g = g)
}

test_that("d117 gate cell 4 boundary seed warns through confint() on the user path", {
  dat <- new_d117_gate_cell4_data(seed = 20660728L)
  fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat)

  pars <- summary(fit)$parameters
  est <- pars$estimate[pars$parm == "sd:mu:(1 | g)"]
  expect_equal(est, 0.1919612, tolerance = 1e-5)

  expect_warning(
    ci <- confint(
      fit,
      parm = "variance_components",
      method = "profile",
      profile_engine = "auto"
    ),
    class = "drmTMB_profile_boundary_warning"
  )

  row <- ci[ci$parm == "sd:mu:(1 | g)", , drop = FALSE]
  expect_true(nrow(row) >= 1L)
  expect_true(row$profile.boundary[[1L]])
  expect_equal(row$lower[[1L]], 0)
  expect_equal(row$profile.message[[1L]], "near_sd_boundary")
})

test_that("d117 gate cell 4 non-boundary seed stays silent on the same user path", {
  dat <- new_d117_gate_cell4_data(seed = 20660729L)
  fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat)

  expect_no_warning(
    ci <- confint(
      fit,
      parm = "variance_components",
      method = "profile",
      profile_engine = "auto"
    )
  )

  row <- ci[ci$parm == "sd:mu:(1 | g)", , drop = FALSE]
  expect_true(nrow(row) >= 1L)
  expect_false(row$profile.boundary[[1L]])
})
