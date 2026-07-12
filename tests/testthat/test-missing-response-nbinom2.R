# P1 slice: missing-RESPONSE masking for a negative-binomial (NB2) count response
# (model_type 7).
#
# The LIVE TRAP family: the engine stores alpha = exp(+2*log_sigma), so the
# externally meaningful NB2 size = exp(-2*log_sigma) = sigma^-2 and the recovery
# truth for a dispersion `theta` is log_sigma = -0.5*log(theta). The recovery cell
# uses theta != 1 (mandatory per the P0 gate: theta = 1 hides a dispersion-sign
# inversion).

missing_response_nbinom2_data <- function(seed = 606, n = 400, miss_frac = 0.2,
                                          b0 = 0.6, b1 = 0.7, theta = 3) {
  set.seed(seed)
  x <- rnorm(n)
  y <- rnbinom(n, size = theta, mu = exp(b0 + b1 * x))
  miss <- sample(n, size = round(miss_frac * n))
  masked <- data.frame(y = y, x = x)
  masked$y[miss] <- NA_integer_
  list(
    masked = masked,
    observed = !(seq_len(n) %in% miss),
    truth_mu = c(b0, b1),
    truth_log_sigma = -0.5 * log(theta)
  )
}

test_that("nbinom2 response mask is inert: include == complete-case", {
  dd <- missing_response_nbinom2_data()
  observed <- dd$observed

  fit_mask <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = nbinom2(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  fit_cc <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = nbinom2(),
    data = dd$masked[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )

  expect_equal(coef(fit_mask, "mu"), coef(fit_cc, "mu"), tolerance = 1e-7)
  expect_equal(coef(fit_mask, "sigma"), coef(fit_cc, "sigma"), tolerance = 1e-7)
  expect_equal(
    as.numeric(logLik(fit_mask)),
    as.numeric(logLik(fit_cc)),
    tolerance = 1e-7
  )
  expect_equal(nobs(fit_mask), sum(observed))
  expect_equal(fit_mask$missing_data$observed_y, observed)
  expect_equal(fit_mask$missing_data$response_policy, "include")
  expect_equal(fit_mask$missing_data$original_row, seq_len(nrow(dd$masked)))
  expect_equal(fit_mask$missing_data$model_row, seq_len(nrow(dd$masked)))
  expect_length(fitted(fit_mask), nrow(dd$masked))
  expect_equal(
    fitted(fit_mask)[observed],
    fitted(fit_cc),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
  expect_true(all(is.na(residuals(fit_mask)[!observed])))
  expect_true(all(is.na(residuals(fit_mask, type = "pearson")[!observed])))
})

test_that("nbinom2 masked-row placeholder cannot leak into likelihood or gradients", {
  dd <- missing_response_nbinom2_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = nbinom2(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  expect_missing_response_sentinel_invariant(fit, sentinels = c(0, 7))
})

test_that("nbinom2 MCAR-masked responses recover the mean AND the dispersion (theta != 1)", {
  dd <- missing_response_nbinom2_data(
    seed = 707, n = 3000, miss_frac = 0.25, theta = 3
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = nbinom2(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  expect_equal(unname(coef(fit, "mu")), dd$truth_mu, tolerance = 0.1)
  # dispersion recovery: log_sigma -> -0.5*log(theta) (the reciprocal-size trap;
  # a +0.5*log(theta) engine would fail this loudly at theta != 1)
  expect_equal(
    unname(coef(fit, "sigma")),
    dd$truth_log_sigma,
    tolerance = 0.15
  )
})

test_that("response = 'include' masks missing responses but drops missing-predictor rows", {
  # Scope check for the keep-logic: response = "include" excludes the RESPONSE
  # from the complete-case rule (so missing-response rows are kept and masked),
  # but predictors are still required, so a missing-PREDICTOR row is dropped.
  dd <- missing_response_nbinom2_data()
  n_total <- nrow(dd$masked)
  n_missing_response <- sum(!dd$observed)
  dd$masked$x[which(dd$observed)[1]] <- NA_real_ # one missing predictor

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = nbinom2(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )

  expect_equal(length(fit$missing_data$observed_y), n_total - 1L)
  expect_equal(sum(!fit$missing_data$observed_y), n_missing_response)
  expect_equal(nobs(fit), sum(dd$observed) - 1L)
})

test_that("nbinom2 response mask rejects zero-inflation", {
  dd <- missing_response_nbinom2_data()
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zi ~ 1),
      family = nbinom2(),
      data = dd$masked,
      missing = miss_control(response = "include"),
      control = drm_control(se = FALSE)
    ),
    "zero-inflat"
  )
})
