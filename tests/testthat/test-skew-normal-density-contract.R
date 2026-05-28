test_that("skew-normal moment transform preserves public mean and sigma", {
  grid <- expand.grid(
    mu = c(-1, 0.25, 2),
    sigma = c(0.5, 1.4),
    nu = c(-3, 0, 2.5)
  )

  native <- skew_normal_public_to_native(
    mu = grid$mu,
    sigma = grid$sigma,
    nu = grid$nu
  )
  mean_shift <- native$delta * sqrt(2 / pi)
  native_mean <- native$xi + native$omega * mean_shift
  native_sd <- native$omega * sqrt(1 - mean_shift^2)

  expect_gt(min(native$omega), 0)
  expect_equal(native_mean, grid$mu, tolerance = 1e-12)
  expect_equal(native_sd, grid$sigma, tolerance = 1e-12)
})

test_that("skew-normal reference density integrates to one", {
  grid <- expand.grid(
    mu = c(-0.75, 0.5),
    sigma = c(0.6, 1.8),
    nu = c(-3, 0, 2.5)
  )

  integrals <- vapply(
    seq_len(nrow(grid)),
    function(i) {
      skew_normal_density_integral_reference(
        mu = grid$mu[[i]],
        sigma = grid$sigma[[i]],
        nu = grid$nu[[i]]
      )
    },
    numeric(1)
  )

  expect_equal(integrals, rep(1, nrow(grid)), tolerance = 1e-8)
})

test_that("skew-normal reference density has the Gaussian normal limit", {
  y <- seq(-4, 4, length.out = 17)
  mu <- 0.4
  sigma <- 1.3

  skew_log_density <- skew_normal_log_density_reference(
    y = y,
    mu = mu,
    sigma = sigma,
    nu = 0
  )
  gaussian_log_density <- dnorm(y, mean = mu, sd = sigma, log = TRUE)

  expect_equal(skew_log_density, gaussian_log_density, tolerance = 1e-12)
  expect_equal(
    -sum(skew_log_density),
    -sum(gaussian_log_density),
    tolerance = 1e-12
  )
})

test_that("skew-normal reference density records the public sign orientation", {
  nu <- c(-4, -1.5, 0, 1.5, 4)
  third_moment <- skew_normal_third_central_moment_reference(
    sigma = 1.2,
    nu = nu
  )

  expect_equal(sign(third_moment), sign(nu))

  mu <- 0.25
  sigma <- 1.1
  offsets <- c(-2, -0.7, 0, 0.7, 2)
  right_skew <- skew_normal_log_density_reference(
    y = mu + offsets,
    mu = mu,
    sigma = sigma,
    nu = 2
  )
  left_skew_mirror <- skew_normal_log_density_reference(
    y = mu - offsets,
    mu = mu,
    sigma = sigma,
    nu = -2
  )

  expect_equal(right_skew, left_skew_mirror, tolerance = 1e-12)
})

test_that("skew-normal density fixture remains test-only", {
  expect_false(
    exists("skew_normal", envir = asNamespace("drmTMB"), inherits = FALSE)
  )

  expect_error(
    skew_normal_public_to_native(mu = 0, sigma = 0, nu = 0),
    "sigma must be finite and positive",
    fixed = TRUE
  )
})
