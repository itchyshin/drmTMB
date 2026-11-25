# R/objective-at.R label validation (no TMB evaluation).

test_that("drm_objective_at_validate_at() enforces named scalar finite values", {
  f <- drmTMB:::drm_objective_at_validate_at
  ok <- f(list("fixef:mu:(Intercept)" = 0.1, "fixef:mu:x" = -0.2))
  expect_identical(ok, list("fixef:mu:(Intercept)" = 0.1, "fixef:mu:x" = -0.2))
  expect_error(f(list()), "non-empty named list")
  expect_error(f(c(a = 1)), "named list")
  expect_error(f(data.frame(a = 1)), "named list")
  arbitrary <- f(list(any_label = 0.5))
  expect_identical(arbitrary, list(any_label = 0.5))
  expect_error(f(list("fixef:mu:(Intercept)" = c(1, 2))), "single finite")
  expect_error(f(list("fixef:mu:(Intercept)" = NA_real_)), "single finite")
  expect_error(f(list("fixef:mu:(Intercept)" = Inf)), "single finite")
  empty_name <- list(1)
  names(empty_name) <- ""
  expect_error(f(empty_name), "name every element")
})