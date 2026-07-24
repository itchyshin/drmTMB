bernoulli_nb2_oracle <- function(binary_y, binary_p, count_y, mu, sigma, eta) {
  size <- drmTMB:::drm_nbinom2_size(sigma)
  stable_quantile <- function(y) {
    log_cdf <- stats::pnbinom(y, size = size, mu = mu, log.p = TRUE)
    log_survival <- stats::pnbinom(
      y, size = size, mu = mu, lower.tail = FALSE, log.p = TRUE
    )
    if (log_cdf <= log(0.5)) {
      stats::qnorm(log_cdf, log.p = TRUE)
    } else {
      stats::qnorm(log_survival, lower.tail = FALSE, log.p = TRUE)
    }
  }
  threshold <- stats::qnorm(binary_p, lower.tail = FALSE)
  lower_count <- if (count_y == 0L) -Inf else stable_quantile(count_y - 1L)
  upper_count <- stable_quantile(count_y)
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
  expect_equal(forward$eta, reverse$eta, tolerance = 1e-7)
  expect_identical(forward$status, reverse$status)
  expect_identical(names(fitted(reverse)), c("count", "binary"))
  forward$status <- reverse$status <- "interior"
  forward$eta <- reverse$eta <- 0
  forward$eta_internal <- reverse$eta_internal <- 0
  forward_draw <- simulate(forward, seed = 71)
  reverse_draw <- simulate(reverse, seed = 71)
  expect_equal(forward_draw, reverse_draw[, names(forward_draw)])
  expect_named(forward$diagnostics$count_interval$row_numerics,
    c("row", "status", "integration_error", "relative_integration_error",
      "binary_threshold", "count_lower", "count_upper", "count_lower_tail",
      "count_upper_tail", "conditional_branch"))
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

  for (case in list(
    list(binary_y = 0L, binary_p = 0.23, count_y = 0L, mu = 4.1, sigma = 0.55, eta = -0.5),
    list(binary_y = 1L, binary_p = 0.04, count_y = 35L, mu = 24, sigma = 0.25, eta = 0.95)
  )) {
    actual <- do.call(
      drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability, unname(case)
    )
    oracle <- do.call(bernoulli_nb2_oracle, case)
    expect_identical(actual$status, "ok")
    expect_equal(actual$probability, oracle, tolerance = 2e-8)
  }
})

test_that("Bernoulli x ordinary-NB2 rectangles normalize and retain tail diagnostics", {
  probabilities <- outer(0:1, 0:40, Vectorize(function(binary_y, count_y) {
    drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability(
      binary_y, 0.18, count_y, 3.6, 0.7, 0.45
    )$probability
  }))
  remainder <- 1 - sum(probabilities)
  expect_gte(remainder, -1e-8)
  expect_lte(remainder, stats::pnbinom(40, size = drmTMB:::drm_nbinom2_size(0.7), mu = 3.6,
    lower.tail = FALSE) + 1e-8)

  rare_high <- drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability(
    1L, 0.04, 35L, 24, 0.25, 0.95
  )
  expect_identical(rare_high$status, "ok")
  expect_true(is.finite(rare_high$integration_error))
  expect_true(rare_high$integration_error <= max(
    rare_high$integration_abs_tol,
    rare_high$integration_rel_tol * rare_high$probability
  ))
  expect_true(rare_high$branch %in% c("lower", "upper", "straddle"))

  expect_true(is.finite(stats::qnorm(1e-12, lower.tail = FALSE)))
  rare_threshold <- drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability(
    1L, 1e-12, 0L, 0.15, 0.9, -0.5,
    integration_rel_tol = 1e-20, integration_abs_tol = 1e-30
  )
  expect_identical(rare_threshold$status, "integration_error_exceeds_tolerance")

  rejected <- drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability(
    1L, 0.04, 35L, 24, 0.25, 0.95,
    integration_rel_tol = 1e-20, integration_abs_tol = 1e-30
  )
  expect_identical(rejected$status, "integration_error_exceeds_tolerance")
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
  expected <- data.frame(binary = as.integer(stats::rnorm(3) > stats::qnorm(
    components$binary_p, lower.tail = FALSE
  )))
  z_count <- stats::rnorm(3)
  expected$count <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(
    z_count, components$nbinom2_mu, components$nbinom2_sigma
  )
  expect_equal(observed, expected)
})
