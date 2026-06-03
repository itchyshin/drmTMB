missing_predictor_truncated_nbinom2_data <- function() {
  n <- 84
  z <- seq(-1.5, 1.9, length.out = n)
  mu <- exp(0.55 + 0.42 * z)
  sigma <- 0.55
  size <- 1 / sigma^2
  p0 <- stats::dnbinom(0, size = size, mu = mu)
  abundance_full <- stats::qnbinom(
    p0 + ppoints(n) * (1 - p0),
    size = size,
    mu = mu
  )
  abundance_full <- as.numeric(abundance_full[order(order(cos(seq_len(n))))])
  y <- 0.22 + 0.31 * abundance_full - 0.18 * z + 0.03 * sin(seq_len(n) / 5)
  dat <- data.frame(y = y, z = z, abundance = abundance_full)
  dat$abundance[c(5, 19, 34, 49, 66, 80)] <- NA_real_
  dat
}

fit_missing_predictor_truncated_nbinom2 <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(abundance), sigma ~ 1),
    data = dat,
    impute = list(
      abundance = impute_model(abundance ~ z, family = truncated_nbinom2())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_truncated_nbinom2_log_density <- function(x, mu, sigma) {
  log_p0 <- stats::dnbinom(
    0,
    size = 1 / sigma^2,
    mu = mu,
    log = TRUE
  )
  stats::dnbinom(
    x,
    size = 1 / sigma^2,
    mu = mu,
    log = TRUE
  ) -
    log1p(-exp(log_p0))
}

manual_truncated_nbinom2_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$abundance$observed
  observed_y <- fit$missing_data$observed_y
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_abundance")
  sigma <- exp(unname(coef(fit, "sigma")))
  sigma_mi <- unname(coef(fit, "sigma_mi_abundance"))
  mu_observed <- as.vector(fit$model$X$mu %*% beta_mu)
  mu_mi <- exp(as.vector(model$X %*% beta_mi))
  nodes <- model$quad_nodes
  x <- dat$abundance
  out <- numeric(nrow(dat))

  observed_rows <- which(observed_x)
  for (row in observed_rows) {
    out[[row]] <- manual_truncated_nbinom2_log_density(
      x[[row]],
      mu = mu_mi[[row]],
      sigma = sigma_mi
    )
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
    log_terms <- manual_truncated_nbinom2_log_density(
      nodes,
      mu = mu_mi[[row]],
      sigma = sigma_mi
    )
    mu_node <- mu_observed[[row]] + beta_abundance * (nodes - x_base[[row]])
    log_terms <- log_terms +
      stats::dnorm(dat$y[[row]], mu_node, sigma, log = TRUE)
    max_log <- max(log_terms)
    out[[row]] <- max_log + log(sum(exp(log_terms - max_log)))
  }
  sum(out)
}

test_that("truncated_nbinom2 mi() predictor uses positive-count likelihood", {
  dat <- missing_predictor_truncated_nbinom2_data()
  missing_x <- is.na(dat$abundance)

  fit <- fit_missing_predictor_truncated_nbinom2(dat)
  imp <- imputed(fit)
  probs <- fit$missing_data$predictors$abundance$conditional_probabilities

  expect_equal(fit$missing_data$version, "MD7e")
  expect_equal(
    fit$missing_data$predictors$abundance$family,
    "truncated_nbinom2"
  )
  expect_equal(
    fit$missing_data$predictors$abundance$model_row,
    which(missing_x)
  )
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_abundance"))))
  expect_true(all(coef(fit, "sigma_mi_abundance") > 0))
  expect_true(all(fit$model$missing_predictor$quad_nodes > 0))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_truncated_nbinom2_mi_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(imp$source, rep("conditional_expected_count", sum(missing_x)))
  expect_true(all(imp$estimate >= 1))
  expect_true(all(is.na(imp$std_error)))
  expect_equal(unname(rowSums(probs)), rep(1, sum(missing_x)), tolerance = 1e-8)
})

test_that("truncated_nbinom2 mi() predictor combines with response masks", {
  dat <- missing_predictor_truncated_nbinom2_data()
  dat$y[c(12, 34, 57)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(abundance), sigma ~ 1),
    data = dat,
    impute = list(
      abundance = impute_model(abundance ~ z, family = truncated_nbinom2())
    ),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD7e")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_truncated_nbinom2_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("truncated_nbinom2 mi() validates positive-count boundaries", {
  dat <- missing_predictor_truncated_nbinom2_data()
  dat$site <- factor(rep(letters[1:6], length.out = nrow(dat)))

  dat_zero <- dat
  dat_zero$abundance[[1L]] <- 0
  expect_error(
    drmTMB(
      bf(y ~ z + mi(abundance), sigma ~ 1),
      data = dat_zero,
      impute = list(
        abundance = impute_model(abundance ~ z, family = truncated_nbinom2())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "positive integer counts"
  )

  dat_fractional <- dat
  dat_fractional$abundance[[1L]] <- 1.5
  expect_error(
    drmTMB(
      bf(y ~ z + mi(abundance), sigma ~ 1),
      data = dat_fractional,
      impute = list(
        abundance = impute_model(abundance ~ z, family = truncated_nbinom2())
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
        abundance = impute_model(
          abundance ~ z + (1 | site),
          family = truncated_nbinom2()
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed effects only"
  )
})
