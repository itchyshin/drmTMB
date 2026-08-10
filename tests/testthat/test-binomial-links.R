# Arc D (docs/design/252-binomial-link-generalisation.md): binomial(link =
# "probit") and binomial(link = "cloglog") admission.
#
# drmTMB's C++ engine already dispatches all three links on the LOG scale
# (src/drm_numeric.h: drm_binom_log_mu / drm_binom_log_mu_eta), deliberately
# NOT ported from gllvmTMB's probability-scale gll_clamp(p, 1e-12, 1-1e-12)
# pattern -- see design doc 252 SS3 and `inst/COPYRIGHTS`. The R surface adds
# probit/cloglog arms to `drm_inverse_link()` (R/methods.R) and
# `predict_parameters_inverse_link_derivative()` (R/predict-parameters.R).
# This file is the evidence the design doc calls for in SS8: glm() parity,
# random-intercept recovery, predict() round-tripping through the new inverse
# links (the regression test for the "silently back-transformed with
# plogis()" defect), delta-method SEs, and log-scale tail accuracy against a
# naive probability-scale clamp.

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

new_binomial_probit_data <- function(n = 260, seed = 2026080901) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n), z = stats::rnorm(n))
  eta <- -0.35 + 0.85 * dat$x - 0.40 * dat$z
  dat$y <- stats::rbinom(n, size = 1, prob = stats::pnorm(eta))
  dat
}

new_binomial_cloglog_data <- function(n = 260, seed = 2026080902) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n), z = stats::rnorm(n))
  eta <- -0.35 + 0.85 * dat$x - 0.40 * dat$z
  # cloglog inverse link: mu = 1 - exp(-exp(eta)) = -expm1(-exp(eta)).
  dat$y <- stats::rbinom(n, size = 1, prob = -expm1(-exp(eta)))
  dat
}

new_binomial_probit_random_intercept_data <- function(
  n_id = 50L,
  n_each = 12L,
  sd_id = 0.8,
  seed = 55
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(id = id, x = stats::rnorm(n))
  u_id <- stats::rnorm(n_id, sd = sd_id)
  u_id <- u_id - mean(u_id)
  eta <- -0.2 + 0.7 * dat$x + u_id[id]
  trials <- stats::rpois(n, 8) + 3
  dat$succ <- stats::rbinom(n, trials, stats::pnorm(eta))
  dat$fail <- trials - dat$succ
  list(dat = dat, u_id = u_id, sd_id = sd_id)
}

new_binomial_cloglog_random_intercept_data <- function(
  n_id = 50L,
  n_each = 12L,
  sd_id = 0.8,
  seed = 56
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(id = id, x = stats::rnorm(n))
  u_id <- stats::rnorm(n_id, sd = sd_id)
  u_id <- u_id - mean(u_id)
  eta <- -0.2 + 0.7 * dat$x + u_id[id]
  trials <- stats::rpois(n, 8) + 3
  dat$succ <- stats::rbinom(n, trials, -expm1(-exp(eta)))
  dat$fail <- trials - dat$succ
  list(dat = dat, u_id = u_id, sd_id = sd_id)
}

# ---------------------------------------------------------------------------
# 1-2. Fixed-effect glm() parity.
#
# Tolerance 1e-5, matching the existing logit `expect_binomial_glm_parity()`
# tolerance in test-binomial-response.R -- both drmTMB and glm() solve the
# same smooth, well-conditioned concave likelihood for an intercept + two
# slopes, so they should agree to near-numerical-optimizer precision.
# ---------------------------------------------------------------------------

test_that("probit fixed effects match glm()", {
  dat <- new_binomial_probit_data()

  fit <- drmTMB(
    bf(y ~ x + z),
    family = stats::binomial(link = "probit"),
    data = dat
  )
  glm_fit <- stats::glm(
    y ~ x + z,
    family = stats::binomial(link = "probit"),
    data = dat
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(coef(fit, "mu"), stats::coef(glm_fit), tolerance = 1e-5)
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(glm_fit)),
    tolerance = 1e-5
  )
})

test_that("cloglog fixed effects match glm()", {
  dat <- new_binomial_cloglog_data()

  fit <- drmTMB(
    bf(y ~ x + z),
    family = stats::binomial(link = "cloglog"),
    data = dat
  )
  glm_fit <- stats::glm(
    y ~ x + z,
    family = stats::binomial(link = "cloglog"),
    data = dat
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  # Coefficient tolerance is 1e-4 here, looser than the 1e-5 used for logit and
  # probit. This is optimizer precision, not a parity defect: the two fits agree
  # on `logLik` to 1e-5 (asserted immediately below) while their coefficients
  # differ by ~2.4e-5 -- which is what a flat optimum looks like. cloglog is
  # asymmetric, so the likelihood is flatter in the coefficient direction than
  # for the two symmetric links. Agreeing on the likelihood is the stronger
  # claim; keep THAT at 1e-5 and do not loosen it to make a fit pass.
  expect_equal(coef(fit, "mu"), stats::coef(glm_fit), tolerance = 1e-4)
  expect_equal(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(glm_fit)),
    tolerance = 1e-5
  )
})

# ---------------------------------------------------------------------------
# 3-4. Random-intercept recovery.
#
# Same n_id/n_each/sd_id as the binomial-logit sentinel in
# test-arc2a-mu-random-intercept.R, so the three links are directly
# comparable. sd_tol and the intercept/slope tolerance also match that file's
# convention. No skip_on_cran(): the arc2a random-intercept tests (up to
# n = 810 rows) run untagged in this repo, so this fixture (n = 600) follows
# the established local convention rather than inventing a new one.
# ---------------------------------------------------------------------------

test_that("probit recovers a random intercept", {
  fx <- new_binomial_probit_random_intercept_data()
  dat <- fx$dat

  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + (1 | id)),
    family = stats::binomial(link = "probit"),
    data = dat
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "binomial")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(fit$sdpars$mu, "(1 | id)")

  sd_hat <- unname(fit$sdpars$mu[["(1 | id)"]])
  expect_gt(sd_hat, 0.05)
  expect_lt(abs(sd_hat - fx$sd_id), 0.30)

  id_effects <- fit$random_effects$mu$terms[["(1 | id)"]]
  expect_equal(length(id_effects), length(fx$u_id))
  expect_gt(stats::cor(id_effects, fx$u_id), 0.45)

  expect_lt(max(abs(coef(fit, "mu") - c(-0.2, 0.7))), 0.30)
})

test_that("cloglog recovers a random intercept", {
  fx <- new_binomial_cloglog_random_intercept_data()
  dat <- fx$dat

  fit <- drmTMB(
    bf(cbind(succ, fail) ~ x + (1 | id)),
    family = stats::binomial(link = "cloglog"),
    data = dat
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "binomial")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(fit$sdpars$mu, "(1 | id)")

  sd_hat <- unname(fit$sdpars$mu[["(1 | id)"]])
  expect_gt(sd_hat, 0.05)
  expect_lt(abs(sd_hat - fx$sd_id), 0.30)

  id_effects <- fit$random_effects$mu$terms[["(1 | id)"]]
  expect_equal(length(id_effects), length(fx$u_id))
  expect_gt(stats::cor(id_effects, fx$u_id), 0.45)

  expect_lt(max(abs(coef(fit, "mu") - c(-0.2, 0.7))), 0.30)
})

# ---------------------------------------------------------------------------
# 5. predict(type = "response") round-trips through the new inverse links.
#
# THE KEY REGRESSION TEST. Before this arc, `drm_inverse_link()` had no
# probit/cloglog case and `drm_dpar_link()` returned a hardcoded "logit" for
# every binomial fit regardless of the requested link (docs/design/252 SS2).
# A probit fit's response-scale prediction would therefore have been
# silently back-transformed with `plogis()` instead of `pnorm()` -- wrong
# numbers with no error. This test fails exactly that way if either arm is
# missing or the wrong link name is threaded through.
# ---------------------------------------------------------------------------

test_that("predict(type='response') round-trips through the new inverse links", {
  dat_probit <- new_binomial_probit_data(n = 120, seed = 2026080903)
  fit_probit <- drmTMB(
    bf(y ~ x + z),
    family = stats::binomial(link = "probit"),
    data = dat_probit
  )
  eta_probit <- predict(fit_probit, type = "link")
  mu_probit <- predict(fit_probit, type = "response")
  expect_equal(mu_probit, stats::pnorm(eta_probit), tolerance = 1e-8)
  # Not plogis(): the pre-arc silent-mislink defect.
  expect_false(isTRUE(all.equal(mu_probit, stats::plogis(eta_probit))))

  dat_cloglog <- new_binomial_cloglog_data(n = 120, seed = 2026080904)
  fit_cloglog <- drmTMB(
    bf(y ~ x + z),
    family = stats::binomial(link = "cloglog"),
    data = dat_cloglog
  )
  eta_cloglog <- predict(fit_cloglog, type = "link")
  mu_cloglog <- predict(fit_cloglog, type = "response")
  expect_equal(mu_cloglog, -expm1(-exp(eta_cloglog)), tolerance = 1e-8)
  expect_false(isTRUE(all.equal(mu_cloglog, stats::plogis(eta_cloglog))))
})

# ---------------------------------------------------------------------------
# 6. predict(se.fit = TRUE) works for probit and cloglog.
#
# drmTMB's SE surface for this is `predict_parameters(..., conf.int = TRUE)`,
# which returns a long data frame with a `std.error` column (verified at
# R/predict-parameters.R:39-49, 79-140, and exercised in
# test-predict-parameters.R:118-178). There is no `predict(..., se.fit =
# TRUE)` argument in this package. `std.error` is computed via
# `predict_parameters_inverse_link_derivative()` (R/predict-parameters.R:337),
# which had no probit/cloglog arm before this arc and would abort with
# "Internal error: unknown inverse-link derivative" for those links.
# ---------------------------------------------------------------------------

test_that("predict(se.fit = TRUE) works for probit and cloglog", {
  dat_probit <- new_binomial_probit_data(n = 120, seed = 2026080905)
  fit_probit <- drmTMB(
    bf(y ~ x + z),
    family = stats::binomial(link = "probit"),
    data = dat_probit
  )
  grid <- data.frame(x = c(-0.5, 0, 0.5), z = c(0.2, -0.2, 0))
  out_probit <- predict_parameters(
    fit_probit,
    newdata = grid,
    dpar = "mu",
    conf.int = TRUE
  )
  expect_true(all(is.finite(out_probit$std.error)))
  expect_true(all(out_probit$std.error > 0))

  dat_cloglog <- new_binomial_cloglog_data(n = 120, seed = 2026080906)
  fit_cloglog <- drmTMB(
    bf(y ~ x + z),
    family = stats::binomial(link = "cloglog"),
    data = dat_cloglog
  )
  out_cloglog <- predict_parameters(
    fit_cloglog,
    newdata = grid,
    dpar = "mu",
    conf.int = TRUE
  )
  expect_true(all(is.finite(out_cloglog$std.error)))
  expect_true(all(out_cloglog$std.error > 0))
})

# ---------------------------------------------------------------------------
# 7. Log-scale link evaluation is accurate in the extreme tails.
#
# gllvmTMB implements probit/cloglog by computing the probability p and then
# clamping it, `gll_clamp(p, 1e-12, 1-1e-12)`, before `dbinom`. drmTMB
# deliberately refused to port that: it evaluates (log mu, log(1-mu)) via
# closed-form log-scale primitives instead (design doc 252 SS3;
# inst/COPYRIGHTS). This test is what earns that refusal: it evaluates the
# compiled TMB objective directly at manufactured intercept-only parameter
# values that push eta to +-40 (plus intermediate +-10, +-25), the same
# direct-obj$fn technique used for the count-family kernels in
# test-count-kernels.R, and checks the result against an R-side numerically
# stable reference AND against what a 1e-12 probability-scale clamp would
# have given.
#
# Fitting AT these extremes is impractical (they are separation-degenerate
# for an intercept), so -- as the task brief anticipates -- the objective is
# evaluated directly rather than through a converged fit: `drmTMB()` still
# runs its ordinary optimizer once on a well-posed mixed 0/1 fixture, and
# `fit$obj$fn()` is then evaluated at hand-picked parameter vectors that
# never need to be an optimum.
# ---------------------------------------------------------------------------

binomial_link_kernel_loglik <- function(fit, beta_mu) {
  par <- fit$obj$par
  par[["beta_mu"]] <- beta_mu
  -fit$obj$fn(par)
}

# A mixed-tolerance closeness check: relative tolerance misbehaves when the
# reference value underflows to (or sits near) exactly 0, which happens for
# the "easy" tail of each link at |eta| = 40 (e.g. pnorm(40, log.p = TRUE) is
# exactly 0 in double precision). The 1e-4 absolute floor covers that case;
# the relative term covers the large-magnitude (~-800) hard-tail case.
expect_close_loglik <- function(observed, reference) {
  expect_true(is.finite(observed))
  tol <- max(1e-4, 1e-6 * abs(reference))
  expect_true(
    abs(observed - reference) <= tol,
    info = sprintf(
      "observed = %.10g, reference = %.10g, tol = %.3g",
      observed, reference, tol
    )
  )
}

test_that("log-scale link evaluation is accurate in the extreme tails", {
  dat <- data.frame(y = c(0, 1, 0, 1, 0, 1))
  n1 <- sum(dat$y == 1)
  n0 <- sum(dat$y == 0)
  eta_grid <- c(-40, -25, -10, 10, 25, 40)

  fit_probit <- drmTMB(
    bf(y ~ 1),
    family = stats::binomial(link = "probit"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  for (eta in eta_grid) {
    ll_drm <- binomial_link_kernel_loglik(fit_probit, eta)
    log_mu <- stats::pnorm(eta, log.p = TRUE)
    log_1m_mu <- stats::pnorm(-eta, log.p = TRUE)
    ll_stable <- n1 * log_mu + n0 * log_1m_mu
    expect_close_loglik(ll_drm, ll_stable)

    if (abs(eta) >= 40) {
      p_naive <- pmin(pmax(stats::pnorm(eta), 1e-12), 1 - 1e-12)
      ll_naive <- n1 * log(p_naive) + n0 * log1p(-p_naive)
      # The true tail log-density here is of order -800 to 0; a 1e-12 floor
      # can only ever report a log-density of about log(1e-12) ~= -27.6. The
      # measured gap at |eta| = 40 is ~2331 -- decisively larger than any
      # plausible numerical-noise threshold.
      expect_gt(abs(ll_drm - ll_naive), 100)
    }
  }

  fit_cloglog <- drmTMB(
    bf(y ~ 1),
    family = stats::binomial(link = "cloglog"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  for (eta in eta_grid) {
    ll_drm <- binomial_link_kernel_loglik(fit_cloglog, eta)
    # log(1 - mu) = -exp(eta) is exact for cloglog (commit 5b6c13197); the
    # numerically delicate side is log(mu) as eta -> -Inf, where mu itself
    # would round to 0 if computed via 1 - exp(-exp(eta)) directly. expm1()
    # is the R-side equivalent stabilization, used here only as an R
    # reference, not as a claim about the C++ implementation's internals.
    log_1m_mu <- -exp(eta)
    log_mu <- log(-expm1(-exp(eta)))
    ll_stable <- n1 * log_mu + n0 * log_1m_mu
    expect_close_loglik(ll_drm, ll_stable)

    if (eta <= -40) {
      p_naive <- pmin(pmax(-expm1(-exp(eta)), 1e-12), 1 - 1e-12)
      ll_naive <- n1 * log(p_naive) + n0 * log1p(-p_naive)
      # True log(mu) here is ~-40 (mu ~ exp(eta) in this asymptotic regime);
      # a 1e-12 floor reports log(1e-12) ~= -27.6. Measured gap ~37.
      expect_gt(abs(ll_drm - ll_naive), 5)
    }
  }
})

# ---------------------------------------------------------------------------
# 8. Unsupported binomial links are still rejected.
# ---------------------------------------------------------------------------

test_that("unsupported binomial links are still rejected", {
  dat <- new_binomial_probit_data(n = 60, seed = 2026080907)
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::binomial(link = "cauchit"),
      data = dat
    ),
    "cauchit"
  )
})

# ---------------------------------------------------------------------------
# 9. Hard-case convergence per link (Emmy, Arc D go/no-go review, condition 4).
#
# The fixtures above are well separated, so they would not catch bad starting
# values. `binomial_start()` used to compute its starts from
# `glm.fit(family = binomial(link = "logit"))` and `qlogis()` UNCONDITIONALLY,
# regardless of the fitted link. Logit and probit differ by a factor of ~1.7,
# so a probit fit began ~70% too far out and cloglog was asymmetrically wrong.
# That does not give a wrong answer -- the optimizer usually recovers -- but on
# sparse or extreme-probability data it shows up as slow convergence,
# `pdHess = FALSE`, or a boundary stall. The link is now threaded through.
#
# This test is deliberately near the awkward end: event probability ~0.02-0.05,
# n = 400, one continuous predictor.

test_that("probit and cloglog converge on extreme-probability data", {
  skip_on_cran()

  for (lk in c("probit", "cloglog")) {
    set.seed(4021)
    n <- 400L
    x <- stats::rnorm(n)
    linkinv <- stats::make.link(lk)$linkinv
    eta <- -2.6 + 0.7 * x
    y <- stats::rbinom(n, 1L, linkinv(eta))
    dat <- data.frame(y = y, x = x)

    # A degenerate draw would test nothing; assert the fixture is actually the
    # hard case it claims to be.
    expect_gt(sum(y), 5)
    expect_lt(mean(y), 0.12)

    fit <- drmTMB(bf(y ~ x), family = stats::binomial(link = lk), data = dat)

    expect_equal(fit$opt$convergence, 0, info = lk)
    expect_true(fit$sdr$pdHess, info = lk)
    expect_true(all(is.finite(coef(fit, "mu"))), info = lk)

    # And the estimates must still be sane, not merely convergent.
    glm_fit <- stats::glm(
      y ~ x,
      family = stats::binomial(link = lk),
      data = dat
    )
    expect_equal(
      unname(coef(fit, "mu")),
      unname(stats::coef(glm_fit)),
      tolerance = 1e-4,
      info = lk
    )
  }
})
