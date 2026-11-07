gaussian_independent_pair_fixture <- function(seed = 20261101L, n_id = 60L, n_each = 14L) {
  set.seed(seed)
  id <- factor(rep(sprintf("id%02d", seq_len(n_id)), each = n_each))
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_id)
  w0 <- rep(c(-0.5, 0.5), length.out = n_id)
  w1 <- rep(c(-0.5, 0.5), times = c(n_id %/% 2L, n_id - n_id %/% 2L))
  alpha0 <- c(`(Intercept)` = log(0.6), w0 = 0.4)
  alpha1 <- c(`(Intercept)` = log(0.45), w1 = -0.5)
  tau0 <- exp(alpha0[[1L]] + alpha0[[2L]] * w0)
  tau1 <- exp(alpha1[[1L]] + alpha1[[2L]] * w1)
  b0 <- stats::rnorm(n_id, sd = tau0)
  b1 <- stats::rnorm(n_id, sd = tau1)
  gi <- as.integer(id)
  y <- 0.3 + 0.5 * x + b0[gi] + b1[gi] * x + stats::rnorm(n_id * n_each, sd = 0.5)
  list(
    data = data.frame(y = y, x = x, id = id, w0 = w0[gi], w1 = w1[gi]),
    alpha0 = alpha0, alpha1 = alpha1
  )
}

# Exact marginal log likelihood: y_g ~ N(X beta, Z diag(tau0^2, tau1^2) Z' + s^2 I).
gaussian_pair_oracle_loglik <- function(data, beta, sigma, alpha0, alpha1) {
  ll <- 0
  for (g in levels(data$id)) {
    d <- data[data$id == g, , drop = FALSE]
    tau0 <- exp(alpha0[[1L]] + alpha0[[2L]] * d$w0[[1L]])
    tau1 <- exp(alpha1[[1L]] + alpha1[[2L]] * d$w1[[1L]])
    Z <- cbind(1, d$x)
    V <- Z %*% diag(c(tau0^2, tau1^2)) %*% t(Z) + diag(sigma^2, nrow(d))
    r <- d$y - (beta[[1L]] + beta[[2L]] * d$x)
    ll <- ll + mvtnorm_free_dmvnorm(r, V)
  }
  ll
}
mvtnorm_free_dmvnorm <- function(r, V) {
  L <- chol(V)
  z <- backsolve(L, r, transpose = TRUE)
  -0.5 * (length(r) * log(2 * pi) + 2 * sum(log(diag(L))) + sum(z^2))
}

test_that("Gaussian independent same-group intercept and slope take separate SD formulas", {
  skip_on_cran()
  fx <- gaussian_independent_pair_fixture()
  key0 <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key1 <- 'sd(id, dpar = "mu", coef = "x")'
  fit <- drmTMB(
    bf(
      y ~ x + (1 | id) + (0 + x | id),
      sigma ~ 1,
      sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
      sd(id, dpar = "mu", coef = "x") ~ w1
    ),
    family = gaussian(), data = fx$data, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, key0), c("(Intercept)", "w0"))
  expect_named(coef(fit, key1), c("(Intercept)", "w1"))
  expect_gt(coef(fit, key0)[["w0"]], 0)
  expect_lt(coef(fit, key1)[["w1"]], 0)
  expect_lt(abs(coef(fit, key0)[["w0"]] - fx$alpha0[["w0"]]), 0.5)
  expect_lt(abs(coef(fit, key1)[["w1"]] - fx$alpha1[["w1"]]), 0.6)

  oracle <- gaussian_pair_oracle_loglik(
    fx$data,
    beta = unname(coef(fit, "mu")),
    sigma = exp(unname(coef(fit, "sigma"))[[1L]]),
    alpha0 = unname(coef(fit, key0)),
    alpha1 = unname(coef(fit, key1))
  )
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-4)

  # Constant-SD limit equals the existing two-term fit.
  constant_fit <- drmTMB(
    bf(
      y ~ x + (1 | id) + (0 + x | id), sigma ~ 1,
      sd(id, dpar = "mu", coef = "(Intercept)") ~ 1,
      sd(id, dpar = "mu", coef = "x") ~ 1
    ),
    family = gaussian(), data = fx$data, control = drm_control(se = FALSE)
  )
  base_fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ 1),
    family = gaussian(), data = fx$data, control = drm_control(se = FALSE)
  )
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
})

test_that("Gaussian same-group SD without coefficient selectors stays refused", {
  fx <- gaussian_independent_pair_fixture(n_id = 20L)
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ 1, sd(id) ~ w0),
      family = gaussian(), data = fx$data, control = drm_control(se = FALSE)
    ),
    "Ambiguous|coef"
  )
})
