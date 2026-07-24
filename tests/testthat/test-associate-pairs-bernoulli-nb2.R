bernoulli_nb2_oracle <- function(binary_y, binary_p, count_y, mu, sigma, eta) {
  size <- drmTMB:::drm_nbinom2_size(sigma)
  threshold <- stats::qnorm(1 - binary_p)
  lower_count <- if (count_y == 0L) -Inf else stats::qnorm(stats::pnbinom(
    count_y - 1L, size = size, mu = mu
  ))
  upper_count <- stats::qnorm(stats::pnbinom(count_y, size = size, mu = mu))
  lower <- c(if (binary_y == 0L) -Inf else threshold, lower_count)
  upper <- c(if (binary_y == 0L) threshold else Inf, upper_count)
  as.numeric(mvtnorm::pmvnorm(lower = lower, upper = upper,
    mean = c(0, 0), sigma = matrix(c(1, eta, eta, 1), 2, 2)))
}

test_that("Bernoulli x ordinary-NB2 descriptor is versioned and pair-private", {
  descriptor <- drmTMB:::drm_pair_descriptor("bernoulli_nbinom2")
  expect_s3_class(descriptor, "drm_pair_descriptor")
  expect_identical(descriptor$version, 1L)
  expect_identical(descriptor$pair_class, "bernoulli_nbinom2")
  expect_identical(descriptor$roles, c("bernoulli", "nbinom2"))
})

test_that("Bernoulli x ordinary-NB2 adapter freezes ML margins in either order", {
  set.seed(20260723)
  n <- 36L
  x <- stats::rnorm(n)
  z_binary <- stats::rnorm(n)
  z_count <- 0.35 * z_binary + sqrt(1 - 0.35^2) * stats::rnorm(n)
  data <- data.frame(x = x,
    binary = as.integer(z_binary > stats::qnorm(0.7)),
    count = drmTMB:::drm_pair_nbinom2_quantile_from_normal(
      z_count, exp(0.3 + 0.15 * x), rep(0.6, n)
    ))
  binary_fit <- drmTMB(bf(mu = binary ~ x), binomial(), data)
  count_fit <- drmTMB(bf(mu = count ~ x, sigma = ~1), nbinom2(), data)
  forward <- associate_pairs(binary_fit, count_fit,
    kernel = latent_normal(), association = ~1)
  reverse <- associate_pairs(count_fit, binary_fit,
    kernel = latent_normal(), association = ~1)
  expect_identical(forward$pair_descriptor$pair_class, "bernoulli_nbinom2")
  expect_identical(forward$pair_descriptor$roles, c("bernoulli", "nbinom2"))
  expect_equal(forward$components$binary_p, predict(binary_fit, dpar = "mu", type = "response"))
  expect_equal(forward$components$nbinom2_mu, predict(count_fit, dpar = "mu", type = "response"))
  expect_equal(forward$logLik, reverse$logLik, tolerance = 1e-7)
  expect_identical(names(fitted(reverse)), c("count", "binary"))
})

test_that("Bernoulli x ordinary-NB2 rectangles factorize and match an independent oracle", {
  skip_if_not_installed("mvtnorm")
  cases <- expand.grid(binary_y = 0:1, eta = c(-0.5, 0, 0.5))
  for (i in seq_len(nrow(cases))) {
    actual <- drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability(
      cases$binary_y[[i]], 0.23, 7L, 4.1, 0.55, cases$eta[[i]]
    )
    expect_identical(actual$status, "ok")
    oracle <- bernoulli_nb2_oracle(cases$binary_y[[i]], 0.23, 7L, 4.1, 0.55, cases$eta[[i]])
    expect_equal(actual$probability, oracle, tolerance = 2e-8)
  }
  factorized <- drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability(
    1L, 0.23, 7L, 4.1, 0.55, 0
  )
  expect_equal(factorized$probability,
    stats::dbinom(1, 1, 0.23) * stats::dnbinom(7, size = drmTMB:::drm_nbinom2_size(0.55), mu = 4.1),
    tolerance = 1e-14)
  expect_identical(factorized$branch, "factorized")
})

test_that("Bernoulli x ordinary-NB2 rectangles normalize and retain tail diagnostics", {
  probabilities <- outer(0:1, 0:80, Vectorize(function(binary_y, count_y) {
    drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability(
      binary_y, 0.18, count_y, 3.6, 0.7, 0.45
    )$probability
  }))
  remainder <- 1 - sum(probabilities)
  expect_gte(remainder, -1e-8)
  expect_lte(remainder, stats::pnbinom(80, size = drmTMB:::drm_nbinom2_size(0.7), mu = 3.6,
    lower.tail = FALSE) + 1e-8)

  rare_high <- drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability(
    1L, 0.04, 35L, 24, 0.25, 0.95
  )
  expect_identical(rare_high$status, "ok")
  expect_true(is.finite(rare_high$integration_error))
  expect_true(rare_high$branch %in% c("lower", "upper", "straddle"))
})

test_that("Bernoulli x ordinary-NB2 fails closed and simulates coupled latent normals", {
  bad <- drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability(
    0L, NaN, 0L, 2, 0.5, 0.2
  )
  expect_identical(bad$status, "invalid_input")
  expect_true(is.na(bad$probability))

  components <- list(pair_class = "bernoulli_nbinom2",
    descriptor = drmTMB:::drm_pair_descriptor("bernoulli_nbinom2"),
    binary_y = c(0L, 1L, 0L), binary_p = c(0.2, 0.5, 0.8),
    nbinom2_y = c(0L, 1L, 2L), nbinom2_mu = c(1, 2, 3),
    nbinom2_sigma = c(0.5, 0.5, 0.5))
  object <- structure(list(status = "interior", eta = 0, eta_internal = 0,
    components = components, margin_order = c(fit_1 = "bernoulli", fit_2 = "nbinom2"),
    response_names = c(fit_1 = "binary", fit_2 = "count")), class = "drm_pair_association")
  observed <- simulate(object, seed = 918)
  set.seed(918)
  expected <- data.frame(binary = as.integer(stats::rnorm(3) > stats::qnorm(1 - components$binary_p)))
  z_count <- stats::rnorm(3)
  expected$count <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(
    z_count, components$nbinom2_mu, components$nbinom2_sigma
  )
  expect_equal(observed, expected)
})
