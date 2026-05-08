test_that("meta_vcov_bivariate() builds row-paired covariance blocks", {
  V <- meta_vcov_bivariate(
    v1 = c(study_a = 0.04, study_b = 0.03),
    v2 = c(study_a = 0.05, study_b = 0.02),
    cov12 = c(0.01, -0.005)
  )

  expect_s3_class(V, "drm_meta_vcov_bivariate")
  expect_equal(dim(V), c(4L, 4L))
  expect_equal(
    unclass(V),
    matrix(
      c(
        0.04, 0.01, 0, 0,
        0.01, 0.05, 0, 0,
        0, 0, 0.03, -0.005,
        0, 0, -0.005, 0.02
      ),
      nrow = 4L,
      byrow = TRUE,
      dimnames = list(
        c("study_a:y1", "study_a:y2", "study_b:y1", "study_b:y2"),
        c("study_a:y1", "study_a:y2", "study_b:y1", "study_b:y2")
      )
    )
  )
})

test_that("meta_vcov_bivariate() computes covariance from sampling correlations", {
  V <- meta_vcov_bivariate(
    v1 = c(0.04, 0.09),
    v2 = c(0.25, 0.16),
    cor12 = 0.5
  )

  expect_equal(V[1, 2], 0.5 * sqrt(0.04 * 0.25))
  expect_equal(V[3, 4], 0.5 * sqrt(0.09 * 0.16))
  expect_equal(V[2, 1], V[1, 2])
  expect_equal(V[4, 3], V[3, 4])
})

test_that("meta_vcov_bivariate() defaults to independent sampling errors", {
  V <- meta_vcov_bivariate(v1 = c(0.04, 0.09), v2 = c(0.25, 0.16))

  expect_equal(diag(V), c(0.04, 0.25, 0.09, 0.16))
  expect_equal(V[1, 2], 0)
  expect_equal(V[3, 4], 0)
})

test_that("meta_vcov_bivariate() rejects malformed covariance inputs", {
  expect_error(
    meta_vcov_bivariate(v1 = c(0.04, 0.09), v2 = 0.25),
    "same length"
  )
  expect_error(
    meta_vcov_bivariate(v1 = c(0.04, NA), v2 = c(0.25, 0.16)),
    "finite"
  )
  expect_error(
    meta_vcov_bivariate(v1 = c(0.04, -0.09), v2 = c(0.25, 0.16)),
    "non-negative"
  )
  expect_error(
    meta_vcov_bivariate(
      v1 = c(0.04, 0.09),
      v2 = c(0.25, 0.16),
      cov12 = 0,
      cor12 = 0
    ),
    "only one"
  )
  expect_error(
    meta_vcov_bivariate(
      v1 = c(0.04, 0.09),
      v2 = c(0.25, 0.16),
      cov12 = c(0.01, 0.02, 0.03)
    ),
    "length 1"
  )
  expect_error(
    meta_vcov_bivariate(
      v1 = c(0.04, 0.09),
      v2 = c(0.25, 0.16),
      cor12 = 1.2
    ),
    "between -1 and 1"
  )
  expect_error(
    meta_vcov_bivariate(
      v1 = c(0.04, 0.09),
      v2 = c(0.25, 0.16),
      cov12 = c(0.2, 0)
    ),
    "positive semidefinite"
  )
})
