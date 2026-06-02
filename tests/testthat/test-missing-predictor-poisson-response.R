missing_predictor_poisson_response_data <- function() {
  n <- 64
  z <- seq(-1.5, 1.8, length.out = n)
  treatment_full <- as.numeric(sin(seq_len(n) * 1.3) + 0.3 * z > 0)
  lambda <- exp(0.25 + 0.45 * z + 0.75 * treatment_full)
  y <- pmax(0, round(lambda + sqrt(lambda) * cos(seq_len(n) / 4)))
  dat <- data.frame(
    y = y,
    z = z,
    treatment = factor(treatment_full, levels = c(0, 1))
  )
  dat$treatment[c(8, 19, 31, 46, 57)] <- NA
  dat
}

fit_missing_predictor_poisson_response <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(treatment)),
    data = dat,
    family = poisson(),
    impute = list(
      treatment = impute_model(treatment ~ z, family = binomial())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_poisson_response_binary_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$treatment$observed
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_treatment")
  eta_x <- as.vector(model$X %*% beta_mi)
  log_p1 <- stats::plogis(eta_x, log.p = TRUE)
  log_p0 <- stats::plogis(eta_x, lower.tail = FALSE, log.p = TRUE)
  eta_base <- as.vector(fit$model$offset$mu + fit$model$X$mu %*% beta_mu)
  beta_x <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  x <- as.numeric(dat$treatment) - 1
  out <- numeric(nrow(dat))

  observed_rows <- which(observed_x)
  for (row in observed_rows) {
    out[[row]] <- if (x[[row]] == 1) log_p1[[row]] else log_p0[[row]]
    out[[row]] <- out[[row]] +
      stats::dpois(dat$y[[row]], lambda = exp(eta_base[[row]]), log = TRUE)
  }

  missing_rows <- which(!observed_x)
  for (row in missing_rows) {
    eta1 <- eta_base[[row]] + beta_x * (1 - x_base[[row]])
    eta0 <- eta_base[[row]] + beta_x * (0 - x_base[[row]])
    lp1 <- log_p1[[row]] +
      stats::dpois(dat$y[[row]], lambda = exp(eta1), log = TRUE)
    lp0 <- log_p0[[row]] +
      stats::dpois(dat$y[[row]], lambda = exp(eta0), log = TRUE)
    max_log <- max(lp1, lp0)
    out[[row]] <- max_log + log(exp(lp1 - max_log) + exp(lp0 - max_log))
  }

  sum(out)
}

test_that("binary mi() predictor works with a Poisson response likelihood", {
  dat <- missing_predictor_poisson_response_data()
  missing_x <- is.na(dat$treatment)

  fit <- fit_missing_predictor_poisson_response(dat)
  imp <- imputed(fit)

  expect_equal(fit$missing_data$version, "MD9a")
  expect_equal(fit$missing_data$predictors$treatment$family, "bernoulli")
  expect_equal(
    fit$missing_data$predictors$treatment$model_row,
    which(missing_x)
  )
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_treatment"))))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_poisson_response_binary_mi_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(imp$source, rep("conditional_probability", sum(missing_x)))
  expect_true(all(is.finite(imp$estimate)))
  expect_true(all(imp$estimate >= 0 & imp$estimate <= 1))
})

test_that("Poisson-response mi() validates the first non-Gaussian response boundary", {
  dat <- missing_predictor_poisson_response_data()
  dat$count <- c(0, 1)[(seq_len(nrow(dat)) %% 2) + 1]
  dat$count[c(4, 21)] <- NA

  expect_error(
    drmTMB(
      bf(y ~ z + mi(count)),
      data = dat,
      family = poisson(),
      impute = list(count = impute_model(count ~ z, family = poisson())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "binary missing predictor"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(treatment), zi ~ 1),
      data = dat,
      family = poisson(),
      impute = list(
        treatment = impute_model(treatment ~ z, family = binomial())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "zero inflation"
  )

  dat$z[3] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ z + mi(treatment)),
      data = dat,
      family = poisson(),
      impute = list(
        treatment = impute_model(treatment ~ 1, family = binomial())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "outside explicit"
  )
})
