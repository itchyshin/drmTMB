# Distributional outputs via fitted models (R/distributional-outputs.R).

cov_1125x7_dist <- function() {
  set.seed(112576)
  dat <- data.frame(y = stats::rnorm(18), x = stats::rnorm(18))
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
}

test_that("predict(type = 'quantile') returns labelled columns", {
  fit <- cov_1125x7_dist()
  qt <- predict(fit, type = "quantile", prob = c(0.1, 0.5, 0.9), newdata = fit$data[1:2, ])
  expect_equal(nrow(qt), 2L)
  expect_equal(ncol(qt), 3L)
  expect_equal(colnames(qt), c("10%", "50%", "90%"))
  expect_false(isTRUE(attr(qt, "calibrated")))
})

test_that("exceedance() returns probabilities between 0 and 1", {
  fit <- cov_1125x7_dist()
  ex <- exceedance(fit, threshold = 0, newdata = fit$data[1:3, ])
  expect_equal(length(ex), 3L)
  expect_true(all(ex >= 0 & ex <= 1))
  expect_false(isTRUE(attr(ex, "calibrated")))
})

test_that("fitted_distribution() exposes dpq closures for a Gaussian fit", {
  fit <- cov_1125x7_dist()
  fd <- fitted_distribution(fit, newdata = fit$data[1, ])
  expect_s3_class(fd, "drm_fitted_distribution")
  expect_equal(fd$d(0), stats::dnorm(0, fd$params$mu, fd$params$sigma))
  expect_equal(fd$p(0), stats::pnorm(0, fd$params$mu, fd$params$sigma))
})

test_that("lognormal quantile predictions stay above zero on the response scale", {
  set.seed(112577)
  dat <- data.frame(y = exp(stats::rnorm(16)), x = stats::rnorm(16))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = lognormal(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  qt <- predict(fit, type = "quantile", prob = 0.5, newdata = dat[1:2, ])
  expect_true(all(as.numeric(qt) > 0))
  expect_false(isTRUE(attr(qt, "calibrated")))
  fd <- fitted_distribution(fit, newdata = dat[1, ])
  expect_equal(fd$p(1), stats::plnorm(1, fd$params$mu, fd$params$sigma))
})