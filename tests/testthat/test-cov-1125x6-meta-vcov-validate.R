# Vector validators in R/meta-vcov.R (beyond bivariate construction).

test_that("validate_meta_variance_vector() enforces named positive variances", {
  expect_equal(
    unname(drmTMB:::validate_meta_variance_vector(c(a = 1, b = 2), "v1")),
  
    c(1, 2)
  )
  expect_error(
    drmTMB:::validate_meta_variance_vector(c("a", "b"), "v1"),
    "numeric"
  )
  expect_error(
    drmTMB:::validate_meta_variance_vector(c(a = -1), "v1"),
    "non-negative"
  )
  expect_equal(unname(drmTMB:::validate_meta_variance_vector(c(a = 0), "v1")), 0)
})

test_that("validate_meta_pair_vector() matches variance length", {
  expect_equal(
    unname(drmTMB:::validate_meta_pair_vector(c(0.1, 0.2), "cor12", 2L)),
    c(0.1, 0.2)
  )
  expect_equal(
    unname(drmTMB:::validate_meta_pair_vector(c(0.1), "cor12", 2L)),
    c(0.1, 0.1)
  )
  expect_error(
    meta_vcov_bivariate(v1 = c(1, 1), v2 = c(1, 1), cor12 = c(1.1, 0)),
    "-1"
  )
})

test_that("meta_vcov_bivariate() names studies on stacked rows", {
  V <- meta_vcov_bivariate(
    v1 = c(A = 0.2, B = 0.3),
    v2 = c(A = 0.4, B = 0.5),
    cor12 = c(0, 0.1)
  )
  expect_match(rownames(V)[[1]], "A:y1")
  expect_equal(V[3, 3], 0.3, tolerance = 1e-15)
})