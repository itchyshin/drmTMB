# Homogeneous Toeplitz helpers in R/temporal.R.

test_that("temporal_homtoep_correlations() returns unit lag-one correlation", {
  rho <- drmTMB:::temporal_homtoep_correlations(numeric())
  expect_equal(rho[[1L]], 1)
  expect_length(rho, 1L)
  rho2 <- drmTMB:::temporal_homtoep_correlations(0.5)
  expect_length(rho2, 2L)
  expect_equal(rho2[[1L]], 1)
  expect_true(is.finite(rho2[[2L]]))
  expect_gt(abs(rho2[[2L]]), 0)
  expect_lt(abs(rho2[[2L]]), 1)
})

test_that("temporal_homtoep_levinson() exposes ar and log_v", {
  out <- drmTMB:::temporal_homtoep_levinson(c(0.2, -0.1))
  expect_named(out, c("rho", "ar", "log_v"))
  expect_equal(length(out$rho), 3L)
  expect_equal(dim(out$ar), c(3L, 3L))
  expect_type(out$log_v, "double")
})

test_that("temporal_integer_gcd() reduces integers", {
  gcd <- drmTMB:::temporal_integer_gcd
  expect_equal(gcd(12L, 8L), 4L)
  expect_equal(gcd(7L, 13L), 1L)
  expect_equal(gcd(0L, 5L), 5L)
})

test_that("temporal_structure_name() labels structure field", {
  term <- list(structure = "homtoep")
  expect_equal(
    drmTMB:::temporal_structure_name(term),
    "Temporal HOMTOEP"
  )
  term2 <- list(structure = "ar1")
  expect_equal(drmTMB:::temporal_structure_name(term2), "Temporal AR1")
})