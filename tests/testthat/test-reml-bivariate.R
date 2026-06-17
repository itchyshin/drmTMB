# REML for the bivariate Gaussian LOCATION model (fixed-effect mu1/mu2).
#
# REML restricts the likelihood for both mean blocks (beta_mu1, beta_mu2). With
# identical regressors in mu1 and mu2 the GLS mean estimates equal the per-
# response OLS estimates (a seemingly-unrelated-regressions result), so the REML
# residual covariance is exactly the OLS-residual cross-products divided by
# (n - p): sigma1 = sqrt(SSE1/(n-p)), sigma2 = sqrt(SSE2/(n-p)), and rho12 is the
# residual correlation (the (n-p) factor cancels, so REML rho12 = ML rho12).
# drmTMB's bivariate REML must match this exact reference.

biv_reml_fixture <- function(n = 150L, seed = 3L) {
  set.seed(seed)
  x <- stats::rnorm(n)
  S <- chol(matrix(c(1, 0.4, 0.4, 1), 2, 2))
  e <- matrix(stats::rnorm(2 * n), n, 2) %*% S
  data.frame(
    y1 = 0.3 + 0.5 * x + 0.8 * e[, 1],
    y2 = 0.1 + 0.2 * x + 0.9 * e[, 2],
    x = x
  )
}

biv_reml_reference <- function(y1, y2, X) {
  n <- length(y1)
  p <- ncol(X)
  hat <- X %*% solve(t(X) %*% X) %*% t(X)
  resid_maker <- diag(n) - hat
  e1 <- as.vector(resid_maker %*% y1)
  e2 <- as.vector(resid_maker %*% y2)
  b1 <- as.vector(solve(t(X) %*% X, t(X) %*% y1))
  b2 <- as.vector(solve(t(X) %*% X, t(X) %*% y2))
  list(
    sigma1 = sqrt(sum(e1^2) / (n - p)),
    sigma2 = sqrt(sum(e2^2) / (n - p)),
    rho12 = sum(e1 * e2) / sqrt(sum(e1^2) * sum(e2^2)),
    beta = c(b1, b2)
  )
}

test_that("bivariate fixed-effect REML matches an exact restricted-likelihood reference", {
  skip_on_cran()
  dat <- biv_reml_fixture()
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = dat,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  expect_equal(fit$estimator, "REML")
  expect_equal(fit$opt$convergence, 0L)

  X <- stats::model.matrix(~x, dat)
  ref <- biv_reml_reference(dat$y1, dat$y2, X)

  expect_equal(
    exp(as.numeric(fit$par$sigma1[1L])),
    ref$sigma1,
    tolerance = 1e-3
  )
  expect_equal(
    exp(as.numeric(fit$par$sigma2[1L])),
    ref$sigma2,
    tolerance = 1e-3
  )
  # rho12 is read on the response scale (fit$par$rho12 is the atanh-scale
  # coefficient); rho12() returns the constant response-scale correlation.
  expect_equal(as.numeric(rho12(fit))[1L], ref$rho12, tolerance = 1e-3)
  expect_equal(
    c(as.numeric(fit$par$mu1), as.numeric(fit$par$mu2)),
    ref$beta,
    tolerance = 1e-3
  )
})

test_that("bivariate REML df counts both marginalised mean blocks", {
  skip_on_cran()
  dat <- biv_reml_fixture()
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = dat,
    REML = TRUE
  )
  # 3 fixed (sigma1, sigma2, rho12 intercepts) + 4 marginalised (mu1, mu2 each x2)
  expect_equal(attr(stats::logLik(fit), "df"), length(fit$opt$par) + 4L)
})

test_that("bivariate REML rejects random/structured mean effects in this slice", {
  skip_on_cran()
  set.seed(5)
  n_id <- 30
  n <- n_id * 4
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = 4)),
    x = stats::rnorm(n)
  )
  u <- stats::rnorm(n_id, 0, 0.7)
  dat$y1 <- 0.3 + 0.5 * dat$x + u[dat$id] + stats::rnorm(n, 0, 0.6)
  dat$y2 <- 0.1 + 0.2 * dat$x + u[dat$id] + stats::rnorm(n, 0, 0.6)
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + (1 | p | id),
        mu2 = y2 ~ x + (1 | p | id),
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      REML = TRUE
    ),
    "fixed-effect mean models only"
  )
})
