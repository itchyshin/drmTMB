missing_predictor_categorical_data <- function() {
  n <- 66
  z <- seq(-1.7, 1.7, length.out = n)
  score <- sin(seq_len(n) / 4) + 0.45 * z
  habitat_full <- factor(
    ifelse(score < -0.35, "forest", ifelse(score < 0.55, "grass", "wetland")),
    levels = c("forest", "grass", "wetland")
  )
  habitat_effect <- c(forest = -0.35, grass = 0.2, wetland = 0.75)
  y <- 0.15 +
    0.5 * z +
    unname(habitat_effect[as.character(habitat_full)]) +
    0.04 * cos(seq_len(n))
  dat <- data.frame(
    y = y,
    z = z,
    habitat = habitat_full
  )
  dat$habitat[c(7, 16, 31, 48, 60)] <- NA
  dat
}

fit_missing_predictor_categorical <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(habitat), sigma ~ 1),
    data = dat,
    impute = list(
      habitat = impute_model(habitat ~ z, family = categorical())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_categorical_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$habitat$observed
  observed_y <- fit$missing_data$observed_y
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_habitat")
  sigma <- exp(unname(coef(fit, "sigma")))
  probability <- drmTMB:::drm_categorical_probability_matrix(
    model$X,
    beta_mi,
    n_state = length(model$levels)
  )
  n_state <- length(model$levels)
  state_mu <- matrix(
    as.vector(model$X_mu_state %*% beta_mu),
    nrow = nrow(dat),
    ncol = n_state,
    byrow = TRUE
  )
  mu_observed <- as.vector(fit$model$X$mu %*% beta_mu)
  x <- as.integer(dat$habitat)
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

test_that("categorical mi() predictor model uses exact finite-state likelihood", {
  dat <- missing_predictor_categorical_data()
  missing_x <- is.na(dat$habitat)

  fit <- fit_missing_predictor_categorical(dat)
  imp <- imputed(fit)
  probs <- fit$missing_data$predictors$habitat$conditional_probabilities

  expect_equal(fit$missing_data$version, "MD6c")
  expect_equal(fit$missing_data$predictors$habitat$family, "categorical")
  expect_equal(
    fit$missing_data$predictors$habitat$levels,
    levels(dat$habitat)
  )
  expect_equal(fit$missing_data$predictors$habitat$n_state, 3L)
  expect_equal(
    fit$missing_data$predictors$habitat$model_row,
    which(missing_x)
  )
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_habitat"))))
  expect_false("sigma_mi_habitat" %in% names(fit$coefficients))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_categorical_mi_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(imp$source, rep("conditional_modal_category", sum(missing_x)))
  expect_true(all(imp$estimate %in% seq_along(levels(dat$habitat))))
  expect_true(all(is.na(imp$std_error)))
  expect_equal(unname(rowSums(probs)), rep(1, sum(missing_x)), tolerance = 1e-8)
  expect_true(all(
    fit$missing_data$predictors$habitat$conditional_modal_category %in%
      levels(dat$habitat)
  ))
})

test_that("categorical mi() predictor model combines with response masks", {
  dat <- missing_predictor_categorical_data()
  dat$y[c(10, 31, 52)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(habitat), sigma ~ 1),
    data = dat,
    impute = list(
      habitat = impute_model(habitat ~ z, family = categorical())
    ),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD6c")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_categorical_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("categorical mi() validates first unordered predictor boundary", {
  dat <- missing_predictor_categorical_data()
  dat$site <- factor(rep(letters[1:6], length.out = nrow(dat)))

  dat_ordered <- dat
  dat_ordered$habitat <- ordered(dat_ordered$habitat)
  expect_error(
    drmTMB(
      bf(y ~ z + mi(habitat), sigma ~ 1),
      data = dat_ordered,
      impute = list(
        habitat = impute_model(habitat ~ z, family = categorical())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "unordered predictor"
  )

  expect_error(
    drmTMB(
      bf(y ~ z + mi(habitat), sigma ~ 1),
      data = dat,
      impute = list(
        habitat = impute_model(
          habitat ~ z + (1 | site),
          family = categorical()
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed effects only"
  )

  dat_sparse <- dat
  dat_sparse$habitat <- factor(
    ifelse(
      as.character(dat$habitat) == "grass",
      "forest",
      as.character(dat$habitat)
    ),
    levels = levels(dat$habitat)
  )
  dat_sparse$habitat[c(7, 16, 31, 48, 60)] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(habitat), sigma ~ 1),
      data = dat_sparse,
      impute = list(
        habitat = impute_model(habitat ~ z, family = categorical())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "Every unordered predictor category"
  )

  dat_two <- dat
  dat_two$habitat <- factor(
    ifelse(as.character(dat$habitat) == "wetland", "grass", "forest"),
    levels = c("forest", "grass")
  )
  dat_two$habitat[c(7, 16, 31, 48, 60)] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(habitat), sigma ~ 1),
      data = dat_two,
      impute = list(
        habitat = impute_model(habitat ~ z, family = categorical())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "at least three"
  )
})
