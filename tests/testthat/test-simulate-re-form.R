# `simulate.drmTMB(..., re.form = )` contract tests -- Arc A1.
#
# `re.form = NULL` (the default) draws a FRESH random effect per replicate
# (marginal simulation); `re.form = NA` freezes every random effect at its
# fitted conditional-mode estimate (conditional simulation, the behaviour
# `simulate.drmTMB()` had before `re.form` was added). This file tests the
# contract itself, not any one family's density.

new_re_form_intercept_data <- function(n_id = 8L, n_each = 6L, seed = 20260726) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  u_id <- stats::rnorm(n_id, sd = 0.7)
  mu <- 0.3 + 0.5 * x + u_id[id]
  y <- stats::rnorm(n, mu, sd = 0.6)
  list(data = data.frame(y = y, x = x, id = id), n_id = n_id)
}

test_that("re.form = NULL is the default and redraws random effects across replicates", {
  sim <- new_re_form_intercept_data()
  fit <- drmTMB(bf(y ~ x + (1 | id)), family = gaussian(), data = sim$data)

  # Same seed: default (re.form omitted) must equal explicit re.form = NULL.
  expect_equal(
    simulate(fit, nsim = 3, seed = 1),
    simulate(fit, nsim = 3, seed = 1, re.form = NULL)
  )

  # Marginal replicates should differ from each other (fresh RE draws), not
  # just from residual noise alone -- distinct seeds give visibly different
  # per-group means.
  nsim <- 60
  sims <- simulate(fit, nsim = nsim, seed = 2, re.form = NULL)
  group_means <- vapply(sims, function(col) {
    tapply(col, sim$data$id, mean)[[1L]]
  }, numeric(1L))
  expect_gt(stats::var(group_means), 0.05)
})

test_that("re.form = NA reproduces conditional simulation (fitted REs held fixed)", {
  sim <- new_re_form_intercept_data()
  fit <- drmTMB(bf(y ~ x + (1 | id)), family = gaussian(), data = sim$data)

  nsim <- 60
  sims_cond <- simulate(fit, nsim = nsim, seed = 3, re.form = NA)
  group_means_cond <- vapply(sims_cond, function(col) {
    tapply(col, sim$data$id, mean)[[1L]]
  }, numeric(1L))
  sims_marg <- simulate(fit, nsim = nsim, seed = 3, re.form = NULL)
  group_means_marg <- vapply(sims_marg, function(col) {
    tapply(col, sim$data$id, mean)[[1L]]
  }, numeric(1L))

  # Conditional group means vary only through residual noise (divided by
  # n_each), so their across-replicate variance must be much smaller than
  # marginal's (which also carries fresh between-group variance).
  expect_lt(
    stats::var(group_means_cond),
    stats::var(group_means_marg) / 5
  )

  # Conditional simulation is reproducible under a fixed seed, same as
  # marginal.
  expect_equal(
    simulate(fit, nsim = 2, seed = 4, re.form = NA),
    simulate(fit, nsim = 2, seed = 4, re.form = NA)
  )
})

test_that("re.form has no effect on a fixed-effects-only model", {
  set.seed(20260727)
  n <- 40
  x <- stats::rnorm(n)
  y <- 0.4 + 0.6 * x + stats::rnorm(n, sd = 0.8)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_equal(
    simulate(fit, nsim = 4, seed = 5, re.form = NULL),
    simulate(fit, nsim = 4, seed = 5, re.form = NA)
  )
})


# Shared fixture for the "unsupported structure" tests below: a correlated
# mu1/mu2/sigma1/sigma2 covariance-block random effect (q4, location AND scale
# share the block) -- still unsupported by marginal simulation (a labelled q2
# mu1/mu2 block alone would be supported). q4 at this fixture size is weakly
# identified (as in test-biv-gaussian.R's own q4/q8 fixtures); these tests
# assert the marginal-simulation abort / escape hatch, not convergence.
new_re_form_unsupported_fit <- function(seed = 20260728) {
  set.seed(seed)
  n_id <- 10L
  n_each <- 4L
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  Sigma_re <- matrix(c(0.36, 0.12, 0.12, 0.25), 2L, 2L)
  chol_re <- chol(Sigma_re)
  u <- matrix(stats::rnorm(n_id * 2L), n_id, 2L) %*% chol_re
  y1 <- 0.2 + 0.5 * x + u[id, 1L] + stats::rnorm(n, sd = 0.4)
  y2 <- -0.1 + 0.3 * x + u[id, 2L] + stats::rnorm(n, sd = 0.4)
  dat <- data.frame(y1 = y1, y2 = y2, x = x, id = id)

  allow_nonconvergence(drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~ 1 + (1 | p | id),
      sigma2 = ~ 1 + (1 | p | id),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(se = FALSE, optimizer = list(eval.max = 500, iter.max = 500))
  ))
}

test_that("marginal simulation aborts with a clear message for an unsupported structure", {
  fit <- new_re_form_unsupported_fit()

  expect_error(
    simulate(fit, nsim = 2, seed = 6),
    "does not yet support.*covariance-block random effects"
  )
  # re.form = NA still works (the escape hatch the error message points to).
  expect_no_error(simulate(fit, nsim = 2, seed = 6, re.form = NA))
})

test_that("confint bootstrap_re_form threads through simulate() for a supported RE structure", {
  sim <- new_re_form_intercept_data()
  fit <- drmTMB(bf(y ~ x + (1 | id)), family = gaussian(), data = sim$data)

  # Default: bootstrap_re_form = NULL runs marginally, same as passing it
  # explicitly.
  ci_default <- confint(
    fit,
    parm = "sd:mu:(1 | id)",
    method = "bootstrap",
    R = 7,
    seed = 11
  )
  ci_marginal <- confint(
    fit,
    parm = "sd:mu:(1 | id)",
    method = "bootstrap",
    R = 7,
    seed = 11,
    bootstrap_re_form = NULL
  )
  expect_equal(ci_default$lower, ci_marginal$lower)
  expect_equal(ci_default$upper, ci_marginal$upper)

  # bootstrap_re_form = NA runs conditionally instead, and threads all the way
  # to a different simulate() draw (and hence, generally, a different
  # interval) than the marginal default under the same seed.
  ci_conditional <- confint(
    fit,
    parm = "sd:mu:(1 | id)",
    method = "bootstrap",
    R = 7,
    seed = 11,
    bootstrap_re_form = NA
  )
  expect_false(isTRUE(all.equal(ci_marginal$lower, ci_conditional$lower)))
})

test_that("confint bootstrap aborts by default on an unsupported RE structure, but bootstrap_re_form = NA succeeds", {
  fit <- new_re_form_unsupported_fit()

  expect_error(
    confint(
      fit,
      parm = "variance_components",
      method = "bootstrap",
      R = 5,
      seed = 12
    ),
    "does not yet support.*covariance-block random effects"
  )

  expect_no_error(confint(
    fit,
    parm = "variance_components",
    method = "bootstrap",
    R = 5,
    seed = 12,
    bootstrap_re_form = NA
  ))
})

test_that("re.form only accepts NULL or NA", {
  set.seed(20260729)
  n <- 30
  x <- stats::rnorm(n)
  y <- 0.1 + 0.4 * x + stats::rnorm(n)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x), family = gaussian(), data = dat)

  expect_error(
    simulate(fit, nsim = 1, seed = 1, re.form = TRUE),
    "re.form.*NULL.*NA"
  )
})
