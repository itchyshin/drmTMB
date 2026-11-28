# R/gaussian-aggregation.R validation and aggregation algebra.

test_that("empty_gaussian_aggregation() returns the disabled template", {
  e <- drmTMB:::empty_gaussian_aggregation()
  expect_false(e$enabled)
  expect_identical(e$n_original, 0L)
  expect_identical(e$n_cells, 0L)
})

test_that("drm_validate_gaussian_aggregation_input() checks row alignment", {
  f <- drmTMB:::drm_validate_gaussian_aggregation_input
  X <- matrix(1, 3, 1)
  expect_error(f(numeric(), X, X, 1:3, 0, 0), "at least one")
  expect_error(f(1:3, matrix(1, 2, 1), X, 1:3, 0, 0), "matching row")
  expect_error(f(1:3, X, X, c(1, 2), 0, 0), "one value per")
  expect_invisible(f(1:3, X, X, rep(1, 3), rep(0, 3), rep(0, 3)))
})

test_that("drm_validate_gaussian_aggregation_weights() requires unit weights", {
  expect_invisible(drmTMB:::drm_validate_gaussian_aggregation_weights(rep(1, 4)))
  expect_error(
    drmTMB:::drm_validate_gaussian_aggregation_weights(c(1, 2)),
    "unit likelihood weights"
  )
})

test_that("drm_gaussian_aggregation() merges duplicate design rows", {
  y <- c(1, 1, 3, 3)
  X_mu <- cbind(1, c(0, 0, 1, 1))
  X_sigma <- matrix(1, 4, 1)
  agg <- drmTMB:::drm_gaussian_aggregation(y, X_mu, X_sigma)
  expect_true(agg$enabled)
  expect_identical(agg$n_original, 4L)
  expect_identical(agg$n_cells, 2L)
  expect_equal(agg$n, c(2, 2))
  expect_equal(agg$mean_y, c(1, 3))
})

test_that("drm_gaussian_aggregation_summary() labels cell counts", {
  agg <- drmTMB:::drm_gaussian_aggregation(
    y = c(0, 0, 2),
    X_mu = cbind(1, c(0, 0, 1)),
    X_sigma = matrix(1, 3, 1)
  )
  s <- drmTMB:::drm_gaussian_aggregation_summary(agg)
  expect_true(all(c("original_rows", "aggregation_cells", "compression_ratio") %in% names(s)))
  expect_gt(s$compression_ratio, 0)
})