missing_predictor_beta_binomial_data <- function() {
  n <- 86
  z <- seq(-1.8, 1.8, length.out = n)
  trials <- rep(8:16, length.out = n)
  p <- stats::plogis(-0.25 + 0.85 * z + 0.10 * sin(seq_len(n) / 5))
  success_full <- stats::qbinom(ppoints(n), size = trials, prob = p)
  cover_full <- success_full / trials
  y <- 0.30 + 1.15 * cover_full - 0.24 * z + 0.05 * cos(seq_len(n) / 6)
  dat <- data.frame(
    y = y,
    z = z,
    cover = cover_full,
    success = success_full,
    trials = trials
  )
  dat$cover[c(8, 20, 36, 55, 73)] <- NA_real_
  dat$success[c(8, 20, 36, 55, 73)] <- NA_real_
  dat
}

fit_missing_predictor_beta_binomial <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(cover), sigma ~ 1),
    data = dat,
    impute = list(
      cover = impute_model(
        success ~ z,
        family = beta_binomial(),
        trials = trials
      )
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_beta_binomial_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$cover$observed
  observed_y <- fit$missing_data$observed_y
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_cover")
  sigma_mi <- unname(coef(fit, "sigma_mi_cover"))
  sigma <- exp(unname(coef(fit, "sigma")))
  mu_observed <- as.vector(fit$model$X$mu %*% beta_mu)
  mu_mi <- stats::plogis(as.vector(model$X %*% beta_mi))
  out <- numeric(nrow(dat))

  observed_rows <- which(observed_x)
  for (row in observed_rows) {
    out[[row]] <- drmTMB:::drm_beta_binomial_missing_predictor_log_density(
      success = dat$success[[row]],
      trials = dat$trials[[row]],
      mu = mu_mi[[row]],
      sigma = sigma_mi
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
    support <- seq.int(0L, dat$trials[[row]])
    cover_support <- support / dat$trials[[row]]
    log_terms <- drmTMB:::drm_beta_binomial_missing_predictor_log_density(
      success = support,
      trials = dat$trials[[row]],
      mu = mu_mi[[row]],
      sigma = sigma_mi
    )
    mu_node <- mu_observed[[row]] +
      beta_cover * (cover_support - x_base[[row]])
    log_terms <- log_terms +
      stats::dnorm(dat$y[[row]], mu_node, sigma, log = TRUE)
    max_log <- max(log_terms)
    out[[row]] <- max_log + log(sum(exp(log_terms - max_log)))
  }
  sum(out)
}

test_that("beta-binomial mi() predictor model uses success/trial likelihood", {
  dat <- missing_predictor_beta_binomial_data()
  missing_x <- is.na(dat$success)

  fit <- fit_missing_predictor_beta_binomial(dat)
  imp <- imputed(fit)
  probs <- fit$missing_data$predictors$cover$conditional_probabilities

  expect_equal(fit$missing_data$version, "MD7f")
  expect_equal(fit$missing_data$predictors$cover$family, "beta_binomial")
  expect_equal(fit$missing_data$predictors$cover$model_row, which(missing_x))
  expect_equal(fit$missing_data$predictors$cover$success_variable, "success")
  expect_equal(fit$missing_data$predictors$cover$trials_variable, "trials")
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_cover"))))
  expect_true(all(coef(fit, "sigma_mi_cover") > 0))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_beta_binomial_mi_loglik(fit),
    tolerance = 5e-4
  )
  expect_equal(imp$source, rep("conditional_proportion_mean", sum(missing_x)))
  expect_true(all(imp$estimate >= 0 & imp$estimate <= 1))
  expect_true(all(is.na(imp$std_error)))
  expect_equal(
    unname(rowSums(probs, na.rm = TRUE)),
    rep(1, sum(missing_x)),
    tolerance = 1e-8
  )
})

test_that("beta-binomial mi() predictor model combines with response masks", {
  dat <- missing_predictor_beta_binomial_data()
  dat$y[c(11, 36, 64)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(cover), sigma ~ 1),
    data = dat,
    impute = list(
      cover = impute_model(
        success ~ z,
        family = beta_binomial(),
        trials = trials
      )
    ),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD7f")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_beta_binomial_mi_loglik(fit),
    tolerance = 5e-4
  )
})

test_that("beta-binomial mi() validates denominator-aware predictor input", {
  dat <- missing_predictor_beta_binomial_data()
  dat$site <- factor(rep(letters[1:6], length.out = nrow(dat)))

  expect_error(
    impute_model(success ~ z, family = beta_binomial()),
    "require a .*trials"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat,
      impute = list(
        cover = impute_model(
          success ~ z,
          family = beta_binomial(),
          trials = trials + 1
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "one trial-count column"
  )

  dat_bad_count <- dat
  dat_bad_count$success[[1L]] <- dat_bad_count$trials[[1L]] + 1
  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat_bad_count,
      impute = list(
        cover = impute_model(
          success ~ z,
          family = beta_binomial(),
          trials = trials
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "between 0 and the trial count"
  )

  dat_fractional <- dat
  dat_fractional$success[[1L]] <- 1.5
  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat_fractional,
      impute = list(
        cover = impute_model(
          success ~ z,
          family = beta_binomial(),
          trials = trials
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "between 0 and the trial count"
  )

  dat_missing_trials <- dat
  dat_missing_trials$trials[[1L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat_missing_trials,
      impute = list(
        cover = impute_model(
          success ~ z,
          family = beta_binomial(),
          trials = trials
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "Keep ordinary predictors complete"
  )

  dat_mismatch <- dat
  dat_mismatch$cover[[1L]] <- dat_mismatch$cover[[1L]] + 0.05
  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat_mismatch,
      impute = list(
        cover = impute_model(
          success ~ z,
          family = beta_binomial(),
          trials = trials
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "must match success divided by trials"
  )

  dat_unpaired <- dat
  dat_unpaired$success[[1L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat_unpaired,
      impute = list(
        cover = impute_model(
          success ~ z,
          family = beta_binomial(),
          trials = trials
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "without matching beta-binomial success counts"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(cover), sigma ~ 1),
      data = dat,
      impute = list(
        cover = impute_model(
          success ~ z + (1 | site),
          family = beta_binomial(),
          trials = trials
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed effects only"
  )
})
