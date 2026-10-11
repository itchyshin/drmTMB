# Regression test for #1468. The Tweedie power is p = 1 + plogis(eta_nu) and
# TMB's dtweedie() forms p - 1 and 2 - p from p. Past |eta_nu| = 36.7 one of
# them rounds to exactly 0 and the log-density is NaN (main at 0eb04678:
# fn = NaN for y = 1 at eta_nu = 37, 40, -37, -40). Well before that, TMB's
# finite series (TWEEDIE_NTERM = 20000) stops covering the peak as p -> 2 and
# the log-density falls off a cliff: y = 1, mu = 1, phi = 1 gave -1.0 at
# eta_nu = 14 but -33.6 at 20 and +6 at 36, against a p -> 2 (Gamma, shape
# 1 / phi = 1) limit of exactly -1. eta_nu now goes through a soft clamp that
# is identity on [-10, 10] and saturates by +/-12 (src/drmTMB.cpp,
# model_type == 16).

tweedie_bound_fit <- function(y) {
  suppressWarnings(drmTMB(
    bf(y ~ 1, sigma ~ 1, nu ~ 1),
    data = data.frame(y = y),
    family = tweedie(),
    control = drm_control(se = FALSE, logsigma_clamp = NULL)
  ))
}

tweedie_bound_par <- function(fit, eta_mu, log_sigma, eta_nu) {
  par <- fit$obj$par
  par[names(par) == "beta_mu"] <- eta_mu
  par[names(par) == "beta_sigma"] <- log_sigma
  par[names(par) == "beta_nu"] <- eta_nu
  par
}

test_that("tweedie log-density and gradient stay finite at any eta_nu (#1468)", {
  for (y in c(0, 0.2, 1, 3)) {
    fit <- tweedie_bound_fit(y)
    for (eta_nu in c(-60, -40, -37, -20, 20, 37, 40, 60)) {
      par <- tweedie_bound_par(fit, 0, 0, eta_nu)
      expect_true(is.finite(fit$obj$fn(par)))
      expect_true(all(is.finite(fit$obj$gr(par))))
    }
  }
})

test_that("tweedie p -> 2 side approaches the Gamma limit instead of a series cliff (#1468)", {
  # y = 1, mu = 1, phi = 1: the p -> 2 limit is Gamma(shape = 1, mean = 1),
  # log f(1) = -1. The clamp saturates near p = 2 - plogis(-12) = 2 - 6.1e-6.
  fit <- tweedie_bound_fit(1)
  for (eta_nu in c(12, 14, 20, 36, 40)) {
    ll <- -fit$obj$fn(tweedie_bound_par(fit, 0, 0, eta_nu))
    expect_lt(abs(ll + 1), 1e-5)
  }
})

test_that("tweedie eta_nu clamp is exact identity inside [-10, 10] (#1468)", {
  # y = 0 has a closed form: log P(Y = 0) = -mu^(2 - p) / (phi * (2 - p)).
  fit <- tweedie_bound_fit(0)
  for (eta_nu in c(-10, -3, 0, 2.5, 7, 10)) {
    for (eta_mu in c(-1, 0, 1.5)) {
      p <- 1 + stats::plogis(eta_nu)
      mu <- exp(eta_mu)
      phi <- exp(0.3)^2
      ref <- -mu^(2 - p) / (phi * (2 - p))
      ll <- -fit$obj$fn(tweedie_bound_par(fit, eta_mu, 0.3, eta_nu))
      # 1e-10: p is rounded to the nearest double, so 2 - p carries a relative
      # error of about eps / (2 - p) = 5e-12 at eta_nu = 10.
      expect_equal(ll, ref, tolerance = 1e-10)
    }
  }
  # Outside the band the power is held inside (1, 2): the y = 0 log-density
  # stays bounded below by its value at the saturation point.
  sat <- 2 - stats::plogis(-12)
  floor_val <- -1 / (exp(0.3)^2 * (2 - sat))
  ll40 <- -fit$obj$fn(tweedie_bound_par(fit, 0, 0.3, 40))
  expect_gte(ll40, floor_val - 1e-6)
})
