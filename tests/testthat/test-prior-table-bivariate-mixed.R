test_that("bivariate rho12 LKJ composes with exact mu1/mu2 Normal and Student-t priors", {
  skip_if_not_installed("TMB")
  set.seed(8801)
  n <- 72L
  x <- rep(seq(-1, 1, length.out = 12), 6L)
  z1 <- rnorm(n); z2 <- rnorm(n)
  rho_true <- 0.35
  e1 <- z1
  e2 <- rho_true * z1 + sqrt(1 - rho_true^2) * z2
  dat <- data.frame(x = x,
    y1 = 0.3 + 0.45 * x + e1,
    y2 = -0.2 + 0.25 * x + e2)
  formula <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~1)
  priors <- data.frame(
    prior = c("normal(0.2,1.5)", "student_t(-0.1,1.2,4)", "lkj(2)"),
    class = c("fixef", "fixef", "correlation"),
    dpar = c("mu1", "mu2", "rho12"),
    coef = c("x", "x", "(Intercept)"),
    scale = c("link", "link", "natural_correlation")
  )
  resolved <- drm_resolve_priors(formula, biv_gaussian(), dat, priors)
  explicit_scale <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x,
    sigma1 = ~1, sigma2 = ~1, rho12 = ~1)
  expect_equal(drm_resolve_priors(explicit_scale, biv_gaussian(), dat, priors), resolved)
  varying_scale <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~x, rho12 = ~1)
  expect_error(drm_resolve_priors(varying_scale, biv_gaussian(), dat, priors),
    "intercept-only sigma1 and sigma2")
  expect_identical(resolved$class, c("fixed", "fixed", "correlation"))
  expect_identical(resolved$dpar, c("mu1", "mu2", "rho12"))
  expect_identical(resolved$kind, c("normal", "student_t", "lkj"))

  fit <- drmTMB(formula, family = biv_gaussian(), data = dat, priors = priors)
  expect_true(is.finite(fit$fixed_prior_penalty))
  expect_true(is.finite(fit$correlation_prior_penalty))

  # Independent dense bivariate Gaussian likelihood and scalar prior densities.
  # This oracle uses only the recorded data and fitted coordinates; it does not
  # call the package objective or prior evaluator.
  theta <- fit$opt$par
  packed <- fit$obj$env$parList(theta)
  beta1 <- as.double(packed$beta_mu1)
  beta2 <- as.double(packed$beta_mu2)
  sigma1 <- exp(as.double(packed$beta_sigma1[[1L]]))
  sigma2 <- exp(as.double(packed$beta_sigma2[[1L]]))
  eta_rho <- as.double(packed$beta_rho12[[1L]])
  guard <- 0.999999
  rho <- guard * tanh(eta_rho)
  mu1 <- beta1[[1L]] + beta1[[2L]] * dat$x
  mu2 <- beta2[[1L]] + beta2[[2L]] * dat$x
  u <- (dat$y1 - mu1) / sigma1
  v <- (dat$y2 - mu2) / sigma2
  det <- 1 - rho^2
  data_nll <- n * (log(2 * pi) + log(sigma1) + log(sigma2) + 0.5 * log(det)) +
    sum(u^2 - 2 * rho * u * v + v^2) / (2 * det)
  normal_penalty <- -dnorm(beta1[[2L]], mean = 0.2, sd = 1.5, log = TRUE)
  student_penalty <- -dt((beta2[[2L]] + 0.1) / 1.2, df = 4, log = TRUE) + log(1.2)
  lkj_log_normalizer <- log(2 * (guard - guard^3 / 3))
  lkj_penalty <- lkj_log_normalizer - log1p(-rho^2)
  oracle_objective <- data_nll + normal_penalty + student_penalty + lkj_penalty

  expect_equal(fit$fixed_prior_penalty, normal_penalty + student_penalty,
    tolerance = 1e-8)
  expect_equal(fit$correlation_prior_penalty, lkj_penalty, tolerance = 1e-8)
  expect_equal(fit$penalized_objective, oracle_objective, tolerance = 1e-7)
  expect_equal(as.numeric(logLik(fit)), -data_nll, tolerance = 1e-7)
  expect_equal(fit$log_prior, -(normal_penalty + student_penalty + lkj_penalty),
    tolerance = 1e-8)

  expect_error(drm_resolve_priors(formula, biv_gaussian(), dat,
    priors[1:2, , drop = FALSE]), "exactly one rho12 LKJ")
  ridge <- drm_prior_ridge(dpar = "mu1", coef = "x", lambda = 1)
  expect_error(drm_resolve_priors(formula, biv_gaussian(), dat,
    drm_priors(ridge, drm_correlation_prior_lkj(dpar = "rho12", eta = 2))),
    "Normal or Student-t")
  expect_error(drm_resolve_priors(formula, biv_gaussian(), dat,
    drm_priors(drm_prior_sd_gamma(group = "site", shape = 2, rate = 3),
      drm_correlation_prior_lkj(dpar = "rho12", eta = 2))),
    "univariate Gaussian identity")
})
