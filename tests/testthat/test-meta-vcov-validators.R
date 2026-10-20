# Characterisation tests for the internal validators behind
# meta_vcov_bivariate(). Pure functions; no fits.

vv <- function(...) drmTMB:::validate_meta_variance_vector(...)
vp <- function(...) drmTMB:::validate_meta_pair_vector(...)

test_that("validate_meta_variance_vector() returns valid input as plain doubles", {
  expect_identical(vv(c(0.04, 0.09), "v1"), c(0.04, 0.09))
  # zero is a documented valid variance (non-negative)
  expect_identical(vv(c(0, 1), "v1"), c(0, 1))
  # integers are coerced to double
  expect_identical(vv(1:3, "v1"), c(1, 2, 3))
  expect_type(vv(1L, "v1"), "double")
  # names are preserved
  expect_identical(vv(c(a = 1, b = 2), "v1"), c(a = 1, b = 2))
  # length-one and length-zero inputs pass the validator itself
  expect_identical(vv(0.5, "v1"), 0.5)
  expect_identical(vv(numeric(0), "v1"), numeric(0))
})

test_that("validate_meta_variance_vector() aborts on each invalid input", {
  expect_error(vv("a", "v1"), "numeric vector of known sampling variances")
  expect_error(vv(TRUE, "v1"), "numeric vector of known sampling variances")
  expect_error(vv(NULL, "v1"), "numeric vector of known sampling variances")
  expect_error(vv(matrix(1:4, 2), "v1"), "numeric vector of known sampling variances")
  expect_error(vv(array(1:8, c(2, 2, 2)), "v1"), "numeric vector of known sampling variances")
  expect_error(vv(c(1, NA), "v1"), "finite")
  expect_error(vv(c(1, NaN), "v1"), "finite")
  expect_error(vv(c(1, Inf), "v1"), "finite")
  expect_error(vv(c(1, -Inf), "v1"), "finite")
  expect_error(vv(c(1, -0.01), "v1"), "non-negative")
})

test_that("validate_meta_variance_vector() names the offending argument", {
  expect_error(vv(c(1, NA), "v2"), "v2")
  expect_error(vv("a", "myarg"), "myarg")
  expect_error(vv(-1, "v2"), "v2")
})

test_that("validate_meta_pair_vector() recycles length one and passes length n", {
  expect_identical(vp(0.3, "cov12", 3L), c(0.3, 0.3, 0.3))
  expect_identical(vp(c(0.1, -0.2, 0), "cov12", 3L), c(0.1, -0.2, 0))
  expect_identical(vp(1:2, "cov12", 2L), c(1, 2))
  expect_type(vp(1L, "cov12", 2L), "double")
  # negative and zero values are allowed here; sign checks live elsewhere
  expect_identical(vp(-5, "cov12", 1L), -5)
  # names are dropped by the recycling step
  expect_null(names(vp(c(a = 1, b = 2), "cov12", 2L)))
})

test_that("validate_meta_pair_vector() aborts on each invalid input", {
  expect_error(vp("a", "cov12", 2L), "must be a numeric vector")
  expect_error(vp(NULL, "cov12", 2L), "must be a numeric vector")
  expect_error(vp(matrix(1:4, 2), "cov12", 4L), "must be a numeric vector")
  expect_error(vp(c(1, 2, 3), "cov12", 2L), "length 1 or the same length")
  expect_error(vp(numeric(0), "cov12", 2L), "length 1 or the same length")
  expect_error(vp(c(1, NA), "cov12", 2L), "finite")
  expect_error(vp(c(1, NaN), "cov12", 2L), "finite")
  expect_error(vp(Inf, "cov12", 2L), "finite")
  expect_error(vp(c(1, 2), "cor12", 2L), NA)
  expect_error(vp(c(1, NA), "cor12", 2L), "cor12")
})

test_that("meta_vcov_bivariate() rejects non-numeric and non-finite variances", {
  expect_error(
    meta_vcov_bivariate(v1 = "a", v2 = 1),
    "numeric vector of known sampling variances"
  )
  expect_error(
    meta_vcov_bivariate(v1 = 1, v2 = matrix(1, 1, 1)),
    "numeric vector of known sampling variances"
  )
  expect_error(meta_vcov_bivariate(v1 = 1, v2 = Inf), "finite")
  expect_error(meta_vcov_bivariate(v1 = 1, v2 = -1), "non-negative")
  expect_error(
    meta_vcov_bivariate(v1 = numeric(0), v2 = numeric(0)),
    "at least one study"
  )
})

test_that("meta_vcov_bivariate() rejects bad cov12 / cor12 values", {
  expect_error(
    meta_vcov_bivariate(v1 = c(1, 1), v2 = c(1, 1), cov12 = c(0.1, NA)),
    "finite"
  )
  expect_error(
    meta_vcov_bivariate(v1 = c(1, 1), v2 = c(1, 1), cor12 = "a"),
    "numeric vector"
  )
  expect_error(
    meta_vcov_bivariate(v1 = c(1, 1), v2 = c(1, 1), cor12 = c(0.1, Inf)),
    "finite"
  )
  expect_error(
    meta_vcov_bivariate(v1 = c(1, 1), v2 = c(1, 1), cor12 = c(0.1, 1, 0.2)),
    "length 1"
  )
  expect_error(
    meta_vcov_bivariate(v1 = c(1, 1), v2 = c(1, 1), cor12 = c(0.1, -1.5)),
    "between -1 and 1"
  )
  # |cov12| above sqrt(v1 * v2), not just at it
  expect_error(
    meta_vcov_bivariate(v1 = 1, v2 = 4, cov12 = 2.5),
    "positive definite"
  )
  expect_error(
    meta_vcov_bivariate(v1 = 1, v2 = 4, cov12 = -2),
    "positive definite"
  )
  # zero variance with a non-zero covariance
  expect_error(
    meta_vcov_bivariate(v1 = 0, v2 = 4, cov12 = 0.5),
    "positive semidefinite"
  )
  expect_error(
    meta_vcov_bivariate(v1 = 1, v2 = 0, cor12 = 0.5),
    NA
  )
})

test_that("cor12 converts to cov12 = cor12 * sqrt(v1 * v2) per study", {
  v1 <- c(0.04, 0.09, 1.5)
  v2 <- c(0.25, 0.16, 0.2)
  cor12 <- c(-0.7, 0.3, 0.95)
  V <- meta_vcov_bivariate(v1 = v1, v2 = v2, cor12 = cor12)
  M <- unclass(V)

  expect_true(isSymmetric(M))
  expect_equal(dim(M), c(6L, 6L))
  i1 <- c(1L, 3L, 5L)
  i2 <- i1 + 1L
  expect_equal(M[cbind(i1, i1)], v1, tolerance = 1e-12)
  expect_equal(M[cbind(i2, i2)], v2, tolerance = 1e-12)
  expect_equal(M[cbind(i1, i2)], cor12 * sqrt(v1 * v2), tolerance = 1e-12)
  expect_equal(M[cbind(i2, i1)], cor12 * sqrt(v1 * v2), tolerance = 1e-12)
  # everything outside the 2x2 diagonal blocks is zero
  block <- matrix(FALSE, 6L, 6L)
  for (k in 1:3) block[c(i1[k], i2[k]), c(i1[k], i2[k])] <- TRUE
  expect_true(all(M[!block] == 0))
  # each block is positive definite
  expect_true(all(eigen(M, symmetric = TRUE, only.values = TRUE)$values > 0))
})

test_that("cov12 and the equivalent cor12 give the same matrix", {
  v1 <- c(0.04, 0.09)
  v2 <- c(0.25, 0.16)
  cor12 <- c(0.2, -0.4)
  expect_equal(
    unclass(meta_vcov_bivariate(v1, v2, cor12 = cor12)),
    unclass(meta_vcov_bivariate(v1, v2, cov12 = cor12 * sqrt(v1 * v2))),
    tolerance = 1e-12
  )
})

test_that("meta_vcov_bivariate() handles size-1 and size-2 inputs", {
  V1 <- meta_vcov_bivariate(v1 = 2, v2 = 3, cor12 = 0.5)
  expect_s3_class(V1, "drm_meta_vcov_bivariate")
  expect_equal(dim(V1), c(2L, 2L))
  expect_null(dimnames(V1))
  expect_equal(
    unclass(V1),
    matrix(c(2, 0.5 * sqrt(6), 0.5 * sqrt(6), 3), 2L),
    tolerance = 1e-12
  )

  V2 <- meta_vcov_bivariate(v1 = c(1, 2), v2 = c(3, 4), cov12 = 0.5)
  expect_equal(dim(V2), c(4L, 4L))
  expect_equal(V2[1, 2], 0.5)
  expect_equal(V2[3, 4], 0.5)
  expect_equal(V2[1:2, 3:4], matrix(0, 2L, 2L), ignore_attr = TRUE)

  # unnamed v1 falls back to the names of v2
  V3 <- meta_vcov_bivariate(v1 = c(1, 2), v2 = c(a = 3, b = 4))
  expect_identical(rownames(V3), c("a:y1", "a:y2", "b:y1", "b:y2"))
})

test_that("cov12 = 0 and cor12 = 0 give a block-diagonal matrix", {
  v1 <- c(0.04, 0.09, 0.5)
  v2 <- c(0.25, 0.16, 0.3)
  expected <- diag(as.vector(rbind(v1, v2)))
  expect_equal(
    unclass(meta_vcov_bivariate(v1, v2, cov12 = 0)),
    expected,
    tolerance = 1e-12
  )
  expect_equal(
    unclass(meta_vcov_bivariate(v1, v2, cor12 = 0)),
    expected,
    tolerance = 1e-12
  )
  expect_equal(
    unclass(meta_vcov_bivariate(v1, v2, cov12 = rep(0, 3))),
    expected,
    tolerance = 1e-12
  )
})
