mr_t6_zip_data <- function(n = 1800L, seed = 20260608L) {
  set.seed(seed)
  dat <- data.frame(
    x = rnorm(n),
    z = rnorm(n),
    habitat = factor(sample(c("open", "edge"), n, replace = TRUE))
  )
  truth <- list(
    mu = c(`(Intercept)` = 0.30, x = -0.35, habitatopen = 0.25),
    zi = c(`(Intercept)` = -0.90, z = 0.55, habitatopen = -0.45)
  )
  X_mu <- model.matrix(~ x + habitat, dat)
  X_zi <- model.matrix(~ z + habitat, dat)
  mu <- exp(as.vector(X_mu %*% truth$mu))
  zi <- plogis(as.vector(X_zi %*% truth$zi))
  dat$count <- ifelse(runif(n) < zi, 0L, rpois(n, mu))
  list(data = dat, truth = truth)
}

mr_t6_fit <- function(route, data, missing = miss_control(), se = FALSE) {
  control <- drm_control(se = se)
  switch(
    route,
    zi_poisson = drmTMB(
      bf(count ~ x + habitat, zi ~ z + habitat),
      poisson(), data, missing = missing, control = control
    )
  )
}

mr_t6_mask_stratum <- function(data, positive, n_missing = 20L, seed) {
  candidates <- which(if (positive) data$count > 0 else data$count == 0)
  if (length(candidates) < n_missing) {
    stop("Not enough responses in the requested mixture stratum.")
  }
  set.seed(seed)
  data$count[sample(candidates, n_missing)] <- NA_integer_
  data
}

mr_t6_expect_parity <- function(route, data) {
  observed <- !is.na(data$count)
  fit_mask <- mr_t6_fit(
    route, data, missing = miss_control(response = "include")
  )
  fit_cc <- mr_t6_fit(route, data[observed, , drop = FALSE])
  for (dpar in fit_mask$model$dpars) {
    expect_equal(
      unname(coef(fit_mask, dpar)), unname(coef(fit_cc, dpar)),
      tolerance = 1e-6, info = paste(route, dpar)
    )
  }
  expect_equal(logLik(fit_mask), logLik(fit_cc), tolerance = 1e-6)
  list(mask = fit_mask, cc = fit_cc, observed = observed)
}

test_that("MR-T6 ZIP masks the complete mixture contribution", {
  sim <- mr_t6_zip_data(n = 720L, seed = 2026071601L)
  dat <- missing_response_mask_mcar(sim$data, "count", seed = 2026071602L)
  parity <- mr_t6_expect_parity("zi_poisson", dat)
  fit <- parity$mask
  observed <- parity$observed

  expect_equal(mean(!observed), 0.25)
  expect_gt(sum(observed & sim$data$count == 0), 0L)
  expect_gt(sum(observed & sim$data$count > 0), 0L)
  expect_equal(fit$missing_data$observed_y, observed)
  expect_equal(fit$missing_data$response_sentinel, 0)
  expect_equal(fit$missing_data$original_row, seq_len(nrow(dat)))
  expect_equal(fit$missing_data$model_row, seq_len(nrow(dat)))
  expect_equal(nobs(fit), sum(observed))
  expect_length(fitted(fit), nrow(dat))
  expect_length(predict(fit, dpar = "mu"), nrow(dat))
  expect_length(predict(fit, dpar = "zi"), nrow(dat))
  expect_length(sigma(fit), nrow(dat))
  expect_true(all(is.na(residuals(fit)[!observed])))
  expect_true(all(is.na(residuals(fit, type = "pearson")[!observed])))
  expect_equal(
    fitted(fit)[observed], fitted(parity$cc), tolerance = 1e-6,
    ignore_attr = TRUE
  )
  expect_missing_response_sentinel_invariant(fit, sentinels = c(0, 7))

  sims <- simulate(fit, nsim = 3, seed = 2026071603L)
  expect_equal(dim(sims), c(nrow(dat), 3L))
  expect_true(all(as.matrix(sims) >= 0))
  expect_true(all(as.matrix(sims) == round(as.matrix(sims))))
  expect_gt(sum(as.matrix(sims) == 0), 0L)
  expect_gt(sum(as.matrix(sims) > 0), 0L)
})

test_that("MR-T6 ZIP separately masks observed zeros and positives", {
  sim <- mr_t6_zip_data(n = 600L, seed = 2026071604L)
  zeros_missing <- mr_t6_mask_stratum(
    sim$data, positive = FALSE, seed = 2026071605L
  )
  positives_missing <- mr_t6_mask_stratum(
    sim$data, positive = TRUE, seed = 2026071606L
  )
  expect_true(all(sim$data$count[is.na(zeros_missing$count)] == 0))
  expect_true(all(sim$data$count[is.na(positives_missing$count)] > 0))
  mr_t6_expect_parity("zi_poisson", zeros_missing)
  mr_t6_expect_parity("zi_poisson", positives_missing)
})

test_that("MR-T6 ZIP recovers mu and zero inflation under 25 percent MCAR", {
  sim <- mr_t6_zip_data()
  dat <- missing_response_mask_mcar(sim$data, "count", seed = 2026071609L)
  fit <- mr_t6_fit(
    "zi_poisson", dat, missing = miss_control(response = "include"), se = TRUE
  )
  expect_equal(mean(is.na(dat$count)), 0.25)
  expect_equal(fit$opt$convergence, 0L)
  expect_lt(max(abs(coef(fit, "mu") - sim$truth$mu)), 0.12)
  expect_lt(max(abs(coef(fit, "zi") - sim$truth$zi)), 0.35)
})

test_that("MR-T6 ZIP keeps malformed and neighbouring gates closed", {
  include <- miss_control(response = "include")
  dat <- mr_t6_zip_data(n = 120L, seed = 2026071608L)$data
  expect_error(
    mr_t6_fit("zi_poisson", transform(dat, count = NA_integer_), include),
    "At least one observed Poisson"
  )
  for (bad in c(-1, 1.5, Inf)) {
    malformed <- dat
    malformed$count[[1L]] <- NA_real_
    malformed$count[[2L]] <- bad
    expect_error(
      mr_t6_fit("zi_poisson", malformed, include),
      "non-negative integer",
      info = paste("bad ZIP response", bad)
    )
  }
  dat$count[[1L]] <- NA_integer_
  dat$x[[2L]] <- NA_real_
  fit <- mr_t6_fit("zi_poisson", dat, include)
  expect_equal(fit$missing_data$original_row, setdiff(seq_len(120L), 2L))
  expect_equal(nobs(fit), 118L)
  expect_length(fitted(fit), 119L)

  expect_error(
    drmTMB(
      bf(count ~ x + habitat, zi ~ z + habitat), poisson(), dat,
      missing = include, REML = TRUE
    ),
    "only for.*Gaussian"
  )
  dat$q <- rbinom(nrow(dat), 1, 0.5)
  dat$q[[3L]] <- NA_integer_
  expect_error(
    drmTMB(
      bf(count ~ x + habitat + mi(q), zi ~ z + habitat), poisson(), dat,
      impute = list(q = impute_model(q ~ x, family = binomial())),
      missing = miss_control(response = "include", predictor = "model")
    ),
    "not implemented together"
  )
})
