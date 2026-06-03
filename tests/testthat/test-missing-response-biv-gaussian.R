missing_response_biv_gaussian_data <- function() {
  x <- seq(-1.5, 1.7, length.out = 36)
  i <- seq_along(x)
  y1 <- 0.4 + 0.8 * x + 0.16 * sin(0.7 * i)
  y2 <- -0.2 - 0.5 * x + 0.14 * cos(0.5 * i) + 0.04 * sin(0.9 * i)
  dat <- data.frame(y1 = y1, y2 = y2, x = x)
  dat$y1[c(5, 14, 29)] <- NA_real_
  dat$y2[c(8, 14, 31)] <- NA_real_
  dat
}

fit_missing_response_biv_gaussian <- function(dat) {
  drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = dat,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
}

manual_biv_missing_loglik <- function(fit) {
  dat <- fit$model$data
  missing_data <- fit$missing_data
  observed_y1 <- missing_data$observed_y1
  observed_y2 <- missing_data$observed_y2
  mu1 <- predict(fit, dpar = "mu1")
  mu2 <- predict(fit, dpar = "mu2")
  sigma1 <- predict(fit, dpar = "sigma1")
  sigma2 <- predict(fit, dpar = "sigma2")
  rho12 <- predict(fit, dpar = "rho12")
  out <- numeric(nrow(dat))

  both <- observed_y1 & observed_y2
  z1 <- (dat$y1[both] - mu1[both]) / sigma1[both]
  z2 <- (dat$y2[both] - mu2[both]) / sigma2[both]
  one_minus_rho2 <- 1 - rho12[both]^2
  out[both] <- -log(2 * pi) -
    log(sigma1[both]) -
    log(sigma2[both]) -
    0.5 * log(one_minus_rho2) -
    0.5 * (z1^2 - 2 * rho12[both] * z1 * z2 + z2^2) / one_minus_rho2

  y1_only <- observed_y1 & !observed_y2
  out[y1_only] <- stats::dnorm(
    dat$y1[y1_only],
    mean = mu1[y1_only],
    sd = sigma1[y1_only],
    log = TRUE
  )

  y2_only <- !observed_y1 & observed_y2
  out[y2_only] <- stats::dnorm(
    dat$y2[y2_only],
    mean = mu2[y2_only],
    sd = sigma2[y2_only],
    log = TRUE
  )

  sum(out)
}

test_that("default missing policy matches complete-pair bivariate Gaussian fits", {
  dat <- missing_response_biv_gaussian_data()
  dat$x[3] <- NA_real_
  keep <- stats::complete.cases(dat[, c("y1", "y2", "x")])

  fit_default <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_cc <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = dat[keep, , drop = FALSE],
    control = drm_control(se = FALSE)
  )

  expect_equal(coef(fit_default, "mu1"), coef(fit_cc, "mu1"), tolerance = 1e-8)
  expect_equal(coef(fit_default, "mu2"), coef(fit_cc, "mu2"), tolerance = 1e-8)
  expect_equal(
    coef(fit_default, "sigma1"),
    coef(fit_cc, "sigma1"),
    tolerance = 1e-8
  )
  expect_equal(
    coef(fit_default, "sigma2"),
    coef(fit_cc, "sigma2"),
    tolerance = 1e-8
  )
  expect_equal(
    coef(fit_default, "rho12"),
    coef(fit_cc, "rho12"),
    tolerance = 1e-8
  )
  expect_equal(as.numeric(logLik(fit_default)), as.numeric(logLik(fit_cc)))
  expect_equal(fit_default$missing_data$response_policy, "drop")
  expect_equal(fit_default$missing_data$original_row, which(keep))
  expect_true(all(fit_default$missing_data$observed_y1))
  expect_true(all(fit_default$missing_data$observed_y2))
})

test_that("bivariate Gaussian response masks retain partial-response rows", {
  dat <- missing_response_biv_gaussian_data()
  observed_y1 <- !is.na(dat$y1)
  observed_y2 <- !is.na(dat$y2)

  fit <- fit_missing_response_biv_gaussian(dat)

  expect_equal(nobs(fit), sum(observed_y1 | observed_y2))
  expect_equal(fit$missing_data$version, "MD2")
  expect_equal(fit$missing_data$original_row, seq_len(nrow(dat)))
  expect_equal(fit$missing_data$model_row, seq_len(nrow(dat)))
  expect_equal(fit$missing_data$observed_y1, observed_y1)
  expect_equal(fit$missing_data$observed_y2, observed_y2)
  expect_equal(
    fit$missing_data$counts$complete_response,
    sum(observed_y1 & observed_y2)
  )
  expect_equal(fit$missing_data$counts$y1_only, sum(observed_y1 & !observed_y2))
  expect_equal(fit$missing_data$counts$y2_only, sum(!observed_y1 & observed_y2))
  expect_equal(
    fit$missing_data$counts$both_missing,
    sum(!observed_y1 & !observed_y2)
  )
  expect_equal(
    as.numeric(logLik(fit)),
    manual_biv_missing_loglik(fit),
    tolerance = 1e-6
  )

  fitted_values <- fitted(fit)
  expect_equal(dim(fitted_values), c(nrow(dat), 2L))

  response <- residuals(fit)
  pearson <- residuals(fit, type = "pearson")
  expect_true(all(is.na(response[!observed_y1, "y1"])))
  expect_true(all(is.na(response[!observed_y2, "y2"])))
  expect_true(all(is.na(pearson[!observed_y1, "y1"])))
  expect_true(all(is.na(pearson[!observed_y2, "y2"])))
  expect_true(all(is.finite(response[observed_y1, "y1"])))
  expect_true(all(is.finite(response[observed_y2, "y2"])))
  expect_true(all(is.finite(pearson[observed_y1, "y1"])))
  expect_true(all(is.finite(pearson[observed_y2, "y2"])))
})

test_that("bivariate Gaussian response-mask sentinel cannot leak", {
  dat <- missing_response_biv_gaussian_data()

  fit_zero <- withr::with_options(
    list(drmTMB.missing_response_sentinel = 0),
    fit_missing_response_biv_gaussian(dat)
  )
  fit_large <- withr::with_options(
    list(drmTMB.missing_response_sentinel = 1e6),
    fit_missing_response_biv_gaussian(dat)
  )

  expect_equal(as.numeric(logLik(fit_zero)), as.numeric(logLik(fit_large)))
  expect_equal(coef(fit_zero, "mu1"), coef(fit_large, "mu1"))
  expect_equal(coef(fit_zero, "mu2"), coef(fit_large, "mu2"))
  expect_equal(coef(fit_zero, "sigma1"), coef(fit_large, "sigma1"))
  expect_equal(coef(fit_zero, "sigma2"), coef(fit_large, "sigma2"))
  expect_equal(coef(fit_zero, "rho12"), coef(fit_large, "rho12"))
  expect_equal(
    fit_zero$obj$gr(fit_zero$opt$par),
    fit_large$obj$gr(fit_large$opt$par),
    tolerance = 1e-9,
    ignore_attr = TRUE
  )
  expect_equal(
    fitted(fit_zero),
    fitted(fit_large),
    tolerance = 1e-10,
    ignore_attr = TRUE
  )
  expect_equal(fit_zero$missing_data$response_sentinel, 0)
  expect_equal(fit_large$missing_data$response_sentinel, 1e6)
})

test_that("bivariate response masks keep predictor and dense-V boundaries explicit", {
  dat <- missing_response_biv_gaussian_data()
  dat_with_missing_x <- dat
  dat_with_missing_x$x[4] <- NA_real_

  expect_error(
    fit_missing_response_biv_gaussian(dat_with_missing_x),
    "Missing predictors"
  )

  V <- diag(0.01, 2L * nrow(dat))
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + meta_V(V = V),
        mu2 = y2 ~ x,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat,
      missing = miss_control(response = "include"),
      control = drm_control(se = FALSE)
    ),
    "dense known sampling covariance"
  )
})

test_that("bivariate response masks warn when rho12 has too few complete pairs", {
  dat <- missing_response_biv_gaussian_data()
  dat$y1[-seq_len(18)] <- NA_real_
  dat$y2[-c(1L, 2L, 19:34)] <- NA_real_

  expect_warning(
    fit <- fit_missing_response_biv_gaussian(dat),
    "rho12"
  )
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$missing_data$counts$complete_response, 2L)
})
