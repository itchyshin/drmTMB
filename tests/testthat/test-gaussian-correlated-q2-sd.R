gaussian_correlated_q2_sd_fixture <- function(groups = 120L, repeats = 10L,
                                              seed = 20261101L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- rep(seq(-1, 1, length.out = repeats), times = groups)
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- sample(rep(c(-1, 1), length.out = groups))
  w0 <- rep(w_group, each = repeats)
  w1 <- rep(v_group, each = repeats)
  rho <- 0.4
  sigma <- 0.5
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  tau0 <- exp(-0.45 + 0.4 * w_group)
  tau1 <- exp(-0.85 - 0.35 * v_group)
  b0 <- tau0 * z0
  b1 <- tau1 * (rho * z0 + sqrt(1 - rho^2) * z1)
  mu <- -0.2 + 0.55 * x + b0[as.integer(id)] + b1[as.integer(id)] * x
  data <- data.frame(
    y = mu + sigma * stats::rnorm(length(id)), x, w0, w1, id
  )
  list(data = data, w_group = w_group, v_group = v_group,
       truth = c(intercept_sd_slope = 0.4, random_slope_sd_slope = -0.35,
                 rho = rho, sigma = sigma))
}

# Exact marginal log-likelihood: each group's response vector is multivariate
# normal with covariance Z S_g Z' + sigma^2 I, where S_g = D_g R D_g.
gaussian_correlated_q2_sd_exact_loglik <- function(
  data, beta_mu, sd_intercept, sd_slope, rho, sigma
) {
  levels <- levels(data$id)
  group_loglik <- vapply(seq_along(levels), function(group) {
    rows <- which(as.integer(data$id) == group)
    x <- data$x[rows]
    z <- cbind(1, x)
    scale <- diag(c(sd_intercept[[group]], sd_slope[[group]]))
    correlation <- matrix(c(1, rho, rho, 1), 2L, 2L)
    covariance <- z %*% (scale %*% correlation %*% scale) %*% t(z) +
      diag(sigma^2, length(rows))
    residual <- data$y[rows] - (beta_mu[[1L]] + beta_mu[[2L]] * x)
    chol_factor <- chol(covariance)
    whitened <- backsolve(chol_factor, residual, transpose = TRUE)
    -0.5 * length(rows) * log(2 * pi) - sum(log(diag(chol_factor))) -
      0.5 * sum(whitened^2)
  }, numeric(1L))
  sum(group_loglik)
}

test_that("Gaussian correlated q2 SD regression recovers both coefficient scales", {
  sim <- gaussian_correlated_q2_sd_fixture()
  dat <- sim$data
  key_intercept <- 'sd(id, coef = "(Intercept)")'
  key_slope <- 'sd(id, coef = "x")'
  formula <- bf(
    y ~ x + (1 + x | id),
    sigma ~ 1,
    sd(id, coef = "(Intercept)") ~ w0,
    sd(id, coef = "x") ~ w1
  )
  fit <- drmTMB(
    formula, family = stats::gaussian(), data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_identical(fit$model$random$mu$n_terms, 2L)
  expect_identical(fit$model$random$mu$n_cors, 1L)
  expect_named(fit$sdpars, c(key_intercept, key_slope))
  expect_true(all(vapply(fit$sdpars, function(x) {
    length(x) == nlevels(dat$id) && all(is.finite(x))
  }, logical(1L))))
  expect_true(all(is.finite(c(
    coef(fit, key_intercept), coef(fit, key_slope), fit$corpars$mu
  ))))
  expect_lt(abs(coef(fit, key_intercept)[["w0"]] - sim$truth[["intercept_sd_slope"]]), 0.3)
  expect_lt(abs(coef(fit, key_slope)[["w1"]] - sim$truth[["random_slope_sd_slope"]]), 0.3)
  expect_lt(abs(unname(fit$corpars$mu[[1L]]) - sim$truth[["rho"]]), 0.3)

  sd_intercept <- predict(fit, dpar = key_intercept,
                          newdata = data.frame(w0 = sim$w_group))
  sd_slope <- predict(fit, dpar = key_slope,
                      newdata = data.frame(w1 = sim$v_group))
  expect_true(all(is.finite(c(sd_intercept, sd_slope))))
  sigma_hat <- exp(unname(coef(fit, "sigma")[[1L]]))
  oracle <- gaussian_correlated_q2_sd_exact_loglik(
    dat, coef(fit, "mu"), sd_intercept, sd_slope,
    unname(fit$corpars$mu[[1L]]), sigma_hat
  )
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-8)

  constant <- drmTMB(
    bf(
      y ~ x + (1 + x | id),
      sigma ~ 1,
      sd(id, coef = "(Intercept)") ~ 1,
      sd(id, coef = "x") ~ 1
    ),
    family = stats::gaussian(), data = dat,
    control = drm_control(se = FALSE)
  )
  ordinary <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1), family = stats::gaussian(),
    data = dat, control = drm_control(se = FALSE)
  )
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(ordinary)),
               tolerance = 1e-6)

})

test_that("Gaussian correlated q3 SD regression stays closed", {
  sim <- gaussian_correlated_q2_sd_fixture(groups = 30L, repeats = 8L)
  dat <- sim$data
  dat$z <- stats::rnorm(nrow(dat))
  # Designed refusal (active_mu_terms check in the Gaussian spec builder).
  expect_error(
    drmTMB(
      bf(
        y ~ x + z + (1 + x + z | id),
        sigma ~ 1,
        sd(id, coef = "(Intercept)") ~ w0,
        sd(id, coef = "x") ~ w1,
        sd(id, coef = "z") ~ w0
      ),
      family = stats::gaussian(), data = dat,
      control = drm_control(se = FALSE)
    ),
    "correlated random-effect block of three or more coefficients"
  )
})

test_that("Gaussian correlated q2 with an SD formula on the slope only keeps a constant intercept SD", {
  skip_on_cran()
  sim <- gaussian_correlated_q2_sd_fixture()
  dat <- sim$data
  key_slope <- 'sd(id, coef = "x")'
  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1, sd(id, coef = "x") ~ w1),
    family = stats::gaussian(), data = dat, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_named(fit$sdpars, c(key_slope, "mu"))
  constant_intercept_sd <- unname(fit$sdpars$mu)
  expect_length(constant_intercept_sd, 1L)
  sd_slope <- predict(
    fit, dpar = key_slope, newdata = data.frame(w1 = sim$v_group)
  )
  oracle <- gaussian_correlated_q2_sd_exact_loglik(
    dat,
    beta_mu = unname(coef(fit, "mu")),
    sd_intercept = rep(constant_intercept_sd, nlevels(dat$id)),
    sd_slope = unname(sd_slope),
    rho = unname(fit$corpars$mu[[1L]]),
    sigma = exp(unname(coef(fit, "sigma"))[[1L]])
  )
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
})
