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

# Fisher's SECOND fresh-context review, of the item-1 fix itself (2a5b0665e,
# docs/dev-log/audits/2026-09-14-dinnage-wave3-review.md, "### M2 follow-up
# (2a5b0665e)"), found that clamping the Wald endpoints through the same
# monotone map bought containment at the cost of coverage: at clamp-bent rows
# the shipped interval collapsed to a zero-width point on the clamp asymptote,
# unflagged, and the response-scale std.error disagreed with conf.low/
# conf.high in the same row by up to 6.1e9x. This shared fixture (same DGP as
# m2_fixture(), but se = TRUE so the Wald interval these items repair actually
# gets computed) and the "M2 repair:" blocks below are the TDD red/green pair
# for Fisher's REQUIRED items 1-4 from that review.
m2_wald_fixture <- function() {
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
  list(fit = fit, data = d, band = band, margin = margin)
}

test_that("M2 repair: clamp-bent rows are NA and flagged clamp_limited; in-band rows keep the ordinary Wald interval (review item 1, was 'interval brackets the clamped point estimate')", {
  # This test replaces the 2a5b0665e version of the same name, which asserted
  # unconditional containment of the CLAMPED point estimate by CLAMPED
  # endpoints. Fisher's follow-up review rejected that contract: measured
  # against an unclamped truth, it bought containment by making clamp-bent
  # rows a zero-width interval sitting on the clamp asymptote, with coverage
  # 0.000. The new contract below is what item 1 REQUIRED instead.
  fx <- m2_wald_fixture()
  fit <- fx$fit
  d <- fx$data

  # Independently-computed RAW (unclamped) sigma predictor, same pattern as
  # m2_raw_sigma_eta() above, to classify rows without depending on the code
  # under test.
  raw_eta <- as.vector(
    stats::model.matrix(~x, data = d) %*% unname(stats::coef(fit)$sigma)
  )
  clamp_bent <- raw_eta < fx$band[[1L]] | raw_eta > fx$band[[2L]]
  n_clamp_bent <- sum(clamp_bent)
  expect_true(n_clamp_bent > 0L) # else this test is vacuous
  in_band <- !clamp_bent

  out_link <- predict_parameters(
    fit,
    newdata = d,
    dpar = "sigma",
    type = "link",
    conf.int = TRUE
  )
  out_resp <- predict_parameters(
    fit,
    newdata = d,
    dpar = "sigma",
    type = "response",
    conf.int = TRUE
  )

  # Clamp-bent rows: NA endpoints and NA std.error, flagged "clamp_limited" --
  # the same status profile()'s drm_profile_clamp_limited_confint_row()
  # (R/profile.R:3514-3530) already uses for a saturated direct-SD trace.
  expect_equal(
    out_link$conf.status[clamp_bent],
    rep("clamp_limited", n_clamp_bent)
  )
  expect_equal(
    out_resp$conf.status[clamp_bent],
    rep("clamp_limited", n_clamp_bent)
  )
  expect_true(all(is.na(out_link$conf.low[clamp_bent])))
  expect_true(all(is.na(out_link$conf.high[clamp_bent])))
  expect_true(all(is.na(out_link$std.error[clamp_bent])))
  expect_true(all(is.na(out_resp$conf.low[clamp_bent])))
  expect_true(all(is.na(out_resp$conf.high[clamp_bent])))
  expect_true(all(is.na(out_resp$std.error[clamp_bent])))
  # Review item 2: std.error is NA exactly where the endpoints are NA.
  expect_equal(is.na(out_link$std.error), is.na(out_link$conf.low))
  expect_equal(is.na(out_link$std.error), is.na(out_link$conf.high))
  expect_equal(is.na(out_resp$std.error), is.na(out_resp$conf.low))
  expect_equal(is.na(out_resp$std.error), is.na(out_resp$conf.high))

  # In-band rows: inside the band the clamp is the identity, so the ordinary
  # raw-eta Wald interval still contains the (identical, clamped) point
  # estimate and the row is labelled "wald".
  expect_equal(out_link$conf.status[in_band], rep("wald", sum(in_band)))
  expect_equal(out_resp$conf.status[in_band], rep("wald", sum(in_band)))
  expect_true(all(
    out_link$conf.low[in_band] <= out_link$estimate[in_band] + 1e-8
  ))
  expect_true(all(
    out_link$estimate[in_band] <= out_link$conf.high[in_band] + 1e-8
  ))
  expect_true(all(
    out_resp$conf.low[in_band] <= out_resp$estimate[in_band] + 1e-8
  ))
  expect_true(all(
    out_resp$estimate[in_band] <= out_resp$conf.high[in_band] + 1e-8
  ))
})

test_that("M2 repair: in-band Wald intervals are bit-identical to the pre-2a5b0665e raw-eta interval; no 'wald' row is clamp-bent or near-zero-width (review items 1-3)", {
  fx <- m2_wald_fixture()
  fit <- fx$fit
  d <- fx$data

  raw_eta <- as.vector(
    stats::model.matrix(~x, data = d) %*% unname(stats::coef(fit)$sigma)
  )
  clamp_bent <- raw_eta < fx$band[[1L]] | raw_eta > fx$band[[2L]]
  expect_true(sum(clamp_bent) > 0L) # else this test is vacuous
  in_band <- !clamp_bent

  # Hand-built raw-eta Wald interval, independent of predict_parameters(),
  # using the same accessor and formula test-predict-parameters.R uses for the
  # pre-2a5b0665e (unclamped) contract.
  basis <- drmTMB:::drm_fixed_effect_basis(
    fit,
    newdata = d,
    dpar = "sigma",
    covariance = TRUE
  )
  X <- as.matrix(basis$X)
  V <- as.matrix(basis$V)
  se_hand <- sqrt(rowSums((X %*% V) * X))
  z <- stats::qnorm(0.975)
  lo_hand <- basis$eta - z * se_hand
  hi_hand <- basis$eta + z * se_hand

  out_link <- predict_parameters(
    fit,
    newdata = d,
    dpar = "sigma",
    type = "link",
    conf.int = TRUE
  )

  expect_equal(out_link$std.error[in_band], unname(se_hand[in_band]))
  expect_equal(out_link$conf.low[in_band], unname(lo_hand[in_band]))
  expect_equal(out_link$conf.high[in_band], unname(hi_hand[in_band]))

  # No row labelled "wald" is clamp-bent, and no "wald" row's interval is a
  # near-zero-width point (the containment-only defect item 3 targets: a
  # clamp-saturated interval can satisfy containment trivially while carrying
  # no information).
  wald_rows <- out_link$conf.status == "wald"
  expect_true(!any(clamp_bent[wald_rows]))
  widths <- out_link$conf.high[wald_rows] - out_link$conf.low[wald_rows]
  expect_true(all(widths >= 1e-6))
})

test_that("M2 repair: an se = FALSE fixed-effect sigma fit reports wald_unavailable without erroring (review item 4)", {
  fx <- m2_wald_fixture()
  d <- fx$data
  fit_no_se <- suppressWarnings(
    drmTMB(
      bf(y ~ x, sigma ~ x),
      family = gaussian(),
      data = d,
      control = drm_control(
        logsigma_clamp = fx$band,
        logsigma_clamp_margin = fx$margin,
        se = FALSE
      )
    )
  )

  expect_no_error(
    out <- predict_parameters(
      fit_no_se,
      newdata = d,
      dpar = "sigma",
      conf.int = TRUE
    )
  )
  expect_equal(out$conf.status, rep("wald_unavailable", nrow(out)))
  expect_true(all(is.na(out$conf.low)))
  expect_true(all(is.na(out$conf.high)))
  expect_true(all(is.na(out$std.error)))
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
