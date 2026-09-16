# Red-first test support for Russell Dinnage's independent evaluation of
# drmTMB 0.7.0. This file stays test-only so Gauss can own the A3 kernel fix.

test_that("Md-H: beta_binomial kernel stays finite at extreme logit means (Dinnage audit)", {
  ctrl <- drm_control(se = FALSE, logsigma_clamp = NULL)
  dat <- data.frame(successes = 0L, failures = 10L)
  fit <- suppressWarnings(drmTMB(
    bf(cbind(successes, failures) ~ 1, sigma ~ 1),
    data = dat,
    family = beta_binomial(),
    control = ctrl
  ))

  par <- fit$obj$par
  par[names(par) == "beta_mu"] <- 700
  par[names(par) == "beta_sigma"] <- 0
  cpp_log_density <- -fit$obj$fn(par)

  eps <- 1e-12
  shape_floor <- 1e-8
  trials <- dat$successes + dat$failures
  mu <- eps + (1 - 2 * eps) * stats::plogis(700)
  phi <- 1
  alpha <- max(mu * phi, shape_floor)
  beta_shape <- max((1 - mu) * phi, shape_floor)
  ref <- lchoose(trials, dat$successes) +
    lbeta(dat$successes + alpha, dat$failures + beta_shape) -
    lbeta(alpha, beta_shape)

  expect_true(is.finite(cpp_log_density))
  expect_equal(cpp_log_density, ref, tolerance = 1e-8)
})

test_that("Md-H: beta_binomial mi() response leaf stays finite at extreme logit means", {
  ctrl <- drm_control(se = FALSE, logsigma_clamp = NULL)
  dat <- data.frame(
    successes = c(0L, 1L, 0L),
    failures = c(10L, 9L, 10L),
    x = c(NA, 1, 0),
    weights = c(1, 0, 0)
  )
  fit <- suppressWarnings(drmTMB(
    bf(cbind(successes, failures) ~ mi(x), sigma ~ 1),
    data = dat,
    family = beta_binomial(),
    weights = weights,
    impute = list(x = impute_model(x ~ 1, family = binomial())),
    missing = miss_control(predictor = "model"),
    control = ctrl
  ))

  expect_identical(unname(fit$model$tmb_data$has_mi), 1L)
  expect_identical(unname(fit$model$tmb_data$mi_family), 1L)

  par <- fit$obj$par
  par[names(par) == "beta_mu"] <- c(700, 0)
  par[names(par) == "beta_sigma"] <- 0

  expect_true(is.finite(fit$obj$fn(par)))
})
