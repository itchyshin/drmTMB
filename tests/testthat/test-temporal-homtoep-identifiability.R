pkgload::load_all(".", compile = TRUE, quiet = TRUE)

source(testthat::test_path("helper-temporal-homtoep-reference.R"))
source(testthat::test_path("..", "..", "tools", "temporal-homtoep-map-study.R"))

test_that("free Toeplitz process and residual scales have an exact covariance ridge", {
  # With one response at each series--occasion, V = s^2 R + sigma^2 I has no
  # unique split between process scale, residual scale, and free correlations.
  # For c near one, s_new^2 = c s^2, rho_new[d] = rho[d] / c, and
  # sigma_new^2 = sigma^2 + (1 - c) s^2 leave every covariance entry unchanged.
  rho <- c(1, 0.55^(1:5))
  s <- 0.8
  sigma <- 0.4
  c_scale <- 1.1
  rho_new <- c(1, rho[-1L] / c_scale)
  expect_gt(min(eigen(stats::toeplitz(rho_new), symmetric = TRUE, only.values = TRUE)$values), 0)
  expect_equal(
    homtoep_pacf_from_rho(rho_new),
    tanh(homtoep_eta_from_rho(rho_new)),
    tolerance = 1e-11
  )

  id <- rep(c("a", "b"), each = 6L)
  occasion <- rep(0:5, 2L)
  V <- homtoep_dense_covariance(id, occasion, s, sigma, rho)
  V_new <- homtoep_dense_covariance(
    id, occasion, sqrt(c_scale) * s,
    sqrt(sigma^2 + (1 - c_scale) * s^2), rho_new
  )
  expect_equal(V_new, V, tolerance = 1e-12)

  y <- seq(-1, 1, length.out = length(id))
  X <- cbind(`(Intercept)` = 1, x = rep(c(-0.5, 0.5), length.out = length(id)))
  beta <- c(0.2, -0.3)
  expect_equal(
    homtoep_dense_gaussian_nll(y, X, beta, id, occasion, s, sigma, rho),
    homtoep_dense_gaussian_nll(
      y, X, beta, id, occasion, sqrt(c_scale) * s,
      sqrt(sigma^2 + (1 - c_scale) * s^2), rho_new
    ),
    tolerance = 1e-12
  )
})
