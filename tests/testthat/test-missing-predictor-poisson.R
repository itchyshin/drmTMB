missing_predictor_poisson_data <- function() {
  n <- 76
  z <- seq(-1.6, 1.7, length.out = n)
  lambda <- exp(0.35 + 0.55 * z)
  abundance_full <- pmax(
    0,
    round(lambda + sqrt(lambda) * sin(seq_len(n) / 3))
  )
  y <- 0.20 + 0.42 * abundance_full - 0.25 * z + 0.03 * cos(seq_len(n) / 5)
  dat <- data.frame(y = y, z = z, abundance = abundance_full)
  dat$abundance[c(7, 18, 33, 49, 68)] <- NA_real_
  dat
}

fit_missing_predictor_poisson <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(abundance), sigma ~ 1),
    data = dat,
    impute = list(
      abundance = impute_model(abundance ~ z, family = poisson())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_poisson_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$abundance$observed
  observed_y <- fit$missing_data$observed_y
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_abundance")
  sigma <- exp(unname(coef(fit, "sigma")))
  mu_observed <- as.vector(fit$model$X$mu %*% beta_mu)
  lambda_mi <- exp(as.vector(model$X %*% beta_mi))
  nodes <- model$quad_nodes
  x <- dat$abundance
  out <- numeric(nrow(dat))

  observed_rows <- which(observed_x)
  for (row in observed_rows) {
    out[[row]] <- stats::dpois(x[[row]], lambda_mi[[row]], log = TRUE)
    if (observed_y[[row]]) {
      out[[row]] <- out[[row]] +
        stats::dnorm(dat$y[[row]], mu_observed[[row]], sigma, log = TRUE)
    }
  }

  missing_rows <- which(!observed_x)
  beta_abundance <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  for (row in missing_rows) {
    if (!observed_y[[row]]) {
      next
    }
    log_terms <- stats::dpois(nodes, lambda_mi[[row]], log = TRUE)
    mu_node <- mu_observed[[row]] + beta_abundance * (nodes - x_base[[row]])
    log_terms <- log_terms +
      stats::dnorm(dat$y[[row]], mu_node, sigma, log = TRUE)
    max_log <- max(log_terms)
    out[[row]] <- max_log + log(sum(exp(log_terms - max_log)))
  }
  sum(out)
}

test_that("poisson mi() predictor model uses finite count likelihood", {
  dat <- missing_predictor_poisson_data()
  missing_x <- is.na(dat$abundance)

  fit <- fit_missing_predictor_poisson(dat)
  imp <- imputed(fit)
  probs <- fit$missing_data$predictors$abundance$conditional_probabilities

  expect_equal(fit$missing_data$version, "MD7b")
  expect_equal(fit$missing_data$predictors$abundance$family, "poisson")
  expect_equal(
    fit$missing_data$predictors$abundance$model_row,
    which(missing_x)
  )
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_abundance"))))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_poisson_mi_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(imp$source, rep("conditional_expected_count", sum(missing_x)))
  expect_true(all(imp$estimate >= 0))
  expect_true(all(is.na(imp$std_error)))
  expect_equal(unname(rowSums(probs)), rep(1, sum(missing_x)), tolerance = 1e-8)
})

test_that("poisson mi() predictor model combines with response masks", {
  dat <- missing_predictor_poisson_data()
  dat$y[c(12, 33, 61)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(abundance), sigma ~ 1),
    data = dat,
    impute = list(
      abundance = impute_model(abundance ~ z, family = poisson())
    ),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD7b")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_poisson_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("poisson mi() validates first count predictor boundary", {
  dat <- missing_predictor_poisson_data()
  dat$site <- factor(rep(letters[1:6], length.out = nrow(dat)))

  dat_negative <- dat
  dat_negative$abundance[[1L]] <- -1
  expect_error(
    drmTMB(
      bf(y ~ z + mi(abundance), sigma ~ 1),
      data = dat_negative,
      impute = list(
        abundance = impute_model(abundance ~ z, family = poisson())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "non-negative integer counts"
  )

  dat_fractional <- dat
  dat_fractional$abundance[[1L]] <- 1.5
  expect_error(
    drmTMB(
      bf(y ~ z + mi(abundance), sigma ~ 1),
      data = dat_fractional,
      impute = list(
        abundance = impute_model(abundance ~ z, family = poisson())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "non-negative integer counts"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(abundance), sigma ~ 1),
      data = dat,
      impute = list(
        abundance = impute_model(abundance ~ z + (1 | site), family = poisson())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed effects only"
  )
})
