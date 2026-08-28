# S6 A7 / #962 / D-23: missing-PREDICTOR mi() with a ZIP response
# (model_type 8). One binary missing predictor in mu only. zi ~ 1.
# The 2-point-sum density is the ZIP mixture, inlined in case 8.
# Do not call the Poisson leaf. zi_nbinom2 and mi() on zi are not this slice.
#
# Symbolic alignment
#   π = logit^{-1}(eta_zi)     eta_zi from observed-only predictors
#   μ(x) = exp(eta_mu(x))      mi() shifts eta_mu only
#   P(y=0 | μ, π) = π + (1-π) e^{-μ}
#   P(y>0 | μ, π) = (1-π) Pois(y | μ)
#   missing x: p(x=1) ZIP(y|μ(1),π) + p(x=0) ZIP(y|μ(0),π)

zip_log_density <- function(y, eta_mu, eta_zi) {
  mu <- exp(eta_mu)
  log_zi <- stats::plogis(eta_zi, log.p = TRUE)
  log_one_minus_zi <- stats::plogis(eta_zi, lower.tail = FALSE, log.p = TRUE)
  n <- length(y)
  out <- numeric(n)
  for (i in seq_len(n)) {
    if (y[[i]] == 0) {
      a <- log_zi[[i]]
      b <- log_one_minus_zi[[i]] - mu[[i]]
      m <- max(a, b)
      out[[i]] <- m + log(exp(a - m) + exp(b - m))
    } else {
      out[[i]] <- log_one_minus_zi[[i]] +
        stats::dpois(y[[i]], mu[[i]], log = TRUE)
    }
  }
  out
}

missing_predictor_zi_poisson_response_data <- function() {
  n <- 90
  z <- seq(-1.6, 1.7, length.out = n)
  treatment_full <- as.numeric(sin(seq_len(n) * 1.3) + 0.3 * z > 0)
  eta <- 0.25 + 0.45 * z + 0.75 * treatment_full
  lambda <- exp(eta)
  y <- pmax(0L, as.integer(round(lambda + sqrt(lambda) * cos(seq_len(n) / 4))))
  # Extra structural zeros, independent of treatment (π from zi ~ 1).
  y[seq(3L, n, by = 5L)] <- 0L
  dat <- data.frame(
    y = y,
    z = z,
    treatment = factor(treatment_full, levels = c(0, 1))
  )
  dat$treatment[c(8, 19, 31, 46, 57, 70, 83)] <- NA
  dat
}

fit_missing_predictor_zi_poisson_response <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(treatment), zi ~ 1),
    data = dat,
    family = poisson(),
    impute = list(
      treatment = impute_model(treatment ~ z, family = binomial())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_zi_poisson_response_binary_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$treatment$observed
  beta_mu <- coef(fit, "mu")
  beta_zi <- coef(fit, "zi")
  beta_mi <- coef(fit, "mi_treatment")
  eta_x <- as.vector(model$X %*% beta_mi)
  log_p1 <- stats::plogis(eta_x, log.p = TRUE)
  log_p0 <- stats::plogis(eta_x, lower.tail = FALSE, log.p = TRUE)
  eta_base <- as.vector(fit$model$offset$mu + fit$model$X$mu %*% beta_mu)
  eta_zi <- as.vector(fit$model$X$zi %*% beta_zi)
  beta_x <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  yv <- as.numeric(dat$y)
  out <- numeric(nrow(dat))

  for (row in which(observed_x)) {
    x_row <- as.numeric(dat$treatment[[row]]) - 1
    out[[row]] <- if (x_row == 1) log_p1[[row]] else log_p0[[row]]
    out[[row]] <- out[[row]] +
      zip_log_density(yv[[row]], eta_base[[row]], eta_zi[[row]])
  }
  for (row in which(!observed_x)) {
    eta1 <- eta_base[[row]] + beta_x * (1 - x_base[[row]])
    eta0 <- eta_base[[row]] + beta_x * (0 - x_base[[row]])
    lp1 <- log_p1[[row]] +
      zip_log_density(yv[[row]], eta1, eta_zi[[row]])
    lp0 <- log_p0[[row]] +
      zip_log_density(yv[[row]], eta0, eta_zi[[row]])
    max_log <- max(lp1, lp0)
    out[[row]] <- max_log + log(exp(lp1 - max_log) + exp(lp0 - max_log))
  }
  sum(out)
}

rzip <- function(n, mu, pi) {
  y <- stats::rpois(n, mu)
  y[stats::runif(n) < pi] <- 0L
  y
}

test_that("binary mi() predictor works with a ZIP mixture likelihood", {
  dat <- missing_predictor_zi_poisson_response_data()

  fit <- fit_missing_predictor_zi_poisson_response(dat)

  expect_equal(fit$model$model_type, "zi_poisson")
  expect_equal(fit$missing_data$version, "MD-zi-poisson-mi")
  expect_equal(fit$missing_data$predictors$treatment$family, "bernoulli")
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "zi"))))
  expect_true(all(is.finite(coef(fit, "mi_treatment"))))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_zi_poisson_response_binary_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("ZIP-response mi() recovers mu, zi, and the predictor under MCAR", {
  set.seed(13)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  eta <- 0.4 + 0.5 * z + 0.7 * x
  pi <- stats::plogis(-0.8)
  y <- rzip(n, exp(eta), pi)
  d <- data.frame(y = y, z = z, x = factor(x, levels = c(0, 1)))
  d$x[sample(n, round(0.2 * n))] <- NA

  fit <- drmTMB(
    bf(y ~ z + mi(x), zi ~ 1),
    family = poisson(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.15)
  expect_equal(unname(coef(fit, "zi")), -0.8, tolerance = 0.15)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.15)
})

test_that("ZIP-response mi() recovers under outcome-dependent MAR", {
  set.seed(21)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  eta <- 0.4 + 0.5 * z + 0.7 * x
  pi <- stats::plogis(-0.8)
  y <- rzip(n, exp(eta), pi)
  d <- data.frame(y = y, z = z, x = factor(x, levels = c(0, 1)))
  p_miss <- stats::plogis(-0.8 + 0.6 * as.numeric(scale(y)))
  d$x[stats::runif(n) < p_miss] <- NA
  expect_true(mean(is.na(d$x)) > 0.1)

  fit <- drmTMB(
    bf(y ~ z + mi(x), zi ~ 1),
    family = poisson(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.20)
  expect_equal(unname(coef(fit, "zi")), -0.8, tolerance = 0.20)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.20)
})

test_that("ZIP-response mi() does not load extra zeros onto x when beta_x is 0", {
  set.seed(34)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  eta <- 0.4 + 0.5 * z + 0 * x
  pi <- stats::plogis(-0.8)
  y <- rzip(n, exp(eta), pi)
  d <- data.frame(y = y, z = z, x = factor(x, levels = c(0, 1)))
  d$x[sample(n, round(0.2 * n))] <- NA

  fit <- drmTMB(
    bf(y ~ z + mi(x), zi ~ 1),
    family = poisson(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu"))[[3]], 0, tolerance = 0.15)
  expect_equal(unname(coef(fit, "zi")), -0.8, tolerance = 0.15)
})

test_that("ZIP-response mi() refuses mi() on zi and a non-binary predictor", {
  dat <- missing_predictor_zi_poisson_response_data()

  expect_error(
    drmTMB(
      bf(y ~ z + mi(treatment), zi ~ mi(treatment)),
      data = dat,
      family = poisson(),
      impute = list(
        treatment = impute_model(treatment ~ z, family = binomial())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "cannot carry"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(treatment), zi ~ treatment),
      data = dat,
      family = poisson(),
      impute = list(
        treatment = impute_model(treatment ~ z, family = binomial())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "missing predictor on"
  )

  dat$biomass <- exp(dat$z)
  dat$biomass[c(4, 21)] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(biomass), zi ~ 1),
      data = dat,
      family = poisson(),
      impute = list(
        biomass = impute_model(biomass ~ z, family = lognormal())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "binary missing predictor"
  )
})
