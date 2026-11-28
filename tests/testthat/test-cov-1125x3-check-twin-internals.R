# Coverage for convergence twin helpers in R/check.R.

test_that("drm_julia_optimizer_ok() checks Julia convergence and logLik", {
  ok <- drmTMB:::drm_julia_optimizer_ok
  expect_true(ok(list(opt = list(convergence = 0L), logLik = -1.2)))
  expect_false(ok(list(opt = list(convergence = 1L), logLik = -1.2)))
  expect_false(ok(list(opt = list(convergence = 0L), logLik = Inf)))
  expect_false(ok(list(opt = list(convergence = 0L), logLik = NA)))
})

test_that("drm_julia_bridge_degenerate() reads bridge convergence_status", {
  g <- drmTMB:::drm_julia_bridge_degenerate
  expect_true(g(list(bridge = list(convergence_status = "degenerate"))))
  expect_false(g(list(bridge = list(convergence_status = "converged"))))
  expect_false(g(list(bridge = list())))
})

test_that("drm_standard_errors_from_vcov() handles empty and valid matrices", {
  f <- drmTMB:::drm_standard_errors_from_vcov
  expect_identical(f(NULL), numeric())
  expect_identical(f(matrix(0, 0, 0)), numeric())
  v <- matrix(c(0.04, 0, 0, 0.09), 2)
  expect_equal(f(v), c(0.2, 0.3), tolerance = 1e-12)
  se_neg <- f(diag(c(0.04, -0.01)))
  expect_length(se_neg, 2L)
  expect_true(is.na(se_neg[[2L]]))
})

test_that("drm_twin_vcov_positive_definite() and inflated SE screen", {
  expect_false(drmTMB:::drm_twin_vcov_positive_definite(NULL))
  expect_false(drmTMB:::drm_twin_vcov_positive_definite(matrix(c(1, 2, 2, 1), 2)))
  expect_true(drmTMB:::drm_twin_vcov_positive_definite(diag(2)))
  infl <- drmTMB:::drm_twin_inflated_se_is_true(c(0.01, 0.02, 50, 0.03))
  expect_true(infl)
  expect_false(drmTMB:::drm_twin_inflated_se_is_true(c(0.01, 0.02, 0.03)))
  expect_false(drmTMB:::drm_twin_inflated_se_is_true(c(NA, NA)))
})

test_that("drm_twin_convergence_status_from_parts() classifies degenerate states", {
  f <- drmTMB:::drm_twin_convergence_status_from_parts
  vc <- diag(2)
  expect_identical(
    f(TRUE, -10, vc, FALSE, FALSE, numeric(), numeric()),
    "converged"
  )
  expect_identical(
    f(FALSE, -10, vc, FALSE, FALSE, numeric(), numeric()),
    "degenerate"
  )
  expect_identical(
    f(TRUE, -1e20, vc, FALSE, FALSE, numeric(), numeric()),
    "degenerate"
  )
  expect_identical(
    f(TRUE, -10, vc, FALSE, TRUE, numeric(), numeric()),
    "degenerate"
  )
  expect_identical(
    f(TRUE, -10, vc, TRUE, FALSE, numeric(), numeric()),
    "degenerate"
  )
})

test_that("validate_check_scalar() and optimizer count helpers", {
  expect_invisible(drmTMB:::validate_check_scalar(0.5, "x", 0, 1))
  expect_error(drmTMB:::validate_check_scalar(NA, "x"), "finite numeric scalar")
  expect_error(drmTMB:::validate_check_scalar(1, "x", 0, 1), "finite numeric scalar")
  expect_identical(drmTMB:::format_optimizer_count(12), "12")
  expect_identical(drmTMB:::format_optimizer_count(NA), "NA")
  expect_identical(drmTMB:::format_optimizer_count(c(1, 2)), "NA")
  expect_identical(drmTMB:::optimizer_evaluation_count(list(`function` = 3), "function"), 3)
  expect_true(is.na(drmTMB:::optimizer_evaluation_count(NULL, "function")))
  expect_identical(drmTMB:::optimizer_budget_limit(list(iter.max = 400), "iter.max"), 400)
  expect_true(drmTMB:::optimizer_budget_reached(400, 400))
  expect_false(drmTMB:::optimizer_budget_reached(10, 400))
})