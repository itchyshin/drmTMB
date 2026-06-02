missing_predictor_zero_one_beta_data <- function() {
  n <- 96
  z <- seq(-2, 2, length.out = n)
  cover_full <- stats::plogis(-0.20 + 0.85 * z + 0.12 * sin(seq_len(n) / 4))
  zero_rows <- seq(6, n, by = 18)
  one_rows <- seq(13, n, by = 19)
  cover_full[zero_rows] <- 0
  cover_full[one_rows] <- 1
  y <- 0.25 + 1.15 * cover_full - 0.28 * z + 0.05 * cos(seq_len(n) / 5)
  dat <- data.frame(y = y, z = z, cover = cover_full)
  dat$cover[c(8, 21, 39, 58, 77, 91)] <- NA_real_
  dat
}

fit_missing_predictor_zero_one_beta <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(cover), sigma ~ 1),
    data = dat,
    impute = list(
      cover = impute_model(cover ~ z, family = zero_one_beta())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_zero_one_beta_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$cover$observed
  observed_y <- fit$missing_data$observed_y
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_cover")
  sigma_mi <- unname(coef(fit, "sigma_mi_cover"))
  zoi_mi <- unname(coef(fit, "zoi_mi_cover"))
  coi_mi <- unname(coef(fit, "coi_mi_cover"))
  sigma <- exp(unname(coef(fit, "sigma")))
  mu_observed <- as.vector(fit$model$X$mu %*% beta_mu)
  eta_mi <- as.vector(model$X %*% beta_mi)
  mu_mi <- drmTMB:::drm_beta_missing_predictor_inverse_link(eta_mi)
  nodes <- model$quad_nodes
  weights <- model$quad_weights
  x <- dat$cover
  out <- numeric(nrow(dat))

  observed_rows <- which(observed_x)
  for (row in observed_rows) {
    out[[row]] <- drmTMB:::drm_zero_one_beta_missing_predictor_log_density(
      x[[row]],
      mu = mu_mi[[row]],
      sigma = sigma_mi,
      zoi = zoi_mi,
      coi = coi_mi
    )
    if (observed_y[[row]]) {
      out[[row]] <- out[[row]] +
        stats::dnorm(dat$y[[row]], mu_observed[[row]], sigma, log = TRUE)
    }
  }

  missing_rows <- which(!observed_x)
  beta_cover <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  for (row in missing_rows) {
    if (!observed_y[[row]]) {
      next
    }
    log_terms <- log(weights) +
      drmTMB:::drm_zero_one_beta_missing_predictor_log_density(
        nodes,
        mu = mu_mi[[row]],
        sigma = sigma_mi,
        zoi = zoi_mi,
        coi = coi_mi
      )
    mu_node <- mu_observed[[row]] + beta_cover * (nodes - x_base[[row]])
    log_terms <- log_terms +
      stats::dnorm(dat$y[[row]], mu_node, sigma, log = TRUE)
    max_log <- max(log_terms)
    out[[row]] <- max_log + log(sum(exp(log_terms - max_log)))
  }
  sum(out)
}

test_that("zero-one beta mi() predictor model uses boundary mixture likelihood", {
  dat <- missing_predictor_zero_one_beta_data()
  missing_x <- is.na(dat$cover)

  fit <- fit_missing_predictor_zero_one_beta(dat)
  imp <- imputed(fit)
  probs <- fit$missing_data$predictors$cover$quadrature_probabilities

  expect_equal(fit$missing_data$version, "MD7d")
  expect_equal(fit$missing_data$predictors$cover$family, "zero_one_beta")
  expect_equal(fit$missing_data$predictors$cover$model_row, which(missing_x))
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_cover"))))
  expect_true(all(is.finite(coef(fit, "sigma_mi_cover"))))
  expect_true(all(coef(fit, "zoi_mi_cover") > 0))
  expect_true(all(coef(fit, "zoi_mi_cover") < 1))
  expect_true(all(coef(fit, "coi_mi_cover") > 0))
  expect_true(all(coef(fit, "coi_mi_cover") < 1))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_zero_one_beta_mi_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(imp$source, rep("conditional_quadrature_mean", sum(missing_x)))
  expect_true(all(imp$estimate >= 0 & imp$estimate <= 1))
  expect_true(all(is.na(imp$std_error)))
  expect_equal(unname(rowSums(probs)), rep(1, sum(missing_x)), tolerance = 1e-8)
})

test_that("zero-one beta mi() predictor model combines with response masks", {
  dat <- missing_predictor_zero_one_beta_data()
  dat$y[c(8, 39, 64)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(cover), sigma ~ 1),
    data = dat,
    impute = list(
      cover = impute_model(cover ~ z, family = zero_one_beta())
    ),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD7d")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_zero_one_beta_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("zero-one beta mi() validates boundary proportion predictors", {
  dat <- missing_predictor_zero_one_beta_data()
  dat$site <- factor(rep(letters[1:6], length.out = nrow(dat)))

  dat_out <- dat
  dat_out$cover[[1L]] <- 1.2
  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat_out,
      impute = list(
        cover = impute_model(cover ~ z, family = zero_one_beta())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "in \\[0, 1\\]"
  )

  dat_boundary <- dat
  dat_boundary$cover[!is.na(dat_boundary$cover)] <- rep(
    c(0, 1),
    length.out = sum(!is.na(dat_boundary$cover))
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat_boundary,
      impute = list(
        cover = impute_model(cover ~ z, family = zero_one_beta())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "at least one observed interior value"
  )

  dat_factor <- dat
  dat_factor$cover <- factor(ifelse(dat$cover > 0.5, "high", "low"))
  dat_factor$cover[c(8, 21, 39, 58, 77, 91)] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat_factor,
      impute = list(
        cover = impute_model(cover ~ z, family = zero_one_beta())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "numeric predictor"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat,
      impute = list(
        cover = impute_model(cover ~ z + (1 | site), family = zero_one_beta())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed effects only"
  )
})
