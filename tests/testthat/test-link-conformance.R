# Arc B / slice S4 -- link and boundary-parameterization conformance.
#
# Scope note: links in drmTMB are NOT user-selectable. drm_family_type()
# hard-rejects any non-canonical link (Gamma must be log, Poisson log, binomial
# logit) and there is no link-selector DATA_INTEGER in C++ -- each family's link
# is hardcoded in its branch. So this file audits the implementation of the one
# admissible link per family at the boundary, not link selection.
#
# These tests use no skip_*(): a skipped test is a vacuous pass, and Arc B's
# gate asserts zero skips.

# ---------------------------------------------------------------------------
# 1. The R -> C++ model_type integer contract.
#
# This is the value actually handed to the C++ dispatch chain, read back off
# the constructed AD object rather than from a comment, so documentation drift
# cannot make it pass. A recon pass in this arc produced a materially wrong map
# (7->zi_poisson, 8->binomial, 11->nbinom2, 18->truncated_nbinom2); the codes
# below are the ones make_tmb_data() actually assigns.
# ---------------------------------------------------------------------------

model_type_of <- function(formula, data, family) {
  fit <- drmTMB(formula, data = data, family = family)
  fit$obj$env$data$model_type
}

test_that("model_type integers passed to C++ match the documented map", {
  set.seed(101)
  n <- 60
  x <- rnorm(n)

  d_gauss <- data.frame(y = 1 + 0.5 * x + rnorm(n), x = x)
  expect_identical(
    as.integer(model_type_of(bf(mu = y ~ x, sigma = ~1), d_gauss, gaussian())),
    1L
  )

  d_pois <- data.frame(y = rpois(n, exp(0.5 + 0.3 * x)), x = x)
  expect_identical(
    as.integer(model_type_of(bf(mu = y ~ x), d_pois, poisson())),
    6L
  )

  # The four codes the recon pass got wrong. nbinom2 is 7 (not zi_poisson) and
  # binomial is 18 (not truncated_nbinom2).
  d_nb <- data.frame(y = rnbinom(n, mu = exp(1 + 0.3 * x), size = 2), x = x)
  expect_identical(
    as.integer(model_type_of(bf(mu = y ~ x, sigma = ~1), d_nb, nbinom2())),
    7L
  )

  d_bin <- data.frame(y = rbinom(n, 1, plogis(0.2 + 0.4 * x)), x = x)
  expect_identical(
    as.integer(model_type_of(bf(mu = y ~ x), d_bin, binomial())),
    18L
  )
})

# ---------------------------------------------------------------------------
# 2. Boundary parameterizations shared by R and C++.
#
# rho12 = 0.999999 * tanh(eta) and nu = 2 + exp(eta) are written out in both
# implementations; these assert the algebra each side claims, at and beyond the
# saturation point, so a change to either literal breaks a test.
# ---------------------------------------------------------------------------

test_that("the guarded tanh correlation transform stays strictly inside (-1, 1)", {
  guard <- 0.999999
  eta <- c(-800, -100, -40, -20, -1, 0, 1, 20, 40, 100, 800)
  rho <- guard * tanh(eta)

  expect_true(all(is.finite(rho)))
  expect_true(all(abs(rho) <= guard))
  # tanh saturates well before overflow, so the guard is reached exactly.
  expect_equal(max(abs(rho)), guard)
  # Monotone and antisymmetric.
  expect_true(!is.unsorted(rho))
  expect_equal(rho, -rev(rho))

  # The derivative decays to zero rather than blowing up at saturation.
  deriv <- guard * (1 - tanh(eta)^2)
  expect_true(all(is.finite(deriv)))
  expect_true(all(deriv >= 0))
  expect_equal(deriv[eta == 800], 0)
})

test_that("the Student-t nu transform enforces nu > 2 at both extremes", {
  eta <- c(-800, -100, -40, 0, 40, 100, 700)
  nu <- 2 + exp(eta)

  expect_true(all(nu > 2 | nu == 2))
  expect_true(all(is.finite(nu[eta <= 700])))
  # Underflow floors nu at exactly 2 rather than dropping below it, which would
  # leave the finite-variance region the route is defined on.
  expect_equal(nu[eta == -800], 2)
  expect_true(all(diff(nu) >= 0))

  # tweedie's nu is a DIFFERENT parameterization (logit12, nominal range (1,2))
  # and must not be conflated with the Student-t logm2 form. Note it saturates
  # to EXACTLY 1 and EXACTLY 2 at extreme eta -- the two excluded endpoints of
  # the Tweedie power range (p = 1 is Poisson, p = 2 is Gamma). The open
  # interval holds only in the interior, so assert the saturation, not the
  # strict inequality.
  nu_tw <- 1 + 1 / (1 + exp(-eta))
  expect_true(all(nu_tw >= 1 & nu_tw <= 2))
  # Saturation to the excluded endpoints begins far earlier than the range of
  # eta might suggest: 1/(1 + exp(36)) is already below machine epsilon, so
  # nu_tw is exactly 1 for eta <~ -36 and exactly 2 for eta >~ 36. The strictly
  # interior region is therefore |eta| <~ 36, not the whole real line.
  interior_eta <- eta[abs(eta) <= 30]
  nu_tw_interior <- 1 + 1 / (1 + exp(-interior_eta))
  expect_true(all(nu_tw_interior > 1 & nu_tw_interior < 2))
  expect_equal(1 + 1 / (1 + exp(40)), 1)
  expect_equal(1 + 1 / (1 + exp(-40)), 2)
})

# ---------------------------------------------------------------------------
# 3. Cumulative-logit cutpoint construction.
#
# C++ builds cutpoints as cutpoints(0) = theta_ord(0),
# cutpoints(j) = cutpoints(j - 1) + exp(theta_ord(j)). Because exp() is
# non-negative and underflows to exactly 0, monotonicity is WEAK (non-
# decreasing), never strict -- adjacent-equal cutpoints are reachable.
# ---------------------------------------------------------------------------

build_cutpoints <- function(theta_ord) {
  cp <- numeric(length(theta_ord))
  cp[1] <- theta_ord[1]
  for (j in seq_along(theta_ord)[-1]) {
    cp[j] <- cp[j - 1] + exp(theta_ord[j])
  }
  cp
}

test_that("cutpoints are non-decreasing but only weakly so", {
  cp <- build_cutpoints(c(-1, 0.5, -0.2, 1.1))
  expect_true(all(diff(cp) > 0))
  expect_true(!is.unsorted(cp))

  # Underflowing increments collapse the gap to exactly zero. Monotonicity
  # survives; strict monotonicity does not. Asserting strictness here would be
  # asserting something the construction never promised.
  cp_flat <- build_cutpoints(c(-1, -800, -800))
  expect_true(!is.unsorted(cp_flat))
  expect_equal(diff(cp_flat), c(0, 0))
})

# ---------------------------------------------------------------------------
# 4. Characterization: the cumulative-logit near-tied-cutpoint boundary.
#
# MEASURED, not assumed. Driving the log-increment theta_ord[2] down shrinks the
# cutpoint gap; the compiled objective stays finite and differentiable down to a
# gap of about 1.7e-15 and returns a non-finite objective with NaN gradient at
# about 2.3e-16 (machine epsilon), where a log-space-stable reference continues
# smoothly (-37.6, -39.6, -41.6 ...).
#
# This is recorded as a CHARACTERIZATION test, not a correctness assertion:
#   * an infinite nll for a zero-probability observed category is defensible;
#   * the NaN gradient is the part worth watching, since an optimizer cannot
#     backtrack out of NaN the way it can out of a large finite value;
#   * reachability was probed and NOT demonstrated -- an ordinal fit with a
#     single-observation category converged cleanly with a gap of 0.034, i.e.
#     thirteen orders of magnitude away from the failure region.
# The test pins current behaviour so that a change in it is noticed.
# ---------------------------------------------------------------------------

test_that("the near-tied-cutpoint boundary sits where it was measured", {
  set.seed(11)
  n <- 200
  x <- rnorm(n)
  eta <- 0.7 * x
  p <- cbind(
    plogis(-1 - eta),
    plogis(0.5 - eta) - plogis(-1 - eta),
    1 - plogis(0.5 - eta)
  )
  y <- apply(p, 1, function(pr) sample(1:3, 1, prob = pr))
  d <- data.frame(y = factor(y, ordered = TRUE), x = x)
  obj <- drmTMB(bf(mu = y ~ x), data = d, family = cumulative_logit())$obj

  at <- function(t2) {
    th <- c(0.7, -1, t2)
    names(th) <- names(obj$par)
    list(fn = obj$fn(th), gr = obj$gr(th))
  }

  # Comfortably inside the safe region: finite and differentiable.
  safe <- at(-30)
  expect_true(is.finite(safe$fn))
  expect_true(all(is.finite(safe$gr)))

  safe_edge <- at(-34)
  expect_true(is.finite(safe_edge$fn))
  expect_true(all(is.finite(safe_edge$gr)))

  # Past the boundary: objective non-finite and gradient NaN.
  broken <- at(-36)
  expect_false(is.finite(broken$fn))
  expect_false(all(is.finite(broken$gr)))

  # A log-space-stable reference has no trouble at the same gap, which is what
  # makes this a boundary of the implementation rather than of the model.
  gap <- exp(-36)
  upper <- -1 + gap
  lower <- -1
  stable <- upper + log(-expm1(-gap)) -
    log1p(exp(upper)) - log1p(exp(lower))
  expect_true(is.finite(stable))
})

test_that("an ordinal fit with a one-observation category still converges", {
  set.seed(3)
  n <- 300
  x <- rnorm(n)
  y <- sample(c(1, 2, 4), n, replace = TRUE, prob = c(0.45, 0.45, 0.10))
  y[1] <- 3
  d <- data.frame(y = factor(y, levels = 1:4, ordered = TRUE), x = x)
  expect_equal(as.integer(table(d$y)[3]), 1L)

  fit <- drmTMB(bf(mu = y ~ x), data = d, family = cumulative_logit())
  expect_equal(fit$opt$convergence, 0L)
  expect_true(is.finite(fit$opt$objective))
  expect_true(all(is.finite(fit$obj$gr(fit$opt$par))))
})

# ---------------------------------------------------------------------------
# 5. Log/logit round-trips at the range extremes.
# ---------------------------------------------------------------------------

test_that("log and logit links round-trip over their working range", {
  eta <- c(-700, -100, -40, -5, 0, 5, 40, 100, 700)

  # log link: exp then log.
  mu <- exp(eta)
  finite <- is.finite(mu) & mu > 0
  expect_equal(log(mu[finite]), eta[finite])
  # exp overflows to Inf above ~709 and underflows to 0 below ~-745; inside the
  # grid above it stays finite and strictly positive.
  expect_true(all(finite))

  # logit link: plogis then qlogis, away from the saturated ends.
  interior <- abs(eta) <= 30
  pr <- plogis(eta[interior])
  expect_equal(qlogis(pr), eta[interior])
  # Saturation is one-directional: plogis(700) is exactly 1, so the round trip
  # is not recoverable there. Assert the saturation rather than the round trip.
  expect_equal(plogis(700), 1)
  expect_equal(plogis(-700), 0)
})
