# P1 slice: missing-RESPONSE masking for a binomial (0/1) response (model_type 18).
#
# A correctly masked missing response contributes nothing to the likelihood, so a
# `response = "include"` fit must equal the complete-case fit on the observed rows
# (byte-identical), the masked-row placeholder must be inert, and MCAR-masked data
# must still recover the truth.

missing_response_binomial_data <- function(seed = 101, n = 400, miss_frac = 0.2) {
  set.seed(seed)
  x <- rnorm(n)
  p <- plogis(-0.3 + 1.1 * x)
  y <- rbinom(n, 1L, p)
  miss <- sample(n, size = round(miss_frac * n))
  masked <- data.frame(y = y, x = x)
  masked$y[miss] <- NA_integer_
  list(
    masked = masked,
    observed = !(seq_len(n) %in% miss),
    truth = c(-0.3, 1.1)
  )
}

test_that("binomial response mask is inert: include == complete-case", {
  dd <- missing_response_binomial_data()
  observed <- dd$observed

  fit_mask <- drmTMB(
    bf(y ~ x),
    family = binomial(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  fit_cc <- drmTMB(
    bf(y ~ x),
    family = binomial(),
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

test_that("binomial masked-row placeholder cannot leak into likelihood or gradients", {
  dd <- missing_response_binomial_data()
  fit <- drmTMB(
    bf(y ~ x),
    family = binomial(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  expect_missing_response_sentinel_invariant(fit, sentinels = c(0, 1))
})

test_that("binomial MCAR-masked responses recover the truth", {
  # n chosen so single-fit recovery is robust; a coverage claim needs many
  # replicates (out of scope here), per the P0 recovery-vs-coverage distinction.
  dd <- missing_response_binomial_data(seed = 202, n = 4000, miss_frac = 0.25)
  expect_equal(mean(!dd$observed), 0.25)
  fit <- drmTMB(
    bf(y ~ x),
    family = binomial(),
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
  # (Binomial predictor handling is complete-case in this slice; predictor
  # modelling / imputation is a separate, gated feature.)
  dd <- missing_response_binomial_data()
  n_total <- nrow(dd$masked)
  n_missing_response <- sum(!dd$observed)
  dd$masked$x[which(dd$observed)[1]] <- NA_real_ # one missing predictor

  fit <- drmTMB(
    bf(y ~ x),
    family = binomial(),
    data = dd$masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )

  expect_equal(length(fit$missing_data$observed_y), n_total - 1L)
  expect_equal(sum(!fit$missing_data$observed_y), n_missing_response)
  expect_equal(nobs(fit), sum(dd$observed) - 1L)
})

test_that("binomial random-intercept response mask matches observed-data fit", {
  set.seed(2026081407)
  n_id <- 48L
  n_each <- 16L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  truth_sd <- 0.6
  u <- rnorm(n_id, sd = truth_sd)
  dat <- data.frame(id, x)
  dat$y <- rbinom(nrow(dat), 1L, plogis(-0.3 + 0.65 * x + u[id]))
  masked <- missing_response_mask_mcar_within_group(
    dat, "y", "id", seed = 2026081408
  )
  observed <- !is.na(masked$y)

  fit_mask <- drmTMB(
    bf(y ~ x + (1 | id)), family = binomial(), data = masked,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    bf(y ~ x + (1 | id)), family = binomial(),
    data = masked[observed, , drop = FALSE], control = drm_control(se = FALSE)
  )

  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-5)
  expect_equal(fit_mask$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(0, 1))
  expect_lt(max(abs(unname(coef(fit_mask, "mu")) - c(-0.3, 0.65))), 0.35)
  expect_lt(abs(unname(fit_mask$sdpars$mu) - truth_sd), 0.35)
  expect_gt(cor(fit_mask$random_effects$mu$values, u), 0.3)
})

test_that("binomial REML random-intercept response mask matches observed data", {
  set.seed(2026081554)
  n_id <- 72L
  n_each <- 16L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  truth_sd <- 0.55
  u <- rnorm(n_id, sd = truth_sd)
  dat <- data.frame(id, x)
  dat$y <- rbinom(nrow(dat), 1L, plogis(-0.30 + 0.65 * x + u[id]))
  masked <- missing_response_mask_mcar_within_group(dat, "y", "id", seed = 2026081555)
  observed <- !is.na(masked$y)
  form <- bf(y ~ x + (1 | id))
  fit_mask <- drmTMB(form, binomial(), masked,
    missing = miss_control(response = "include"), REML = TRUE, control = drm_control(se = FALSE))
  fit_observed <- drmTMB(form, binomial(), masked[observed, , drop = FALSE],
    REML = TRUE, control = drm_control(se = FALSE))
  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-5)
  expect_equal(fit_mask$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(0, 1))
  expect_lt(max(abs(unname(coef(fit_mask, "mu")) - c(-0.30, 0.65))), 0.30)
  expect_lt(abs(unname(fit_mask$sdpars$mu) - truth_sd), 0.25)
  expect_gt(cor(fit_mask$random_effects$mu$values, u), 0.35)
})

test_that("grouped-binomial REML random-slope response mask matches observed data", {
  set.seed(2026081558)
  n_id <- 64L
  n_each <- 16L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  truth_sd <- 0.55
  u <- rnorm(n_id, sd = truth_sd)
  trials <- rep(12L, length(x))
  success <- rbinom(length(x), trials, plogis(-0.30 + (0.65 + u[id]) * x))
  dat <- data.frame(success, failure = trials - success, x, id)
  masked <- missing_response_mask_mcar_within_group(dat, "success", "id", seed = 2026081559)
  masked$failure[is.na(masked$success)] <- NA_integer_
  observed <- !is.na(masked$success)
  form <- bf(cbind(success, failure) ~ x + (0 + x | id))
  fit_mask <- drmTMB(form, binomial(), masked,
    missing = miss_control(response = "include"), REML = TRUE, control = drm_control(se = FALSE))
  fit_observed <- drmTMB(form, binomial(), masked[observed, , drop = FALSE],
    REML = TRUE, control = drm_control(se = FALSE))
  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-5)
  expect_equal(fit_mask$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(0, 11))
  expect_lt(max(abs(unname(coef(fit_mask, "mu")) - c(-0.30, 0.65))), 0.22)
  expect_lt(abs(unname(fit_mask$sdpars$mu) - truth_sd), 0.20)
  slope_effects <- fit_mask$random_effects$mu$terms[["(0 + x | id)"]]
  expect_gt(cor(slope_effects, u), 0.55)
})

test_that("grouped-binomial random-slope response mask matches observed-data fit", {
  # Multiple trials give the slope-SD recovery target enough information.  Both
  # columns of the cbind response are missing on an omitted response row.
  set.seed(2026081507)
  n_id <- 48L
  n_each <- 16L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  truth_sd <- 0.6
  u <- rnorm(n_id, sd = truth_sd)
  trials <- rep(12L, length(x))
  success <- rbinom(length(x), trials, plogis(-0.3 + 0.65 * x + u[id] * x))
  dat <- data.frame(success, failure = trials - success, x, id)
  masked <- missing_response_mask_mcar_within_group(
    dat, "success", "id", seed = 2026081508
  )
  masked$failure[is.na(masked$success)] <- NA_integer_
  observed <- !is.na(masked$success)

  fit_mask <- drmTMB(
    bf(cbind(success, failure) ~ x + (0 + x | id)), family = binomial(),
    data = masked, missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    bf(cbind(success, failure) ~ x + (0 + x | id)), family = binomial(),
    data = masked[observed, , drop = FALSE], control = drm_control(se = FALSE)
  )

  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-5)
  expect_equal(fit_mask$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_equal(nobs(fit_mask), sum(observed))
  expect_equal(fit_mask$missing_data$observed_y, observed)
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(0, 11))
  expect_lt(max(abs(unname(coef(fit_mask, "mu")) - c(-0.3, 0.65))), 0.3)
  expect_lt(abs(unname(fit_mask$sdpars$mu) - truth_sd), 0.2)
  expect_gt(cor(fit_mask$random_effects$mu$values, u), 0.6)
})
