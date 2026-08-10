# P3: missing-PREDICTOR mi() modelling with a Gamma mean-CV response
# (model_type 5). One binary missing predictor; the response density in the
# mi() 2-point sum is the shared drm_response_log_density leaf, carrying the
# coefficient-of-variation sigma (shape = 1/sigma^2, scale = mu*sigma^2).

# Gamma log-density in the exact C++ mean-CV parameterization.
gamma_response_log_density <- function(y, eta, log_sigma) {
  mu <- exp(eta)
  sigma <- exp(log_sigma)
  shape <- 1 / sigma^2
  scale <- mu * sigma^2
  stats::dgamma(y, shape = shape, scale = scale, log = TRUE)
}

missing_predictor_gamma_response_data <- function() {
  n <- 90
  z <- seq(-1.6, 1.7, length.out = n)
  treatment_full <- as.numeric(sin(seq_len(n) * 1.3) + 0.3 * z > 0)
  eta <- 0.3 + 0.4 * z + 0.6 * treatment_full
  # Deterministic strictly-positive response; the FIML identity does not
  # require y to be truly Gamma-distributed, only strictly positive.
  y <- exp(eta + 0.2 * cos(seq_len(n) / 4))
  dat <- data.frame(
    y = y,
    z = z,
    treatment = factor(treatment_full, levels = c(0, 1))
  )
  dat$treatment[c(8, 19, 31, 46, 57, 70, 83)] <- NA
  dat
}

fit_missing_predictor_gamma_response <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(treatment), sigma ~ 1),
    data = dat,
    family = stats::Gamma(link = "log"),
    impute = list(
      treatment = impute_model(treatment ~ z, family = binomial())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_gamma_response_binary_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$treatment$observed
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_treatment")
  log_sigma <- as.numeric(coef(fit, "sigma"))
  eta_x <- as.vector(model$X %*% beta_mi)
  log_p1 <- stats::plogis(eta_x, log.p = TRUE)
  log_p0 <- stats::plogis(eta_x, lower.tail = FALSE, log.p = TRUE)
  # Gamma has no offset on mu.
  eta_base <- as.vector(fit$model$X$mu %*% beta_mu)
  beta_x <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  yv <- fit$model$y
  out <- numeric(nrow(dat))

  for (row in which(observed_x)) {
    x_row <- as.numeric(dat$treatment[[row]]) - 1
    out[[row]] <- if (x_row == 1) log_p1[[row]] else log_p0[[row]]
    out[[row]] <- out[[row]] +
      gamma_response_log_density(yv[[row]], eta_base[[row]], log_sigma)
  }
  for (row in which(!observed_x)) {
    eta1 <- eta_base[[row]] + beta_x * (1 - x_base[[row]])
    eta0 <- eta_base[[row]] + beta_x * (0 - x_base[[row]])
    lp1 <- log_p1[[row]] + gamma_response_log_density(yv[[row]], eta1, log_sigma)
    lp0 <- log_p0[[row]] + gamma_response_log_density(yv[[row]], eta0, log_sigma)
    max_log <- max(lp1, lp0)
    out[[row]] <- max_log + log(exp(lp1 - max_log) + exp(lp0 - max_log))
  }
  sum(out)
}

test_that("binary mi() predictor works with a Gamma response likelihood", {
  dat <- missing_predictor_gamma_response_data()

  fit <- fit_missing_predictor_gamma_response(dat)

  expect_equal(fit$missing_data$predictors$treatment$family, "bernoulli")
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_treatment"))))
  # the fitted marginal likelihood equals the hand-computed 2-point-sum FIML
  expect_equal(
    as.numeric(logLik(fit)),
    manual_gamma_response_binary_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("Gamma-response mi() recovers the mean, CV, and predictor model", {
  set.seed(13)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  eta <- 0.4 + 0.5 * z + 0.7 * x
  mu <- exp(eta)
  cv <- 0.3
  y <- stats::rgamma(n, shape = 1 / cv^2, scale = mu * cv^2)
  d <- data.frame(y = y, z = z, x = factor(x, levels = c(0, 1)))
  d$x[sample(n, round(0.2 * n))] <- NA

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    family = stats::Gamma(link = "log"),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.15)
  expect_equal(unname(coef(fit, "sigma")), log(cv), tolerance = 0.15)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.15)
})
