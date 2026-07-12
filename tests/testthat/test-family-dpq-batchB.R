# DO-T3 batch B tests for R/family-dpq.R: skew_normal, beta_binomial,
# cumulative_logit -- the shape/ordinal families promoted to
# `status = "reference"`. Gaussian/tweedie (DO-T0a) and
# student/lognormal/gamma/beta/binomial/poisson/nbinom2 (DO-T3 batch A) are
# covered elsewhere and not repeated here.
#
# DG2 per family (blocking before "reference" status; verification-spec.md):
#   1. inverse identity p(q(a)) ~= a for a in {.01,.05,.25,.5,.75,.95,.99}
#      (continuous: tolerance 1e-6; discrete: q() is the correct
#      right-inverse -- p(q(a)) >= a and p(q(a) - 1) < a).
#   2. normalization: p() -> 0/1 at the support boundaries.
#   3. density agreement: the compiled nll matches -sum(log(fd$d(y))) at the
#      fitted theta (exercises the internal->native parameter map).
#   4. external reference: skew_normal uses an independent bivariate-normal
#      CDF identity (mvtnorm::pmvnorm); beta_binomial uses
#      extraDistr::{d,p}bbinom(); cumulative_logit's natural object -- the
#      cumulative category probability -- has no single external package
#      comparator, so its external reference is a hand-built proportional-
#      odds probability computed directly from cutpoints/eta in the TEST
#      body (documented at that test), independent of the package's own
#      drm_cumulative_logit_* helpers.
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
  # vector aligned to that row order, then subsets AFTER the call.
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

# ---- skew_normal ------------------------------------------------------------

test_that("skew_normal: DG2 inverse identity, normalization, density + mvtnorm-identity agreement", {
  set.seed(20260723)
  n <- 80
  x <- stats::rnorm(n)
  mu_true <- 0.5 + 0.4 * x
  y <- rskew_normal_public(n, mu = mu_true, sigma = 1.1, nu = 3)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = skew_normal(),
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
  alpha <- nu_hat
  delta <- alpha / sqrt(1 + alpha^2)
  mean_shift <- delta * sqrt(2 / pi)
  omega <- sigma_hat / sqrt(1 - mean_shift^2)
  xi <- mu_hat - omega * mean_shift
  # Normalization: p() -> 0/1 at +/- 1e4 native SDs (a boundary this far out
  # exercises the integrate()-over-a-huge-interval guard added in DO-T3
  # batch B -- see drm_skew_normal_cdf()'s comment).
  expect_equal(fd$p(xi - 1e4 * omega), rep(0, n), tolerance = 1e-6)
  expect_equal(fd$p(xi + 1e4 * omega), rep(1, n), tolerance = 1e-6)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-6)

  # External reference (independent of the package's own CDF integration):
  # F(z) = 2*Phi(z) - 2*Phi2(0, z; rho = delta), the standard bivariate-
  # normal identity for the skew-normal CDF (Azzalini 1985).
  testthat::skip_if_not_installed("mvtnorm")
  idx <- 1:5
  z <- (dat$y[idx] - xi[idx]) / omega[idx]
  external_cdf <- vapply(seq_along(idx), function(j) {
    2 * stats::pnorm(z[j]) -
      2 * mvtnorm::pmvnorm(
        upper = c(0, z[j]),
        mean = c(0, 0),
        corr = matrix(c(1, delta[idx[j]], delta[idx[j]], 1), 2)
      )
  }, numeric(1))
  expect_equal(fd$p(dat$y[idx]), external_cdf, tolerance = 1e-6)
})

test_that("skew_normal: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260723)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- 0.5 + 0.4 * x
  y <- rskew_normal_public(n, mu = mu_true, sigma = 1.1, nu = 3)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = skew_normal(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 19)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- beta_binomial (discrete) -----------------------------------------------

test_that("beta_binomial: DG2 right-inverse, normalization, density + external extraDistr::pbbinom() agreement, trials attaches via params", {
  set.seed(20260724)
  n <- 90
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  trials <- sample(8:24, n, replace = TRUE)
  beta_mu <- c(-0.20, 0.70)
  beta_sigma <- c(-1.10, 0.25)
  mu_true <- stats::plogis(beta_mu[1] + beta_mu[2] * x)
  sigma_true <- exp(beta_sigma[1] + beta_sigma[2] * z)
  phi_true <- 1 / sigma_true^2
  p_true <- stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true)
  success <- stats::rbinom(n, size = trials, prob = p_true)
  dat <- data.frame(
    success = success,
    failure = trials - success,
    x = x,
    z = z,
    trials = trials
  )
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x, sigma ~ z),
    family = beta_binomial(),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_true(fd$discrete)
  expect_false(fd$has_atom)
  expect_equal(fd$params$trials, trials)

  expect_discrete_right_inverse(fd, n)

  expect_equal(fd$p(rep(-1, n)), rep(0, n))
  expect_equal(fd$p(trials), rep(1, n))

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$success))), tolerance = 1e-8)

  # external reference: (mu, sigma) -> (alpha, beta) re-derived directly here
  # (not via drm_beta_shapes()), so a bug there cannot cancel against the
  # assertion.
  testthat::skip_if_not_installed("extraDistr")
  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  phi_direct <- 1 / sigma_hat^2
  alpha_direct <- mu_hat * phi_direct
  beta_direct <- (1 - mu_hat) * phi_direct
  p_direct <- extraDistr::pbbinom(dat$success, size = trials, alpha = alpha_direct, beta = beta_direct)
  d_direct <- extraDistr::dbbinom(dat$success, size = trials, alpha = alpha_direct, beta = beta_direct)
  expect_equal(fd$p(dat$success), p_direct, tolerance = 1e-8)
  expect_equal(fd$d(dat$success), d_direct, tolerance = 1e-8)

  # newdata contract: trials must be supplied explicitly (mirrors binomial's
  # and meta_V()'s contracts), never silently defaulted.
  expect_error(
    fitted_distribution(fit, newdata = data.frame(x = c(-1, 0, 1), z = c(0, 0, 0))),
    "needs the number of trials"
  )
  fd_new <- fitted_distribution(
    fit,
    newdata = data.frame(x = c(-1, 0, 1), z = c(0, 0, 0), trials = c(10, 10, 10))
  )
  expect_equal(fd_new$params$trials, c(10, 10, 10))
})

test_that("beta_binomial: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260724)
  n <- 300
  x <- stats::rnorm(n)
  trials <- sample(8:24, n, replace = TRUE)
  mu_true <- stats::plogis(-0.2 + 0.7 * x)
  sigma_true <- 0.5
  phi_true <- 1 / sigma_true^2
  p_true <- stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true)
  success <- stats::rbinom(n, size = trials, prob = p_true)
  dat <- data.frame(success = success, failure = trials - success, x = x)
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x, sigma ~ 1),
    family = beta_binomial(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 23)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- cumulative_logit (discrete, ordinal) -----------------------------------

new_batchb_ordinal_data <- function(n, seed) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n))
  beta_mu <- 0.85
  cutpoints <- c(-0.90, 0.75)
  eta <- beta_mu * dat$x
  p_low <- stats::plogis(cutpoints[1] - eta)
  p_medium <- stats::plogis(cutpoints[2] - eta) - p_low
  prob <- cbind(p_low, p_medium, 1 - stats::plogis(cutpoints[2] - eta))
  draw <- vapply(
    seq_len(n),
    function(i) sample.int(3L, size = 1L, prob = prob[i, ]),
    integer(1)
  )
  dat$score <- ordered(
    c("low", "medium", "high")[draw],
    levels = c("low", "medium", "high")
  )
  list(data = dat, beta_mu = beta_mu, cutpoints = cutpoints)
}

test_that("cumulative_logit: DG2 right-inverse, normalization, density + hand-built proportional-odds agreement, cutpoints attach via params", {
  sim <- new_batchb_ordinal_data(n = 400, seed = 20260725)
  dat <- sim$data
  fit <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_true(fd$discrete)
  expect_false(fd$has_atom)
  n <- nrow(dat)
  n_categories <- length(fit$ordinal$levels)
  cutpoints_fit <- unname(fit$ordinal$cutpoints)
  expect_equal(fd$params$CP1, rep(cutpoints_fit[1], n))
  expect_equal(fd$params$CP2, rep(cutpoints_fit[2], n))

  expect_discrete_right_inverse(fd, n)

  # Normalization: F(0) = 0, F(n_categories) = 1.
  expect_equal(fd$p(rep(0, n)), rep(0, n))
  expect_equal(fd$p(rep(n_categories, n)), rep(1, n))

  y <- as.integer(fit$model$y)
  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(y))), tolerance = 1e-8)

  # External reference: a hand-built proportional-odds probability computed
  # directly from cutpoints/eta here (independent of
  # drm_cumulative_logit_p()/drm_cumulative_logit_cutpoints()), matching the
  # verification spec's "hand-built mixture from the reference base +
  # verified atom/renormalization algebra" convention for families with no
  # single external package comparator.
  eta_hat <- predict(fit, dpar = "mu", type = "link")
  cp1 <- cutpoints_fit[1]
  cp2 <- cutpoints_fit[2]
  cum1 <- stats::plogis(cp1 - eta_hat)
  cum2 <- stats::plogis(cp2 - eta_hat)
  p_direct <- cbind(cum1, cum2 - cum1, 1 - cum2)
  d_direct <- p_direct[cbind(seq_len(n), y)]
  p_cdf_direct <- cbind(cum1, cum2, 1)[cbind(seq_len(n), y)]
  expect_equal(fd$d(y), d_direct, tolerance = 1e-8)
  expect_equal(fd$p(y), p_cdf_direct, tolerance = 1e-8)

  # newdata: cutpoints are model-level constants, so they attach without
  # needing a per-row newdata column (unlike trials/V_known).
  fd_new <- fitted_distribution(fit, newdata = data.frame(x = c(-1, 0, 1)))
  expect_equal(fd_new$params$CP1, rep(cutpoints_fit[1], 3))
  expect_equal(fd_new$params$CP2, rep(cutpoints_fit[2], 3))
})

test_that("cumulative_logit: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  sim <- new_batchb_ordinal_data(n = 300, seed = 20260726)
  fit <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = sim$data,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 29)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})
