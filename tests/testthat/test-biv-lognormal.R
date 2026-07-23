lognormal_biv_oracle <- function(y1, y2, mu1, mu2, sigma1, sigma2, rho12) {
  z1 <- (log(y1) - mu1) / sigma1
  z2 <- (log(y2) - mu2) / sigma2
  log_density <- -log(2 * pi) - log(sigma1) - log(sigma2) -
    0.5 * log(1 - rho12^2) -
    0.5 * (z1^2 - 2 * rho12 * z1 * z2 + z2^2) / (1 - rho12^2)
  sum(log_density - log(y1) - log(y2))
}

simulate_biv_lognormal_truth <- function(n, beta1, beta2, sigma1, sigma2, rho12) {
  x <- seq(-1, 1, length.out = n)
  z1 <- stats::rnorm(n)
  z2 <- rho12 * z1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  data.frame(
    x = x,
    y1 = exp(beta1[[1]] + beta1[[2]] * x + sigma1 * z1),
    y2 = exp(beta2[[1]] + beta2[[2]] * x + sigma2 * z2)
  )
}

test_that("biv_lognormal matches an independent transformed-scale oracle", {
  skip_if_not_installed("drmTMB")
  set.seed(6301)
  dat <- simulate_biv_lognormal_truth(
    n = 80, beta1 = c(0.2, 0.3), beta2 = c(-0.1, -0.2),
    sigma1 = 0.45, sigma2 = 0.8, rho12 = 0.35
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
    family = biv_lognormal(), data = dat
  )
  mu1 <- predict(fit, dpar = "mu1")
  mu2 <- predict(fit, dpar = "mu2")
  sigma1 <- predict(fit, dpar = "sigma1")
  sigma2 <- predict(fit, dpar = "sigma2")
  rho12 <- rho12(fit)
  expect_equal(
    as.numeric(logLik(fit)),
    lognormal_biv_oracle(dat$y1, dat$y2, mu1, mu2, sigma1, sigma2, rho12),
    tolerance = 1e-7
  )
})

test_that("zero rho12 gives the product of two lognormal margins", {
  skip_if_not_installed("drmTMB")
  set.seed(6302)
  dat <- simulate_biv_lognormal_truth(
    n = 70, beta1 = c(0.1, 0.2), beta2 = c(-0.2, 0.1),
    sigma1 = 0.4, sigma2 = 0.7, rho12 = 0
  )
  formula <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1)
  spec <- drmTMB:::drm_build_biv_lognormal_spec(formula, dat)
  spec$map$beta_rho12 <- factor(NA)
  spec$start$beta_rho12 <- 0
  fit <- drmTMB:::drm_fit_spec(
    spec = spec, formula = formula, family = biv_lognormal(),
    control = drm_control(), REML = FALSE
  )
  mu1 <- predict(fit, dpar = "mu1")
  mu2 <- predict(fit, dpar = "mu2")
  sigma1 <- predict(fit, dpar = "sigma1")
  sigma2 <- predict(fit, dpar = "sigma2")
  product_loglik <- sum(stats::dlnorm(dat$y1, mu1, sigma1, log = TRUE)) +
    sum(stats::dlnorm(dat$y2, mu2, sigma2, log = TRUE))
  expect_equal(
    as.numeric(logLik(fit)),
    product_loglik,
    tolerance = 1e-7
  )
})

test_that("biv_lognormal preserves label-swap symmetry and response semantics", {
  skip_if_not_installed("drmTMB")
  set.seed(6303)
  dat <- simulate_biv_lognormal_truth(
    n = 90, beta1 = c(0.1, 0.4), beta2 = c(-0.3, -0.1),
    sigma1 = 0.35, sigma2 = 0.65, rho12 = -0.3
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
    family = biv_lognormal(), data = dat
  )
  swapped <- drmTMB(
    bf(mu1 = y2 ~ x, mu2 = y1 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
    family = biv_lognormal(), data = dat
  )
  expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(swapped)), tolerance = 1e-7)
  expect_equal(rho12(fit), rho12(swapped), tolerance = 1e-7)
  expected <- cbind(
    exp(predict(fit, dpar = "mu1") + predict(fit, dpar = "sigma1")^2 / 2),
    exp(predict(fit, dpar = "mu2") + predict(fit, dpar = "sigma2")^2 / 2)
  )
  expect_equal(unname(fitted(fit)), unname(expected), tolerance = 1e-10)
  sims <- simulate(fit, nsim = 1, seed = 6304)
  expect_true(all(is.finite(as.matrix(sims))) && all(as.matrix(sims) > 0))
  scales <- sigma(fit)
  expect_true(all(scales$sigma1 > 0) && all(scales$sigma2 > 0))
})

test_that("biv_lognormal retains a finite guarded correlation near the boundary", {
  skip_if_not_installed("drmTMB")
  set.seed(6305)
  dat <- simulate_biv_lognormal_truth(
    n = 160, beta1 = c(0.2, 0.1), beta2 = c(-0.1, -0.15),
    sigma1 = 0.35, sigma2 = 0.5, rho12 = 0.95
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
    family = biv_lognormal(), data = dat
  )
  rho <- rho12(fit)
  expect_true(all(is.finite(rho)))
  expect_true(all(abs(rho) < 1))
})

test_that("biv_lognormal rejects deferred syntax and invalid responses", {
  skip_if_not_installed("drmTMB")
  dat <- data.frame(y1 = c(1, 2.1, 2.9, 4.2), y2 = c(2.1, 2.8, 4.2, 4.7), x = 1:4, id = 1:4)
  base_formula <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1)
  expect_error(drmTMB(base_formula, family = biv_lognormal(), data = transform(dat, y1 = c(0, 2, 3, 4))), "strictly positive")
  expect_error(drmTMB(base_formula, family = biv_lognormal(), data = transform(dat, y1 = c(-1, 2, 3, 4))), "strictly positive")
  expect_error(drmTMB(base_formula, family = biv_lognormal(), data = transform(dat, y2 = c(2, NA, 4, 5))), "complete")
  expect_error(drmTMB(base_formula, family = biv_lognormal(), data = transform(dat, y2 = c(2, Inf, 4, 5))), "complete")
  expect_error(drmTMB(base_formula, family = biv_lognormal(), data = transform(dat, y2 = c(2, NaN, 4, 5))), "complete")
  expect_error(drmTMB(base_formula, family = biv_lognormal(), data = dat, weights = rep(1, 4)), "does not support")
  expect_error(drmTMB(bf(mu1 = y1 ~ offset(x), mu2 = y2 ~ x), family = biv_lognormal(), data = dat), "offset")
  fit <- drmTMB(base_formula, family = biv_lognormal(), data = dat)
  expect_error(confint(fit), "not implemented")
  expect_error(profile(fit), "not implemented")
  expect_error(corpairs(fit, conf.int = TRUE), "not implemented")
  expect_error(summary(fit, conf.int = TRUE), "not implemented")
  expect_error(predict_parameters(fit, conf.int = TRUE), "not implemented")
  expect_equal(nrow(profile_targets(fit)), 0L)
  expect_error(drmTMB(bf(mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x), family = biv_lognormal(), data = dat), "fixed-effect")
  expect_error(drmTMB(bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~ x), family = biv_lognormal(), data = dat), "intercept-only")
})
