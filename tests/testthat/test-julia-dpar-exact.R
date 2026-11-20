# Julia-bridge coef()/predict() must not partial-match dpar (refs #1724, #1698).

julia_stub_fit <- function() {
  structure(
    list(
      coefficients = list(mu = c("(Intercept)" = 0.1), sigma = c("(Intercept)" = 0)),
      formula = list(entries = list())
    ),
    class = "drmTMB_julia"
  )
}

test_that("coef.drmTMB_julia rejects abbreviated dpar names", {
  fit <- julia_stub_fit()
  expect_error(coef(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
  expect_equal(coef(fit, dpar = "sigma"), fit$coefficients$sigma)
})

test_that("coef.drmTMB_julia_joint rejects abbreviated dpar names", {
  fit <- structure(
    list(coefficients = list(mu = 1, sigma = 2)),
    class = c("drmTMB_julia_joint", "drmTMB_julia")
  )
  expect_error(coef(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
})

test_that("coef.drmTMB_julia_xfam rejects abbreviated dpar names", {
  fit <- structure(
    list(
      coefficients = list(mu1 = c(`(Intercept)` = 0)),
      sigma_coef = list(sigma1 = c(`(Intercept)` = 0))
    ),
    class = "drmTMB_julia_xfam"
  )
  expect_error(coef(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
  expect_error(coef(fit, dpar = "m"), class = "drmTMB_unknown_dpar")
})