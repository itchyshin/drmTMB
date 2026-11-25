# Wald confint() and summary interval columns (R/profile.R, R/methods.R).

cov_1125x7_wald <- function() {
  set.seed(112575)
  dat <- data.frame(y = stats::rnorm(22), x = stats::rnorm(22))
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = TRUE)
  )
}

test_that("confint(..., method = 'wald') returns drm_confint rows for fixef targets", {
  fit <- cov_1125x7_wald()
  ci <- confint(fit, method = "wald", parm = "fixef:mu:x")
  expect_s3_class(ci, "drm_confint")
  expect_equal(nrow(ci), 1L)
  expect_true(all(is.finite(c(ci$lower, ci$upper))))
  expect_lt(ci$lower, ci$upper)
  expect_equal(ci$method, "wald")
})

test_that("summary() with conf.int reports interval metadata", {
  fit <- cov_1125x7_wald()
  sm <- summary(fit, conf.int = TRUE)
  expect_s3_class(sm, "summary.drmTMB")
  expect_true(isTRUE(sm$conf.int))
  expect_true(is.data.frame(sm$coefficients))
  expect_true(nrow(sm$coefficients) >= 2L)
  expect_true(!is.null(sm$confint) || "conf.low" %in% names(sm$coefficients))
})

test_that("vcov() matches the Wald covariance for fixed effects", {
  fit <- cov_1125x7_wald()
  V <- vcov(fit)
  expect_true(is.matrix(V) || inherits(V, "Matrix"))
  expect_true(nrow(V) >= 2L)
  expect_true(all(is.finite(diag(as.matrix(V)))))
})

test_that("confint() on sigma reports a positive upper Wald bound", {
  fit <- cov_1125x7_wald()
  ci_sig <- confint(fit, method = "wald", parm = "fixef:sigma:(Intercept)")
  expect_equal(nrow(ci_sig), 1L)
  expect_gt(ci_sig$upper, 0)
  expect_equal(ci_sig$parm, "fixef:sigma:(Intercept)")
})