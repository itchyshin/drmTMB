# Regression for drmTMB#1698: coef()/fixef() must not partial-match dpar names.

test_that("coef and fixef require exact dpar names like predict", {
  set.seed(1)
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  expect_error(coef(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
  expect_error(fixef(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
  expect_error(predict(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
  expect_identical(coef(fit, dpar = "sigma"), coef(fit, dpar = "sigma"))
  expect_equal(coef(fit, dpar = "sigma"), coef(fit, "sigma"))
})