# AICC helper edges in R/model-comparison.R.

tiny_gauss <- function(formula) {
  set.seed(99)
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  drmTMB(formula, family = gaussian(), data = dat, control = drm_control(se = FALSE))
}

test_that("drm_aicc_from_loglik() returns Inf for small samples", {
  val <- drmTMB:::drm_aicc_from_loglik(-5, k = 10, n = 10)
  expect_equal(val, Inf)
  finite <- drmTMB:::drm_aicc_from_loglik(-20, k = 2, n = 50)
  expect_true(is.finite(finite))
  expect_gt(finite, 40)
})

test_that("aicc() works on native drmTMB fits", {
  fit <- tiny_gauss(bf(y ~ x, sigma ~ 1))
  val <- aicc(fit)
  expect_type(val, "double")
  expect_true(is.finite(val))
})

test_that("drm_lrtest() returns a list with statistic, df, and p.value", {
  reduced <- tiny_gauss(bf(y ~ 1, sigma ~ 1))
  full <- tiny_gauss(bf(y ~ x, sigma ~ 1))
  t <- drm_lrtest(reduced, full)
  expect_equal(names(t), c("statistic", "df", "p.value"))
  expect_gt(t$df, 0)
  expect_true(t$p.value >= 0 && t$p.value <= 1)
})

test_that("drm_anova_vc_labels() flattens sdpars names", {
  fit <- list(sdpars = list(mu = c(`sd(g)` = 0.5)))
  labs <- drmTMB:::drm_anova_vc_labels(fit, "sdpars")
  expect_equal(labs, "mu:sd(g)")
  expect_equal(drmTMB:::drm_anova_vc_labels(list(sdpars = list()), "sdpars"), character())
})