# Adequacy residuals from fitted objects (R/adequacy.R).

cov_1125x7_adequacy <- function() {
  set.seed(112579)
  dat <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
}

test_that("drm_quantile_residuals() returns normalized residuals for a Gaussian fit", {
  fit <- cov_1125x7_adequacy()
  qr <- drm_quantile_residuals(fit, seed = 1, nsim = 1L)
  expect_equal(length(qr), fit$nobs)
  expect_true(all(is.finite(qr)))
})

test_that("drm_quantile_residual_qq_data() includes theoretical and sample quantiles", {
  fit <- cov_1125x7_adequacy()
  qq <- drm_quantile_residual_qq_data(fit, seed = 2, nsim = 1L)
  expect_s3_class(qq, "data.frame")
  expect_true(nrow(qq) >= 5L)
  expect_true(all(c("theoretical", "sample") %in% names(qq)))
})

test_that("check_drm() returns a reader table for a converged fit", {
  fit <- cov_1125x7_adequacy()
  chk <- check_drm(fit)
  expect_s3_class(chk, "data.frame")
  expect_true(all(c("check", "status", "value", "message") %in% names(chk)))
  expect_type(attr(chk, "ok"), "logical")
})

test_that("Poisson quantile residuals stay finite", {
  set.seed(1125791)
  dat <- data.frame(y = stats::rpois(18, 3), x = stats::rnorm(18))
  fit <- drmTMB(
    bf(y ~ x),
    family = poisson(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  qr <- drm_quantile_residuals(fit, seed = 3, nsim = 1L)
  expect_equal(length(qr), 18L)
  expect_true(all(is.finite(qr)))
  expect_true(is.finite(sum(qr)))
})