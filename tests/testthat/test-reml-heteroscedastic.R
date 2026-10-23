# REML with a heteroscedastic residual (sigma ~ predictors) and an ordinary
# mean random effect. REML restricts the likelihood for the mean fixed effects
# regardless of the scale model; for a Gaussian with residual variance
# V = sigma_u^2 Z Z' + diag(sigma_i^2) the restricted likelihood is exact, so
# drmTMB's REML estimates must match a hand-computed restricted-likelihood
# reference that maximises over (sigma_u, the sigma coefficients).

reml_hetero_fixture <- function(n_id = 30L, n_each = 4L, seed = 11L) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u <- stats::rnorm(n_id, 0, 0.6) # true mean random-intercept SD
  sigma <- exp(-0.5 + 0.3 * z) # heteroscedastic residual
  y <- 0.4 + 0.7 * x + u[id] + stats::rnorm(n, 0, sigma)
  list(
    data = data.frame(y = y, x = x, z = z, id = id), id = id,
    true_beta = c(`(Intercept)` = 0.4, x = 0.7),
    true_sd_u = 0.6,
    true_sigma = c(`(Intercept)` = -0.5, z = 0.3),
    # Structural zero: x does not appear in the sigma DGP above (sigma is a
    # function of z only), so the true `fixef:sigma:x` coefficient is exactly
    # 0 by construction, not an estimated/rounded value.
    true_sigma_x_coef = 0
  )
}

det_log <- function(m) as.numeric(determinant(m, logarithm = TRUE)$modulus)

reml_hetero_reference <- function(y, X, Z_re, Z_sig) {
  n <- length(y)
  p <- ncol(X)
  ZZt <- Z_re %*% t(Z_re)
  neg_restricted_ll <- function(par) {
    sd_u <- exp(par[1])
    a <- par[-1]
    sig <- exp(as.vector(Z_sig %*% a))
    V <- sd_u^2 * ZZt + diag(sig^2)
    Vi <- solve(V)
    XtViX <- t(X) %*% Vi %*% X
    b <- solve(XtViX, t(X) %*% Vi %*% y)
    r <- y - X %*% b
    0.5 *
      ((n - p) *
        log(2 * pi) +
        det_log(V) +
        det_log(XtViX) +
        as.numeric(t(r) %*% Vi %*% r))
  }
  opt <- stats::optim(
    c(log(0.6), 0, 0),
    neg_restricted_ll,
    method = "Nelder-Mead",
    control = list(reltol = 1e-10, maxit = 8000)
  )
  sd_u <- exp(opt$par[1])
  a <- opt$par[-1]
  sig <- exp(as.vector(Z_sig %*% a))
  V <- sd_u^2 * ZZt + diag(sig^2)
  Vi <- solve(V)
  b <- solve(t(X) %*% Vi %*% X, t(X) %*% Vi %*% y)
  list(sd_u = sd_u, a = a, beta = as.numeric(b))
}

reml_random_slope_reference <- function(y, X, Z_slope) {
  n <- length(y)
  p <- ncol(X)
  ZVZt <- Z_slope %*% t(Z_slope)
  neg_restricted_ll <- function(par) {
    sd_slope <- exp(par[[1L]])
    sigma <- exp(par[[2L]])
    V <- sd_slope^2 * ZVZt + diag(sigma^2, n)
    Vi <- solve(V)
    XtViX <- t(X) %*% Vi %*% X
    beta <- solve(XtViX, t(X) %*% Vi %*% y)
    residual <- y - X %*% beta
    0.5 * (
      (n - p) * log(2 * pi) + det_log(V) + det_log(XtViX) +
        as.numeric(t(residual) %*% Vi %*% residual)
    )
  }
  opt <- stats::optim(
    c(log(0.5), log(0.35)),
    neg_restricted_ll,
    method = "Nelder-Mead",
    control = list(reltol = 1e-10, maxit = 8000)
  )
  sd_slope <- exp(opt$par[[1L]])
  sigma <- exp(opt$par[[2L]])
  V <- sd_slope^2 * ZVZt + diag(sigma^2, n)
  Vi <- solve(V)
  beta <- solve(t(X) %*% Vi %*% X, t(X) %*% Vi %*% y)
  list(sd_slope = sd_slope, sigma = sigma, beta = as.numeric(beta))
}

ml_random_slope_reference <- function(y, X, Z_slope) {
  n <- length(y)
  ZVZt <- Z_slope %*% t(Z_slope)
  neg_log_likelihood <- function(par) {
    sd_slope <- exp(par[[1L]])
    sigma <- exp(par[[2L]])
    V <- sd_slope^2 * ZVZt + diag(sigma^2, n)
    Vi <- solve(V)
    beta <- solve(t(X) %*% Vi %*% X, t(X) %*% Vi %*% y)
    residual <- y - X %*% beta
    0.5 * (
      n * log(2 * pi) + det_log(V) +
        as.numeric(t(residual) %*% Vi %*% residual)
    )
  }
  opt <- stats::optim(
    c(log(0.5), log(0.35)),
    neg_log_likelihood,
    method = "Nelder-Mead",
    control = list(reltol = 1e-10, maxit = 8000)
  )
  sd_slope <- exp(opt$par[[1L]])
  sigma <- exp(opt$par[[2L]])
  V <- sd_slope^2 * ZVZt + diag(sigma^2, n)
  Vi <- solve(V)
  beta <- solve(t(X) %*% Vi %*% X, t(X) %*% Vi %*% y)
  list(sd_slope = sd_slope, sigma = sigma, beta = as.numeric(beta))
}

ml_random_intercept_reference <- function(y, X, Z_intercept) {
  n <- length(y)
  ZVZt <- Z_intercept %*% t(Z_intercept)
  neg_log_likelihood <- function(par) {
    sd_intercept <- exp(par[[1L]])
    sigma <- exp(par[[2L]])
    V <- sd_intercept^2 * ZVZt + diag(sigma^2, n)
    Vi <- solve(V)
    beta <- solve(t(X) %*% Vi %*% X, t(X) %*% Vi %*% y)
    residual <- y - X %*% beta
    0.5 * (
      n * log(2 * pi) + det_log(V) +
        as.numeric(t(residual) %*% Vi %*% residual)
    )
  }
  opt <- stats::optim(
    c(log(0.55), log(0.35)),
    neg_log_likelihood,
    method = "Nelder-Mead",
    control = list(reltol = 1e-10, maxit = 8000)
  )
  sd_intercept <- exp(opt$par[[1L]])
  sigma <- exp(opt$par[[2L]])
  V <- sd_intercept^2 * ZVZt + diag(sigma^2, n)
  Vi <- solve(V)
  beta <- solve(t(X) %*% Vi %*% X, t(X) %*% Vi %*% y)
  list(sd_intercept = sd_intercept, sigma = sigma, beta = as.numeric(beta))
}

test_that("heteroscedastic REML matches a hand-computed restricted likelihood", {
  skip_on_cran()
  fx <- reml_hetero_fixture()
  dat <- fx$data
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = dat,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  expect_equal(fit$estimator, "REML")
  expect_equal(fit$opt$convergence, 0L)

  X <- stats::model.matrix(~x, dat)
  Z_re <- stats::model.matrix(~ 0 + id, dat)
  Z_sig <- stats::model.matrix(~z, dat)
  ref <- reml_hetero_reference(dat$y, X, Z_re, Z_sig)

  expect_equal(as.numeric(fit$sdpars$mu[[1L]]), ref$sd_u, tolerance = 3e-2)
  expect_equal(as.numeric(fit$par$sigma), ref$a, tolerance = 3e-2)
  expect_equal(as.numeric(fit$par$mu), ref$beta, tolerance = 3e-2)
})

test_that("heteroscedastic Gaussian REML response masks match the observed-data reference", {
  fx <- reml_hetero_fixture(n_id = 96L, n_each = 8L, seed = 2026081402L)
  dat <- fx$data
  set.seed(2026081403L)
  observed <- stats::runif(nrow(dat)) > 0.25
  dat_masked <- dat
  dat_masked$y[!observed] <- NA_real_

  fit_masked <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = dat_masked,
    missing = miss_control(response = "include"),
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust", se = FALSE)
  )
  fit_observed <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = dat[observed, , drop = FALSE],
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust", se = FALSE)
  )
  observed_data <- dat[observed, , drop = FALSE]
  ref <- reml_hetero_reference(
    observed_data$y,
    stats::model.matrix(~ x, observed_data),
    stats::model.matrix(~ 0 + id, observed_data),
    stats::model.matrix(~ z, observed_data)
  )

  expect_equal(as.numeric(fit_masked$sdpars$mu[[1L]]), ref$sd_u, tolerance = 3e-2)
  expect_equal(as.numeric(fit_masked$par$sigma), ref$a, tolerance = 3e-2)
  expect_equal(as.numeric(fit_masked$par$mu), ref$beta, tolerance = 3e-2)
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-8)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-8)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-8)
  expect_equal(nobs(fit_masked), sum(observed))

  expect_equal(as.numeric(fit_masked$par$mu), unname(fx$true_beta), tolerance = 0.12)
  expect_equal(as.numeric(fit_masked$par$sigma), unname(fx$true_sigma), tolerance = 0.14)
  expect_equal(as.numeric(fit_masked$sdpars$mu[[1L]]), fx$true_sd_u, tolerance = 0.14)
  expect_missing_response_sentinel_invariant(
    fit_masked,
    sentinels = c(-1e6, 1e6)
  )
})

test_that("Gaussian REML random-slope response masks match their observed-data oracle", {
  set.seed(2026081404L)
  n_id <- 64L
  n_each <- 8L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n_id * n_each)
  beta <- c(`(Intercept)` = 0.4, x = 0.7)
  sd_slope <- 0.5
  sigma <- 0.35
  slope <- stats::rnorm(n_id, sd = sd_slope)
  y <- beta[[1L]] + beta[[2L]] * x + slope[id] * x +
    stats::rnorm(n_id * n_each, sd = sigma)
  observed <- stats::runif(n_id * n_each) > 0.25
  dat <- data.frame(y = y, x = x, id = id)
  dat_masked <- dat
  dat_masked$y[!observed] <- NA_real_

  fit_masked <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1),
    family = gaussian(),
    data = dat_masked,
    missing = miss_control(response = "include"),
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust", se = FALSE)
  )
  observed_data <- dat[observed, , drop = FALSE]
  ref <- reml_random_slope_reference(
    observed_data$y,
    stats::model.matrix(~ x, observed_data),
    stats::model.matrix(~ 0 + id:x, observed_data)
  )

  expect_equal(as.numeric(fit_masked$par$mu), ref$beta, tolerance = 3e-2)
  expect_equal(exp(as.numeric(fit_masked$par$sigma)), ref$sigma, tolerance = 3e-2)
  expect_equal(as.numeric(fit_masked$sdpars$mu[[1L]]), ref$sd_slope, tolerance = 3e-2)
  expect_equal(as.numeric(fit_masked$par$mu), unname(beta), tolerance = 0.13)
  expect_equal(exp(as.numeric(fit_masked$par$sigma)), sigma, tolerance = 0.08)
  expect_equal(as.numeric(fit_masked$sdpars$mu[[1L]]), sd_slope, tolerance = 0.15)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_missing_response_sentinel_invariant(
    fit_masked,
    sentinels = c(-1e6, 1e6)
  )
})

test_that("Gaussian ML random-slope response masks match their observed-data oracle", {
  set.seed(2026081404L)
  n_id <- 64L
  n_each <- 8L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n_id * n_each)
  beta <- c(`(Intercept)` = 0.4, x = 0.7)
  sd_slope <- 0.5
  sigma <- 0.35
  slope <- stats::rnorm(n_id, sd = sd_slope)
  y <- beta[[1L]] + beta[[2L]] * x + slope[id] * x +
    stats::rnorm(n_id * n_each, sd = sigma)
  observed <- stats::runif(n_id * n_each) > 0.25
  dat <- data.frame(y = y, x = x, id = id)
  dat_masked <- dat
  dat_masked$y[!observed] <- NA_real_

  fit_masked <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1),
    family = gaussian(),
    data = dat_masked,
    missing = miss_control(response = "include"),
    REML = FALSE,
    control = drm_control(optimizer_preset = "robust", se = FALSE)
  )
  observed_data <- dat[observed, , drop = FALSE]
  ref <- ml_random_slope_reference(
    observed_data$y,
    stats::model.matrix(~ x, observed_data),
    stats::model.matrix(~ 0 + id:x, observed_data)
  )

  expect_equal(as.numeric(fit_masked$par$mu), ref$beta, tolerance = 3e-2)
  expect_equal(exp(as.numeric(fit_masked$par$sigma)), ref$sigma, tolerance = 3e-2)
  expect_equal(as.numeric(fit_masked$sdpars$mu[[1L]]), ref$sd_slope, tolerance = 3e-2)
  expect_equal(as.numeric(fit_masked$par$mu), unname(beta), tolerance = 0.13)
  expect_equal(exp(as.numeric(fit_masked$par$sigma)), sigma, tolerance = 0.08)
  expect_equal(as.numeric(fit_masked$sdpars$mu[[1L]]), sd_slope, tolerance = 0.15)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_missing_response_sentinel_invariant(
    fit_masked,
    sentinels = c(-1e6, 1e6)
  )
})

test_that("Gaussian ML random-intercept response masks match their observed-data oracle", {
  set.seed(2026081405L)
  n_id <- 64L
  n_each <- 8L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n_id * n_each)
  beta <- c(`(Intercept)` = 0.4, x = 0.7)
  sd_intercept <- 0.55
  sigma <- 0.35
  intercept <- stats::rnorm(n_id, sd = sd_intercept)
  y <- beta[[1L]] + beta[[2L]] * x + intercept[id] +
    stats::rnorm(n_id * n_each, sd = sigma)
  observed <- stats::runif(n_id * n_each) > 0.25
  dat <- data.frame(y = y, x = x, id = id)
  dat_masked <- dat
  dat_masked$y[!observed] <- NA_real_

  fit_masked <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat_masked,
    missing = miss_control(response = "include"),
    control = drm_control(optimizer_preset = "robust", se = FALSE)
  )
  observed_data <- dat[observed, , drop = FALSE]
  ref <- ml_random_intercept_reference(
    observed_data$y,
    stats::model.matrix(~ x, observed_data),
    stats::model.matrix(~ 0 + id, observed_data)
  )

  expect_equal(as.numeric(fit_masked$par$mu), ref$beta, tolerance = 3e-2)
  expect_equal(exp(as.numeric(fit_masked$par$sigma)), ref$sigma, tolerance = 3e-2)
  expect_equal(as.numeric(fit_masked$sdpars$mu[[1L]]), ref$sd_intercept, tolerance = 3e-2)
  expect_equal(as.numeric(fit_masked$par$mu), unname(beta), tolerance = 0.13)
  expect_equal(exp(as.numeric(fit_masked$par$sigma)), sigma, tolerance = 0.08)
  expect_equal(as.numeric(fit_masked$sdpars$mu[[1L]]), sd_intercept, tolerance = 0.15)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_missing_response_sentinel_invariant(
    fit_masked,
    sentinels = c(-1e6, 1e6)
  )
})

test_that("REML degrees of freedom count the marginalised mean fixed effects", {
  skip_on_cran()
  fx <- reml_hetero_fixture()
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z),
    family = gaussian(),
    data = fx$data,
    REML = TRUE
  )
  # df = fixed params in opt$par (sigma coefs + log_sd_u) + the 2 marginalised
  # mean coefficients (intercept, x).
  expect_equal(attr(stats::logLik(fit), "df"), length(fit$opt$par) + 2L)
})

test_that("REML df also counts the marginalised SCALE fixed effects", {
  skip_on_cran()
  fx <- reml_hetero_fixture()
  # A sigma random effect makes REML marginalise `beta_sigma` too, so df must add
  # back the scale fixed effects as well as the mean ones. Regression: df used to
  # drop ncol(X$sigma), under-counting the scale coefficients (and hence AIC/BIC).
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x + (1 | id)),
    family = gaussian(), data = fx$data, REML = TRUE
  )
  expect_true("beta_sigma" %in% fit$model$tmb_random_names)
  expect_equal(
    attr(stats::logLik(fit), "df"),
    length(fit$opt$par) + ncol(fit$model$X$mu) + ncol(fit$model$X$sigma)
  )
  # The total parameter count does not depend on the estimator: REML df == ML df.
  fit_ml <- drmTMB(
    bf(y ~ x, sigma ~ x + (1 | id)),
    family = gaussian(), data = fx$data, REML = FALSE
  )
  expect_equal(
    attr(stats::logLik(fit), "df"),
    attr(stats::logLik(fit_ml), "df")
  )
})
