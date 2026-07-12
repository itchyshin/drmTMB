# DO-T3 batch C tests for R/family-dpq.R: the atom/mixture families promoted
# to `status = "reference"` -- tweedie, zero_one_beta, zi_poisson,
# zi_nbinom2, truncated_nbinom2, hurdle_nbinom2. Gaussian/skew_normal
# (DO-T0a/batch B), student/lognormal/gamma/beta/binomial/poisson/nbinom2
# (batch A), and beta_binomial/cumulative_logit (batch B) are covered
# elsewhere and not repeated here.
#
# DG2 per family (blocking before "reference" status; verification-spec.md):
#   1. inverse identity p(q(a)) ~= a for a in {.01,.05,.25,.5,.75,.95,.99}
#      (discrete/atom families: q() is the correct right-inverse --
#      p(q(a)) >= a and p(q(a) - eps) < a; eps = 1 for a count family's
#      "F(y - 1)" spacing, a small fixed offset for zero_one_beta's
#      continuous-atom-at-1 spacing).
#   2. atom decomposition: enumerate atoms explicitly (tweedie: {0};
#      zi_poisson/zi_nbinom2/hurdle_nbinom2: {0}; zero_one_beta: {0, 1};
#      truncated_nbinom2: no atom -- a proper renormalized discrete lattice,
#      not a jump breaking one). d() at each atom is asserted to equal the
#      hand-built atom-mass formula (independent of the package's own
#      drm_family_dpq_*() closure), and p() at the family's support boundary
#      is asserted to reach 0/1 -- since p() is the proper CDF, boundary
#      normalization already encodes "atom masses + continuous/non-atom part
#      sum to 1" (the same convention batch A/B used for ordinary continuous
#      and discrete families' normalization check, extended here with the
#      explicit atom-mass agreement).
#   3. density agreement: the compiled nll matches -sum(log(fd$d(y))) at the
#      fitted theta (exercises the internal->native parameter map AND the
#      atom/mixture algebra together).
#   4. external reference: an INDEPENDENT hand-built mixture from the
#      reference base ({d,p,q}pois/{d,p,q}nbinom/pbeta) plus the explicit
#      atom/renormalization algebra, computed directly from predict()-ed
#      dpars in the TEST body (not via the package's own drm_family_dpq_*()
#      closures, so a bug there cannot cancel against the assertion) -- per
#      the verification spec's "hand-built mixture ... document the
#      construction" convention for families with no single external package
#      comparator (zi_*/hurdle_*/truncated_*/zero_one_beta). tweedie is the
#      exception: `tweedie::{d,p,q}tweedie()` IS a direct external
#      comparator (same convention as the DO-T0a spike test this batch
#      promotes); a fully package-independent series-expansion tweedie
#      density reference also already exists
#      (tests/testthat/helper-tweedie-density.R,
#      `tweedie_compound_log_density_reference()`, used elsewhere in the
#      suite) for a future pass that wants to cross-check the `tweedie`
#      package itself.
#
# DG3 (verification-spec.md): one fixed-seed known-DGP smoke test per family
# -- residuals(fit, type = "quantile") should pass a KS test against N(0,1).
# This is LOCAL SMOKE ONLY (n in the low hundreds, one seed each), not the
# gated multi-seed power-arm campaign (Curie/Grace, NOT_CRAN, Totoro/DRAC).

alpha_grid <- c(0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99)

fast_control <- drm_control(se = FALSE)

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

# Same right-inverse convention as expect_discrete_right_inverse(), but for a
# continuous-with-isolated-atoms family where there is no natural unit
# spacing: a small fixed epsilon stands in for "the previous integer".
expect_atom_right_inverse <- function(fd, n, epsilon = 1e-6) {
  for (a in alpha_grid) {
    q_val <- fd$q(rep(a, n))
    expect_true(all(fd$p(q_val) >= a - 1e-8))
    expect_true(all(fd$p(q_val - epsilon) < a + 1e-8))
  }
}

# ---- tweedie (atom at 0) -----------------------------------------------------

test_that("tweedie: DG2 atom decomposition, right-inverse, density + external tweedie::dtweedie() agreement", {
  testthat::skip_if_not_installed("tweedie")
  set.seed(20260714)
  n <- 80
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  y <- rtweedie_compound(n, mu = mu_true, phi = 0.9^2, power = 1.5)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = tweedie(),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_false(fd$discrete)
  expect_true(fd$has_atom)
  expect_identical(fd$atoms, c(0))

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  nu_hat <- predict(fit, dpar = "nu")

  # Atom decomposition: the atom mass at y = 0 IS the CDF value there (no
  # continuous density at or below 0), and p() reaches 1 at a far upper
  # boundary -- together these certify atom mass + continuous integral = 1.
  d0 <- tweedie::dtweedie(rep(0, n), mu = mu_hat, phi = sigma_hat^2, power = nu_hat[1])
  expect_equal(fd$d(rep(0, n)), d0)
  expect_equal(fd$p(rep(0, n)), d0)
  expect_equal(fd$p(rep(1e6, n)), rep(1, n), tolerance = 1e-6)

  expect_atom_right_inverse(fd, n)

  d_direct <- tweedie::dtweedie(dat$y, mu = mu_hat, phi = sigma_hat^2, power = nu_hat[1])
  expect_equal(fd$d(dat$y), d_direct)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(pmax(fd$d(dat$y), 1e-300))), tolerance = 1e-6)

  p_direct <- tweedie::ptweedie(dat$y, mu = mu_hat, phi = sigma_hat^2, power = nu_hat[1])
  expect_equal(fd$p(dat$y), p_direct)
})

test_that("tweedie: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  testthat::skip_if_not_installed("tweedie")
  set.seed(20260714)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  y <- rtweedie_compound(n, mu = mu_true, phi = 0.9^2, power = 1.5)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = tweedie(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 31)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- zi_poisson (discrete, atom at 0 for DG2 bookkeeping) -------------------

test_that("zi_poisson: DG2 atom decomposition, right-inverse, density + hand-built zi mixture agreement", {
  set.seed(20260727)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.4 + 0.25 * x)
  zi_true <- 0.3
  y <- ifelse(stats::runif(n) < zi_true, 0L, stats::rpois(n, mu_true))
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, zi ~ 1),
    family = poisson(),
    data = dat,
    control = fast_control
  )
  expect_identical(fit$model$model_type, "zi_poisson")
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_true(fd$discrete)
  expect_false(fd$has_atom)
  expect_identical(fd$atoms, c(0))

  mu_hat <- predict(fit, dpar = "mu")
  zi_hat <- predict(fit, dpar = "zi")

  # Atom decomposition: d(0) matches the hand-built mixture atom mass
  # zi + (1 - zi) * dpois(0, mu); p() reaches 0/1 at the discrete boundary.
  atom0_direct <- zi_hat + (1 - zi_hat) * stats::dpois(0, lambda = mu_hat)
  expect_equal(fd$d(rep(0, n)), atom0_direct)
  expect_equal(fd$p(rep(-1, n)), rep(0, n))
  expect_equal(
    fd$p(stats::qpois(1 - 1e-10, lambda = mu_hat)),
    rep(1, n),
    tolerance = 1e-8
  )

  expect_discrete_right_inverse(fd, n)

  d_direct <- ifelse(
    dat$y == 0,
    atom0_direct,
    (1 - zi_hat) * stats::dpois(dat$y, lambda = mu_hat)
  )
  expect_equal(fd$d(dat$y), d_direct)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  # external reference: F(y) = zi + (1 - zi) * ppois(y, mu), hand-built here.
  p_direct <- zi_hat + (1 - zi_hat) * stats::ppois(dat$y, lambda = mu_hat)
  expect_equal(fd$p(dat$y), p_direct)
})

test_that("zi_poisson: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260727)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.4 + 0.25 * x)
  zi_true <- 0.3
  y <- ifelse(stats::runif(n) < zi_true, 0L, stats::rpois(n, mu_true))
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, zi ~ 1),
    family = poisson(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 37)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- zi_nbinom2 (discrete, atom at 0 for DG2 bookkeeping) -------------------

test_that("zi_nbinom2: DG2 atom decomposition, right-inverse, density + hand-built zi mixture agreement", {
  set.seed(20260728)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.4 + 0.25 * x)
  sigma_true <- 0.6
  zi_true <- 0.25
  y <- ifelse(
    stats::runif(n) < zi_true,
    0L,
    stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true)
  )
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, zi ~ 1),
    family = nbinom2(),
    data = dat,
    control = fast_control
  )
  expect_identical(fit$model$model_type, "zi_nbinom2")
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_true(fd$discrete)
  expect_false(fd$has_atom)
  expect_identical(fd$atoms, c(0))

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  zi_hat <- predict(fit, dpar = "zi")
  size_hat <- 1 / sigma_hat^2

  atom0_direct <- zi_hat + (1 - zi_hat) * stats::dnbinom(0, size = size_hat, mu = mu_hat)
  expect_equal(fd$d(rep(0, n)), atom0_direct)
  expect_equal(fd$p(rep(-1, n)), rep(0, n))
  expect_equal(
    fd$p(stats::qnbinom(1 - 1e-10, size = size_hat, mu = mu_hat)),
    rep(1, n),
    tolerance = 1e-8
  )

  expect_discrete_right_inverse(fd, n)

  d_direct <- ifelse(
    dat$y == 0,
    atom0_direct,
    (1 - zi_hat) * stats::dnbinom(dat$y, size = size_hat, mu = mu_hat)
  )
  expect_equal(fd$d(dat$y), d_direct)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  # external reference: F(y) = zi + (1 - zi) * pnbinom(y, size, mu).
  p_direct <- zi_hat + (1 - zi_hat) * stats::pnbinom(dat$y, size = size_hat, mu = mu_hat)
  expect_equal(fd$p(dat$y), p_direct)
})

test_that("zi_nbinom2: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260728)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.4 + 0.25 * x)
  sigma_true <- 0.6
  zi_true <- 0.25
  y <- ifelse(
    stats::runif(n) < zi_true,
    0L,
    stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true)
  )
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, zi ~ 1),
    family = nbinom2(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 41)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- truncated_nbinom2 (discrete, no atom -- renormalized lattice) ---------

test_that("truncated_nbinom2: DG2 right-inverse, renormalized-support normalization, density + hand-built truncation agreement", {
  set.seed(20260729)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.25 * x)
  sigma_true <- 0.6
  p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
  u_true <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
  y <- stats::qnbinom(u_true, size = 1 / sigma_true^2, mu = mu_true)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = fast_control
  )
  expect_identical(fit$model$model_type, "truncated_nbinom2")
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_true(fd$discrete)
  expect_false(fd$has_atom)
  expect_identical(fd$atoms, numeric(0))

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  size_hat <- 1 / sigma_hat^2
  p0_hat <- stats::dnbinom(0, size = size_hat, mu = mu_hat)

  # Normalization: F(0) = 0 (nothing below the truncated support) and
  # F(huge) -> 1; d() is 0 below the support too.
  expect_equal(fd$p(rep(0, n)), rep(0, n))
  expect_equal(fd$d(rep(0, n)), rep(0, n))
  expect_equal(
    fd$p(stats::qnbinom(1 - 1e-10, size = size_hat, mu = mu_hat)),
    rep(1, n),
    tolerance = 1e-8
  )

  expect_discrete_right_inverse(fd, n)

  d_direct <- stats::dnbinom(dat$y, size = size_hat, mu = mu_hat) / (1 - p0_hat)
  expect_equal(fd$d(dat$y), d_direct)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  # external reference: F(y) = (pnbinom(y,...) - p0) / (1 - p0), y >= 1.
  p_direct <- (stats::pnbinom(dat$y, size = size_hat, mu = mu_hat) - p0_hat) /
    (1 - p0_hat)
  expect_equal(fd$p(dat$y), p_direct)
})

test_that("truncated_nbinom2: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260729)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.25 * x)
  sigma_true <- 0.6
  p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
  u_true <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
  y <- stats::qnbinom(u_true, size = 1 / sigma_true^2, mu = mu_true)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 43)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- hurdle_nbinom2 (discrete, atom at 0 for DG2 bookkeeping) ---------------

test_that("hurdle_nbinom2: DG2 atom decomposition, right-inverse, density + hand-built hurdle mixture agreement", {
  set.seed(20260730)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.25 * x)
  sigma_true <- 0.6
  hu_true <- 0.3
  p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
  pos_u <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
  pos_y <- stats::qnbinom(pos_u, size = 1 / sigma_true^2, mu = mu_true)
  y <- ifelse(stats::runif(n) < hu_true, 0L, pos_y)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, hu ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = fast_control
  )
  expect_identical(fit$model$model_type, "hurdle_nbinom2")
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_true(fd$discrete)
  expect_false(fd$has_atom)
  expect_identical(fd$atoms, c(0))

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  hu_hat <- predict(fit, dpar = "hu")
  size_hat <- 1 / sigma_hat^2
  p0_hat <- stats::dnbinom(0, size = size_hat, mu = mu_hat)

  # Atom decomposition: d(0) = hu (the hurdle mechanism REPLACES, not adds
  # to, the y = 0 mass); p() reaches 0/1 at the discrete boundary.
  expect_equal(fd$d(rep(0, n)), hu_hat)
  expect_equal(fd$p(rep(-1, n)), rep(0, n))
  expect_equal(
    fd$p(stats::qnbinom(1 - 1e-10, size = size_hat, mu = mu_hat)),
    rep(1, n),
    tolerance = 1e-8
  )

  expect_discrete_right_inverse(fd, n)

  trunc_pmf <- stats::dnbinom(dat$y, size = size_hat, mu = mu_hat) / (1 - p0_hat)
  d_direct <- ifelse(dat$y == 0, hu_hat, (1 - hu_hat) * trunc_pmf)
  expect_equal(fd$d(dat$y), d_direct)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-8)

  # external reference: F(0) = hu; F(y) = hu + (1 - hu) * truncated_F(y) for
  # y >= 1, hand-built here from the SAME truncated-CDF formula
  # "truncated_nbinom2" uses.
  trunc_cdf <- (stats::pnbinom(dat$y, size = size_hat, mu = mu_hat) - p0_hat) /
    (1 - p0_hat)
  p_direct <- ifelse(dat$y == 0, hu_hat, hu_hat + (1 - hu_hat) * trunc_cdf)
  expect_equal(fd$p(dat$y), p_direct)
})

test_that("hurdle_nbinom2: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260730)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.25 * x)
  sigma_true <- 0.6
  hu_true <- 0.3
  p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
  pos_u <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
  pos_y <- stats::qnbinom(pos_u, size = 1 / sigma_true^2, mu = mu_true)
  y <- ifelse(stats::runif(n) < hu_true, 0L, pos_y)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, hu ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 47)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})

# ---- zero_one_beta (continuous, atoms at 0 AND 1) ---------------------------

test_that("zero_one_beta: DG2 two-atom decomposition, right-inverse, density + hand-built pbeta mixture agreement", {
  set.seed(20260731)
  n <- 400
  x <- stats::rnorm(n)
  mu_true <- stats::plogis(0.2 + 0.4 * x)
  sigma_true <- 0.5
  zoi_true <- 0.3
  coi_true <- 0.4
  phi_true <- 1 / sigma_true^2
  boundary <- stats::runif(n) < zoi_true
  one <- stats::runif(n) < coi_true
  interior <- stats::rbeta(
    n,
    shape1 = mu_true * phi_true,
    shape2 = (1 - mu_true) * phi_true
  )
  y <- ifelse(boundary, as.numeric(one), interior)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
    family = zero_one_beta(),
    data = dat,
    control = fast_control
  )
  fd <- fitted_distribution(fit)
  expect_identical(fd$status, "reference")
  expect_false(fd$discrete)
  expect_true(fd$has_atom)
  expect_identical(fd$atoms, c(0, 1))

  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  zoi_hat <- predict(fit, dpar = "zoi")
  coi_hat <- predict(fit, dpar = "coi")
  phi_direct <- 1 / sigma_hat^2
  shape1_direct <- mu_hat * phi_direct
  shape2_direct <- (1 - mu_hat) * phi_direct
  atom0_direct <- zoi_hat * (1 - coi_hat)
  atom1_direct <- zoi_hat * coi_hat

  # Two-atom decomposition: d(0)/d(1) match the hand-built zoi/coi atom-mass
  # algebra; p() reaches the atom0 mass exactly at y = 0 and 1 at y = 1 --
  # together with the interior beta component these certify
  # P(Y=0) + P(Y=1) + (1 - zoi) * integral(dbeta) = 1 (the last term is
  # exactly 1 - zoi since dbeta integrates to 1 over its support by
  # construction, so p(1) == 1 already certifies the full decomposition).
  expect_equal(fd$d(rep(0, n)), atom0_direct)
  expect_equal(fd$d(rep(1, n)), atom1_direct)
  expect_equal(fd$p(rep(0, n)), atom0_direct)
  expect_equal(fd$p(rep(1, n)), rep(1, n))
  expect_equal(fd$p(rep(-1e-6, n)), rep(0, n))

  expect_atom_right_inverse(fd, n, epsilon = 1e-6)

  interior_direct <- (1 - zoi_hat) *
    stats::dbeta(dat$y, shape1 = shape1_direct, shape2 = shape2_direct)
  d_direct <- ifelse(
    dat$y == 0,
    atom0_direct,
    ifelse(dat$y == 1, atom1_direct, interior_direct)
  )
  expect_equal(fd$d(dat$y), d_direct)

  nll_compiled <- fit$obj$fn(fit$obj$env$last.par.best)
  expect_equal(nll_compiled, -sum(log(fd$d(dat$y))), tolerance = 1e-6)

  # external reference: F(y) = P(Y=0) + (1 - zoi) * pbeta(y, ...) for
  # 0 <= y < 1, hand-built here directly from pbeta() + the zoi/coi atom
  # algebra (independent of drm_beta_shapes()/drm_family_dpq_zero_one_beta()).
  y_clamped <- pmin(pmax(dat$y, 0), 1)
  interior_cdf_direct <- atom0_direct +
    (1 - zoi_hat) * stats::pbeta(y_clamped, shape1 = shape1_direct, shape2 = shape2_direct)
  p_direct <- ifelse(dat$y >= 1, 1, interior_cdf_direct)
  expect_equal(fd$p(dat$y), p_direct, tolerance = 1e-8)
})

test_that("zero_one_beta: DG3 smoke -- quantile residuals ~ N(0,1) under the true DGP", {
  set.seed(20260731)
  n <- 400
  x <- stats::rnorm(n)
  mu_true <- stats::plogis(0.2 + 0.4 * x)
  sigma_true <- 0.5
  zoi_true <- 0.3
  coi_true <- 0.4
  phi_true <- 1 / sigma_true^2
  boundary <- stats::runif(n) < zoi_true
  one <- stats::runif(n) < coi_true
  interior <- stats::rbeta(
    n,
    shape1 = mu_true * phi_true,
    shape2 = (1 - mu_true) * phi_true
  )
  y <- ifelse(boundary, as.numeric(one), interior)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
    family = zero_one_beta(),
    data = dat,
    control = fast_control
  )
  r <- residuals(fit, type = "quantile", seed = 53)
  ks <- stats::ks.test(r, "pnorm")
  expect_gt(ks$p.value, 0.05)
})
