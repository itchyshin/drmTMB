nbinom2_gamma_pair_fixture <- function(family = c("nbinom2", "gamma"),
                                       seed = 20261102L, n_id = 50L,
                                       n_each = 12L) {
  family <- match.arg(family)
  set.seed(seed)
  id <- factor(rep(sprintf("id%02d", seq_len(n_id)), each = n_each))
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_id)
  w0 <- rep(c(-0.5, 0.5), length.out = n_id)
  w1 <- rep(c(-0.5, 0.5), times = c(n_id %/% 2L, n_id - n_id %/% 2L))
  alpha0 <- c(`(Intercept)` = log(0.5), w0 = 0.4)
  alpha1 <- c(`(Intercept)` = log(0.35), w1 = -0.5)
  tau0 <- exp(alpha0[[1L]] + alpha0[[2L]] * w0)
  tau1 <- exp(alpha1[[1L]] + alpha1[[2L]] * w1)
  b0 <- stats::rnorm(n_id, sd = tau0)
  b1 <- stats::rnorm(n_id, sd = tau1)
  gi <- as.integer(id)
  sigma <- 0.4
  mu <- exp(0.4 + 0.3 * x + b0[gi] + b1[gi] * x)
  y <- if (identical(family, "nbinom2")) {
    stats::rnbinom(length(mu), size = 1 / sigma^2, mu = mu)
  } else {
    # Gamma with coefficient of variation sigma: shape 1/sigma^2, mean mu.
    stats::rgamma(length(mu), shape = 1 / sigma^2, scale = mu * sigma^2)
  }
  list(
    data = data.frame(y = y, x = x, id = id, w0 = w0[gi], w1 = w1[gi]),
    alpha0 = alpha0, alpha1 = alpha1, w0_group = w0[seq_len(n_id)],
    w1_group = w1[seq_len(n_id)]
  )
}

# Shared checks. There is no closed-form marginal likelihood for NB2 or Gamma,
# so the oracle is internal consistency: (i) the SD-regression model nests the
# constant-SD model, (ii) the constant-SD model equals the plain two-term fit,
# and (iii) predicted SDs equal exp(linear predictor) built from coef().
# Tolerances were fixed before the first run and are not tuned to pass.
expect_independent_pair_sd_regression <- function(family_fun) {
  family_name <- family_fun()$family
  fx <- nbinom2_gamma_pair_fixture(
    if (identical(family_name, "nbinom2")) "nbinom2" else "gamma"
  )
  key0 <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key1 <- 'sd(id, dpar = "mu", coef = "x")'
  ctl <- drm_control(se = FALSE)
  fit <- drmTMB(
    bf(
      y ~ x + (1 | id) + (0 + x | id),
      sigma ~ 1,
      sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
      sd(id, dpar = "mu", coef = "x") ~ w1
    ),
    family = family_fun(), data = fx$data, control = ctl
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_named(fit$sdpars, c(key0, key1))
  expect_named(coef(fit, key0), c("(Intercept)", "w0"))
  expect_named(coef(fit, key1), c("(Intercept)", "w1"))
  expect_true(all(is.finite(coef(fit, key0))))
  expect_true(all(is.finite(coef(fit, key1))))
  # Loose wiring check only (no oracle): estimates are in the neighbourhood of
  # the generating slopes, so a swapped or dropped selector would fail.
  expect_lt(abs(coef(fit, key0)[["w0"]] - fx$alpha0[["w0"]]), 1)
  expect_lt(abs(coef(fit, key1)[["w1"]] - fx$alpha1[["w1"]]), 1)

  # Prediction identity: predicted SD is exp(X alpha) from the fitted alphas.
  pred0 <- predict(fit, dpar = key0, newdata = data.frame(w0 = c(-0.5, 0, 0.5)))
  pred1 <- predict(fit, dpar = key1, newdata = data.frame(w1 = c(-0.5, 0, 0.5)))
  a0 <- coef(fit, key0)
  a1 <- coef(fit, key1)
  expect_equal(
    unname(pred0), unname(exp(a0[[1L]] + a0[[2L]] * c(-0.5, 0, 0.5))),
    tolerance = 1e-8
  )
  expect_equal(
    unname(pred1), unname(exp(a1[[1L]] + a1[[2L]] * c(-0.5, 0, 0.5))),
    tolerance = 1e-8
  )

  constant_fit <- drmTMB(
    bf(
      y ~ x + (1 | id) + (0 + x | id), sigma ~ 1,
      sd(id, dpar = "mu", coef = "(Intercept)") ~ 1,
      sd(id, dpar = "mu", coef = "x") ~ 1
    ),
    family = family_fun(), data = fx$data, control = ctl
  )
  base_fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ 1),
    family = family_fun(), data = fx$data, control = ctl
  )
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(base_fit$opt$convergence, 0L)
  # Constant-SD limit reproduces the existing two-term fit.
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 1e-4
  )
  expect_equal(
    unname(coef(constant_fit, "mu")), unname(coef(base_fit, "mu")),
    tolerance = 5e-3
  )
  expect_equal(
    unname(coef(constant_fit, "sigma")), unname(coef(base_fit, "sigma")),
    tolerance = 5e-3
  )
  # Likelihood sanity: finite, and the larger model nests the constant-SD one.
  expect_true(is.finite(as.numeric(logLik(fit))))
  expect_gte(
    as.numeric(logLik(fit)), as.numeric(logLik(constant_fit)) - 1e-4
  )
  invisible(fit)
}

test_that("NB2 independent same-group intercept and slope take separate SD formulas", {
  skip_on_cran()
  expect_independent_pair_sd_regression(nbinom2)
})

test_that("Gamma independent same-group intercept and slope take separate SD formulas", {
  skip_on_cran()
  expect_independent_pair_sd_regression(function() Gamma(link = "log"))
})
