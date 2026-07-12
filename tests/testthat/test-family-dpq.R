# DO-T0a foundation tests for R/family-dpq.R (drm_family_dpq(),
# fitted_distribution(), and the Dunn-Smyth seed-contract primitive).
# Gaussian is the promoted reference (status = "reference"); tweedie and
# skew_normal are feasibility spikes (status = "spike") -- see the DO-T0a
# after-task report for what remains before DO-T3 promotion.

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
  set.seed(1)
  dat <- data.frame(y = rpois(30, 3), x = stats::rnorm(30))
  fit <- drmTMB(bf(y ~ x), family = poisson(), data = dat)
  expect_error(
    drm_family_dpq(fit),
    "does not yet cover model type"
  )
})

test_that("tweedie feasibility spike matches tweedie::dtweedie and the atom at 0", {
  testthat::skip_if_not_installed("tweedie")
  set.seed(20260714)
  n <- 80
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  y <- rtweedie_compound(n, mu = mu_true, phi = 0.9^2, power = 1.5)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat)
  fd <- fitted_distribution(fit)

  expect_identical(fd$status, "spike")
  expect_true(fd$has_atom)

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  nu_hat <- predict(fit, dpar = "nu")

  d_direct <- tweedie::dtweedie(dat$y, mu = mu_hat, phi = sigma_hat^2, power = nu_hat[1])
  expect_equal(fd$d(dat$y), d_direct)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(pmax(fd$d(dat$y), 1e-300))), tolerance = 1e-6)

  p0 <- fd$p(rep(0, n))
  d0 <- tweedie::dtweedie(rep(0, n), mu = mu_hat, phi = sigma_hat^2, power = nu_hat[1])
  expect_equal(p0, d0)
})

test_that("skew_normal feasibility spike CDF matches the bivariate-normal identity", {
  testthat::skip_if_not_installed("mvtnorm")
  set.seed(20260715)
  n <- 40
  x <- stats::rnorm(n)
  mu_true <- 0.5 + 0.4 * x
  y <- rskew_normal_public(n, mu = mu_true, sigma = 1.1, nu = 3)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = skew_normal(), data = dat)
  fd <- fitted_distribution(fit)

  expect_identical(fd$status, "spike")

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  nu_hat <- predict(fit, dpar = "nu")

  # compiled log-density agreement
  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-6)

  # independent CDF formula: F(z) = 2*Phi(z) - 2*Phi2(0, z; rho = delta)
  alpha <- nu_hat[1]
  delta <- alpha / sqrt(1 + alpha^2)
  mean_shift <- delta * sqrt(2 / pi)
  omega <- sigma_hat[1] / sqrt(1 - mean_shift^2)
  idx <- 1:5
  xi <- mu_hat[idx] - omega * mean_shift
  z <- (dat$y[idx] - xi) / omega
  external_cdf <- vapply(z, function(zz) {
    2 * stats::pnorm(zz) -
      2 * mvtnorm::pmvnorm(
        upper = c(0, zz),
        mean = c(0, 0),
        corr = matrix(c(1, delta, delta, 1), 2)
      )
  }, numeric(1))
  expect_equal(fd$p(dat$y[idx]), external_cdf, tolerance = 1e-6)
})

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

test_that("Dunn-Smyth randomized quantile residuals are ~N(0,1) at the tweedie atom", {
  testthat::skip_if_not_installed("tweedie")
  set.seed(20260714)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  y <- rtweedie_compound(n, mu = mu_true, phi = 0.9^2, power = 1.5)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat)
  fd <- fitted_distribution(fit)

  Fy <- fd$p(dat$y)
  Fy_left <- ifelse(dat$y == 0, 0, Fy)
  u_ds <- drm_dunn_smyth_u(Fy_left, Fy, seed = 7)
  z_ds <- stats::qnorm(u_ds)

  expect_equal(mean(z_ds), 0, tolerance = 0.1)
  expect_equal(stats::sd(z_ds), 1, tolerance = 0.1)
  expect_gt(stats::ks.test(z_ds, "pnorm")$p.value, 0.01)
})
