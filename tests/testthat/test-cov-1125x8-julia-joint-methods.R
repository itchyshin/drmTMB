# Julia joint adapter helpers in R/julia-joint-methods.R and R/julia-joint-call.R.

test_that("drm_julia_joint_result_vector enforces finite numerics", {
  f <- drmTMB:::drm_julia_joint_result_vector
  expect_equal(f(1:3, "t"), c(1, 2, 3))
  expect_equal(f(list(a = 2, b = 3), "t"), c(2, 3))
  expect_error(f(numeric(0), "t"), "non-empty finite")
  expect_error(f(c(1, NA), "t"), "non-empty finite")
  expect_error(f(c(1, Inf), "t"), "non-empty finite")
})

test_that("drm_julia_joint_scalar_string and integer_ids validate types", {
  expect_equal(drmTMB:::drm_julia_joint_scalar_string("schema", "s"), "schema")
  expect_error(drmTMB:::drm_julia_joint_scalar_string("", "s"), "one non-empty")
  expect_error(drmTMB:::drm_julia_joint_scalar_string(c("a", "b"), "s"), "one non-empty")

  ids <- drmTMB:::drm_julia_joint_integer_ids(c(1, 2.0, 3), "row")
  expect_identical(ids, c(1L, 2L, 3L))
  expect_error(drmTMB:::drm_julia_joint_integer_ids(1.5, "row"), "integer row IDs")
  expect_error(drmTMB:::drm_julia_joint_integer_ids(NA, "row"), "integer row IDs")
})

test_that("drm_julia_joint_mask accepts logical or 0/1 numeric", {
  m <- drmTMB:::drm_julia_joint_mask
  expect_identical(m(c(TRUE, FALSE), "y"), c(TRUE, FALSE))
  expect_identical(m(c(1, 0, 1), "y"), c(TRUE, FALSE, TRUE))
  expect_error(m(c(NA, TRUE), "y"), "TRUE or FALSE")
  expect_error(m(c(2, 1), "y"), "0/1")
})

test_that("drm_julia_joint_validate_raw_vcov enforces PD observed information", {
  raw_names <- c("b_mu", "b_sigma")
  good <- list(
    coefficients = c(0, 0),
    vcov = matrix(c(2, 0.1, 0.1, 2), 2),
    vcov_names = raw_names,
    covariance_status = "observed_information_inverse"
  )
  V <- drmTMB:::drm_julia_joint_validate_raw_vcov(good, raw_names)
  expect_equal(dim(V), c(2L, 2L))
  expect_true(all(is.finite(V)))

  bad_status <- good
  bad_status$covariance_status <- "unknown"
  expect_error(
    drmTMB:::drm_julia_joint_validate_raw_vcov(bad_status, raw_names),
    "not recognized"
  )

  bad_names <- good
  bad_names$vcov_names <- c("a", "b")
  expect_error(
    drmTMB:::drm_julia_joint_validate_raw_vcov(bad_names, raw_names),
    "exactly match"
  )

  pd_fail <- good
  pd_fail$vcov <- matrix(c(1, 2, 2, 1), 2)
  expect_error(
    drmTMB:::drm_julia_joint_validate_raw_vcov(pd_fail, raw_names),
    "positive definite"
  )
})

test_that("drm_julia_joint_validate_result_rows matches payload masks", {
  payload <- list(
    schema = "joint_missing_v1",
    original_row = c(1L, 2L),
    observed_y = c(TRUE, FALSE),
    observed_x = c(TRUE, TRUE)
  )
  result <- list(
    original_row = c(1L, 2L),
    observed_y = c(TRUE, FALSE),
    observed_x = c(TRUE, TRUE)
  )
  rows <- drmTMB:::drm_julia_joint_validate_result_rows(result, payload)
  expect_identical(rows$original_row, payload$original_row)
  expect_identical(rows$observed_y, payload$observed_y)

  bad <- result
  bad$observed_x <- c(TRUE, FALSE)
  expect_error(
    drmTMB:::drm_julia_joint_validate_result_rows(bad, payload),
    "exactly match"
  )
})

test_that("drm_julia_require_joint_capability aborts when bridge missing", {
  expect_error(
    drmTMB:::drm_julia_require_joint_capability(available = FALSE),
    "drm_bridge_joint"
  )
  expect_invisible(drmTMB:::drm_julia_require_joint_capability(available = TRUE))
})

test_that("drm_julia_call_joint refuses without JuliaCall installed", {
  skip_if(requireNamespace("JuliaCall", quietly = TRUE), "JuliaCall present; install guard not testable")
  expect_error(drmTMB:::drm_julia_call_joint(list(schema = "x")), "JuliaCall")
})