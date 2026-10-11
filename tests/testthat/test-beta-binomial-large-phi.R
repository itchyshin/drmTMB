# Regression test for #1467: the beta-binomial log-density used to be a plain
# lgamma sum whose terms are about phi log(phi) in size, so as sigma -> 0
# (phi = exp(-2 log_sigma) -> Inf, the binomial limit) each row lost about
# eps * phi log(phi) absolutely. On main at 0eb04678 the compiled objective
# for 300 binomial(10, 0.3) rows was off the binomial limit by 2.5 at
# log_sigma = -12, by -60 at -14 and by +5e5 at -20 (it overshot the limit,
# which a beta-binomial log-likelihood cannot do). The kernel now uses
# drm_lgamma_ratio() (src/drm_numeric.h), which differences the Stirling
# series analytically.

bb_large_phi_fit <- function() {
  set.seed(20261003)
  trials <- 10
  y <- stats::rbinom(300, trials, 0.3)
  dat <- data.frame(succ = y, fail = trials - y)
  fit <- suppressWarnings(drmTMB(
    bf(cbind(succ, fail) ~ 1, sigma ~ 1),
    data = dat,
    family = beta_binomial(),
    control = drm_control(se = FALSE, logsigma_clamp = NULL)
  ))
  list(fit = fit, y = y, trials = trials)
}

# Exact reference with no lgamma call:
# lgamma(x + m) - lgamma(x) = sum_{k = 0}^{m - 1} log(x + k).
bb_exact_loglik <- function(y, trials, mu, phi) {
  a <- mu * phi
  b <- (1 - mu) * phi
  rising <- function(x, m) if (m == 0) 0 else sum(log(x + seq_len(m) - 1))
  sum(vapply(y, function(yi) {
    lchoose(trials, yi) + rising(a, yi) + rising(b, trials - yi) -
      rising(a + b, trials)
  }, numeric(1)))
}

test_that("beta_binomial log-likelihood is exact and tends to the binomial limit as sigma -> 0 (#1467)", {
  setup <- bb_large_phi_fit()
  fit <- setup$fit
  mu <- 0.3
  par <- fit$obj$par
  par[names(par) == "beta_mu"] <- stats::qlogis(mu)
  binom_limit <- sum(stats::dbinom(setup$y, setup$trials, mu, log = TRUE))
  log_sigma <- c(-2, -5, -9, -11.5, -12, -13, -14, -15, -20)
  ll <- numeric(length(log_sigma))
  for (k in seq_along(log_sigma)) {
    par[names(par) == "beta_sigma"] <- log_sigma[k]
    ll[k] <- -fit$obj$fn(par)
    # The kernel's own mean nudge (1e-12) is applied before the shapes.
    mu_k <- 1e-12 + (1 - 2e-12) * mu
    exact <- bb_exact_loglik(setup$y, setup$trials, mu_k, exp(-2 * log_sigma[k]))
    expect_lt(abs(ll[k] - exact), 1e-8)
    expect_true(all(is.finite(fit$obj$gr(par))))
  }
  # Never above the binomial limit, non-decreasing towards it, and equal to it
  # once phi is huge.
  expect_true(all(ll <= binom_limit + 1e-9))
  expect_true(all(diff(ll) >= -1e-9))
  expect_lt(abs(ll[length(ll)] - binom_limit), 1e-8)
})

test_that("drm_lgamma_ratio() branches agree at the switch (#1467)", {
  # Indirect check through the compiled kernel: a single row with trials = 50
  # evaluated just below and above phi = 100 (the Stirling switch for the
  # a + b term) must agree with the exact product form to 1e-11.
  dat <- data.frame(succ = 17, fail = 33)
  fit <- suppressWarnings(drmTMB(
    bf(cbind(succ, fail) ~ 1, sigma ~ 1),
    data = dat,
    family = beta_binomial(),
    control = drm_control(se = FALSE, logsigma_clamp = NULL)
  ))
  par <- fit$obj$par
  par[names(par) == "beta_mu"] <- 0
  for (phi in c(99.999999, 100, 100.000001, 250, 1e4)) {
    par[names(par) == "beta_sigma"] <- -0.5 * log(phi)
    mu_k <- 1e-12 + (1 - 2e-12) * 0.5
    exact <- bb_exact_loglik(17, 50, mu_k, phi)
    expect_lt(abs(-fit$obj$fn(par) - exact), 1e-11)
  }
})
