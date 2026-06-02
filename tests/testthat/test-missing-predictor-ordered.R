missing_predictor_ordered_data <- function() {
  n <- 60
  z <- seq(-1.8, 1.8, length.out = n)
  latent <- 0.7 * z + 0.55 * sin(seq_len(n) / 3)
  score_full <- cut(
    latent,
    breaks = c(-Inf, -0.55, 0.55, Inf),
    labels = c("low", "medium", "high"),
    ordered_result = TRUE
  )
  score_effect <- c(low = -0.45, medium = 0.15, high = 0.65)
  y <- 0.25 +
    0.45 * z +
    unname(score_effect[as.character(score_full)]) +
    0.05 * cos(seq_len(n))
  dat <- data.frame(
    y = y,
    z = z,
    score = score_full
  )
  dat$score[c(5, 14, 27, 41, 53)] <- NA
  dat
}

fit_missing_predictor_ordered <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(score), sigma ~ 1),
    data = dat,
    impute = list(
      score = impute_model(score ~ z, family = cumulative_logit())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_ordered_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$score$observed
  observed_y <- fit$missing_data$observed_y
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_score")
  sigma <- exp(unname(coef(fit, "sigma")))
  cutpoints <- fit$missing_data$predictors$score$cutpoints
  eta_x <- as.vector(model$X %*% beta_mi)
  probability <- drmTMB:::drm_ordinal_probability_matrix(eta_x, cutpoints)
  n_state <- length(model$levels)
  state_mu <- matrix(
    as.vector(model$X_mu_state %*% beta_mu),
    nrow = nrow(dat),
    ncol = n_state,
    byrow = TRUE
  )
  mu_observed <- as.vector(fit$model$X$mu %*% beta_mu)
  x <- as.integer(dat$score)
  out <- numeric(nrow(dat))

  observed_rows <- which(observed_x)
  for (row in observed_rows) {
    state <- x[[row]]
    out[[row]] <- log(probability[row, state])
    if (observed_y[[row]]) {
      out[[row]] <- out[[row]] +
        stats::dnorm(dat$y[[row]], mu_observed[[row]], sigma, log = TRUE)
    }
  }

  missing_rows <- which(!observed_x)
  for (row in missing_rows) {
    log_terms <- log(probability[row, ])
    if (observed_y[[row]]) {
      log_terms <- log_terms +
        stats::dnorm(dat$y[[row]], state_mu[row, ], sigma, log = TRUE)
    }
    max_log <- max(log_terms)
    out[[row]] <- max_log + log(sum(exp(log_terms - max_log)))
  }
  sum(out)
}

test_that("ordered mi() predictor model uses exact finite-state likelihood", {
  dat <- missing_predictor_ordered_data()
  missing_x <- is.na(dat$score)

  fit <- fit_missing_predictor_ordered(dat)
  imp <- imputed(fit)
  probs <- fit$missing_data$predictors$score$conditional_probabilities

  expect_equal(fit$missing_data$version, "MD6b")
  expect_equal(fit$missing_data$predictors$score$family, "ordinal")
  expect_equal(fit$missing_data$predictors$score$levels, levels(dat$score))
  expect_equal(fit$missing_data$predictors$score$n_state, 3L)
  expect_equal(
    fit$missing_data$predictors$score$model_row,
    which(missing_x)
  )
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_score"))))
  expect_false("sigma_mi_score" %in% names(fit$coefficients))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_ordered_mi_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(imp$source, rep("conditional_expected_score", sum(missing_x)))
  expect_true(all(is.finite(imp$estimate)))
  expect_true(all(imp$estimate >= 1 & imp$estimate <= 3))
  expect_true(all(is.na(imp$std_error)))
  expect_equal(rowSums(probs), rep(1, sum(missing_x)), tolerance = 1e-8)
})

test_that("ordered mi() predictor model combines with response masks", {
  dat <- missing_predictor_ordered_data()
  dat$y[c(9, 27, 44)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(score), sigma ~ 1),
    data = dat,
    impute = list(
      score = impute_model(score ~ z, family = cumulative_logit())
    ),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD6b")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_ordered_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("ordered mi() validates first ordinal predictor boundary", {
  dat <- missing_predictor_ordered_data()
  dat$site <- factor(rep(letters[1:6], length.out = nrow(dat)))

  dat_unordered <- dat
  dat_unordered$score <- factor(dat_unordered$score, ordered = FALSE)
  expect_error(
    drmTMB(
      bf(y ~ z + mi(score), sigma ~ 1),
      data = dat_unordered,
      impute = list(
        score = impute_model(score ~ z, family = cumulative_logit())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "ordered predictor"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(score), sigma ~ 1),
      data = dat,
      impute = list(
        score = impute_model(
          score ~ z + (1 | site),
          family = cumulative_logit()
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed effects only"
  )

  dat_sparse <- dat
  dat_sparse$score <- ordered(
    ifelse(as.character(dat$score) == "medium", "low", as.character(dat$score)),
    levels = levels(dat$score)
  )
  dat_sparse$score[c(5, 14, 27, 41, 53)] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(score), sigma ~ 1),
      data = dat_sparse,
      impute = list(
        score = impute_model(score ~ z, family = cumulative_logit())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "Every ordered predictor category"
  )
})
