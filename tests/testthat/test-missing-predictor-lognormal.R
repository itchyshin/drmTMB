missing_predictor_lognormal_data <- function() {
  n <- 76
  z <- seq(-1.6, 1.6, length.out = n)
  biomass_full <- exp(0.15 + 0.55 * z + 0.10 * sin(seq_len(n) / 4))
  y <- 0.40 + 0.85 * biomass_full - 0.25 * z + 0.05 * cos(seq_len(n) / 5)
  dat <- data.frame(y = y, z = z, biomass = biomass_full)
  dat$biomass[c(7, 18, 33, 49, 65)] <- NA_real_
  dat
}

fit_missing_predictor_lognormal <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(biomass), sigma ~ 1),
    data = dat,
    impute = list(
      biomass = impute_model(biomass ~ z, family = lognormal())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_lognormal_mi_loglik <- function(fit) {
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
  nodes <- model$quad_nodes
  weights <- model$quad_weights
  x <- dat$biomass
  out <- numeric(nrow(dat))

  observed_rows <- which(observed_x)
  for (row in observed_rows) {
    out[[row]] <- stats::dnorm(
      log(x[[row]]),
      mean = eta_mi[[row]],
      sd = sigma_mi,
      log = TRUE
    ) -
      log(x[[row]])
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
    x_nodes <- exp(eta_mi[[row]] + sigma_mi * nodes)
    mu_node <- mu_observed[[row]] + beta_biomass * (x_nodes - x_base[[row]])
    log_terms <- log(weights) +
      stats::dnorm(dat$y[[row]], mu_node, sigma, log = TRUE)
    max_log <- max(log_terms)
    out[[row]] <- max_log + log(sum(exp(log_terms - max_log)))
  }
  sum(out)
}

test_that("lognormal mi() predictor model uses log-scale quadrature likelihood", {
  dat <- missing_predictor_lognormal_data()
  missing_x <- is.na(dat$biomass)

  fit <- fit_missing_predictor_lognormal(dat)
  imp <- imputed(fit)
  probs <- fit$missing_data$predictors$biomass$quadrature_probabilities
  values <- fit$missing_data$predictors$biomass$quadrature_values

  expect_equal(fit$missing_data$version, "MD8a")
  expect_equal(fit$missing_data$predictors$biomass$family, "lognormal")
  expect_equal(fit$missing_data$predictors$biomass$model_row, which(missing_x))
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_biomass"))))
  expect_true(all(is.finite(coef(fit, "sigma_mi_biomass"))))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_lognormal_mi_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(imp$source, rep("conditional_quadrature_mean", sum(missing_x)))
  expect_true(all(imp$estimate > 0))
  expect_true(all(is.na(imp$std_error)))
  expect_equal(unname(rowSums(probs)), rep(1, sum(missing_x)), tolerance = 1e-8)
  expect_true(all(values > 0))
})

test_that("lognormal mi() predictor model combines with response masks", {
  dat <- missing_predictor_lognormal_data()
  dat$y[c(12, 33, 58)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(biomass), sigma ~ 1),
    data = dat,
    impute = list(
      biomass = impute_model(biomass ~ z, family = lognormal())
    ),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD8a")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_lognormal_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("lognormal mi() validates first positive predictor boundary", {
  dat <- missing_predictor_lognormal_data()
  dat$site <- factor(rep(letters[1:6], length.out = nrow(dat)))

  dat_zero <- dat
  dat_zero$biomass[[1L]] <- 0
  expect_error(
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = dat_zero,
      impute = list(
        biomass = impute_model(biomass ~ z, family = lognormal())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "greater than 0"
  )

  dat_factor <- dat
  dat_factor$biomass <- factor(ifelse(dat$biomass > 1, "high", "low"))
  dat_factor$biomass[c(7, 18, 33, 49, 65)] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = dat_factor,
      impute = list(
        biomass = impute_model(biomass ~ z, family = lognormal())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "numeric positive predictor"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = dat,
      impute = list(
        biomass = impute_model(biomass ~ z + (1 | site), family = lognormal())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed effects only"
  )
})
