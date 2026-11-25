# predict(), fitted(), and logLik() on tiny fits (R/methods.R).

cov_1125x7_gauss <- function() {
  set.seed(112571)
  dat <- data.frame(y = stats::rnorm(18), x = stats::rnorm(18))
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
}

test_that("predict() returns numeric vectors for newdata rows", {
  fit <- cov_1125x7_gauss()
  nd <- fit$data[1:4, , drop = FALSE]
  pred <- predict(fit, newdata = nd)
  expect_length(pred, 4L)
  expect_type(pred, "double")
  expect_true(all(is.finite(pred)))
  expect_equal(length(fitted(fit)), fit$nobs)
})

test_that("predict(type = 'mean') matches fitted() on the training rows", {
  fit <- cov_1125x7_gauss()
  mean_pred <- predict(fit, type = "mean", newdata = fit$data[1:3, ])
  expect_length(mean_pred, 3L)
  expect_equal(mean_pred, fitted(fit)[1:3], tolerance = 1e-8)
})

test_that("predict(type = 'link') tracks predict_parameters() on the link scale", {
  fit <- cov_1125x7_gauss()
  link_pred <- predict(fit, type = "link", newdata = fit$data[1:2, ])
  params <- predict_parameters(fit, newdata = fit$data[1:2, ], dpar = "mu", type = "link")
  expect_equal(link_pred, params$estimate, tolerance = 1e-9)
})

test_that("Poisson predict() returns finite link-scale values", {
  set.seed(112572)
  dat <- data.frame(y = stats::rpois(16, exp(0.2)), x = stats::rnorm(16))
  fit <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  pred <- predict(fit, type = "link", newdata = dat[1:3, ])
  expect_length(pred, 3L)
  expect_true(all(is.finite(pred)))
  expect_equal(length(fitted(fit)), 16L)
  ll <- as.numeric(logLik(fit))
  expect_true(is.finite(ll))
  expect_lt(ll, 0)
  expect_equal(attr(logLik(fit), "nobs"), fit$nobs)
  expect_true(all(is.finite(fitted(fit))))
  expect_gt(mean(fitted(fit)), 0)
})