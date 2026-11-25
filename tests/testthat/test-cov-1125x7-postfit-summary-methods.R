# Summary, coef(), and vcov() journeys on fitted objects (R/methods.R).

cov_1125x7_sm <- function() {
  set.seed(112592)
  dat <- data.frame(
    y = stats::rnorm(20),
    x = stats::rnorm(20),
    g = rep(letters[1:2], each = 10)
  )
  drmTMB(
    bf(y ~ x + g, sigma ~ 1),
    data = dat,
    control = drm_control(se = TRUE)
  )
}

test_that("summary(), coef(), and nobs() stay consistent", {
  fit <- cov_1125x7_sm()
  sm <- summary(fit)
  expect_s3_class(sm, "summary.drmTMB")
  expect_equal(fit$nobs, 20L)
  expect_equal(sm$nobs, 20L)
  expect_true(is.data.frame(sm$coefficients))
  expect_true(nrow(sm$coefficients) >= 3L)
  expect_true(is.numeric(coef(fit)$mu))
  expect_length(coef(fit)$mu, 3L)
  expect_true(is.finite(as.numeric(logLik(fit))))
  expect_true(is.finite(AIC(fit)))
  expect_true(is.finite(BIC(fit)))
})

test_that("fit$data retains the response and predictors used in the fit", {
  fit <- cov_1125x7_sm()
  expect_s3_class(fit$data, "data.frame")
  expect_equal(nrow(fit$data), 20L)
  expect_true("y" %in% names(fit$data))
  expect_true("x" %in% names(fit$data))
  expect_true("g" %in% names(fit$data))
})

test_that("predict_parameters() sigma matches summary parameters intercept", {
  fit <- cov_1125x7_sm()
  pp <- predict_parameters(fit, dpar = "sigma", type = "response", newdata = fit$data[1, ])
  sm <- summary(fit)
  sig_row <- sm$parameters[sm$parameters$dpar == "sigma", ][1L, ]
  expect_equal(nrow(pp), 1L)
  expect_equal(pp$estimate, sig_row$estimate, tolerance = 1e-8)
  expect_gt(pp$estimate, 0)
})

test_that("is_converged() and check_drm() agree for a simple converged fit", {
  fit <- cov_1125x7_sm()
  expect_true(is_converged(fit))
  chk <- check_drm(fit)
  expect_type(attr(chk, "ok"), "logical")
  expect_true(nrow(chk) >= 3L)
})

test_that("lognormal and Poisson fits keep finite predictive surfaces", {
  set.seed(112593)
  dat <- data.frame(y = exp(stats::rnorm(16)), x = stats::rnorm(16))
  ln <- drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = dat, control = drm_control(se = FALSE))
  expect_true(all(is.finite(predict(ln, newdata = dat[1:3, ]))))
  sig <- predict_parameters(ln, dpar = "sigma", type = "response", newdata = dat[1, ])
  expect_equal(nrow(sig), 1L)
  expect_gt(sig$estimate, 0)
  dat2 <- data.frame(y = stats::rpois(16, 2), x = stats::rnorm(16))
  pois <- drmTMB(bf(y ~ x), family = poisson(), data = dat2, control = drm_control(se = FALSE))
  expect_length(fitted(pois), 16L)
  expect_true(all(is.finite(predict(pois, type = "response", newdata = dat2[1:2, ]))))
  expect_gt(predict_parameters(pois, dpar = "mu", type = "response")$estimate[1], 0)
})