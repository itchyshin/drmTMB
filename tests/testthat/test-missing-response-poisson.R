# P1 slice: missing-RESPONSE masking for a Poisson count response (model_type 6).
#
# A correctly masked missing response contributes nothing to the likelihood, so a
# `response = "include"` fit must equal the complete-case fit on the observed rows
# (byte-identical), the masked-row placeholder must be inert, and MCAR-masked data
# must still recover the truth. Poisson uses the log link (mu = exp(eta)), no
# dispersion parameter.

missing_response_poisson_data <- function(seed = 303, n = 400, miss_frac = 0.2,
                                          b0 = 0.5, b1 = 0.8) {
  set.seed(seed)
  x <- rnorm(n)
  y <- rpois(n, exp(b0 + b1 * x))
  miss <- sample(n, size = round(miss_frac * n))
  masked <- data.frame(y = y, x = x)
  masked$y[miss] <- NA_integer_
  list(masked = masked, observed = !(seq_len(n) %in% miss), truth = c(b0, b1))
}

test_that("poisson response mask is inert: include == complete-case", {
  dd <- missing_response_poisson_data()
  observed <- dd$observed

  fit_mask <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  fit_cc <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = dd$masked[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )

  expect_equal(coef(fit_mask, "mu"), coef(fit_cc, "mu"), tolerance = 1e-8)
  expect_equal(
    as.numeric(logLik(fit_mask)),
    as.numeric(logLik(fit_cc)),
    tolerance = 1e-8
  )
  expect_equal(nobs(fit_mask), sum(observed))
  expect_equal(fit_mask$missing_data$observed_y, observed)
  expect_equal(fit_mask$missing_data$original_row, seq_len(nrow(dd$masked)))
  expect_equal(fit_mask$missing_data$model_row, seq_len(nrow(dd$masked)))
  expect_equal(fit_mask$missing_data$response_policy, "include")
  expect_equal(
    fit_mask$missing_data$counts$missing_response,
    sum(!observed)
  )
  expect_length(fitted(fit_mask), nrow(dd$masked))
  expect_equal(
    fitted(fit_mask)[observed],
    fitted(fit_cc),
    tolerance = 1e-8,
    ignore_attr = TRUE
  )
  expect_true(all(is.na(residuals(fit_mask)[!observed])))
  expect_true(all(is.na(residuals(fit_mask, type = "pearson")[!observed])))
})

test_that("poisson masked-row placeholder cannot leak into likelihood or gradients", {
  dd <- missing_response_poisson_data()
  fit <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  expect_missing_response_sentinel_invariant(fit, sentinels = c(0, 7))
})

test_that("poisson MCAR-masked responses recover the truth", {
  # n chosen so single-fit recovery is robust; a coverage claim needs many
  # replicates (out of scope here), per the P0 recovery-vs-coverage distinction.
  dd <- missing_response_poisson_data(seed = 404, n = 4000, miss_frac = 0.25)
  fit <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  est <- unname(coef(fit, "mu"))
  truth <- dd$truth

  expect_equal(est, truth, tolerance = 0.1)
})

test_that("response = 'include' masks missing responses but drops missing-predictor rows", {
  # Scope check for the keep-logic: response = "include" excludes the RESPONSE
  # from the complete-case rule (so missing-response rows are kept and masked),
  # but predictors are still required, so a missing-PREDICTOR row is dropped.
  dd <- missing_response_poisson_data()
  n_total <- nrow(dd$masked)
  n_missing_response <- sum(!dd$observed)
  dd$masked$x[which(dd$observed)[1]] <- NA_real_ # one missing predictor

  fit <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )

  expect_equal(length(fit$missing_data$observed_y), n_total - 1L)
  expect_equal(sum(!fit$missing_data$observed_y), n_missing_response)
  expect_equal(nobs(fit), sum(dd$observed) - 1L)
})

test_that("poisson response mask combines with a random-effect mu term", {
  # The first Poisson missing-response slice scopes out zero-inflation and mi()
  # missing-predictor models, but plain random-effect terms are supported.
  set.seed(505)
  n <- 300
  g <- factor(rep(letters[1:10], length.out = n))
  x <- rnorm(n)
  u <- rnorm(nlevels(g), 0, 0.3)[as.integer(g)]
  y <- rpois(n, exp(0.4 + 0.6 * x + u))
  d <- data.frame(y = y, x = x, g = g)
  miss <- sample(n, size = round(0.2 * n))
  d$y[miss] <- NA_integer_

  fit <- drmTMB(
    bf(y ~ x + (1 | g)),
    family = poisson(),
    data = d,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  expect_equal(nobs(fit), n - length(miss))
  expect_equal(sum(!fit$missing_data$observed_y), length(miss))
})

test_that("poisson response mask rejects zero-inflation and mi() predictor combos", {
  dd <- missing_response_poisson_data()
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ 1),
      family = poisson(),
      data = dd$masked,
      missing = miss_control(response = "include"),
      control = drm_control(se = FALSE)
    ),
    "zero-inflat"
  )

  d2 <- dd$masked
  d2$z <- rbinom(nrow(d2), 1, 0.5)
  d2$x <- factor(d2$z) # reuse a binary predictor as the mi() target
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x)),
      family = poisson(),
      data = d2,
      missing = miss_control(response = "include", predictor = "model"),
      impute = list(x = impute_model(x ~ z, family = binomial())),
      control = drm_control(se = FALSE)
    ),
    "not implemented together"
  )
})
