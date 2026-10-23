# S6 A7 / #962: missing-PREDICTOR mi() with a beta_binomial response
# (model_type 14). One binary missing predictor. The 2-point-sum density
# is the shared drm_response_log_density leaf (logit mu, phi = exp(-2*log_sigma)).
# Student and zi-* are not this slice.

beta_binomial_response_log_density <- function(y, eta, log_sigma, trials) {
  mu <- stats::plogis(eta)
  phi <- exp(-2 * log_sigma)
  alpha <- mu * phi
  beta_shape <- (1 - mu) * phi
  failures <- trials - y
  lgamma(trials + 1) -
    lgamma(y + 1) -
    lgamma(failures + 1) +
    lgamma(phi) -
    lgamma(trials + phi) +
    lgamma(y + alpha) -
    lgamma(alpha) +
    lgamma(failures + beta_shape) -
    lgamma(beta_shape)
}

missing_predictor_beta_binomial_response_data <- function() {
  n <- 90
  z <- seq(-1.6, 1.7, length.out = n)
  treatment_full <- as.numeric(sin(seq_len(n) * 1.3) + 0.3 * z > 0)
  eta <- 0.3 + 0.4 * z + 0.6 * treatment_full
  trials <- 8L
  # Deterministic valid counts; the FIML identity does not require a
  # true beta-binomial draw.
  success <- pmin(trials, pmax(0L, as.integer(round(4 + 2 * sin(seq_len(n) / 4) + 2 * treatment_full))))
  dat <- data.frame(
    success = success,
    failure = trials - success,
    z = z,
    treatment = factor(treatment_full, levels = c(0, 1))
  )
  dat$treatment[c(8, 19, 31, 46, 57, 70, 83)] <- NA
  dat
}

fit_missing_predictor_beta_binomial_response <- function(dat) {
  drmTMB(
    bf(cbind(success, failure) ~ z + mi(treatment), sigma ~ 1),
    data = dat,
    family = beta_binomial(),
    impute = list(
      treatment = impute_model(treatment ~ z, family = binomial())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_beta_binomial_response_binary_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$treatment$observed
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_treatment")
  log_sigma <- as.numeric(coef(fit, "sigma"))
  eta_x <- as.vector(model$X %*% beta_mi)
  log_p1 <- stats::plogis(eta_x, log.p = TRUE)
  log_p0 <- stats::plogis(eta_x, lower.tail = FALSE, log.p = TRUE)
  eta_base <- as.vector(fit$model$offset$mu + fit$model$X$mu %*% beta_mu)
  beta_x <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  yv <- fit$model$y
  trials <- fit$model$trials
  out <- numeric(nrow(dat))

  for (row in which(observed_x)) {
    x_row <- as.numeric(dat$treatment[[row]]) - 1
    out[[row]] <- if (x_row == 1) log_p1[[row]] else log_p0[[row]]
    out[[row]] <- out[[row]] +
      beta_binomial_response_log_density(
        yv[[row]], eta_base[[row]], log_sigma, trials[[row]]
      )
  }
  for (row in which(!observed_x)) {
    eta1 <- eta_base[[row]] + beta_x * (1 - x_base[[row]])
    eta0 <- eta_base[[row]] + beta_x * (0 - x_base[[row]])
    lp1 <- log_p1[[row]] +
      beta_binomial_response_log_density(
        yv[[row]], eta1, log_sigma, trials[[row]]
      )
    lp0 <- log_p0[[row]] +
      beta_binomial_response_log_density(
        yv[[row]], eta0, log_sigma, trials[[row]]
      )
    max_log <- max(lp1, lp0)
    out[[row]] <- max_log + log(exp(lp1 - max_log) + exp(lp0 - max_log))
  }
  sum(out)
}

rbeta_binomial <- function(n, trials, mu, phi) {
  alpha <- mu * phi
  beta_shape <- (1 - mu) * phi
  p <- stats::rbeta(n, alpha, beta_shape)
  stats::rbinom(n, size = trials, prob = p)
}

test_that("binary mi() predictor works with a beta_binomial response likelihood", {
  dat <- missing_predictor_beta_binomial_response_data()

  fit <- fit_missing_predictor_beta_binomial_response(dat)

  expect_equal(fit$missing_data$version, "MD-beta-binomial-mi")
  expect_equal(fit$missing_data$predictors$treatment$family, "bernoulli")
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_treatment"))))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_beta_binomial_response_binary_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("beta_binomial-response mi() recovers the logit mean, sigma, and predictor model under MCAR", {
  set.seed(13)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  eta <- 0.4 + 0.5 * z + 0.7 * x
  sigma <- 0.3
  phi <- 1 / sigma^2
  trials <- 20L
  success <- rbeta_binomial(n, trials, stats::plogis(eta), phi)
  d <- data.frame(
    success = success,
    failure = trials - success,
    z = z,
    x = factor(x, levels = c(0, 1))
  )
  d$x[sample(n, round(0.2 * n))] <- NA

  fit <- drmTMB(
    bf(cbind(success, failure) ~ z + mi(x), sigma ~ 1),
    family = beta_binomial(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.15)
  expect_equal(unname(coef(fit, "sigma")), log(sigma), tolerance = 0.15)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.15)
})

test_that("beta_binomial-response mi() recovers under outcome-dependent MAR", {
  set.seed(21)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  eta <- 0.4 + 0.5 * z + 0.7 * x
  sigma <- 0.3
  phi <- 1 / sigma^2
  trials <- 20L
  success <- rbeta_binomial(n, trials, stats::plogis(eta), phi)
  d <- data.frame(
    success = success,
    failure = trials - success,
    z = z,
    x = factor(x, levels = c(0, 1))
  )
  p_miss <- stats::plogis(-0.8 + 0.6 * scale(success / trials)[, 1])
  d$x[stats::runif(n) < p_miss] <- NA
  expect_true(mean(is.na(d$x)) > 0.1)

  fit <- drmTMB(
    bf(cbind(success, failure) ~ z + mi(x), sigma ~ 1),
    family = beta_binomial(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.20)
  expect_equal(unname(coef(fit, "sigma")), log(sigma), tolerance = 0.20)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.20)
})

test_that("beta_binomial-response mi() still refuses a non-binary predictor", {
  dat <- missing_predictor_beta_binomial_response_data()
  dat$biomass <- exp(dat$z)
  dat$biomass[c(4, 21)] <- NA

  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ z + mi(biomass), sigma ~ 1),
      data = dat,
      family = beta_binomial(),
      impute = list(
        biomass = impute_model(biomass ~ z, family = lognormal())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "binary missing predictor"
  )
})
