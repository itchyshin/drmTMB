# Accessor guards in R/coevolution-accessors.R (no q4 fit required).

test_that("coevolution accessors refuse an ordinary univariate Gaussian fit", {
  set.seed(3)
  dat <- data.frame(y = rnorm(10), x = rnorm(10))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat,
                control = drm_control(se = FALSE))
  expect_error(coevolution_cor(fit), "q = 4")
  expect_error(coevolution_vc(fit), "q = 4")
  expect_error(coevolution_summary(fit), "q = 4")
})

test_that("drm_coevolution_refuse() formats optional detail", {
  expect_error(
    drmTMB:::drm_coevolution_refuse("custom detail text"),
    "custom detail"
  )
})