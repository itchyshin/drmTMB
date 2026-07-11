# P3: missing-PREDICTOR mi() modelling with a binomial (0/1) response
# (model_type 18). One binary missing predictor, mirroring the Poisson MD9a; the
# response density in the mi() 2-point sum is the shared drm_response_log_density
# leaf.

missing_predictor_binomial_response_data <- function() {
  n <- 80
  z <- seq(-1.6, 1.7, length.out = n)
  treatment_full <- as.numeric(sin(seq_len(n) * 1.3) + 0.3 * z > 0)
  p <- stats::plogis(-0.1 + 0.6 * z + 0.9 * treatment_full)
  y <- as.numeric(cos(seq_len(n) / 3) + 2 * p > 1.2)
  dat <- data.frame(
    y = y,
    z = z,
    treatment = factor(treatment_full, levels = c(0, 1))
  )
  dat$treatment[c(8, 19, 31, 46, 57, 70)] <- NA
  dat
}

fit_missing_predictor_binomial_response <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(treatment)),
    data = dat,
    family = binomial(),
    impute = list(
      treatment = impute_model(treatment ~ z, family = binomial())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_binomial_response_binary_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$treatment$observed
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_treatment")
  eta_x <- as.vector(model$X %*% beta_mi)
  log_p1 <- stats::plogis(eta_x, log.p = TRUE)
  log_p0 <- stats::plogis(eta_x, lower.tail = FALSE, log.p = TRUE)
  offset_mu <- if (!is.null(fit$model$offset$mu)) {
    fit$model$offset$mu
  } else {
    rep(0, nrow(dat))
  }
  eta_base <- as.vector(offset_mu + fit$model$X$mu %*% beta_mu)
  beta_x <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  trials <- fit$model$trials
  yv <- fit$model$y
  out <- numeric(nrow(dat))

  for (row in which(observed_x)) {
    x_row <- as.numeric(dat$treatment[[row]]) - 1
    out[[row]] <- if (x_row == 1) log_p1[[row]] else log_p0[[row]]
    out[[row]] <- out[[row]] +
      stats::dbinom(
        yv[[row]],
        size = trials[[row]],
        prob = stats::plogis(eta_base[[row]]),
        log = TRUE
      )
  }
  for (row in which(!observed_x)) {
    eta1 <- eta_base[[row]] + beta_x * (1 - x_base[[row]])
    eta0 <- eta_base[[row]] + beta_x * (0 - x_base[[row]])
    lp1 <- log_p1[[row]] +
      stats::dbinom(yv[[row]], size = trials[[row]], prob = stats::plogis(eta1), log = TRUE)
    lp0 <- log_p0[[row]] +
      stats::dbinom(yv[[row]], size = trials[[row]], prob = stats::plogis(eta0), log = TRUE)
    max_log <- max(lp1, lp0)
    out[[row]] <- max_log + log(exp(lp1 - max_log) + exp(lp0 - max_log))
  }
  sum(out)
}

test_that("binary mi() predictor works with a binomial response likelihood", {
  dat <- missing_predictor_binomial_response_data()
  missing_x <- is.na(dat$treatment)

  fit <- fit_missing_predictor_binomial_response(dat)

  expect_equal(fit$missing_data$predictors$treatment$family, "bernoulli")
  expect_equal(
    fit$missing_data$predictors$treatment$model_row,
    which(missing_x)
  )
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_treatment"))))
  # the fitted marginal likelihood equals the hand-computed 2-point-sum FIML
  expect_equal(
    as.numeric(logLik(fit)),
    manual_binomial_response_binary_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("binomial-response mi() recovers the response and predictor models", {
  set.seed(11)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  y <- rbinom(n, 1, stats::plogis(-0.2 + 0.5 * z + 1.0 * x))
  d <- data.frame(y = y, z = z, x = factor(x, levels = c(0, 1)))
  d$x[sample(n, round(0.2 * n))] <- NA

  fit <- drmTMB(
    bf(y ~ z + mi(x)),
    family = binomial(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  # response model: intercept, z, mi(x) effect
  expect_equal(unname(coef(fit, "mu")), c(-0.2, 0.5, 1.0), tolerance = 0.15)
  # predictor model: intercept, z
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.15)
})

test_that("non-binary binomial-response mi() predictors are rejected in this slice", {
  dat <- missing_predictor_binomial_response_data()
  dat$w <- dat$z + 0.1
  dat$w[c(8, 19)] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(w)),
      data = dat,
      family = binomial(),
      impute = list(w = impute_model(w ~ z, family = gaussian())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "one binary missing predictor"
  )
})
