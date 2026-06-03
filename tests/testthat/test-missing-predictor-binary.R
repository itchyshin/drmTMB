missing_predictor_binary_data <- function() {
  z <- seq(-1.6, 1.6, length.out = 50)
  treatment_full <- as.numeric(sin(seq_along(z) * 1.7) + 0.35 * z > 0)
  y <- 0.45 + 0.55 * z + 1.25 * treatment_full + 0.08 * sin(seq_along(z))
  dat <- data.frame(
    y = y,
    z = z,
    treatment = factor(treatment_full, levels = c(0, 1))
  )
  dat$treatment[c(6, 15, 28, 43)] <- NA
  dat
}

fit_missing_predictor_binary <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(treatment), sigma ~ 1),
    data = dat,
    impute = list(
      treatment = impute_model(treatment ~ z, family = binomial())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_binary_mi_loglik <- function(fit) {
  dat <- fit$model$data
  observed_x <- fit$missing_data$predictors$treatment$observed
  observed_y <- fit$missing_data$observed_y
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_treatment")
  sigma <- exp(unname(coef(fit, "sigma")))
  z <- dat$z
  x <- as.numeric(dat$treatment) - 1
  eta_x <- unname(beta_mi[["(Intercept)"]] + beta_mi[["z"]] * z)
  log_p1 <- stats::plogis(eta_x, log.p = TRUE)
  log_p0 <- stats::plogis(eta_x, lower.tail = FALSE, log.p = TRUE)
  beta_x <- unname(beta_mu[["mi(treatment)"]])
  mu0 <- unname(beta_mu[["(Intercept)"]] + beta_mu[["z"]] * z)
  mu1 <- mu0 + beta_x
  out <- numeric(nrow(dat))

  x1 <- observed_x & x == 1
  x0 <- observed_x & x == 0
  out[x1] <- log_p1[x1]
  out[x0] <- log_p0[x0]
  out[x1 & observed_y] <- out[x1 & observed_y] +
    stats::dnorm(
      dat$y[x1 & observed_y],
      mu1[x1 & observed_y],
      sigma,
      log = TRUE
    )
  out[x0 & observed_y] <- out[x0 & observed_y] +
    stats::dnorm(
      dat$y[x0 & observed_y],
      mu0[x0 & observed_y],
      sigma,
      log = TRUE
    )

  missing_x <- !observed_x
  if (any(missing_x & observed_y)) {
    rows <- which(missing_x & observed_y)
    lp1 <- log_p1[rows] +
      stats::dnorm(dat$y[rows], mu1[rows], sigma, log = TRUE)
    lp0 <- log_p0[rows] +
      stats::dnorm(dat$y[rows], mu0[rows], sigma, log = TRUE)
    out[rows] <- log(exp(lp1 - pmax(lp1, lp0)) + exp(lp0 - pmax(lp1, lp0))) +
      pmax(lp1, lp0)
  }
  sum(out)
}

test_that("binary mi() predictor model uses exact two-state likelihood", {
  dat <- missing_predictor_binary_data()
  missing_x <- is.na(dat$treatment)

  fit <- fit_missing_predictor_binary(dat)
  imp <- imputed(fit)

  expect_equal(fit$missing_data$version, "MD6a")
  expect_equal(fit$missing_data$predictors$treatment$family, "bernoulli")
  expect_equal(
    fit$missing_data$predictors$treatment$model_row,
    which(missing_x)
  )
  expect_equal(
    fit$missing_data$predictors$treatment$levels,
    c("0", "1")
  )
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_treatment"))))
  expect_false("sigma_mi_treatment" %in% names(fit$coefficients))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_binary_mi_loglik(fit),
    tolerance = 1e-6
  )
  expect_equal(imp$source, rep("conditional_probability", sum(missing_x)))
  expect_true(all(is.finite(imp$estimate)))
  expect_true(all(imp$estimate >= 0 & imp$estimate <= 1))
  expect_true(all(is.na(imp$std_error)))
})

test_that("binary mi() predictor model combines with response masks", {
  dat <- missing_predictor_binary_data()
  dat$y[c(4, 17)] <- NA_real_
  observed_y <- !is.na(dat$y)

  fit <- drmTMB(
    bf(y ~ z + mi(treatment), sigma ~ 1),
    data = dat,
    impute = list(
      treatment = impute_model(treatment ~ z, family = binomial())
    ),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$missing_data$version, "MD6a")
  expect_equal(nobs(fit), sum(observed_y))
  expect_equal(fit$missing_data$observed_y, observed_y)
  expect_true(all(is.na(residuals(fit)[!observed_y])))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_binary_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("binary mi() validates first discrete predictor boundary", {
  dat <- missing_predictor_binary_data()
  dat$site <- factor(rep(letters[1:5], length.out = nrow(dat)))

  expect_error(
    impute_model(treatment ~ z, family = student()),
    "Unsupported missing-predictor family"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(treatment), sigma ~ 1),
      data = dat,
      impute = list(
        treatment = impute_model(
          treatment ~ z + (1 | site),
          family = binomial()
        )
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "fixed effects only"
  )

  dat3 <- dat
  dat3$treatment <- factor(
    ifelse(as.character(dat$treatment) == "1", "b", "a"),
    levels = c("a", "b", "c")
  )
  dat3$treatment[seq(1, nrow(dat3), by = 7)] <- "c"
  dat3$treatment[c(6, 15, 28, 43)] <- NA
  expect_error(
    drmTMB(
      bf(y ~ z + mi(treatment), sigma ~ 1),
      data = dat3,
      impute = list(
        treatment = impute_model(treatment ~ z, family = binomial())
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "exactly two"
  )
})
