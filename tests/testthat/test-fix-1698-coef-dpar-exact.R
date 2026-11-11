test_that("coef() and fixef() require an exact fitted dpar name (#1698)", {
  set.seed(1)
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(coef(fit, dpar = "s"), "exactly match")
  expect_error(coef(fit, dpar = "s"), "Did you mean")
  expect_error(coef(fit, dpar = "s"), "sigma")
  expect_error(fixef(fit, dpar = "s"), "exactly match")

  expect_identical(coef(fit, dpar = "sigma"), coef(fit, dpar = "sigma"))
  expect_identical(fixef(fit, dpar = "mu"), coef(fit, dpar = "mu"))
})

test_that("coef(), fixef(), and predict() agree on invalid dpar abbreviations", {
  set.seed(1)
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(coef(fit, dpar = "s"), "sigma")
  expect_error(fixef(fit, dpar = "s"), "sigma")
  expect_error(predict(fit, dpar = "s"), "sigma")
})
