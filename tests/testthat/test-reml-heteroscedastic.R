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
  list(data = data.frame(y = y, x = x, z = z, id = id), id = id)
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
