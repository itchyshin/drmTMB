# DO-T3 batch A tests for R/family-dpq.R: the base-R-closed-form families
# promoted to `status = "reference"` -- student, lognormal, gamma, beta,
# binomial, poisson, nbinom2. Gaussian/tweedie/skew_normal (DO-T0a) are
# covered in tests/testthat/test-family-dpq.R and not repeated here.
#
# DG2 per family (blocking before "reference" status; verification-spec.md):
#   1. inverse identity p(q(a)) ~= a for a in {.01,.05,.25,.5,.75,.95,.99}
#      (continuous: tolerance 1e-6; discrete: q() is the correct
#      right-inverse -- p(q(a)) >= a and p(q(a) - 1) < a).
#   2. normalization: p() -> 0/1 at the support boundaries.
#   3. density agreement: the compiled nll matches -sum(log(fd$d(y))) at the
#      fitted theta (exercises the internal->native parameter map).
#   4. external reference: fd$p()/fd$d() match a hand-derived native-parameter
#      call to the base-R {d,p,q}FAMILY function, computed directly from
#      predict()-ed dpars in the TEST (not by calling the package's internal
#      drm_*_shape_scale()/drm_*_size() helpers), so a bug in those helpers
#      cannot cancel against the same bug in the assertion.
#
# DG3 (verification-spec.md): one fixed-seed known-DGP smoke test per family
# -- residuals(fit, type = "quantile") should pass a KS test against N(0,1).
# This is LOCAL SMOKE ONLY (n in the low hundreds, one seed each), not the
# gated multi-seed power-arm campaign (Curie/Grace, NOT_CRAN, Totoro/DRAC).

alpha_grid <- c(0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99)

fast_control <- drm_control(se = FALSE)

expect_continuous_inverse_identity <- function(fd, n) {
  for (a in alpha_grid) {
    q_val <- fd$q(rep(a, n))
    expect_equal(fd$p(q_val), rep(a, n), tolerance = 1e-6)
  }
}

expect_discrete_right_inverse <- function(fd, n) {
  # `fd$p`/`fd$q` are per-row closures bound to the FULL `params` table
  # (frozen (y_or_u, params) signature): every call here passes a length-n
  # vector aligned to that row order, then subsets AFTER the call. Passing a
  # pre-subsetted (shorter) vector would silently misalign against the
  # length-n `params$mu` inside the closure via R's recycling rules.
  for (a in alpha_grid) {
    q_val <- fd$q(rep(a, n))
    expect_true(all(fd$p(q_val) >= a - 1e-8))
    left <- fd$p(q_val - 1)
    has_left <- q_val > 0
    if (any(has_left)) {
      expect_true(all(left[has_left] < a))
    }
  }
}

# ---- student ----------------------------------------------------------------

test_that("student: DG2 inverse identity, normalization, density + external pt() agreement", {
  set.seed(20260716)
  n <- 80
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.4 + 0.6 * x + 1.1 * stats::rt(n, df = 6), x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x, nu ~ 1),
    family = student(),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_false(fd$discrete)
  expect_false(fd$has_atom)

  expect_continuous_inverse_identity(fd, n)

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  nu_hat <- predict(fit, dpar = "nu")
  expect_equal(fd$p(mu_hat - 1e4 * sigma_hat), rep(0, n), tolerance = 1e-6)
  expect_equal(fd$p(mu_hat + 1e4 * sigma_hat), rep(1, n), tolerance = 1e-6)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  p_direct <- stats::pt((dat$y - mu_hat) / sigma_hat, df = nu_hat)
  expect_equal(fd$p(dat$y), p_direct)
})

test_that("student: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260716)
  n <- 300
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.4 + 0.6 * x + 1.1 * stats::rt(n, df = 6), x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = student(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile")
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- lognormal ----------------------------------------------------------------

test_that("lognormal: DG2 inverse identity, normalization, density + external plnorm() agreement (no extra Jacobian on the CDF)", {
  set.seed(20260717)
  n <- 80
  x <- stats::rnorm(n)
  dat <- data.frame(y = stats::rlnorm(n, meanlog = 0.3 + 0.4 * x, sdlog = 0.5), x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = lognormal(),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_false(fd$discrete)
  expect_false(fd$has_atom)

  expect_continuous_inverse_identity(fd, n)

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  expect_equal(fd$p(rep(1e-8, n)), rep(0, n), tolerance = 1e-6)
  expect_equal(fd$p(exp(mu_hat + 1e4 * sigma_hat)), rep(1, n), tolerance = 1e-6)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  # Noether's trap: the CDF does NOT carry the density-scale `-log(y)`
  # Jacobian -- plnorm(meanlog, sdlog) directly, nothing added.
  p_direct <- stats::plnorm(dat$y, meanlog = mu_hat, sdlog = sigma_hat)
  expect_equal(fd$p(dat$y), p_direct)
})

test_that("lognormal: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260717)
  n <- 300
  x <- stats::rnorm(n)
  dat <- data.frame(y = stats::rlnorm(n, meanlog = 0.3 + 0.4 * x, sdlog = 0.5), x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = lognormal(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile")
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- gamma ----------------------------------------------------------------

test_that("gamma: DG2 inverse identity, normalization, density + external pgamma() agreement", {
  set.seed(20260718)
  n <- 90
  x <- stats::rnorm(n)
  mu_true <- exp(0.4 + 0.3 * x)
  dat <- data.frame(
    y = stats::rgamma(n, shape = 1 / 0.6^2, scale = mu_true * 0.6^2),
    x = x
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = Gamma(link = "log"),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_false(fd$discrete)
  expect_false(fd$has_atom)

  expect_continuous_inverse_identity(fd, n)

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  expect_equal(fd$p(rep(0, n)), rep(0, n), tolerance = 1e-6)
  expect_equal(
    fd$p(stats::qgamma(1 - 1e-10, shape = 1 / sigma_hat^2, scale = mu_hat * sigma_hat^2)),
    rep(1, n),
    tolerance = 1e-6
  )

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  # external reference: (mu, sigma) -> (shape, scale) re-derived directly here.
  shape_direct <- 1 / sigma_hat^2
  scale_direct <- mu_hat * sigma_hat^2
  p_direct <- stats::pgamma(dat$y, shape = shape_direct, scale = scale_direct)
  d_direct <- stats::dgamma(dat$y, shape = shape_direct, scale = scale_direct)
  expect_equal(fd$p(dat$y), p_direct)
  expect_equal(fd$d(dat$y), d_direct)
})

test_that("gamma: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260718)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.4 + 0.3 * x)
  dat <- data.frame(
    y = stats::rgamma(n, shape = 1 / 0.6^2, scale = mu_true * 0.6^2),
    x = x
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = Gamma(link = "log"),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile")
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- beta ----------------------------------------------------------------

test_that("beta: DG2 inverse identity, normalization, density + external pbeta() agreement", {
  set.seed(20260719)
  n <- 90
  x <- stats::rnorm(n)
  mu_true <- stats::plogis(0.2 + 0.5 * x)
  phi_true <- 1 / 0.4^2
  dat <- data.frame(
    y = stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true),
    x = x
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = beta(),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_false(fd$discrete)
  expect_false(fd$has_atom)

  expect_continuous_inverse_identity(fd, n)

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  expect_equal(fd$p(rep(0, n)), rep(0, n), tolerance = 1e-6)
  expect_equal(fd$p(rep(1, n)), rep(1, n), tolerance = 1e-6)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  phi_direct <- 1 / sigma_hat^2
  shape1_direct <- mu_hat * phi_direct
  shape2_direct <- (1 - mu_hat) * phi_direct
  p_direct <- stats::pbeta(dat$y, shape1 = shape1_direct, shape2 = shape2_direct)
  d_direct <- stats::dbeta(dat$y, shape1 = shape1_direct, shape2 = shape2_direct)
  expect_equal(fd$p(dat$y), p_direct)
  expect_equal(fd$d(dat$y), d_direct)
})

test_that("beta: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260719)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- stats::plogis(0.2 + 0.5 * x)
  phi_true <- 1 / 0.4^2
  dat <- data.frame(
    y = stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true),
    x = x
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = beta(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile")
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- binomial (discrete) -------------------------------------------------

test_that("binomial: DG2 right-inverse, normalization, density + external pbinom() agreement, trials attaches via params", {
  set.seed(20260720)
  n <- 90
  x <- stats::rnorm(n)
  trials <- sample(5:20, n, replace = TRUE)
  mu_true <- stats::plogis(-0.2 + 0.6 * x)
  success <- stats::rbinom(n, size = trials, prob = mu_true)
  dat <- data.frame(success = success, failure = trials - success, x = x, trials = trials)
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x),
    family = binomial(),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_true(fd$discrete)
  expect_false(fd$has_atom)
  expect_equal(fd$params$trials, trials)

  expect_discrete_right_inverse(fd, n)

  mu_hat <- predict(fit, dpar = "mu")
  expect_equal(fd$p(rep(-1, n)), rep(0, n))
  expect_equal(fd$p(trials), rep(1, n))

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$success))), tolerance = 1e-8)

  p_direct <- stats::pbinom(dat$success, size = trials, prob = mu_hat)
  d_direct <- stats::dbinom(dat$success, size = trials, prob = mu_hat)
  expect_equal(fd$p(dat$success), p_direct)
  expect_equal(fd$d(dat$success), d_direct)

  # newdata contract: trials must be supplied explicitly (mirrors meta_V()'s
  # V-column contract), never silently defaulted.
  expect_error(
    fitted_distribution(fit, newdata = data.frame(x = c(-1, 0, 1))),
    "needs the number of trials"
  )
  fd_new <- fitted_distribution(
    fit,
    newdata = data.frame(x = c(-1, 0, 1), trials = c(10, 10, 10))
  )
  expect_equal(fd_new$params$trials, c(10, 10, 10))
})

test_that("binomial: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260720)
  n <- 300
  x <- stats::rnorm(n)
  trials <- sample(5:20, n, replace = TRUE)
  mu_true <- stats::plogis(-0.2 + 0.6 * x)
  success <- stats::rbinom(n, size = trials, prob = mu_true)
  dat <- data.frame(success = success, failure = trials - success, x = x)
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x),
    family = binomial(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 11)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- poisson (discrete) ---------------------------------------------------

test_that("poisson: DG2 right-inverse, normalization, density + external ppois() agreement", {
  set.seed(20260721)
  n <- 90
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  dat <- data.frame(y = stats::rpois(n, lambda = mu_true), x = x)
  fit <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_true(fd$discrete)
  expect_false(fd$has_atom)

  expect_discrete_right_inverse(fd, n)

  mu_hat <- predict(fit, dpar = "mu")
  expect_equal(fd$p(rep(-1, n)), rep(0, n))
  expect_equal(fd$p(stats::qpois(1 - 1e-10, lambda = mu_hat)), rep(1, n), tolerance = 1e-8)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  p_direct <- stats::ppois(dat$y, lambda = mu_hat)
  d_direct <- stats::dpois(dat$y, lambda = mu_hat)
  expect_equal(fd$p(dat$y), p_direct)
  expect_equal(fd$d(dat$y), d_direct)
})

test_that("poisson: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260721)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  dat <- data.frame(y = stats::rpois(n, lambda = mu_true), x = x)
  fit <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 13)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- nbinom2 (discrete) ----------------------------------------------------

test_that("nbinom2: DG2 right-inverse, normalization, density + external pnbinom() agreement", {
  set.seed(20260722)
  n <- 90
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  sigma_true <- 0.7
  dat <- data.frame(
    y = stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true),
    x = x
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_true(fd$discrete)
  expect_false(fd$has_atom)

  expect_discrete_right_inverse(fd, n)

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  size_hat <- 1 / sigma_hat^2
  expect_equal(fd$p(rep(-1, n)), rep(0, n))
  expect_equal(
    fd$p(stats::qnbinom(1 - 1e-10, size = size_hat, mu = mu_hat)),
    rep(1, n),
    tolerance = 1e-8
  )

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  # external reference: sigma -> size re-derived directly here (1 / sigma^2).
  p_direct <- stats::pnbinom(dat$y, size = size_hat, mu = mu_hat)
  d_direct <- stats::dnbinom(dat$y, size = size_hat, mu = mu_hat)
  expect_equal(fd$p(dat$y), p_direct)
  expect_equal(fd$d(dat$y), d_direct)
})

test_that("nbinom2: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260722)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  sigma_true <- 0.7
  dat <- data.frame(
    y = stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true),
    x = x
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 17)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})
