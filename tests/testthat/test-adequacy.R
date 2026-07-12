# DO-T1 tests for R/adequacy.R (drm_quantile_residuals(),
# residuals(type = "quantile")) and R/adequacy-plots.R (worm_plot(),
# qq_plot()). Built on the FROZEN DO-T0a foundation (R/family-dpq.R); see
# tests/testthat/test-family-dpq.R for the underlying fitted_distribution()
# correctness tests this file does not repeat.
#
# Fixed-effect adequacy only (Rose's firewall): every assertion here is about
# whether the diagnostic flags a mis-specified FIXED-EFFECT distributional
# form; "no detectable departure" is the honest reading of a pass, never
# "adequate"/"valid"/"correct".
#
# These are toy-scale seed grids (n in the hundreds, a handful of seeds) for
# fast local/CRAN-lane validation. The gated multi-seed DG3 power-arm
# campaign (>=20 seeds, families x mis-specs) is a DO-T3/Curie/Grace concern
# under NOT_CRAN, per the verification spec's compute directive.

test_that("correctly specified gaussian: quantile residuals pass a KS test at a fixed seed", {
  set.seed(20260712)
  n <- 300
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.3 + 0.6 * x + stats::rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  r <- residuals(fit, type = "quantile")
  expect_length(r, n)
  ks <- stats::ks.test(r, "pnorm")
  # type-I control: under a correctly specified fit the residual should not
  # be flagged as non-N(0,1) -- "no detectable departure", not "the model is
  # correct".
  expect_gt(ks$p.value, 0.05)
})

test_that("residuals(type = 'quantile') matches drm_quantile_residuals() directly", {
  set.seed(1)
  n <- 40
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_identical(
    residuals(fit, type = "quantile"),
    drm_quantile_residuals(fit)
  )
  expect_identical(
    residuals(fit, type = "quantile", seed = 3, nsim = 2),
    drm_quantile_residuals(fit, seed = 3, nsim = 2)
  )
})

test_that("GAMLSS-Primer Fig-4c: a location-only fit to heteroscedastic gaussian data is flagged, the matching location-scale fit is not", {
  set.seed(20260712)
  n <- 400
  x <- stats::rnorm(n)
  sigma_true <- exp(0.1 + 0.9 * x)
  y <- 0.3 + 0.6 * x + stats::rnorm(n, sd = sigma_true)
  dat <- data.frame(y = y, x = x)

  fit_true <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)
  fit_mis <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  r_true <- residuals(fit_true, type = "quantile")
  r_mis <- residuals(fit_mis, type = "quantile")

  ks_true <- stats::ks.test(r_true, "pnorm")
  ks_mis <- stats::ks.test(r_mis, "pnorm")

  # The diagnostic's job is to DETECT the location-only mis-specification,
  # not merely to "never reject" -- a pass here is a detection.
  expect_gt(ks_true$p.value, 0.05)
  expect_lt(ks_mis$p.value, 0.001)

  # Worm plot: the fitted trend (cubic on the deviation vs. theoretical
  # quantile) should depart from flat under the mis-specified fit and stay
  # close to flat under the correctly specified fit. Use the same order-
  # statistic table worm_plot() draws from, so the assertion is about
  # exactly what the plot shows.
  qd_true <- drm_quantile_residual_qq_data(fit_true)
  qd_mis <- drm_quantile_residual_qq_data(fit_mis)
  r2 <- function(qd) {
    fit_lm <- stats::lm(
      deviation ~ poly(theoretical, 3, raw = TRUE),
      data = qd
    )
    summary(fit_lm)$r.squared
  }
  r2_true <- r2(qd_true)
  r2_mis <- r2(qd_mis)

  # Order-statistic noise gives the cubic fit some R^2 even under truth, so
  # the discriminating claim is the GAP, not an absolute threshold on
  # r2_true alone.
  expect_gt(r2_mis, 0.75)
  expect_gt(r2_mis - r2_true, 0.25)
})

test_that("Fig-4c verdict is seed-stable: truth rarely rejects, mis-spec reliably detected, over several data-generating seeds", {
  n <- 400
  alpha <- 0.05
  seeds <- 101:108
  verdicts <- vapply(seeds, function(s) {
    set.seed(s)
    x <- stats::rnorm(n)
    sigma_true <- exp(0.1 + 0.9 * x)
    y <- 0.3 + 0.6 * x + stats::rnorm(n, sd = sigma_true)
    dat <- data.frame(y = y, x = x)
    fit_true <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)
    fit_mis <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
    p_true <- stats::ks.test(
      residuals(fit_true, type = "quantile"),
      "pnorm"
    )$p.value
    p_mis <- stats::ks.test(
      residuals(fit_mis, type = "quantile"),
      "pnorm"
    )$p.value
    c(reject_true = p_true < alpha, reject_mis = p_mis < alpha)
  }, logical(2))

  # Arm A (type-I control): at alpha = 0.05 across 8 seeds, false rejections
  # should be rare -- allow at most one to avoid Monte Carlo flakiness.
  expect_lte(sum(verdicts["reject_true", ]), 1L)
  # Arm B (power): the diagnostic should reliably catch the location-only
  # mis-specification across seeds (target power >= 0.8 per the verification
  # spec).
  expect_gte(mean(verdicts["reject_mis", ]), 0.8)
})

test_that("tweedie (atom family): Dunn-Smyth randomization seed does not change the qualitative KS verdict", {
  testthat::skip_if_not_installed("tweedie")
  set.seed(20260714)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  y <- rtweedie_compound(n, mu = mu_true, phi = 0.9^2, power = 1.5)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat)

  pvals <- vapply(1:10, function(s) {
    suppressWarnings(
      stats::ks.test(
        residuals(fit, type = "quantile", seed = s),
        "pnorm"
      )$p.value
    )
  }, numeric(1))
  # only the ~atom-at-0 rows are actually randomized per draw, so the KS
  # statistic barely moves across seeds -- the qualitative verdict (do not
  # reject) should be identical every time.
  expect_true(all(pvals > 0.05))
})

test_that("spike-status families warn once per session, not on every call", {
  testthat::skip_if_not_installed("tweedie")
  drm_reset_adequacy_warning_state()
  set.seed(20260714)
  n <- 60
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  y <- rtweedie_compound(n, mu = mu_true, phi = 0.9^2, power = 1.5)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat)

  expect_warning(
    residuals(fit, type = "quantile"),
    "feasibility-grade"
  )
  expect_no_warning(residuals(fit, type = "quantile"))
  drm_reset_adequacy_warning_state()
})

test_that("residuals(type = 'quantile') errors clearly for an unimplemented model type", {
  set.seed(1)
  dat <- data.frame(y = rpois(30, 3), x = stats::rnorm(30))
  fit <- drmTMB(bf(y ~ x), family = poisson(), data = dat)
  expect_error(
    residuals(fit, type = "quantile"),
    "does not yet cover model type"
  )
})

test_that("worm_plot() and qq_plot() return ggplot objects for a gaussian fit", {
  testthat::skip_if_not_installed("ggplot2")
  set.seed(20260712)
  n <- 60
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  p_worm <- worm_plot(fit)
  p_qq <- qq_plot(fit)
  expect_s3_class(p_worm, "ggplot")
  expect_s3_class(p_qq, "ggplot")

  # nsim > 1 envelope: for a continuous, atom-free family every Dunn-Smyth
  # realization is identical, so the envelope degenerates to zero width.
  p_worm_env <- worm_plot(fit, seed = 1, nsim = 5)
  expect_s3_class(p_worm_env, "ggplot")
  envelope <- drm_adequacy_envelope(
    drm_quantile_residual_qq_data(fit, seed = 1, nsim = 5),
    "deviation"
  )
  expect_equal(envelope$ymin, envelope$ymax)
})

test_that("worm_plot()/qq_plot() envelope is non-degenerate for an atom family", {
  testthat::skip_if_not_installed("ggplot2")
  testthat::skip_if_not_installed("tweedie")
  set.seed(20260714)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  y <- rtweedie_compound(n, mu = mu_true, phi = 0.9^2, power = 1.5)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat)

  p_qq_env <- suppressWarnings(qq_plot(fit, seed = 1, nsim = 8))
  expect_s3_class(p_qq_env, "ggplot")
  qd <- suppressWarnings(drm_quantile_residual_qq_data(fit, seed = 1, nsim = 8))
  envelope <- drm_adequacy_envelope(qd, "sample")
  expect_true(any(envelope$ymax > envelope$ymin))
})
