# objective_at() and heritability() on fitted RE models (R/objective-at.R, R/heritability.R).

cov_1125x7_h2 <- function() {
  set.seed(112580)
  dat <- data.frame(
    y = stats::rnorm(24),
    x = stats::rnorm(24),
    g = rep(letters[1:3], length.out = 24)
  )
  drmTMB(
    bf(y ~ x + (1 | g), sigma ~ 1),
    data = dat,
    control = drm_control(se = TRUE, keep_tmb_object = TRUE)
  )
}

test_that("objective_at() matches -logLik() at the fitted optimum", {
  fit <- cov_1125x7_h2()
  at <- list("fixef:mu:(Intercept)" = unname(coef(fit)$mu[1]))
  val <- objective_at(fit, at = at)
  expect_equal(val, -as.numeric(logLik(fit)), tolerance = 1e-6)
})

test_that("objective_at() moves when a fixed effect is perturbed", {
  fit <- cov_1125x7_h2()
  base <- objective_at(fit, at = list("fixef:mu:(Intercept)" = unname(coef(fit)$mu[1])))
  off <- objective_at(fit, at = list("fixef:mu:(Intercept)" = unname(coef(fit)$mu[1]) + 1))
  expect_gt(off, base)
})

test_that("heritability(), icc(), and repeatability() return drm_heritability tables", {
  fit <- cov_1125x7_h2()
  h2 <- heritability(fit)
  icc_val <- icc(fit)
  rep_val <- repeatability(fit)
  expect_s3_class(h2, "drm_heritability")
  expect_s3_class(icc_val, "drm_heritability")
  expect_s3_class(rep_val, "drm_heritability")
  expect_true(all(c("estimate", "component") %in% names(h2)))
  expect_true(is.finite(h2$estimate))
  expect_true(is.finite(icc_val$estimate))
  expect_true(is.finite(rep_val$estimate))
  expect_equal(nrow(h2), 1L)
})

test_that("random-effect scale objective_at uses the natural sd scale", {
  fit <- cov_1125x7_h2()
  at_sd <- list("sd:mu:(1 | g)" = 0.05)
  val <- objective_at(fit, at = at_sd)
  expect_true(is.finite(val))
  expect_gt(val, -as.numeric(logLik(fit)))
})