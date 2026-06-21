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

test_that("skew-normal TMB tail floor preserves ordinary log densities", {
  y <- seq(-2, 2, length.out = 9)
  exact <- skew_normal_log_density_reference(
    y = y,
    mu = 0.25,
    sigma = 0.8,
    nu = 1.4
  )
  floored <- skew_normal_log_density_tmb_floor_reference(
    y = y,
    mu = 0.25,
    sigma = 0.8,
    nu = 1.4
  )

  expect_equal(floored, exact, tolerance = 1e-12)
  expect_true(is.finite(skew_normal_log_density_tmb_floor_reference(
    y = 100,
    mu = 0,
    sigma = 1,
    nu = -10
  )))
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

test_that("skew-normal comparator scale map separates native and moment scales", {
  scale_map <- skew_normal_comparator_scale_map(
    mu = 0.4,
    sigma = 1.2,
    nu = -2.5
  )
  native <- scale_map$native_azzalini
  public <- scale_map$public_moment

  mean_shift <- public$alpha / sqrt(1 + public$alpha^2) * sqrt(2 / pi)

  expect_equal(native$alpha, public$alpha)
  expect_gt(native$omega, 0)
  expect_equal(
    native$xi + native$omega * mean_shift,
    public$mu,
    tolerance = 1e-12
  )
  expect_equal(
    native$omega * sqrt(1 - mean_shift^2),
    public$sigma,
    tolerance = 1e-12
  )

  comparator <- scale_map$comparators
  expect_equal(
    comparator$parameter_scale[comparator$comparator == "sn::dsn"],
    "native_azzalini"
  )
  expect_equal(
    comparator$parameter_scale[comparator$comparator == "RTMBdist::dskewnorm2"],
    "public_moment"
  )
  expect_false(
    comparator$comparable_density[comparator$comparator == "gamlss.dist::SN2"]
  )
  expect_equal(
    comparator$parameter_scale[comparator$comparator == "gamlss.dist::SN2"],
    "two_piece_not_azzalini"
  )
})

test_that("skew-normal native comparator density matches after scale conversion", {
  y <- seq(-2.5, 2.5, length.out = 11)
  scale_map <- skew_normal_comparator_scale_map(
    mu = -0.2,
    sigma = 0.9,
    nu = 1.7
  )
  native <- scale_map$native_azzalini
  z <- (y - native$xi) / native$omega
  native_log_density <- log(2) -
    log(native$omega) +
    dnorm(z, log = TRUE) +
    pnorm(native$alpha * z, log.p = TRUE)

  expect_equal(
    native_log_density,
    skew_normal_log_density_reference(y = y, mu = -0.2, sigma = 0.9, nu = 1.7),
    tolerance = 1e-12
  )
})

test_that("skew-normal density fixture matches the exported first slice", {
  expect_true(
    exists("skew_normal", envir = asNamespace("drmTMB"), inherits = FALSE)
  )
  expect_equal(unname(skew_normal()$links[["nu"]]), "identity")

  expect_error(
    skew_normal_public_to_native(mu = 0, sigma = 0, nu = 0),
    "sigma must be finite and positive",
    fixed = TRUE
  )
})
