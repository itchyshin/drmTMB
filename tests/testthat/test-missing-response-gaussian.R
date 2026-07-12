missing_response_gaussian_data <- function() {
  x <- seq(-1.4, 1.6, length.out = 24)
  y <- 0.35 + 0.75 * x + 0.12 * cos(seq_along(x))
  dat <- data.frame(y = y, x = x)
  dat$y[c(4, 11, 19)] <- NA_real_
  dat
}

fit_missing_response_gaussian <- function(dat) {
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
}

missing_response_gaussian_group_data <- function() {
  x <- seq(-1.4, 1.6, length.out = 24)
  group <- factor(rep(letters[1:6], each = 4))
  group_shift <- rep(seq(-0.25, 0.25, length.out = 6), each = 4)
  y <- 0.35 + 0.75 * x + group_shift + 0.08 * cos(seq_along(x))
  dat <- data.frame(y = y, x = x, group = group)
  dat$y[c(4, 11, 19)] <- NA_real_
  dat
}

fit_missing_response_gaussian_group <- function(dat) {
  drmTMB(
    bf(y ~ x + (1 | group), sigma ~ 1),
    data = dat,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
}

test_that("default missing policy matches existing complete-case Gaussian fits", {
  dat <- missing_response_gaussian_data()
  dat$x[7] <- NA_real_
  keep <- stats::complete.cases(dat[, c("y", "x")])

  fit_default <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_cc <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat[keep, , drop = FALSE],
    control = drm_control(se = FALSE)
  )

  expect_equal(coef(fit_default, "mu"), coef(fit_cc, "mu"), tolerance = 1e-8)
  expect_equal(
    coef(fit_default, "sigma"),
    coef(fit_cc, "sigma"),
    tolerance = 1e-8
  )
  expect_equal(as.numeric(logLik(fit_default)), as.numeric(logLik(fit_cc)))
  expect_equal(fit_default$missing_data$response_policy, "drop")
  expect_equal(fit_default$missing_data$original_row, which(keep))
  expect_true(all(fit_default$missing_data$observed_y))
})

test_that("Gaussian response masks retain rows but match observed complete-case likelihood", {
  dat <- missing_response_gaussian_data()
  observed <- !is.na(dat$y)

  fit_mask <- fit_missing_response_gaussian(dat)
  fit_cc <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )

  expect_equal(coef(fit_mask, "mu"), coef(fit_cc, "mu"), tolerance = 1e-8)
  expect_equal(coef(fit_mask, "sigma"), coef(fit_cc, "sigma"), tolerance = 1e-8)
  expect_equal(
    as.numeric(logLik(fit_mask)),
    as.numeric(logLik(fit_cc)),
    tolerance = 1e-8
  )
  expect_equal(nobs(fit_mask), sum(observed))
  expect_equal(fit_mask$missing_data$original_row, seq_len(nrow(dat)))
  expect_equal(fit_mask$missing_data$model_row, seq_len(nrow(dat)))
  expect_equal(fit_mask$missing_data$observed_y, observed)
  expect_equal(fit_mask$missing_data$counts$observed_response, sum(observed))
  expect_equal(fit_mask$missing_data$counts$missing_response, sum(!observed))
  expect_length(fitted(fit_mask), nrow(dat))
  expect_equal(
    fitted(fit_mask)[observed],
    fitted(fit_cc),
    tolerance = 1e-8,
    ignore_attr = TRUE
  )
  expect_true(all(is.na(residuals(fit_mask)[!observed])))
  expect_true(all(is.na(residuals(fit_mask, type = "pearson")[!observed])))
})

test_that("Gaussian response-mask sentinel cannot leak into likelihood or gradients", {
  dat <- missing_response_gaussian_data()
  observed <- !is.na(dat$y)

  fit_zero <- withr::with_options(
    list(drmTMB.missing_response_sentinel = 0),
    fit_missing_response_gaussian(dat)
  )
  fit_large <- withr::with_options(
    list(drmTMB.missing_response_sentinel = 1e6),
    fit_missing_response_gaussian(dat)
  )

  expect_equal(as.numeric(logLik(fit_zero)), as.numeric(logLik(fit_large)))
  expect_equal(coef(fit_zero, "mu"), coef(fit_large, "mu"))
  expect_equal(coef(fit_zero, "sigma"), coef(fit_large, "sigma"))
  expect_equal(
    fit_zero$obj$gr(fit_zero$opt$par),
    fit_large$obj$gr(fit_large$opt$par),
    tolerance = 1e-9,
    ignore_attr = TRUE
  )
  expect_equal(
    fitted(fit_zero)[observed],
    fitted(fit_large)[observed],
    tolerance = 1e-10,
    ignore_attr = TRUE
  )
  expect_equal(fit_zero$missing_data$response_sentinel, 0)
  expect_equal(fit_large$missing_data$response_sentinel, 1e6)
  expect_missing_response_sentinel_invariant(
    fit_zero,
    sentinels = c(0, 1e6)
  )

  dat_group <- missing_response_gaussian_group_data()
  observed_group <- !is.na(dat_group$y)
  fit_random_zero <- withr::with_options(
    list(drmTMB.missing_response_sentinel = 0),
    fit_missing_response_gaussian_group(dat_group)
  )
  fit_random_large <- withr::with_options(
    list(drmTMB.missing_response_sentinel = 1e6),
    fit_missing_response_gaussian_group(dat_group)
  )

  expect_equal(
    as.numeric(logLik(fit_random_zero)),
    as.numeric(logLik(fit_random_large))
  )
  expect_equal(coef(fit_random_zero, "mu"), coef(fit_random_large, "mu"))
  expect_equal(fit_random_zero$sdpars$mu, fit_random_large$sdpars$mu)
  expect_equal(
    fit_random_zero$obj$gr(fit_random_zero$opt$par),
    fit_random_large$obj$gr(fit_random_large$opt$par),
    tolerance = 1e-8,
    ignore_attr = TRUE
  )
  expect_equal(
    fitted(fit_random_zero)[observed_group],
    fitted(fit_random_large)[observed_group],
    tolerance = 1e-8,
    ignore_attr = TRUE
  )
  expect_missing_response_sentinel_invariant(
    fit_random_zero,
    sentinels = c(-1e6, 1e6)
  )
})

test_that("missing predictors still fail under predictor = 'fail'", {
  dat <- missing_response_gaussian_data()
  dat$x[4] <- NA_real_

  expect_error(
    fit_missing_response_gaussian(dat),
    "Missing predictors"
  )
})
