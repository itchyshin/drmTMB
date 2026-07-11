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
})

test_that("binomial masked-row placeholder cannot leak into likelihood or gradients", {
  dd <- missing_response_binomial_data()
  fit_it <- function() {
    drmTMB(
      bf(y ~ x),
      family = binomial(),
      data = dd$masked,
      missing = miss_control(response = "include"),
      control = drm_control(se = FALSE)
    )
  }
  # The binomial masked-row placeholder is a fixed valid (0/1) value, so the
  # numeric response sentinel option must have no effect whatsoever.
  f0 <- withr::with_options(
    list(drmTMB.missing_response_sentinel = 0),
    fit_it()
  )
  f1 <- withr::with_options(
    list(drmTMB.missing_response_sentinel = 1e6),
    fit_it()
  )
  expect_equal(as.numeric(logLik(f0)), as.numeric(logLik(f1)))
  expect_equal(coef(f0, "mu"), coef(f1, "mu"))
  expect_equal(
    f0$obj$gr(f0$opt$par),
    f1$obj$gr(f1$opt$par),
    tolerance = 1e-9,
    ignore_attr = TRUE
  )
})

test_that("binomial MCAR-masked responses recover the truth", {
  # n chosen so single-fit recovery is robust; a coverage claim needs many
  # replicates (out of scope here), per the P0 recovery-vs-coverage distinction.
  dd <- missing_response_binomial_data(seed = 202, n = 4000, miss_frac = 0.25)
  fit <- drmTMB(
    bf(y ~ x),
    family = binomial(),
    data = dd$masked,
    missing = miss_control(response = "include")
  )
  est <- unname(coef(fit, "mu"))
  se <- sqrt(diag(vcov(fit)))[seq_along(est)]
  truth <- dd$truth

  # point-near-truth (MCAR): estimates close to the data-generating logits
  expect_equal(est, truth, tolerance = 0.1)
  # truth-in-CI (Wald 95%)
  lower <- est - 1.96 * se
  upper <- est + 1.96 * se
  expect_true(all(truth >= lower & truth <= upper))
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
