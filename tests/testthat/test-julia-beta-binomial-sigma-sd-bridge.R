beta_binomial_sigma_sd_bridge_formula <- function() {
  bf(
    cbind(success, failure) ~ 1 + x,
    sigma ~ 1 + (1 | id),
    sd(id, dpar = "sigma") ~ w
  )
}

beta_binomial_sigma_sd_marginal_loglik <- function(fit, data) {
  target <- 'sd(id, dpar = "sigma")'
  beta_mu <- coef(fit, dpar = "mu")
  beta_sigma <- coef(fit, dpar = "sigma")
  alpha <- coef(fit, dpar = target)
  eta_mu <- as.vector(stats::model.matrix(~ x, data) %*% beta_mu)
  mu <- stats::plogis(eta_mu)
  trials <- data$success + data$failure
  group_levels <- levels(data$id)

  sum(vapply(group_levels, function(group) {
    rows <- which(data$id == group)
    tau <- exp(alpha[[1L]] + alpha[[2L]] * data$w[rows[[1L]]])
    log_integrand <- function(z) {
      vapply(z, function(z_value) {
        phi <- exp(-2 * (beta_sigma[["(Intercept)"]] + tau * z_value))
        a <- mu[rows] * phi
        b <- (1 - mu[rows]) * phi
        log_mass <- lchoose(trials[rows], data$success[rows]) +
          lbeta(data$success[rows] + a, data$failure[rows] + b) -
          lbeta(a, b)
        sum(log_mass) + stats::dnorm(z_value, log = TRUE)
      }, numeric(1))
    }
    integral <- stats::integrate(
      function(z) exp(log_integrand(z)),
      lower = -8, upper = 8, rel.tol = 1e-9, subdivisions = 300L
    )
    log(integral$value)
  }, numeric(1)))
}

test_that("BetaBinomial sigma-SD formula is admitted and marshalled to Julia", {
  dat <- expand.grid(id = factor(seq_len(8L)), replicate = seq_len(4L))
  dat$w <- rep(seq(-1, 1, length.out = 8L), each = 4L)
  dat$x <- seq_len(nrow(dat)) / nrow(dat)
  dat$success <- 1L
  dat$failure <- 9L
  formula <- beta_binomial_sigma_sd_bridge_formula()

  expect_true(drmTMB:::drm_julia_beta_binomial_sigma_sd_route_admitted(
    formula, data = dat
  ))
  expect_silent(drmTMB:::drm_julia_refuse_fe_only_random_effects(
    formula, "beta_binomial", data = dat
  ))
  spec <- drmTMB:::drm_julia_formula_spec(formula)
  expect_true(any(unname(spec) == "sd(id, sigma) ~ w"))
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula, dat, environment(), family_type = "beta_binomial"
  )
  expect_setequal(names(labels), c("mu", "sigma", "sd"))

  sigma_slope <- bf(
    cbind(success, failure) ~ 1 + x,
    sigma ~ 1 + (0 + x | id),
    sd(id, dpar = "sigma", coef = "x") ~ w
  )
  expect_true(drmTMB:::drm_julia_beta_binomial_sigma_sd_route_admitted(
    sigma_slope, data = dat
  ))
  expect_silent(drmTMB:::drm_julia_refuse_fe_only_random_effects(
    sigma_slope, "beta_binomial", data = dat
  ))
  sigma_slope_spec <- drmTMB:::drm_julia_formula_spec(sigma_slope)
  expect_true(any(unname(sigma_slope_spec) == "sd(id, sigma, coef(x)) ~ w"))
  sigma_slope_labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    sigma_slope, dat, environment(), family_type = "beta_binomial"
  )
  expect_identical(sigma_slope_labels[["sd"]], c("(Intercept)", "w"))

  bad_mean_re <- bf(
    cbind(success, failure) ~ 1 + x + (1 | id),
    sigma ~ 1 + (1 | id),
    sd(id, dpar = "sigma") ~ w
  )
  bad_sigma_slope <- bf(
    cbind(success, failure) ~ 1 + x,
    sigma ~ 1 + (0 + x | id),
    sd(id, dpar = "sigma") ~ w
  )
  bad_target <- bf(
    cbind(success, failure) ~ 1 + x,
    sigma ~ 1 + (1 | id),
    sd(other, dpar = "sigma") ~ w
  )
  expect_false(drmTMB:::drm_julia_beta_binomial_sigma_sd_route_admitted(
    bad_mean_re, data = dat
  ))
  expect_false(drmTMB:::drm_julia_beta_binomial_sigma_sd_route_admitted(
    bad_sigma_slope, data = dat
  ))
  expect_false(drmTMB:::drm_julia_beta_binomial_sigma_sd_route_admitted(
    bad_target, data = dat
  ))
})

test_that("BetaBinomial sigma-SD bridge agrees with native TMB on a synthetic fit", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261024L)
  groups <- 80L
  repeats <- 18L
  group_w <- rep(c(-1, 1), each = groups / 2L)
  tau <- exp(log(0.29) + 0.35 * group_w)
  group_index <- rep(seq_len(groups), each = repeats)
  id <- factor(group_index)
  w <- group_w[group_index]
  x <- stats::rnorm(length(id))
  log_sigma <- -0.55 + tau[group_index] * stats::rnorm(groups)[group_index]
  mu <- stats::plogis(-0.15 + 0.45 * x)
  phi <- exp(-2 * log_sigma)
  probability <- stats::rbeta(length(id), mu * phi, (1 - mu) * phi)
  trials <- rep(24L, length(id))
  success <- stats::rbinom(length(id), trials, probability)
  dat <- data.frame(success, failure = trials - success, id, w, x)
  formula <- bf(
    cbind(success, failure) ~ x,
    sigma ~ 1 + (1 | id),
    sd(id, dpar = "sigma") ~ w
  )

  fit_tmb <- drmTMB(
    formula, family = beta_binomial(), data = dat, engine = "tmb"
  )
  fit <- drmTMB(
    formula, family = beta_binomial(), data = dat, engine = "julia"
  )
  target <- 'sd(id, dpar = "sigma")'
  estimate <- coef(fit, dpar = target)
  estimate_tmb <- coef(fit_tmb, dpar = target)
  prediction <- predict(fit, dpar = target)
  prediction_tmb <- predict(fit_tmb, dpar = target)
  expect_true(isTRUE(fit$bridge$converged))
  expect_true(is_converged(fit_tmb))
  expect_named(estimate, c("(Intercept)", "w"))
  expect_named(estimate_tmb, names(estimate))
  expect_true(all(abs(unname(estimate) - c(log(0.29), 0.35)) < 0.65))
  expect_true(max(abs(estimate - estimate_tmb)) < 0.05)
  expect_equal(length(prediction), groups)
  expect_named(prediction_tmb, names(prediction))
  expect_true(all(is.finite(prediction)))
  expect_true(max(abs(prediction - prediction_tmb)) < 0.02)
  loglik_julia <- as.numeric(logLik(fit))
  loglik_tmb <- as.numeric(logLik(fit_tmb))
  expect_true(all(is.finite(c(loglik_julia, loglik_tmb))))
  oracle_julia <- beta_binomial_sigma_sd_marginal_loglik(fit, dat)
  oracle_tmb <- beta_binomial_sigma_sd_marginal_loglik(fit_tmb, dat)
  expect_lt(abs(loglik_julia - oracle_julia), 0.1)
  expect_lt(abs(loglik_tmb - oracle_tmb), 0.5)
})

test_that("BetaBinomial sigma-slope SD formula reaches the Julia bridge", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261029L)
  groups <- 60L
  repeats <- 24L
  group_z <- rep(c(-1, 1), each = groups / 2L)
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  x <- stats::rnorm(length(id))
  w <- stats::rnorm(length(id))
  tau <- exp(log(0.35) + 0.25 * group_z)
  b_sigma <- stats::rnorm(groups, sd = tau)
  sigma <- exp(-0.55 + x * b_sigma[id_index])
  mu <- stats::plogis(-0.15 + 0.45 * w)
  trials <- rep(24L, length(id))
  phi <- exp(-2 * log(sigma))
  probability <- stats::rbeta(length(id), mu * phi, (1 - mu) * phi)
  success <- stats::rbinom(length(id), size = trials, prob = probability)
  dat <- data.frame(
    success, failure = trials - success, id, x, w,
    z = group_z[id_index]
  )
  formula <- bf(
    cbind(success, failure) ~ w,
    sigma ~ 1 + (0 + x | id),
    sd(id, dpar = "sigma", coef = "x") ~ z
  )

  fit_tmb <- drmTMB(
    formula, family = beta_binomial(), data = dat, engine = "tmb"
  )
  fit_julia <- drmTMB(
    formula, family = beta_binomial(), data = dat, engine = "julia"
  )
  target <- 'sd(id, dpar = "sigma", coef = "x")'
  estimate_tmb <- coef(fit_tmb, dpar = target)
  estimate_julia <- coef(fit_julia, dpar = target)

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(estimate_tmb, c("(Intercept)", "z"))
  expect_named(estimate_julia, names(estimate_tmb))
  expect_true(all(abs(unname(estimate_tmb) - c(log(0.35), 0.25)) < 0.5))
  expect_true(all(abs(unname(estimate_julia) - c(log(0.35), 0.25)) < 0.5))
  expect_equal(unname(estimate_julia), unname(estimate_tmb), tolerance = 0.35)
  pred_tmb <- predict(fit_tmb, dpar = target)
  pred_julia <- predict(fit_julia, dpar = target)
  expect_length(pred_julia, groups)
  expect_named(pred_julia, names(pred_tmb))
  expect_equal(unname(pred_julia), unname(pred_tmb), tolerance = 0.35)
  expect_true(all(c("mu", "sigma") %in% names(fit_julia$bridge$dpars)))
})
