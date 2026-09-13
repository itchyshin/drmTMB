# Dinnage independent evaluation of drmTMB 0.7.0 (pinned commit 945da24f,
# https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md), Major
# findings M4, S4, and S5 (report section 4 / Appendix A).

new_masked_family_data <- function(family_name, n = 120L, masked = 20L, seed = 1L) {
  set.seed(seed)
  x <- stats::rnorm(n)
  eta <- 0.3 + 0.4 * x
  y <- switch(
    family_name,
    poisson = stats::rpois(n, lambda = exp(eta)),
    binomial = stats::rbinom(n, size = 1L, prob = stats::plogis(eta)),
    nbinom2 = stats::rnbinom(n, size = 4, mu = exp(eta)),
    gamma = stats::rgamma(n, shape = 4, scale = exp(eta) / 4),
    stop("unhandled family in test helper: ", family_name)
  )
  y <- as.numeric(y)
  out <- data.frame(y = y, x = x)
  out$y[seq_len(masked)] <- NA_real_
  out
}

new_masked_family_fit <- function(family_name, ...) {
  family_obj <- switch(
    family_name,
    poisson = stats::poisson(),
    binomial = stats::binomial(),
    nbinom2 = nbinom2(),
    gamma = stats::Gamma(link = "log"),
    stop("unhandled family in test helper: ", family_name)
  )
  drmTMB(
    bf(y ~ x),
    family = family_obj,
    data = new_masked_family_data(family_name, ...),
    missing = miss_control(response = "include")
  )
}

test_that("M4: simulate() masks missing-response rows instead of leaking the sentinel", {
  for (family_name in c("poisson", "binomial", "nbinom2", "gamma")) {
    fit <- new_masked_family_fit(family_name)
    observed_y <- fit$missing_data$observed_y
    expect_true(any(!observed_y), info = family_name)
    sims <- stats::simulate(fit, nsim = 3L, seed = 20260913, re.form = NA)
    expect_true(
      all(is.na(as.matrix(sims[!observed_y, , drop = FALSE]))),
      info = family_name
    )
    expect_true(
      all(!is.na(as.matrix(sims[observed_y, , drop = FALSE]))),
      info = family_name
    )
  }
})

test_that("M4: the already-correct beta_binomial branch still masks", {
  n <- 120L
  masked <- 20L
  set.seed(2L)
  x <- stats::rnorm(n)
  trials <- rep(10L, n)
  eta <- 0.2 + 0.3 * x
  success <- stats::rbinom(n, size = trials, prob = stats::plogis(eta))
  failure <- trials - success
  dat <- data.frame(success = success, failure = failure, x = x)
  dat$success[seq_len(masked)] <- NA_real_
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x),
    family = beta_binomial(),
    data = dat,
    missing = miss_control(response = "include")
  )
  observed_y <- fit$missing_data$observed_y
  sims <- stats::simulate(fit, nsim = 2L, seed = 20260913, re.form = NA)
  expect_true(all(is.na(as.matrix(sims[!observed_y, , drop = FALSE]))))
})

test_that("S4: vcov(fit, type = 'robust') no longer silently returns the model-based matrix", {
  set.seed(3L)
  n <- 80L
  x <- stats::rnorm(n)
  y <- 0.4 + 0.6 * x + stats::rnorm(n)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x), family = gaussian(), data = dat)

  model_based <- stats::vcov(fit)
  expect_error(stats::vcov(fit, type = "robust"), class = "drmTMB_vcov_robust_unsupported")
  expect_error(stats::vcov(fit, robust = TRUE), class = "drmTMB_vcov_robust_unsupported")
  # The default call is unaffected by the new argument.
  expect_identical(stats::vcov(fit), model_based)
})
