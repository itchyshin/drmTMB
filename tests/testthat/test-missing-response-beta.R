# P1 slice: missing-RESPONSE masking for a beta (0,1) proportion response
# (model_type 10).
#
# Beta has a fitted dispersion phi = exp(-2*log_sigma). The masked-row placeholder
# is 0, which is OUTSIDE the beta support (0,1): a broken guard would evaluate
# log(0) = -Inf on the placeholder and produce a non-finite objective, so the
# include==complete-case and finite-objective checks are real guard tests here.

missing_response_beta_data <- function(seed = 808, n = 400, miss_frac = 0.2,
                                       b0 = 0.3, b1 = 0.8, phi = 8) {
  set.seed(seed)
  x <- rnorm(n)
  mu <- plogis(b0 + b1 * x)
  y <- rbeta(n, mu * phi, (1 - mu) * phi)
  miss <- sample(n, size = round(miss_frac * n))
  masked <- data.frame(y = y, x = x)
  masked$y[miss] <- NA_real_
  list(
    masked = masked,
    observed = !(seq_len(n) %in% miss),
    truth_mu = c(b0, b1),
    truth_log_sigma = -0.5 * log(phi)
  )
}

test_that("beta response mask is inert: include == complete-case (and stays finite)", {
  dd <- missing_response_beta_data()
  observed <- dd$observed

  fit_mask <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = beta(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  fit_cc <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = beta(),
    data = dd$masked[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )

  # a broken guard would evaluate log(0) on the placeholder -> non-finite
  expect_true(is.finite(as.numeric(logLik(fit_mask))))
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

test_that("beta masked-row placeholder (0, outside (0,1)) stays out of the likelihood", {
  dd <- missing_response_beta_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = beta(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  # a placeholder leak would blow the gradient up (log(0)); confirm it is finite
  expect_true(all(is.finite(fit$obj$gr(fit$opt$par))))
  expect_equal(fit$missing_data$response_sentinel, 0)
  expect_missing_response_sentinel_invariant(fit, sentinels = c(0.2, 0.8))
})

test_that("beta MCAR-masked responses recover the mean AND the dispersion (phi != 1)", {
  dd <- missing_response_beta_data(
    seed = 909, n = 2500, miss_frac = 0.25, phi = 8
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = beta(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  expect_equal(unname(coef(fit, "mu")), dd$truth_mu, tolerance = 0.12)
  # dispersion recovery: log_sigma -> -0.5*log(phi)
  expect_equal(
    unname(coef(fit, "sigma")),
    dd$truth_log_sigma,
    tolerance = 0.2
  )
})

test_that("response = 'include' masks missing beta responses but drops missing-predictor rows", {
  dd <- missing_response_beta_data()
  n_total <- nrow(dd$masked)
  n_missing <- sum(!dd$observed)
  dd$masked$x[which(dd$observed)[1]] <- NA_real_

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = beta(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  expect_equal(length(fit$missing_data$observed_y), n_total - 1L)
  expect_equal(sum(!fit$missing_data$observed_y), n_missing)
  expect_equal(nobs(fit), sum(dd$observed) - 1L)
})
