test_that("drm_julia_joint_scalar_string requires one non-empty value", {
  expect_equal(drmTMB:::drm_julia_joint_scalar_string("ok", "label"), "ok")
  expect_error(
    drmTMB:::drm_julia_joint_scalar_string(character(0), "label"),
    "one non-empty string"
  )
  expect_error(
    drmTMB:::drm_julia_joint_scalar_string(NA_character_, "label"),
    "one non-empty string"
  )
})

test_that("drm_julia_joint_result_vector requires finite numerics", {
  expect_equal(drmTMB:::drm_julia_joint_result_vector(c(1, 2, 3), "theta"), c(1, 2, 3))
  expect_error(
    drmTMB:::drm_julia_joint_result_vector(c(1, Inf), "theta"),
    "finite numeric vector"
  )
  expect_error(
    drmTMB:::drm_julia_joint_result_vector(list(), "theta"),
    "finite numeric vector"
  )
})

test_that("drm_julia_joint_integer_ids rejects fractional row ids", {
  expect_equal(drmTMB:::drm_julia_joint_integer_ids(c(1, 2), "rows"), c(1L, 2L))
  expect_error(
    drmTMB:::drm_julia_joint_integer_ids(c(1.2, 2), "rows"),
    "finite integer row IDs"
  )
})

test_that("drm_julia_joint_mask accepts logical and 0/1 numerics", {
  expect_equal(drmTMB:::drm_julia_joint_mask(c(TRUE, FALSE), "mask"), c(TRUE, FALSE))
  expect_equal(drmTMB:::drm_julia_joint_mask(c(1, 0), "mask"), c(TRUE, FALSE))
  expect_error(drmTMB:::drm_julia_joint_mask(c(0.5, 1), "mask"), "TRUE/FALSE or 0/1")
  expect_error(drmTMB:::drm_julia_joint_mask(c(TRUE, NA), "mask"), "TRUE or FALSE")
})

test_that("drm_julia_joint_validate_raw_vcov enforces status contracts", {
  raw_names <- c("mu_intercept", "sigma_intercept")
  bad_status <- list(
    vcov = diag(2),
    vcov_names = raw_names,
    covariance_status = "not_a_status"
  )
  expect_error(
    drmTMB:::drm_julia_joint_validate_raw_vcov(bad_status, raw_names),
    "covariance_status is not recognized"
  )
  good <- list(
    vcov = diag(c(0.1, 0.2)),
    vcov_names = raw_names,
    covariance_status = "observed_information_inverse"
  )
  V <- drmTMB:::drm_julia_joint_validate_raw_vcov(good, raw_names)
  expect_equal(dim(V), c(2L, 2L))
})

test_that("drm_julia_joint_validate_result_rows enforces mask alignment", {
  payload <- list(
    schema = "joint_missing_v1",
    original_row = c(1L, 2L),
    observed_y = c(TRUE, TRUE),
    observed_x = c(TRUE, FALSE)
  )
  result <- list(
    original_row = c(2L, 1L),
    observed_y = c(TRUE, TRUE),
    observed_x = c(TRUE, FALSE)
  )
  expect_error(
    drmTMB:::drm_julia_joint_validate_result_rows(result, payload),
    "must exactly match"
  )
  ok <- list(
    original_row = c(1L, 2L),
    observed_y = c(TRUE, TRUE),
    observed_x = c(TRUE, FALSE)
  )
  rows <- drmTMB:::drm_julia_joint_validate_result_rows(ok, payload)
  expect_equal(rows$original_row, c(1L, 2L))
})