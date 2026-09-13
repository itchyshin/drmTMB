# Regression tests for three Major findings from Russell Dinnage's independent
# evaluation of drmTMB 0.7.0 (https://github.com/rdinnager/drmTMB_eval,
# REPORT.md pinned at commit 945da24f, 2026-08-29), Wave 2a (M3, S1, S3).
# See .unlazy/dinnage-wave2a/gates/leaf-A4a.md for the ledger.

fast_control <- drm_control(se = FALSE)

# ---- M3: check_drm()'s fixed_gradient row on correct, large-n fits --------
#
# Dinnage's report measured `fixed_gradient` (an ABSOLUTE `max|g| <=
# gradient_tolerance = 1e-3` criterion, R/check.R) warning on 19/20 correct
# Gaussian location-scale fits at n = 1000 and 20/20 at n = 4000, so
# `attr(check_drm(fit), "ok")` carried no information at realistic n.
#
# On this checkout that failure mode does not reproduce: `drm_newton_polish()`
# (issue #1130, `drm_control(newton_polish = TRUE)` by default, R/drmTMB.R)
# lands between the report's pin and this checkout and Newton-polishes every
# fit's outer gradient below `grad_tol = 1e-8` -- two orders of magnitude
# under `check_drm()`'s default `gradient_tolerance = 1e-3` -- before
# `check_drm()` ever evaluates it. Scanning Gaussian location-scale fits at
# n = 2000 (20 seeds), a weighted n = 300 Gaussian fit (10 seeds), and a
# skew-normal location-scale fit at n = 4000 (5 seeds) found no firing case
# (see ledger EVIDENCE). M3 is therefore recorded ABANDON in the ledger
# (already fixed on main by an orthogonal change) rather than reworked here;
# this test is the regression guard that keeps it that way.
test_that("fixed_gradient does not fire on a correct Gaussian fit at n = 2000 (Dinnage audit M3)", {
  skip_on_cran()
  set.seed(20260913)
  n <- 2000
  dat <- data.frame(x = stats::rnorm(n))
  dat$y <- 1 + 2 * dat$x + stats::rnorm(n, sd = exp(0.3 * dat$x))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat,
    control = drm_control(keep_tmb_object = TRUE)
  )
  chk <- check_drm(fit)
  expect_true(attr(chk, "ok"))
  fg <- chk[chk$check == "fixed_gradient", ]
  expect_identical(nrow(fg), 1L)
  expect_identical(fg$status, "ok")
})

# ---- S1: fitted_distribution()$p()/$d() scalar recycling ------------------
#
# `ifelse(test, yes, no)` returns a result the length of `test`, not of the
# longer `yes`/`no` operand, so a scalar `y` against a length-n `params$mu`
# silently returned row 1's value only, for every atom-bearing count family
# built with an `ifelse()`-based d()/p() (zi_poisson, zi_nbinom2,
# hurdle_nbinom2, truncated_nbinom2). `poisson`/`nbinom2` build d()/p()
# directly on `stats::d/ppois`/`d/pnbinom`, with no `ifelse()`, and already
# recycled correctly -- included below as the unaffected baseline.
# `drm_recycle_scalar_arg()` (R/family-dpq.R) closes the gap for the affected
# families.

s1_scalar_recycling_case <- function(label, fit, threshold = 0) {
  fd <- fitted_distribution(fit)
  n <- nobs(fit)
  scalar_p <- fd$p(threshold)
  vector_p <- fd$p(rep(threshold, n))
  scalar_d <- fd$d(threshold)
  vector_d <- fd$d(rep(threshold, n))
  expect_equal(length(scalar_p), n, info = paste(label, "p(scalar) length"))
  expect_equal(length(scalar_d), n, info = paste(label, "d(scalar) length"))
  expect_equal(scalar_p, vector_p, info = paste(label, "p(scalar) vs p(vector)"))
  expect_equal(scalar_d, vector_d, info = paste(label, "d(scalar) vs d(vector)"))
}

test_that("fitted_distribution()$p()/$d() recycle a scalar threshold across every row (Dinnage audit S1)", {
  skip_on_cran()
  set.seed(20260727)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.4 + 0.25 * x)

  # Baseline (unaffected even before the fix): poisson.
  y_pois <- stats::rpois(n, mu_true)
  fit_pois <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = data.frame(y = y_pois, x = x),
    control = fast_control
  )
  s1_scalar_recycling_case("poisson", fit_pois)
  fd_pois <- fitted_distribution(fit_pois)
  mu_hat <- predict(fit_pois, dpar = "mu")
  expect_equal(fd_pois$p(0), stats::ppois(0, lambda = mu_hat))

  # Baseline (unaffected even before the fix): nbinom2.
  sigma_true <- 0.6
  y_nb <- stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true)
  fit_nb <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = nbinom2(),
    data = data.frame(y = y_nb, x = x),
    control = fast_control
  )
  s1_scalar_recycling_case("nbinom2", fit_nb)
  fd_nb <- fitted_distribution(fit_nb)
  mu_hat_nb <- predict(fit_nb, dpar = "mu")
  sigma_hat_nb <- predict(fit_nb, dpar = "sigma")
  expect_equal(
    fd_nb$p(0),
    stats::pnbinom(0, size = 1 / sigma_hat_nb^2, mu = mu_hat_nb)
  )

  # Affected: zi_poisson (family = poisson() + zi ~ formula).
  zi_true <- 0.3
  y_zip <- ifelse(stats::runif(n) < zi_true, 0L, stats::rpois(n, mu_true))
  fit_zip <- drmTMB(
    bf(y ~ x, zi ~ 1),
    family = poisson(),
    data = data.frame(y = y_zip, x = x),
    control = fast_control
  )
  expect_identical(fit_zip$model$model_type, "zi_poisson")
  s1_scalar_recycling_case("zi_poisson", fit_zip)
  fd_zip <- fitted_distribution(fit_zip)
  mu_hat_zip <- predict(fit_zip, dpar = "mu")
  zi_hat_zip <- predict(fit_zip, dpar = "zi")
  expect_equal(
    fd_zip$p(0),
    zi_hat_zip + (1 - zi_hat_zip) * stats::ppois(0, lambda = mu_hat_zip)
  )

  # Affected: zi_nbinom2 (family = nbinom2() + zi ~ formula).
  y_zinb <- ifelse(
    stats::runif(n) < zi_true,
    0L,
    stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true)
  )
  fit_zinb <- drmTMB(
    bf(y ~ x, sigma ~ 1, zi ~ 1),
    family = nbinom2(),
    data = data.frame(y = y_zinb, x = x),
    control = fast_control
  )
  expect_identical(fit_zinb$model$model_type, "zi_nbinom2")
  s1_scalar_recycling_case("zi_nbinom2", fit_zinb)

  # Affected: truncated_nbinom2 (family = truncated_nbinom2()).
  p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
  u_true <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
  y_trunc <- stats::qnbinom(u_true, size = 1 / sigma_true^2, mu = mu_true)
  fit_trunc <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = truncated_nbinom2(),
    data = data.frame(y = y_trunc, x = x),
    control = fast_control
  )
  expect_identical(fit_trunc$model$model_type, "truncated_nbinom2")
  s1_scalar_recycling_case("truncated_nbinom2", fit_trunc, threshold = 1)

  # Affected: hurdle_nbinom2 (family = truncated_nbinom2() + hu ~ formula).
  hu_true <- 0.25
  y_hurdle <- ifelse(stats::runif(n) < hu_true, 0L, y_trunc)
  fit_hurdle <- drmTMB(
    bf(y ~ x, sigma ~ 1, hu ~ 1),
    family = truncated_nbinom2(),
    data = data.frame(y = y_hurdle, x = x),
    control = fast_control
  )
  expect_identical(fit_hurdle$model$model_type, "hurdle_nbinom2")
  s1_scalar_recycling_case("hurdle_nbinom2", fit_hurdle)
})

# ---- S3: drm_phylo_penalty()'s SD penalty shape ----------------------------
#
# The compiled penalty (`drm_phylo_penalty_value()`, src/drmTMB.cpp) adds
# `rate * sd - log(sd) - log(rate)` per phylogenetic SD, `sd = exp(log_sd)`.
# `test-phylo-penalized-map.R` already validates this closed form against the
# compiled TMB objective's own `fit$phylo_penalty` to `tolerance = 1e-8`, so
# reusing it here (rather than refitting a phylo model) tests the SHAPE the
# corrected `?drm_phylo_penalty` documents: up to a `sd`-independent additive
# constant this is the negative log-density of a `Gamma(shape = 2,
# rate = rate)` distribution, whose mode is `1 / rate` -- so the penalty
# regularises the SD *toward* `1 / rate`, not toward zero (a plain
# exponential-on-SD PC prior would instead be monotonically increasing in
# `sd`, minimized at `sd -> 0`). Chose to correct the DOCS to match this
# already-implemented, already-cited (Chung et al. 2013) penalty rather than
# the CODE: see the ledger and commit message for why.
drm_phylo_penalty_closed_form <- function(sd, rate) {
  rate * sd - log(sd) - log(rate)
}

test_that("the phylogenetic SD penalty is minimized at 1 / rate, not at sd -> 0 (Dinnage audit S3)", {
  pen <- drm_phylo_penalty(sd_u = 1, sd_alpha = 0.05)
  rate <- pen$rate
  mode <- 1 / rate

  near_zero <- drm_phylo_penalty_closed_form(1e-4, rate)
  at_mode <- drm_phylo_penalty_closed_form(mode, rate)
  ten_x_mode <- drm_phylo_penalty_closed_form(10 * mode, rate)

  # The penalty at the documented mode is lower than near sd = 0: the old
  # ("exponential prior, mass at zero") doc's claimed shape -- monotonically
  # increasing away from sd = 0 -- does not hold for the code as implemented.
  expect_lt(at_mode, near_zero)
  # And lower than 10x the mode, confirming a genuine interior minimum (the
  # Gamma(shape = 2, ...) shape), not merely "less bad than near zero".
  expect_lt(at_mode, ten_x_mode)

  # Numeric check against Dinnage's measured default-parameter mode (0.3338).
  expect_equal(mode, 0.3338082, tolerance = 1e-6)
})
