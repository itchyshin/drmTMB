# Non-Gaussian REML for the binomial family (doc 224, object O2). drmTMB implements
# REML by folding the mean fixed effect `beta_mu` into TMB's Laplace random set
# (drm_apply_estimator_spec). For a binomial GLMM that fold IS the joint-Laplace
# restricted likelihood, and it equals glmmTMB(REML = TRUE), which builds its restricted
# likelihood by the identical fixed-effect-into-random construction. So the tight oracle
# is glmmTMB REML (not the marginalize-u-first rolled Cox-Reid, which is a different,
# AGHQ-based object -- see doc 224 S4.1). These tests: (1) the deterministic identity
# drmTMB REML == glmmTMB REML on the RE-SD; (2) the debiasing direction REML > ML; and
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
  list(data = data.frame(y = y, x = x, g = g), sd_re = sd_re)
}

drm_re_sd <- function(fit) {
  s <- summary(fit$sdr)
  i <- which(rownames(s) == "sd_mu_re")
  if (length(i)) unname(s[i[1L], "Estimate"]) else NA_real_
}

test_that("binomial REML RE-SD matches glmmTMB(REML = TRUE) to Laplace-fold tolerance", {
  skip_if_not_installed("glmmTMB")
  fx <- binom_re_fixture()
  fit_reml <- drmTMB(bf(y ~ x + (1 | g)), family = binomial(), data = fx$data, REML = TRUE)
  gm_reml <- glmmTMB::glmmTMB(y ~ x + (1 | g), family = binomial(), data = fx$data, REML = TRUE)
  g_sd <- attr(glmmTMB::VarCorr(gm_reml)$cond$g, "stddev")

  expect_identical(fit_reml$opt$convergence, 0L)
  # Same joint-Laplace restricted likelihood -> RE-SD agrees to ~1e-6 (observed ~7e-9).
  expect_equal(drm_re_sd(fit_reml), unname(g_sd), tolerance = 1e-5)
})

test_that("binomial REML debiases the RE-SD upward relative to ML", {
  fx <- binom_re_fixture()
  fit_ml <- drmTMB(bf(y ~ x + (1 | g)), family = binomial(), data = fx$data, REML = FALSE)
  fit_reml <- drmTMB(bf(y ~ x + (1 | g)), family = binomial(), data = fx$data, REML = TRUE)
  expect_identical(fit_ml$opt$convergence, 0L)
  expect_identical(fit_reml$opt$convergence, 0L)
  # REML restricts for the fixed effects and lifts the downward-biased ML variance
  # component (Cox-Reid adjustment); on this fixture 0.9547 (REML) > 0.9235 (ML).
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
