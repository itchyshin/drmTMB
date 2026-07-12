# DO-T0a foundation tests for R/family-dpq.R (drm_family_dpq(),
# fitted_distribution(), and the Dunn-Smyth seed-contract primitive).
# Gaussian is the promoted reference (status = "reference") and is the only
# family with its full DG2 suite kept in this file. skew_normal was promoted
# to `status = "reference"` in DO-T3 batch B; its DG2/DG3 tests live in
# test-family-dpq-batchB.R. tweedie was promoted to `status = "reference"` in
# DO-T3 batch C (the atom-decomposition DG2 case); its DG2/DG3 tests moved to
# test-family-dpq-batchC.R along with the rest of that batch's atom/mixture
# families -- not repeated here. biv_gaussian (bivariate, MARGINAL-only) was
# promoted in DO-T3 batch D, the last of all 18 fitted model_type values; its
# DG2/DG3 tests, and fitted_distribution()'s `response` argument, live in
# test-family-dpq-batchD.R.

test_that("fitted_distribution() gaussian matches the compiled log-density", {
  set.seed(20260712)
  n <- 60
  x <- stats::rnorm(n)
  sigma_true <- exp(-0.2 + 0.15 * x)
  dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n, sd = sigma_true), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)

  fd <- fitted_distribution(fit)
  expect_s3_class(fd, "drm_fitted_distribution")
  expect_identical(fd$model_type, "gaussian")
  expect_identical(fd$status, "reference")
  expect_false(fd$discrete)
  expect_false(fd$has_atom)

  d_direct <- stats::dnorm(
    dat$y,
    mean = predict(fit, dpar = "mu"),
    sd = observation_sigma(fit)
  )
  expect_equal(fd$d(dat$y), d_direct)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)
})

test_that("fitted_distribution() gaussian p-q inverse identity holds", {
  set.seed(20260712)
  n <- 60
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  fd <- fitted_distribution(fit)

  u <- c(0.01, 0.1, 0.25, 0.5, 0.75, 0.9, 0.99)
  for (uu in u) {
    q_val <- fd$q(rep(uu, n))
    expect_equal(fd$p(q_val), rep(uu, n), tolerance = 1e-8)
  }
})

test_that("fitted_distribution() gaussian meta_V includes known sampling variance", {
  set.seed(20260713)
  n <- 40
  x <- stats::rnorm(n)
  V <- stats::runif(n, 0.05, 0.3)
  dat <- data.frame(
    y = 0.3 + 0.5 * x + stats::rnorm(n, sd = sqrt(V + 0.4^2)),
    x = x,
    V = V
  )
  fit <- drmTMB(bf(y ~ x + meta_V(V = V), sigma ~ 1), family = gaussian(), data = dat)
  fd <- fitted_distribution(fit)

  expect_equal(fd$params$V_known, known_v_diag(fit))
  d_direct <- stats::dnorm(
    dat$y,
    mean = predict(fit, dpar = "mu"),
    sd = observation_sigma(fit)
  )
  expect_equal(fd$d(dat$y), d_direct)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  # CP1 contract: a meta_V() fit requires an explicit per-row `V` column in
  # newdata; silently assuming 0 would give the wrong fitted distribution.
  expect_error(
    fitted_distribution(fit, newdata = data.frame(x = c(-1, 0, 1))),
    "needs a known sampling variance"
  )
  fd_new <- fitted_distribution(
    fit,
    newdata = data.frame(x = c(-1, 0, 1), V = c(0.1, 0.2, 0.3))
  )
  expect_equal(fd_new$params$V_known, c(0.1, 0.2, 0.3))
})

test_that("drm_family_dpq() aborts clearly for an unimplemented model type", {
  # "poisson" was promoted to status = "reference" in DO-T3 batch A,
  # "beta_binomial" in DO-T3 batch B, "zero_one_beta"/"tweedie"/the
  # count-mixture families in DO-T3 batch C, and "biv_gaussian" (the last
  # remaining model type) in DO-T3 batch D -- all 18 fitted model_type
  # values now have a promoted entry, so this test can no longer reach the
  # abort branch through any live drmTMB() fit's model_type. drm_family_dpq()
  # only ever reads object$model$model_type (no other field), so a minimal
  # synthetic object is enough to exercise the defensive abort branch
  # directly, without needing a genuinely-unimplemented family to exist.
  fake_fit <- list(model = list(model_type = "not_a_real_model_type"))
  expect_error(
    drm_family_dpq(fake_fit),
    "does not yet cover model type"
  )
})

# The skew_normal DG2/DG3 tests (formerly a "feasibility spike" CDF-identity
# check here) moved to tests/testthat/test-family-dpq-batchB.R and were
# extended to full DG2 (inverse identity, normalization, compiled-density
# agreement, the mvtnorm bivariate-normal external-reference identity) + DG3
# smoke when skew_normal was promoted to `status = "reference"` in DO-T3
# batch B. The tweedie DG2/DG3 tests (formerly a "feasibility spike"
# density/atom check here) moved to tests/testthat/test-family-dpq-batchC.R
# and were extended to the full atom-decomposition DG2 suite + DG3 smoke when
# tweedie was promoted to `status = "reference"` in DO-T3 batch C.

test_that("drm_dunn_smyth_u() is seed-reproducible, bounded, and RNG-neutral", {
  lower <- c(0, 0.5, 0.9)
  upper <- c(0.2, 0.6, 1.0)
  u1 <- drm_dunn_smyth_u(lower, upper, seed = 42)
  u2 <- drm_dunn_smyth_u(lower, upper, seed = 42)
  expect_identical(u1, u2)
  expect_true(all(u1 >= lower & u1 <= upper))

  set.seed(1)
  before <- stats::runif(3)
  set.seed(1)
  invisible(drm_dunn_smyth_u(lower, upper, seed = 999))
  after <- stats::runif(3)
  expect_identical(before, after)
})

# The tweedie-atom Dunn-Smyth demonstration (formerly here, hand-building
# Fy_left via `ifelse(y == 0, 0, Fy)`) moved to
# tests/testthat/test-family-dpq-batchC.R as part of tweedie's DG3 smoke test
# -- drm_atom_left_limit() (R/adequacy.R) now derives that same left-limit
# rule generically from `fd$atoms` rather than a family-specific `y == 0`
# check, and the batch C test exercises the generic path via
# `residuals(fit, type = "quantile")`.
