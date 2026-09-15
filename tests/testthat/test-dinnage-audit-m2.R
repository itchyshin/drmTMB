# Dinnage audit M2 (issue #1308): when the log(sigma) soft-clamp is active,
# the TMB likelihood evaluates the CLAMPED scale, but sigma()/predict()/
# residuals()/simulate() reported the raw, unclamped linear predictor. This
# file fits a Gaussian location-scale model under a deliberately narrow clamp
# band so the clamp binds for about half the rows, then checks that the
# reported scale matches what the likelihood actually used.

m2_fixture <- function() {
  set.seed(1308)
  n <- 200
  x <- stats::rnorm(n)
  mu <- 1 + 0.5 * x
  band <- c(-1, 1)
  margin <- 0.3
  # Generate the response through the SAME soft clamp the TMB likelihood
  # applies, so a correctly-specified fit's clamped scale recovers the true
  # generating sigma (a model can only ever describe what its likelihood
  # evaluates). The raw slope is steep enough that the clamp binds for about
  # half the rows.
  raw_eta_true <- 1.6 * x
  sigma_true <- exp(drm_softclamp_log_sd(
    raw_eta_true,
    list(use_logsigma_clamp = 1L, logsigma_clamp = c(band, margin))
  ))
  y <- stats::rnorm(n, mu, sigma_true)
  d <- data.frame(y = y, x = x)
  fit <- suppressWarnings(
    drmTMB(
      bf(y ~ x, sigma ~ x),
      family = gaussian(),
      data = d,
      control = drm_control(
        logsigma_clamp = band,
        logsigma_clamp_margin = margin,
        se = FALSE
      )
    )
  )
  list(fit = fit, data = d)
}

# Raw (unclamped) sigma-linear-predictor, computed independently of predict()
# via the fitted coefficients, so it stays valid whether or not predict()
# itself has been fixed to report the clamped scale.
m2_raw_sigma_eta <- function(fx) {
  beta_sigma <- unname(stats::coef(fx$fit)$sigma)
  X_sigma <- stats::model.matrix(~x, data = fx$data)
  as.vector(X_sigma %*% beta_sigma)
}

test_that("M2: hand-recomputed log-likelihood matches logLik() under the clamp", {
  fx <- m2_fixture()
  fit <- fx$fit
  ll_hand <- sum(stats::dnorm(
    fx$data$y,
    predict(fit, dpar = "mu"),
    sigma(fit),
    log = TRUE
  ))
  expect_equal(ll_hand, as.numeric(logLik(fit)), tolerance = 1e-6)
})

test_that("M2: sigma() equals the softclamp of the raw linear predictor and stays inside the clamp bounds", {
  fx <- m2_fixture()
  fit <- fx$fit
  tmb_data <- fit$model$tmb_data
  band <- tmb_data$logsigma_clamp
  lo <- band[[1L]]
  hi <- band[[2L]]
  margin <- band[[3L]]

  raw_eta <- m2_raw_sigma_eta(fx)
  expected <- exp(drm_softclamp_log_sd(raw_eta, tmb_data))
  observed <- unname(sigma(fit))

  expect_equal(observed, expected, tolerance = 1e-6)
  expect_true(all(observed <= exp(hi + margin) + 1e-8))
  expect_true(all(observed >= exp(lo - margin) - 1e-8))
  expect_equal(max(observed), max(expected), tolerance = 1e-8)
})

test_that("M2: Pearson residual SD is close to 1 once sigma() reports the clamped scale", {
  fx <- m2_fixture()
  fit <- fx$fit
  resid_sd <- stats::sd(residuals(fit, type = "pearson"))
  expect_true(abs(resid_sd - 1) < 0.15)
})

test_that("M2: simulate() per-row draw SD at the most-clamped rows matches the clamped sigma()", {
  fx <- m2_fixture()
  fit <- fx$fit
  tmb_data <- fit$model$tmb_data

  raw_eta <- m2_raw_sigma_eta(fx)
  clamped_eta <- drm_softclamp_log_sd(raw_eta, tmb_data)
  expected_sigma <- exp(clamped_eta)
  distortion <- abs(raw_eta - clamped_eta)
  most_clamped <- order(distortion, decreasing = TRUE)[1:10]

  sims <- simulate(fit, nsim = 200, seed = 1)
  sim_sd <- apply(sims, 1, stats::sd)

  rel_err <- abs(sim_sd[most_clamped] - expected_sigma[most_clamped]) /
    expected_sigma[most_clamped]
  expect_true(all(rel_err < 0.15))
})

test_that("M2: the clamp fix is a no-op when the clamp band is not binding", {
  set.seed(2026)
  n <- 150
  x <- stats::rnorm(n)
  y <- stats::rnorm(n, 0.3 + 0.5 * x, exp(-0.2 + 0.3 * x))
  d <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = d,
    control = drm_control(se = FALSE)
  )
  expect_equal(fit$model$tmb_data$use_logsigma_clamp, 1L)

  link_eta <- predict(fit, dpar = "sigma", type = "link")
  expect_equal(unname(sigma(fit)), exp(unname(link_eta)), tolerance = 1e-12)
  expect_equal(
    unname(predict(fit, dpar = "sigma", type = "response")),
    exp(unname(link_eta)),
    tolerance = 1e-12
  )
})
