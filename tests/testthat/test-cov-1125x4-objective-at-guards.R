# Argument guards in R/objective-at.R (no TMB object required).

test_that("drm_objective_at_validate_at() requires a named list", {
  f <- drmTMB:::drm_objective_at_validate_at
  expect_error(f(list()), "non-empty named list")
  expect_error(f(c(a = 1)), "named list")
  un <- structure(1, names = "")
  expect_error(f(list(un)), "name every element")
  expect_error(f(list("fixef:mu:x" = c(1, 2))), "single finite")
  expect_error(f(list("fixef:mu:x" = NA_real_)), "single finite")
})

test_that("drm_objective_at_validate_at() accepts a valid point", {
  at <- list("fixef:mu:(Intercept)" = 0.2, "fixef:mu:x" = -0.1)
  expect_identical(drmTMB:::drm_objective_at_validate_at(at), at)
})

test_that("objective_at.drmTMB refuses missing TMB object", {
  fit <- structure(list(model = list(), class = "drmTMB"), class = "drmTMB")
  expect_error(
    objective_at(fit, list("fixef:mu:(Intercept)" = 0)),
    "fit\\$obj"
  )
})

test_that("objective_at.drmTMB refuses MSPL fits", {
  fit <- structure(
    list(estimator = "MSPL", obj = list(), opt = list(par = 1), model = list()),
    class = "drmTMB"
  )
  expect_error(
    objective_at(fit, list("fixef:mu:(Intercept)" = 0)),
    class = "drmTMB_mspl_inference_unsupported"
  )
})