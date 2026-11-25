# Dimnames and correlation paths in R/meta-vcov.R.

test_that("meta_vcov_bivariate() keeps study names on the stacked matrix", {
  V <- meta_vcov_bivariate(
    v1 = c(studyA = 0.04, studyB = 0.09),
    v2 = c(studyA = 0.05, studyB = 0.02),
    cor12 = c(0.2, -0.1)
  )
  expect_s3_class(V, "drm_meta_vcov_bivariate")
  expect_identical(dim(V), c(4L, 4L))
  rn <- rownames(V)
  expect_true(all(c("studyA:y1", "studyA:y2", "studyB:y1", "studyB:y2") %in% rn))
  expect_equal(V[1, 1], 0.04, tolerance = 1e-15)
  expect_equal(V[2, 2], 0.05, tolerance = 1e-15)
})

test_that("meta_vcov_bivariate() builds covariance from cor12", {
  V <- meta_vcov_bivariate(v1 = 1, v2 = 4, cor12 = 0.5)
  expect_equal(V[1, 2], 1, tolerance = 1e-12)
  expect_equal(V[2, 1], 1, tolerance = 1e-12)
})

test_that("meta_vcov_bivariate() rejects singular sampling blocks", {
  expect_error(
    meta_vcov_bivariate(v1 = 1, v2 = 1, cor12 = 1),
    "positive definite"
  )
  expect_error(
    meta_vcov_bivariate(v1 = 0, v2 = 1, cov12 = 0.5),
    "zero sampling variance"
  )
})