mspl_q2_logsech <- function(eta) {
  log(2) - abs(eta) - log1p(exp(-2 * abs(eta)))
}

mspl_q2_chol <- function(theta) {
  stopifnot(length(theta) == 3L)
  rho <- tanh(theta[[3L]])
  matrix(
    c(
      exp(theta[[1L]]), 0,
      exp(theta[[2L]]) * rho, exp(theta[[2L]] + mspl_q2_logsech(theta[[3L]]))
    ),
    nrow = 2L,
    byrow = TRUE
  )
}

mspl_q2_data <- function(
  n_group = 56L,
  n_each = 14L,
  sd_intercept = 0.65,
  sd_slope = 0.42,
  rho = 0.45,
  seed = 20260808L
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_group), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z_intercept <- stats::rnorm(n_group)
  z_slope <- stats::rnorm(n_group)
  u_intercept <- sd_intercept * z_intercept
  u_slope <- sd_slope * (rho * z_intercept + sqrt(1 - rho^2) * z_slope)
  trials <- stats::rpois(n, lambda = 16) + 8L
  p <- stats::plogis(-0.25 + 0.70 * x + u_intercept[id] + u_slope[id] * x)
  success <- stats::rbinom(n, size = trials, prob = p)
  list(
    data = data.frame(success = success, failure = trials - success, x = x, id = id),
    truth = c(`(Intercept)` = sd_intercept, x = sd_slope, rho = rho)
  )
}

test_that("binomial q2 Cholesky map is positive definite and stable at extreme eta", {
  for (eta in c(-40, -2, 0, 2, 40)) {
    L <- mspl_q2_chol(c(log(0.65), log(0.42), eta))
    Sigma <- tcrossprod(L)
    expect_true(all(is.finite(L)))
    expect_true(all(is.finite(Sigma)))
    # Positive diagonal Cholesky entries establish positive definiteness even
    # when the smallest eigenvalue is below double-precision resolution.
    expect_true(all(diag(L) > 0))
    expect_true(is.finite(2 * sum(log(diag(L)))))
    expect_equal(Sigma[[1L, 2L]], 0.65 * 0.42 * tanh(eta), tolerance = 1e-12)
  }
})

test_that("binomial q2 parser admits only one unlabelled intercept-slope block", {
  sim <- mspl_q2_data(n_group = 10L, n_each = 8L, seed = 20260809L)
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x + (1 + x | id)),
    family = binomial(),
    data = sim$data
  )
  expect_equal(fit$model$random$mu$n_terms, 2L)
  expect_equal(fit$model$random$mu$n_cors, 1L)
  expect_named(fit$corpars$mu, "cor((Intercept),x | id)")
  raw_par <- fit$obj$env$parList(fit$opt$par)
  expect_equal(
    unname(fit$corpars$mu),
    tanh(unname(raw_par$eta_cor_mu)),
    tolerance = 1e-12
  )
  report <- fit$obj$report()
  expect_true(all(c("eta_cor_mu", "rho_mu_re", "logsech_mu_re") %in% names(report)))
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x + (1 + x | p | id)),
      family = binomial(), data = sim$data
    ),
    "unlabelled intercept-slope block"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x + (1 + x + z | id)),
      family = binomial(), data = transform(sim$data, z = x^2)
    ),
    "unlabelled intercept-slope block"
  )
})

test_that("binomial q2 likelihood, fitted effects, and gradients use the same map", {
  skip_if_not_installed("numDeriv")
  sim <- mspl_q2_data(seed = 20260810L)
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x + (1 + x | id)),
    family = binomial(), data = sim$data
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_true(all(is.finite(c(fit$sdpars$mu, fit$corpars$mu))))
  raw_par <- fit$obj$env$parList(fit$opt$par)
  latent <- unname(raw_par$u_mu)
  values <- drmTMB:::transform_mu_random_effects(
    latent, raw_par, fit$model$random$mu, fit$model$random_scale$mu,
    tmb_data = fit$model$tmb_data, binomial_q2 = TRUE
  )
  expect_equal(unname(fit$random_effects$mu$values), values, tolerance = 1e-10)

  theta <- fit$obj$par
  ad_gradient <- fit$obj$gr(theta)
  fd_gradient <- numDeriv::grad(fit$obj$fn, theta, method = "simple", method.args = list(eps = 1e-5))
  expect_true(all(is.finite(c(ad_gradient, fd_gradient))))
  expect_lt(max(abs(ad_gradient - fd_gradient)) / (1 + max(abs(ad_gradient))), 2e-3)

  eta_index <- which(names(theta) == "eta_cor_mu")
  for (eta in c(-40, 40)) {
    extreme <- theta
    extreme[[eta_index]] <- eta
    expect_true(is.finite(fit$obj$fn(extreme)))
    expect_true(all(is.finite(fit$obj$gr(extreme))))
  }
})

test_that("fresh q2 simulation uses the native eta and stable sech map", {
  sim <- mspl_q2_data(n_group = 12L, n_each = 8L, seed = 20260812L)
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x + (1 + x | id)),
    family = binomial(), data = sim$data,
    control = drm_control(se = FALSE)
  )
  re <- fit$model$random$mu
  eta <- as.numeric(fit$obj$env$parList(fit$opt$par)$eta_cor_mu)
  set.seed(991L)
  draw <- drmTMB:::drm_fresh_ordinary_random_effect_values(
    re, fit$sdpars$mu, fit$corpars$mu, eta_lookup = eta
  )
  set.seed(991L)
  latent <- stats::rnorm(re$n_re)
  expected <- numeric(re$n_re)
  sd_by_term <- unname(fit$sdpars$mu[re$labels])
  for (idx in seq_len(re$n_re)) {
    term <- re$term_id0[[idx]] + 1L
    cor_id <- re$re_cor_id0[[idx]] + 1L
    value <- latent[[idx]]
    if (cor_id > 0L && re$re_pos0[[idx]] == 1L) {
      pair <- re$re_pair_index0[[idx]] + 1L
      value <- tanh(eta[[cor_id]]) * latent[[pair]] +
        exp(mspl_q2_logsech(eta[[cor_id]])) * latent[[idx]]
    }
    expected[[idx]] <- sd_by_term[[term]] * value
  }
  expect_equal(draw$latent, latent, tolerance = 0)
  expect_equal(draw$values, expected, tolerance = 1e-14)
})

test_that("binomial q2 ML recovers a correlated random intercept and slope", {
  sim <- mspl_q2_data(seed = 20260811L)
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x + (1 + x | id)),
    family = binomial(), data = sim$data
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_equal(
    names(fit$sdpars$mu),
    c("(1 + x | id):(Intercept)", "(1 + x | id):x")
  )
  expect_lt(max(abs(unname(fit$sdpars$mu) - sim$truth[1:2])), 0.30)
  expect_lt(abs(unname(fit$corpars$mu) - sim$truth[["rho"]]), 0.30)
})
