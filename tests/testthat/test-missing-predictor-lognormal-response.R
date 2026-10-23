# S6 A7 / #962: missing-PREDICTOR mi() with a lognormal log-location
# response (model_type 4). One binary missing predictor. The 2-point-sum
# density is the shared drm_response_log_density leaf
# (dnorm(log(y), mu, sigma) - log(y)). Ported from the held 2026-08-10 P3
# leaf work (claude/mi-response-leaves @ 110633584); student is not this
# slice (nu does not fit the current leaf signature).

# Lognormal log-density in the exact C++ identity-log-location parameterization.
lognormal_response_log_density <- function(y, mu, log_sigma) {
  sigma <- exp(log_sigma)
  stats::dnorm(log(y), mean = mu, sd = sigma, log = TRUE) - log(y)
}

missing_predictor_lognormal_response_data <- function() {
  n <- 90
  z <- seq(-1.6, 1.7, length.out = n)
  treatment_full <- as.numeric(sin(seq_len(n) * 1.3) + 0.3 * z > 0)
  mu <- 0.3 + 0.4 * z + 0.6 * treatment_full
  # Deterministic strictly-positive response; the FIML identity does not
  # require y to be truly lognormal, only strictly positive.
  y <- exp(mu + 0.2 * cos(seq_len(n) / 4))
  dat <- data.frame(
    y = y,
    z = z,
    treatment = factor(treatment_full, levels = c(0, 1))
  )
  dat$treatment[c(8, 19, 31, 46, 57, 70, 83)] <- NA
  dat
}

fit_missing_predictor_lognormal_response <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(treatment), sigma ~ 1),
    data = dat,
    family = lognormal(),
    impute = list(
      treatment = impute_model(treatment ~ z, family = binomial())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_lognormal_response_binary_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$treatment$observed
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_treatment")
  log_sigma <- as.numeric(coef(fit, "sigma"))
  eta_x <- as.vector(model$X %*% beta_mi)
  log_p1 <- stats::plogis(eta_x, log.p = TRUE)
  log_p0 <- stats::plogis(eta_x, lower.tail = FALSE, log.p = TRUE)
  mu_base <- as.vector(fit$model$offset$mu + fit$model$X$mu %*% beta_mu)
  beta_x <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  yv <- fit$model$y
  out <- numeric(nrow(dat))

  for (row in which(observed_x)) {
    x_row <- as.numeric(dat$treatment[[row]]) - 1
    out[[row]] <- if (x_row == 1) log_p1[[row]] else log_p0[[row]]
    out[[row]] <- out[[row]] +
      lognormal_response_log_density(yv[[row]], mu_base[[row]], log_sigma)
  }
  for (row in which(!observed_x)) {
    mu1 <- mu_base[[row]] + beta_x * (1 - x_base[[row]])
    mu0 <- mu_base[[row]] + beta_x * (0 - x_base[[row]])
    lp1 <- log_p1[[row]] +
      lognormal_response_log_density(yv[[row]], mu1, log_sigma)
    lp0 <- log_p0[[row]] +
      lognormal_response_log_density(yv[[row]], mu0, log_sigma)
    max_log <- max(lp1, lp0)
    out[[row]] <- max_log + log(exp(lp1 - max_log) + exp(lp0 - max_log))
  }
  sum(out)
}

test_that("binary mi() predictor works with a lognormal response likelihood", {
  dat <- missing_predictor_lognormal_response_data()

  fit <- fit_missing_predictor_lognormal_response(dat)

  expect_equal(fit$missing_data$version, "MD-lognormal-mi")
  expect_equal(fit$missing_data$predictors$treatment$family, "bernoulli")
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_treatment"))))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_lognormal_response_binary_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("lognormal-response mi() recovers the mean, sdlog, and predictor model under MCAR", {
  set.seed(13)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  mu <- 0.4 + 0.5 * z + 0.7 * x
  sdlog <- 0.3
  y <- stats::rlnorm(n, meanlog = mu, sdlog = sdlog)
  d <- data.frame(y = y, z = z, x = factor(x, levels = c(0, 1)))
  d$x[sample(n, round(0.2 * n))] <- NA

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    family = lognormal(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.15)
  expect_equal(unname(coef(fit, "sigma")), log(sdlog), tolerance = 0.15)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.15)
})

test_that("lognormal-response mi() recovers under outcome-dependent MAR", {
  set.seed(21)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  mu <- 0.4 + 0.5 * z + 0.7 * x
  sdlog <- 0.3
  y <- stats::rlnorm(n, meanlog = mu, sdlog = sdlog)
  d <- data.frame(y = y, z = z, x = factor(x, levels = c(0, 1)))
  p_miss <- stats::plogis(-0.8 + 0.6 * scale(log(y))[, 1])
  d$x[stats::runif(n) < p_miss] <- NA
  expect_true(mean(is.na(d$x)) > 0.1)

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    family = lognormal(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.20)
  expect_equal(unname(coef(fit, "sigma")), log(sdlog), tolerance = 0.20)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.20)
})

test_that("lognormal-response mi() still refuses a non-binary predictor", {
  dat <- missing_predictor_lognormal_response_data()
  dat$biomass <- exp(dat$z)
  dat$biomass[c(4, 21)] <- NA

  expect_error(
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = dat,
      family = lognormal(),
      impute = list(
        biomass = impute_model(biomass ~ z, family = lognormal())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "binary missing predictor"
  )
})
