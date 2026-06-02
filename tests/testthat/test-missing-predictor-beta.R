missing_predictor_beta_data <- function() {
  n <- 72
  z <- seq(-1.8, 1.8, length.out = n)
  cover_full <- stats::plogis(
    -0.25 + 0.9 * z + 0.18 * sin(seq_len(n) / 5)
  )
  y <- 0.35 + 1.25 * cover_full - 0.30 * z + 0.04 * cos(seq_len(n) / 4)
  dat <- data.frame(y = y, z = z, cover = cover_full)
  dat$cover[c(8, 19, 34, 51, 67)] <- NA_real_
  dat
}

fit_missing_predictor_beta <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(cover), sigma ~ 1),
    data = dat,
    impute = list(
      cover = impute_model(cover ~ z, family = beta())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_beta_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$cover$observed
  observed_y <- fit$missing_data$observed_y
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_cover")
  sigma_mi <- unname(coef(fit, "sigma_mi_cover"))
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
    out[[row]] <- stats::dbeta(
      x[[row]],
      shape1 = mu_mi[[row]] / sigma_mi^2,
      shape2 = (1 - mu_mi[[row]]) / sigma_mi^2,
      log = TRUE
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
      stats::dbeta(
        nodes,
        shape1 = mu_mi[[row]] / sigma_mi^2,
        shape2 = (1 - mu_mi[[row]]) / sigma_mi^2,
        log = TRUE
      )
    mu_node <- mu_observed[[row]] + beta_cover * (nodes - x_base[[row]])
    log_terms <- log_terms +
      stats::dnorm(dat$y[[row]], mu_node, sigma, log = TRUE)
    max_log <- max(log_terms)
    out[[row]] <- max_log + log(sum(exp(log_terms - max_log)))
  }
  sum(out)
}

test_that("beta mi() predictor model uses quadrature likelihood", {
  dat <- missing_predictor_beta_data()
  missing_x <- is.na(dat$cover)

  fit <- fit_missing_predictor_beta(dat)
  imp <- imputed(fit)
  probs <- fit$missing_data$predictors$cover$quadrature_probabilities

  expect_equal(fit$missing_data$version, "MD7a")
  expect_equal(fit$missing_data$predictors$cover$family, "beta")
  expect_equal(fit$missing_data$predictors$cover$model_row, which(missing_x))
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_cover"))))
  expect_true(all(is.finite(coef(fit, "sigma_mi_cover"))))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_beta_mi_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(imp$source, rep("conditional_quadrature_mean", sum(missing_x)))
  expect_true(all(imp$estimate > 0 & imp$estimate < 1))
  expect_true(all(is.na(imp$std_error)))
  expect_equal(unname(rowSums(probs)), rep(1, sum(missing_x)), tolerance = 1e-8)
})

test_that("beta mi() predictor model combines with response masks", {
  dat <- missing_predictor_beta_data()
  dat$y[c(10, 34, 58)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(cover), sigma ~ 1),
    data = dat,
    impute = list(
      cover = impute_model(cover ~ z, family = beta())
    ),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD7a")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_beta_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("beta mi() validates first proportion predictor boundary", {
  dat <- missing_predictor_beta_data()
  dat$site <- factor(rep(letters[1:6], length.out = nrow(dat)))

  dat_boundary <- dat
  dat_boundary$cover[[1L]] <- 0
  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat_boundary,
      impute = list(
        cover = impute_model(cover ~ z, family = beta())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "strictly between 0 and 1"
  )

  dat_factor <- dat
  dat_factor$cover <- factor(ifelse(dat$cover > 0.5, "high", "low"))
  dat_factor$cover[c(8, 19, 34, 51, 67)] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat_factor,
      impute = list(
        cover = impute_model(cover ~ z, family = beta())
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
        cover = impute_model(cover ~ z + (1 | site), family = beta())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed effects only"
  )
})
