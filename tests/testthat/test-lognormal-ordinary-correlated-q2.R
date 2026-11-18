lognormal_q2_data <- function(
  n_group = 56L,
  n_each = 14L,
  sd_intercept = 0.65,
  sd_slope = 0.42,
  rho = 0.45,
  sigma = exp(-0.70),
  seed = 20260816L
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_group), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z_intercept <- stats::rnorm(n_group)
  z_slope <- stats::rnorm(n_group)
  u_intercept <- sd_intercept * z_intercept
  u_slope <- sd_slope * (rho * z_intercept + sqrt(1 - rho^2) * z_slope)
  mu <- -0.25 + 0.70 * x + u_intercept[id] + u_slope[id] * x
  list(
    data = data.frame(
      y = stats::rlnorm(n, meanlog = mu, sdlog = sigma),
      x = x,
      id = id
    ),
    truth = c(`(Intercept)` = sd_intercept, x = sd_slope, rho = rho)
  )
}

test_that("Lognormal q2 parser admits only one unlabelled intercept-slope block", {
  sim <- lognormal_q2_data(n_group = 12L, n_each = 8L, seed = 20260817L)
  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1),
    family = lognormal(),
    data = sim$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(fit$model$random$mu$n_terms, 2L)
  expect_equal(fit$model$random$mu$n_cors, 1L)
  expect_named(fit$corpars$mu, "cor((Intercept),x | id)")
  raw_par <- selected_tmb_par_list(fit)
  expect_equal(
    unname(fit$corpars$mu),
    0.99999999 * tanh(unname(raw_par$eta_cor_mu)),
    tolerance = 1e-12
  )
  report <- fit$obj$report()
  expect_true(all(c("eta_cor_mu", "rho_mu_re") %in% names(report)))
  expect_false("logsech_mu_re" %in% names(report))
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | p | id), sigma ~ 1),
      family = lognormal(),
      data = sim$data
    ),
    "Only independent"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x + z | id), sigma ~ 1),
      family = lognormal(),
      data = transform(sim$data, z = x^2)
    ),
    "Only independent"
  )
})

test_that("Lognormal q2 likelihood, fitted effects, and gradients use the design-17 map", {
  skip_if_not_installed("numDeriv")
  sim <- lognormal_q2_data(n_group = 24L, n_each = 10L, seed = 20260818L)
  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1),
    family = lognormal(),
    data = sim$data
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_true(all(is.finite(c(fit$sdpars$mu, fit$corpars$mu))))
  raw_par <- selected_tmb_par_list(fit)
  latent <- unname(raw_par$u_mu)
  values <- drmTMB:::transform_mu_random_effects(
    latent, raw_par, fit$model$random$mu, fit$model$random_scale$mu,
    tmb_data = fit$model$tmb_data, binomial_q2 = FALSE
  )
  expect_equal(unname(fit$random_effects$mu$values), values, tolerance = 1e-10)

  theta <- fit$obj$par
  ad_gradient <- fit$obj$gr(theta)
  fd_gradient <- numDeriv::grad(
    fit$obj$fn, theta, method = "simple", method.args = list(eps = 1e-5)
  )
  expect_true(all(is.finite(c(ad_gradient, fd_gradient))))
  expect_lt(max(abs(ad_gradient - fd_gradient)) / (1 + max(abs(ad_gradient))), 2e-3)
})

test_that("Lognormal q2 ML recovers a correlated random intercept and slope", {
  sim <- lognormal_q2_data(seed = 20260816L)
  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1),
    family = lognormal(),
    data = sim$data
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_equal(
    names(fit$sdpars$mu),
    c("(1 + x | id):(Intercept)", "(1 + x | id):x")
  )
  sd0 <- unname(fit$sdpars$mu[["(1 + x | id):(Intercept)"]])
  sd1 <- unname(fit$sdpars$mu[["(1 + x | id):x"]])
  rho_re <- unname(fit$corpars$mu[["cor((Intercept),x | id)"]])
  expect_lt(abs(sd0 - sim$truth[["(Intercept)"]]), 0.30)
  expect_lt(abs(sd1 - sim$truth[["x"]]), 0.30)
  expect_lt(abs(rho_re - sim$truth[["rho"]]), 0.30)
  raw_par <- selected_tmb_par_list(fit)
  expect_equal(rho_re, 0.99999999 * tanh(unname(raw_par$eta_cor_mu)), tolerance = 1e-12)
})

test_that("Lognormal q2 rejection matrix stays closed", {
  sim <- lognormal_q2_data(n_group = 10L, n_each = 8L, seed = 20260819L)
  q2 <- bf(y ~ x + (1 + x | id), sigma ~ 1)

  expect_error(
    drmTMB(q2, family = lognormal(), data = sim$data, REML = TRUE),
    "Gaussian and binomial models"
  )

  missing_dat <- sim$data
  missing_dat$y[[1L]] <- NA_real_
  expect_error(
    drmTMB(
      q2,
      family = lognormal(),
      data = missing_dat,
      missing = miss_control(response = "include")
    ),
    "missing-response integration",
    fixed = TRUE
  )

  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id) + (1 + x | id), sigma ~ 1),
      family = lognormal(),
      data = sim$data
    ),
    "Only independent"
  )

  expect_error(
    drmTMB(
      q2,
      family = stats::Gamma(link = "log"),
      data = sim$data
    ),
    "Only independent"
  )

  const_dat <- sim$data
  const_dat$x <- as.numeric(const_dat$id)
  expect_error(
    drmTMB(q2, family = lognormal(), data = const_dat),
    "need within-group variation in the slope predictor",
    fixed = TRUE
  )
})

lognormal_q2_predictor_sd_data <- function(
  n_group = 100L,
  n_each = 16L,
  seed = 20261028L
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_group), each = n_each))
  x <- rep(seq(-1.5, 1.5, length.out = n_each), times = n_group)
  w0_group <- seq(-1, 1, length.out = n_group)
  w1_group <- sample(rep(c(-1, 1), length.out = n_group))
  rho <- 0.4
  z0 <- stats::rnorm(n_group)
  z1 <- stats::rnorm(n_group)
  sd0 <- exp(-0.25 + 0.4 * w0_group)
  sd1 <- exp(-0.75 - 0.3 * w1_group)
  b0 <- sd0 * z0
  b1 <- sd1 * (rho * z0 + sqrt(1 - rho^2) * z1)
  log_y <- 0.2 + 0.55 * x + b0[as.integer(id)] +
    b1[as.integer(id)] * x + stats::rnorm(length(id), sd = 0.38)
  list(
    data = data.frame(
      y = exp(log_y), x = x, id = id,
      w0 = w0_group[as.integer(id)],
      w1 = w1_group[as.integer(id)]
    ),
    w0_group = w0_group,
    w1_group = w1_group,
    truth = c(intercept_sd_slope = 0.4, random_slope_sd_slope = -0.3)
  )
}

test_that("Lognormal correlated q2 admits coefficient-specific SD regression", {
  sim <- lognormal_q2_predictor_sd_data()
  dat <- sim$data
  target0 <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  target1 <- 'sd(id, dpar = "mu", coef = "x")'
  fit <- drmTMB(
    bf(
      y ~ x + (1 + x | id), sigma ~ 1,
      sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
      sd(id, dpar = "mu", coef = "x") ~ w1
    ),
    family = lognormal(), data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_identical(fit$model$random$mu$n_terms, 2L)
  expect_identical(fit$model$random$mu$n_cors, 1L)
  expect_named(fit$sdpars, c(target0, target1))
  expect_lt(abs(coef(fit, target0)[["w0"]] -
                  sim$truth[["intercept_sd_slope"]]), 0.35)
  expect_lt(abs(coef(fit, target1)[["w1"]] -
                  sim$truth[["random_slope_sd_slope"]]), 0.35)
  expect_true(is.finite(unname(fit$corpars$mu[[1L]])))
  expect_lt(abs(unname(fit$corpars$mu[[1L]])), 1)

  pred0 <- predict(fit, dpar = target0, newdata = data.frame(w0 = sim$w0_group))
  pred1 <- predict(fit, dpar = target1, newdata = data.frame(w1 = sim$w1_group))
  expect_named(pred0, levels(dat$id))
  expect_named(pred1, levels(dat$id))
  expect_equal(length(pred0), nlevels(dat$id))
  expect_equal(length(pred1), nlevels(dat$id))
  expect_true(all(is.finite(c(pred0, pred1))))
  expected0 <- exp(coef(fit, target0)[["(Intercept)"]] +
                     coef(fit, target0)[["w0"]] * sim$w0_group)
  expected1 <- exp(coef(fit, target1)[["(Intercept)"]] +
                     coef(fit, target1)[["w1"]] * sim$w1_group)
  expect_equal(unname(pred0), unname(expected0), tolerance = 1e-10)
  expect_equal(unname(pred1), unname(expected1), tolerance = 1e-10)

  constant <- drmTMB(
    bf(
      y ~ x + (1 + x | id), sigma ~ 1,
      sd(id, dpar = "mu", coef = "(Intercept)") ~ 1,
      sd(id, dpar = "mu", coef = "x") ~ 1
    ),
    family = lognormal(), data = dat,
    control = drm_control(se = FALSE)
  )
  ordinary <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1),
    family = lognormal(), data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(ordinary)),
               tolerance = 1e-6)
})
