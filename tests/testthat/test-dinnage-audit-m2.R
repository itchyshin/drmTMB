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

  # Independently-computed raw (unclamped) sigma predictor, the same pattern
  # m2_raw_sigma_eta() uses above, rather than routing back through
  # predict()/sigma() -- which would compare that code path with itself.
  # Fisher's fresh-context review of 0526baa2f (docs/dev-log/audits/
  # 2026-09-14-dinnage-wave3-review.md, "### M2 (0526baa2f)") found that the
  # prior version of this block was exactly that tautology: its only
  # non-tautological assertion was the use_logsigma_clamp check above.
  eta_hand <- as.vector(
    stats::model.matrix(~x, data = d) %*% unname(stats::coef(fit)$sigma)
  )
  expect_equal(
    exp(drm_softclamp_log_sd(eta_hand, fit$model$tmb_data)),
    unname(sigma(fit)),
    tolerance = 1e-12
  )
  # The test's name is a claim that the clamp is a no-op here: demonstrate it
  # directly by checking the RAW (un-softclamped) predictor already matches
  # sigma() bit-for-bit, rather than inferring it from use_logsigma_clamp == 1.
  expect_equal(exp(eta_hand), unname(sigma(fit)), tolerance = 1e-12)

  # And confirm the clamp is genuinely inactive at the optimum, using the same
  # accessor pattern check_drm() uses (R/check.R:590-592): report at the
  # fit's stored last.par.best rather than a bare obj$report(), which would
  # judge the clamp off-optimum.
  report <- fit$obj$report(fit$tmb_state$last.par.best)
  expect_null(drm_logsigma_clamp_active(report, fit$model$tmb_data))
})

# Fisher's fresh-context review of 0526baa2f (docs/dev-log/audits/
# 2026-09-14-dinnage-wave3-review.md, "### M2 (0526baa2f)") found the no-op
# block above tautological (it compares sigma() with predict() through the
# same code path) and found two repair items. These "M2 repair:" blocks are
# the TDD red/green pair for both.

test_that("M2 repair: predict_parameters() interval brackets the clamped point estimate (review item 1)", {
  # m2_fixture() sets se = FALSE (no vcov, so no Wald interval is available at
  # all); build the same design with se = TRUE so the interval this item
  # repairs actually gets computed.
  set.seed(1308)
  n <- 200
  x <- stats::rnorm(n)
  mu <- 1 + 0.5 * x
  band <- c(-1, 1)
  margin <- 0.3
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
      control = drm_control(logsigma_clamp = band, logsigma_clamp_margin = margin)
    )
  )

  out_link <- predict_parameters(
    fit,
    newdata = d,
    dpar = "sigma",
    type = "link",
    conf.int = TRUE
  )
  expect_true(all(out_link$conf.low <= out_link$estimate + 1e-8))
  expect_true(all(out_link$estimate <= out_link$conf.high + 1e-8))

  out_resp <- predict_parameters(
    fit,
    newdata = d,
    dpar = "sigma",
    type = "response",
    conf.int = TRUE
  )
  expect_true(all(out_resp$conf.low <= out_resp$estimate + 1e-8))
  expect_true(all(out_resp$estimate <= out_resp$conf.high + 1e-8))
})

test_that("M2 repair: predict(fit, dpar = 'sd(id)') matches the kernel's clamped sd(id) (review item 2)", {
  sim <- new_gaussian_re_scale_data()
  fit <- suppressWarnings(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
      family = gaussian(),
      data = sim$data,
      control = drm_control(
        logsigma_clamp = c(-0.2, 0.2),
        logsigma_clamp_margin = 0.05,
        se = FALSE
      )
    )
  )

  sd_hat <- predict(fit, dpar = "sd(id)")
  expect_equal(unname(sd_hat), unname(fit$sdpars[["sd(id)"]]), tolerance = 1e-6)
})
