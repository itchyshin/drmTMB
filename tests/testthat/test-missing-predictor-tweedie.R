missing_predictor_tweedie_data <- function() {
  n <- 82
  z <- seq(-1.7, 1.8, length.out = n)
  mean_full <- exp(0.10 + 0.45 * z)
  zero <- seq_len(n) %% 6 %in% c(0, 1)
  biomass_full <- ifelse(
    zero,
    0,
    mean_full * (1 + 0.16 * sin(seq_len(n) / 4))
  )
  y <- 0.25 + 0.62 * biomass_full - 0.18 * z + 0.04 * cos(seq_len(n) / 6)
  dat <- data.frame(y = y, z = z, biomass = biomass_full)
  dat$biomass[c(7, 18, 31, 44, 58, 76)] <- NA_real_
  dat
}

fit_missing_predictor_tweedie <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(biomass), sigma ~ 1),
    data = dat,
    impute = list(
      biomass = impute_model(biomass ~ z, family = tweedie())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_tweedie_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$biomass$observed
  observed_y <- fit$missing_data$observed_y
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_biomass")
  sigma_mi <- unname(coef(fit, "sigma_mi_biomass"))
  sigma <- exp(unname(coef(fit, "sigma")))
  mu_observed <- as.vector(fit$model$X$mu %*% beta_mu)
  eta_mi <- as.vector(model$X %*% beta_mi)
  mean_mi <- exp(eta_mi)
  nodes <- model$quad_nodes
  weights <- model$quad_weights
  power <- fit$missing_data$predictors$biomass$power
  x <- dat$biomass
  out <- numeric(nrow(dat))

  observed_rows <- which(observed_x)
  for (row in observed_rows) {
    out[[row]] <- drmTMB:::drm_tweedie_missing_predictor_log_density(
      x[[row]],
      mu = mean_mi[[row]],
      sigma = sigma_mi,
      power = power
    )
    if (observed_y[[row]]) {
      out[[row]] <- out[[row]] +
        stats::dnorm(dat$y[[row]], mu_observed[[row]], sigma, log = TRUE)
    }
  }

  missing_rows <- which(!observed_x)
  beta_biomass <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  for (row in missing_rows) {
    if (!observed_y[[row]]) {
      next
    }
    log_terms <- log(weights) +
      drmTMB:::drm_tweedie_missing_predictor_log_density(
        nodes,
        mu = mean_mi[[row]],
        sigma = sigma_mi,
        power = power
      )
    mu_node <- mu_observed[[row]] + beta_biomass * (nodes - x_base[[row]])
    log_terms <- log_terms +
      stats::dnorm(dat$y[[row]], mu_node, sigma, log = TRUE)
    max_log <- max(log_terms)
    out[[row]] <- max_log + log(sum(exp(log_terms - max_log)))
  }
  sum(out)
}

test_that("Tweedie mi() predictor model handles exact-zero semi-continuous predictors", {
  dat <- missing_predictor_tweedie_data()
  missing_x <- is.na(dat$biomass)

  fit <- fit_missing_predictor_tweedie(dat)
  imp <- imputed(fit)
  probs <- fit$missing_data$predictors$biomass$quadrature_probabilities
  values <- fit$missing_data$predictors$biomass$quadrature_values

  expect_equal(fit$missing_data$version, "MD8c")
  expect_equal(fit$missing_data$predictors$biomass$family, "tweedie")
  expect_equal(fit$missing_data$predictors$biomass$power, 1.5)
  expect_equal(fit$missing_data$predictors$biomass$model_row, which(missing_x))
  expect_equal(nobs(fit), nrow(dat))
  expect_true(any(dat$biomass == 0, na.rm = TRUE))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_biomass"))))
  expect_true(all(is.finite(coef(fit, "sigma_mi_biomass"))))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_tweedie_mi_loglik(fit),
    tolerance = 1e-5
  )
  expect_equal(imp$source, rep("conditional_quadrature_mean", sum(missing_x)))
  expect_true(all(imp$estimate >= 0))
  expect_true(all(is.na(imp$std_error)))
  expect_equal(unname(rowSums(probs)), rep(1, sum(missing_x)), tolerance = 1e-8)
  expect_true(any(values == 0))
  expect_true(all(values >= 0))
})

test_that("Tweedie mi() predictor model combines with response masks", {
  dat <- missing_predictor_tweedie_data()
  dat$y[c(12, 31, 55)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(biomass), sigma ~ 1),
    data = dat,
    impute = list(
      biomass = impute_model(biomass ~ z, family = tweedie())
    ),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD8c")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_tweedie_mi_loglik(fit),
    tolerance = 1e-5
  )
})

test_that("Tweedie mi() validates first semi-continuous predictor boundary", {
  dat <- missing_predictor_tweedie_data()
  dat$site <- factor(rep(letters[1:6], length.out = nrow(dat)))

  dat_negative <- dat
  dat_negative$biomass[[2L]] <- -0.2
  expect_error(
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = dat_negative,
      impute = list(
        biomass = impute_model(biomass ~ z, family = tweedie())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "greater than or equal to 0"
  )

  dat_factor <- dat
  dat_factor$biomass <- factor(ifelse(dat$biomass > 0, "positive", "zero"))
  dat_factor$biomass[c(7, 18, 31, 44, 58, 76)] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = dat_factor,
      impute = list(
        biomass = impute_model(biomass ~ z, family = tweedie())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "numeric non-negative predictor"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = dat,
      impute = list(
        biomass = impute_model(biomass ~ z + (1 | site), family = tweedie())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed effects only"
  )
})
