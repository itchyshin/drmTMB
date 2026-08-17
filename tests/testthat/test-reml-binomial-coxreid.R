# Non-Gaussian REML for the binomial family (doc 224, object O2). drmTMB implements
# REML by folding the mean fixed effect `beta_mu` into TMB's Laplace random set
# (drm_apply_estimator_spec). For a binomial GLMM that fold IS the joint-Laplace
# restricted likelihood, and it equals glmmTMB(REML = TRUE), which builds its restricted
# likelihood by the identical fixed-effect-into-random construction. So the tight oracle
# is glmmTMB REML (not the marginalize-u-first rolled Cox-Reid, which is a different,
# AGHQ-based object -- see doc 224 S4.1). These tests: (1) the deterministic identity
# drmTMB REML == glmmTMB REML on the RE-SD; (2) the fixture-specific ordering REML > ML; and
# (3) the uncertainty path (vcov/sdreport) is finite under binomial REML.

binom_re_fixture <- function(nid = 40L, neach = 8L, seed = 20260718L) {
  set.seed(seed)
  g <- factor(rep(seq_len(nid), each = neach))
  N <- nid * neach
  x <- stats::rnorm(N)
  b0 <- -0.2; b1 <- 0.6; sd_re <- 0.7
  u <- stats::rnorm(nid, 0, sd_re)
  eta <- b0 + b1 * x + u[as.integer(g)]
  y <- stats::rbinom(N, 1L, stats::plogis(eta))
  list(
    data = data.frame(
      y = y,
      successes = y,
      failures = 1L - y,
      x = x,
      g = g
    ),
    sd_re = sd_re
  )
}

binom_slope_fixture <- function(nid = 60L, neach = 12L, seed = 20260808L) {
  set.seed(seed)
  g <- factor(rep(seq_len(nid), each = neach))
  x <- rep(seq(-1.5, 1.5, length.out = neach), times = nid)
  u1 <- stats::rnorm(nid, 0, 1)
  eta <- -0.25 + 0.4 * x + u1[as.integer(g)] * x
  y <- stats::rbinom(length(x), 1L, stats::plogis(eta))
  data.frame(y = y, x = x, g = g)
}

binom_grouped_fixture <- function(nid = 50L, neach = 10L, trials = 5L, seed = 20260809L) {
  set.seed(seed)
  g <- factor(rep(seq_len(nid), each = neach))
  x <- rep(seq(-1.5, 1.5, length.out = neach), times = nid)
  u0 <- stats::rnorm(nid, 0, 0.75)
  u1 <- stats::rnorm(nid, 0, 0.85)
  eta <- -0.25 + 0.4 * x + u0[as.integer(g)] + u1[as.integer(g)] * x
  successes <- stats::rbinom(length(x), trials, stats::plogis(eta))
  data.frame(successes, failures = trials - successes, x, g)
}

drm_re_sd <- function(fit) {
  s <- summary(fit$sdr)
  i <- which(rownames(s) == "sd_mu_re")
  if (length(i)) unname(s[i[1L], "Estimate"]) else NA_real_
}

test_that("fixed-only binomial REML fails early for Bernoulli and cbind responses", {
  fx <- binom_re_fixture()
  err <- "Binomial `REML` requires exactly one admitted ordinary unlabelled `mu` random-effect term"

  expect_error(
    drmTMB(bf(y ~ x), family = binomial(), data = fx$data, REML = TRUE),
    err,
    fixed = TRUE
  )
  expect_error(
    drmTMB(
      bf(cbind(successes, failures) ~ x),
      family = binomial(),
      data = fx$data,
      REML = TRUE
    ),
    err,
    fixed = TRUE
  )

  fit_bernoulli_ml <- drmTMB(
    bf(y ~ x),
    family = binomial(),
    data = fx$data,
    REML = FALSE
  )
  fit_cbind_ml <- drmTMB(
    bf(cbind(successes, failures) ~ x),
    family = binomial(),
    data = fx$data,
    REML = FALSE
  )
  expect_identical(fit_bernoulli_ml$opt$convergence, 0L)
  expect_identical(fit_cbind_ml$opt$convergence, 0L)
})

test_that("binomial REML RE-SD matches glmmTMB(REML = TRUE) to Laplace-fold tolerance", {
  skip_if_not_installed("glmmTMB")
  fx <- binom_re_fixture()
  fit_reml <- drmTMB(bf(y ~ x + (1 | g)), family = binomial(), data = fx$data, REML = TRUE)
  gm_reml <- glmmTMB::glmmTMB(y ~ x + (1 | g), family = binomial(), data = fx$data, REML = TRUE)
  g_sd <- attr(glmmTMB::VarCorr(gm_reml)$cond$g, "stddev")

  expect_identical(fit_reml$opt$convergence, 0L)
  expect_true(isTRUE(fit_reml$sdr$pdHess))
  # Same joint-Laplace restricted likelihood -> RE-SD agrees to ~1e-6 (observed ~7e-9).
  expect_equal(drm_re_sd(fit_reml), unname(g_sd), tolerance = 1e-5)
})

test_that("binomial independent-slope REML matches glmmTMB and has finite uncertainty", {
  skip_if_not_installed("glmmTMB")
  dat <- binom_slope_fixture()
  fit_reml <- drmTMB(
    bf(y ~ x + (0 + x | g)),
    family = binomial(),
    data = dat,
    REML = TRUE
  )
  gm_reml <- glmmTMB::glmmTMB(
    y ~ x + (0 + x | g),
    family = binomial(),
    data = dat,
    REML = TRUE
  )
  g_sd <- attr(glmmTMB::VarCorr(gm_reml)$cond$g, "stddev")

  expect_identical(fit_reml$opt$convergence, 0L)
  expect_true(isTRUE(fit_reml$sdr$pdHess))
  expect_equal(drm_re_sd(fit_reml), unname(g_sd[[1L]]), tolerance = 1e-5)
  expect_true(all(is.finite(as.matrix(stats::vcov(fit_reml)))))
})

test_that("grouped-binomial intercept and slope REML match glmmTMB", {
  skip_if_not_installed("glmmTMB")
  dat <- binom_grouped_fixture()
  response <- cbind(dat$successes, dat$failures)

  fit_intercept <- drmTMB(
    bf(cbind(successes, failures) ~ x + (1 | g)),
    family = binomial(), data = dat, REML = TRUE
  )
  gm_intercept <- glmmTMB::glmmTMB(
    response ~ x + (1 | g), family = binomial(), data = dat, REML = TRUE
  )
  fit_slope <- drmTMB(
    bf(cbind(successes, failures) ~ x + (0 + x | g)),
    family = binomial(), data = dat, REML = TRUE
  )
  gm_slope <- glmmTMB::glmmTMB(
    response ~ x + (0 + x | g), family = binomial(), data = dat, REML = TRUE
  )

  expect_identical(fit_intercept$opt$convergence, 0L)
  expect_true(isTRUE(fit_intercept$sdr$pdHess))
  expect_equal(
    drm_re_sd(fit_intercept),
    unname(attr(glmmTMB::VarCorr(gm_intercept)$cond$g, "stddev")),
    tolerance = 1e-5
  )
  expect_identical(fit_slope$opt$convergence, 0L)
  expect_true(isTRUE(fit_slope$sdr$pdHess))
  expect_equal(
    drm_re_sd(fit_slope),
    unname(attr(glmmTMB::VarCorr(gm_slope)$cond$g, "stddev")[[1L]]),
    tolerance = 1e-5
  )
})

test_that("binomial REML gives a larger RE-SD than ML on the frozen fixture", {
  fx <- binom_re_fixture()
  fit_ml <- drmTMB(bf(y ~ x + (1 | g)), family = binomial(), data = fx$data, REML = FALSE)
  fit_reml <- drmTMB(bf(y ~ x + (1 | g)), family = binomial(), data = fx$data, REML = TRUE)
  expect_identical(fit_ml$opt$convergence, 0L)
  expect_identical(fit_reml$opt$convergence, 0L)
  # On this one frozen fixture 0.9547 (REML) > 0.9235 (ML). This direction check
  # is not a generic debiasing, recovery, or coverage claim.
  expect_gt(drm_re_sd(fit_reml), drm_re_sd(fit_ml))
})

test_that("binomial REML exposes a finite uncertainty path (sdreport / vcov)", {
  fx <- binom_re_fixture()
  fit_reml <- drmTMB(bf(y ~ x + (1 | g)), family = binomial(), data = fx$data, REML = TRUE)
  expect_true(is.finite(drm_re_sd(fit_reml)))
  V <- try(stats::vcov(fit_reml), silent = TRUE)
  expect_false(inherits(V, "try-error"))
  expect_true(all(is.finite(as.matrix(V))))
})

test_that("binomial REML preserves unsupported-shape and missing-engine rejections", {
  fx <- binom_re_fixture()
  # Rejection preserved; the MESSAGE moved. The experimental MSPL lane admits
  # one complete-data unlabelled correlated q = 2 binomial block, so
  # `(1 + x | g)` is now parsed rather than refused outright. Under REML it is
  # therefore caught by drm_validate_binomial_q2_context() -- which names the
  # actual reason -- instead of by validate_binomial_mu_random_terms().
  # The safety property is unchanged: correlated q = 2 binomial + REML errors.
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | g)),
      family = binomial(),
      data = fx$data,
      REML = TRUE
    ),
    "Correlated q = 2 binomial random effects are not implemented with",
    fixed = TRUE
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g) + (0 + x | g)),
      family = binomial(),
      data = fx$data,
      REML = TRUE
    ),
    "requires exactly one admitted ordinary unlabelled `mu` random-effect term",
    fixed = TRUE
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g) + (1 | h)),
      family = binomial(),
      data = transform(fx$data, h = factor(rep(seq_len(20L), length.out = nrow(fx$data)))),
      REML = TRUE
    ),
    "requires exactly one admitted ordinary unlabelled `mu` random-effect term",
    fixed = TRUE
  )
  # Same message move as above: labelled blocks are still refused by
  # validate_binomial_mu_random_terms(), but its wording widened when the
  # experimental unlabelled correlated q = 2 block was admitted. Labelled
  # `(1 | p | g)` remains unsupported.
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | p | g)),
      family = binomial(),
      data = fx$data,
      REML = TRUE
    ),
    "Binomial `mu` supports independent random intercepts/slopes",
    fixed = TRUE
  )

  dat_missing <- fx$data
  dat_missing$y[[1L]] <- NA_integer_
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g)),
      family = binomial(),
      data = dat_missing,
      missing = miss_control(response = "include"),
      REML = TRUE
    ),
    "`REML` is not implemented with explicit missing-data engines yet",
    fixed = TRUE
  )
})

test_that("binomial REML rejects every structured mu provider", {
  # #1048 admits ML binomial q1 phylo(1 | id) only. Under REML that slice still
  # refuses: the Cox-Reid route requires exactly one ordinary unlabelled mu RE.
  # Other structured providers remain phase-1 refusals for binomial.
  fx <- binom_re_fixture(nid = 8L, neach = 4L)
  ids <- levels(fx$data$g)
  # Ultrametric so phylo tree validation does not mask the REML fence.
  tree <- ape::rcoal(length(ids))
  tree$tip.label <- ids
  coords <- cbind(x = seq_along(ids), y = rep(c(0, 1), length.out = length(ids)))
  rownames(coords) <- ids
  A <- diag(length(ids))
  dimnames(A) <- list(ids, ids)

  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 | g, tree = tree)),
      family = binomial(),
      data = fx$data,
      REML = TRUE
    ),
    "Binomial `REML` requires exactly one admitted ordinary unlabelled `mu`",
    fixed = TRUE
  )

  deferred_calls <- list(
    quote(drmTMB(bf(y ~ x + spatial(1 | g, coords = coords)), family = binomial(), data = fx$data, REML = TRUE)),
    quote(drmTMB(bf(y ~ x + animal(1 | g, A = A)), family = binomial(), data = fx$data, REML = TRUE)),
    quote(drmTMB(bf(y ~ x + relmat(1 | g, K = A)), family = binomial(), data = fx$data, REML = TRUE))
  )
  for (call in deferred_calls) {
    expect_error(
      eval(call),
      "Structured-effect syntax is planned, not implemented",
      fixed = TRUE
    )
  }

  fx$data$partner1 <- fx$data$g
  fx$data$partner2 <- factor(rep(ids, each = 4L))
  expect_error(
    drmTMB(
      bf(y ~ x + phylo_interaction(1 | partner1:partner2, tree1 = tree, tree2 = tree)),
      family = binomial(), data = fx$data, REML = TRUE
    ),
    "Structured-effect syntax is planned, not implemented",
    fixed = TRUE
  )
})
