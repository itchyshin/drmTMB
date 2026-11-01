# The map-study helpers live in tools/, which .Rbuildignore keeps out of the
# built package, so this suite runs only from a source checkout.
source_homtoep_map_study <- function(env = parent.frame()) {
  path <- testthat::test_path("..", "..", "tools", "temporal-homtoep-map-study.R")
  testthat::skip_if_not(
    file.exists(path),
    "tools/temporal-homtoep-map-study.R is not in the built package"
  )
  sys.source(path, envir = env)
}

test_that("reflection-coefficient map yields positive-definite Toeplitz matrices", {
  source_homtoep_map_study()

  set.seed(20260910)
  for (K in 1:12) {
    for (draw in seq_len(40)) {
      eta <- if (K == 1L) numeric() else rnorm(K - 1L, sd = 1.5)
      R <- homtoep_reflection_cor(eta, K)
      expect_equal(R, t(R), tolerance = 1e-13)
      expect_equal(diag(R), rep(1, K), tolerance = 1e-13)
      expect_gt(min(eigen(R, symmetric = TRUE, only.values = TRUE)$values), 1e-13)
    }
  }
})

test_that("reflection map reconstructs its partial autocorrelations", {
  source_homtoep_map_study()

  eta <- c(-1.3, 0.2, 1.1, -0.7, 0.4)
  rho <- homtoep_reflection_rho(eta)
  expect_equal(homtoep_pacf_from_rho(rho), tanh(eta), tolerance = 1e-11)
  expect_equal(homtoep_eta_from_rho(rho), eta, tolerance = 1e-13)
})

test_that("reflection map has stable numerical derivatives and agrees with dense lag construction", {
  source_homtoep_map_study()

  eta <- c(-0.8, 0.3, 1.0, -0.2)
  d_small <- homtoep_map_jacobian(eta, step = 1e-6)
  d_large <- homtoep_map_jacobian(eta, step = 1e-5)
  expect_true(all(is.finite(d_small)))
  expect_lt(max(abs(d_small - d_large)), 1e-4)

  R <- homtoep_reflection_cor(eta)
  rho <- homtoep_reflection_rho(eta)
  expect_equal(R, homtoep_dense_from_lags(rho), tolerance = 1e-13)
  expect_equal(R, stats::toeplitz(rho), tolerance = 1e-13)
})

test_that("rejected maps demonstrate the two required failures", {
  source_homtoep_map_study()

  # Independently bounded lags can form an indefinite Toeplitz matrix.
  lagwise <- homtoep_lagwise_squash_cor(c(1.5, -1.5), K = 3)
  expect_lt(min(eigen(lagwise, symmetric = TRUE, only.values = TRUE)$values), 0)

  # An unconstrained Cholesky map gives a correlation matrix, but not a Toeplitz one.
  generic <- homtoep_generic_cholesky_cor(seq(-0.4, 0.6, length.out = 10), K = 4)
  expect_gt(homtoep_toeplitz_deviation(generic), 1e-3)
})
