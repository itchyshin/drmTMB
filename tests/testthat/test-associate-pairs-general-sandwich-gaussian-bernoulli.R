gaussian_bernoulli_sandwich_fixture <- function(
  n = 96L,
  eta = 0.35,
  seed = 20260725
) {
  set.seed(seed)
  x <- seq(-1, 1, length.out = n)
  gaussian_sigma <- 0.75
  z_g <- stats::rnorm(n)
  z_b <- eta * z_g + sqrt(1 - eta^2) * stats::rnorm(n)
  binary_p <- stats::plogis(-0.2 + 0.35 * x)
  dat <- data.frame(
    x = x,
    gaussian_y = 0.3 + 0.5 * x + gaussian_sigma * z_g,
    binary_y = as.integer(z_b > stats::qnorm(binary_p, lower.tail = FALSE))
  )
  gaussian_fit <- drmTMB(
    bf(mu = gaussian_y ~ x, sigma = ~1), gaussian(), dat
  )
  binary_fit <- drmTMB(bf(mu = binary_y ~ x), binomial(), dat)
  association_fit <- associate_pairs(
    gaussian_fit, binary_fit, kernel = latent_normal(), association = ~1
  )
  list(
    gaussian_fit = gaussian_fit,
    binary_fit = binary_fit,
    association_fit = association_fit
  )
}

gaussian_bernoulli_sandwich_oracle_logprob <- function(q, gaussian_y, binary_y) {
  a <- q[[1L]]
  m <- q[[2L]]
  tau <- q[[3L]]
  lambda <- q[[4L]]
  sigma <- exp(tau)
  p <- stats::plogis(lambda)
  eta <- 0.999999 * tanh(a)
  z_g <- (gaussian_y - m) / sigma
  threshold <- stats::qnorm(p, lower.tail = FALSE)
  limits <- if (binary_y == 1L) c(threshold, Inf) else c(-Inf, threshold)
  bivariate_density <- function(z_b) {
    exp(
      -(z_g^2 - 2 * eta * z_g * z_b + z_b^2) /
        (2 * (1 - eta^2))
    ) / (2 * pi * sqrt(1 - eta^2))
  }
  log(stats::dnorm(gaussian_y, m, sigma)) - log(stats::dnorm(z_g)) +
    log(stats::integrate(bivariate_density, limits[[1L]], limits[[2L]])$value)
}

test_that("Gaussian x Bernoulli analytic margin scores and bread match derivatives", {
  y_g <- 0.9
  y_b <- 1L
  q <- c(m = 0.2, tau = log(0.8), lambda = -0.35)
  margin_loglik <- function(x) {
    stats::dnorm(y_g, x[[1L]], exp(x[[2L]]), log = TRUE) +
      stats::dbinom(y_b, 1L, stats::plogis(x[[3L]]), log = TRUE)
  }
  block <- drmTMB:::drm_pair_gaussian_bernoulli_sandwich_margin_blocks(
    gaussian_y = y_g,
    binary_y = y_b,
    gaussian_mu = q[[1L]],
    gaussian_sigma = exp(q[[2L]]),
    binary_p = stats::plogis(q[[3L]]),
    x_g = matrix(1),
    z_g = matrix(1),
    x_b = matrix(1)
  )
  score <- c(block$score_g_mu, block$score_g_sigma, block$score_b)
  bread <- rbind(
    cbind(block$bread_g_mm, block$bread_g_ms, 0),
    cbind(block$bread_g_ms, block$bread_g_ss, 0),
    cbind(0, 0, block$bread_b)
  )
  expect_equal(score, numDeriv::grad(margin_loglik, q), tolerance = 1e-7)
  expect_equal(bread, -numDeriv::hessian(margin_loglik, q), tolerance = 2e-5)
})

test_that("Gaussian x Bernoulli row kernel and mixed derivatives match an independent oracle", {
  q <- c(a = 0.28, m = -0.15, tau = log(0.75), lambda = 0.35)
  production <- function(x) {
    drmTMB:::drm_pair_gaussian_bernoulli_sandwich_row_logprob(
      gaussian_y = 0.6,
      binary_y = 1L,
      m = x[[2L]],
      tau = x[[3L]],
      lambda = x[[4L]],
      a = x[[1L]]
    )
  }
  oracle <- function(x) gaussian_bernoulli_sandwich_oracle_logprob(
    x, gaussian_y = 0.6, binary_y = 1L
  )
  production_derivatives <- drmTMB:::drm_pair_sandwich_derivatives(
    production, q, 1e-2
  )
  expect_equal(production_derivatives$gradient, numDeriv::grad(oracle, q),
    tolerance = 2e-4
  )
  expect_equal(production_derivatives$hessian, numDeriv::hessian(oracle, q),
    tolerance = 2e-3
  )
  expect_gt(max(abs(production_derivatives$hessian[1L, 2:4])), 1e-5)
})

test_that("Gaussian x Bernoulli row kernel factorizes at eta zero across interior signs", {
  a <- atanh(c(-0.55, 0, 0.55) / 0.999999)
  values <- vapply(a, function(a_i) {
    drmTMB:::drm_pair_gaussian_bernoulli_sandwich_row_logprob(
      gaussian_y = 0.4,
      binary_y = 1L,
      m = -0.1,
      tau = log(0.7),
      lambda = 0.25,
      a = a_i
    )
  }, numeric(1L))
  expect_true(all(is.finite(values)))
  expect_equal(
    values[[2L]],
    stats::dnorm(0.4, -0.1, 0.7, log = TRUE) +
      stats::dbinom(1L, 1L, stats::plogis(0.25), log = TRUE),
    tolerance = 1e-12
  )
})

test_that("Gaussian x Bernoulli adapter has canonical labels and swap-equivalent blocks", {
  fixture <- gaussian_bernoulli_sandwich_fixture()
  forward <- drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
    fixture$gaussian_fit, fixture$binary_fit, fixture$association_fit
  )
  routed <- drmTMB:::drm_pair_general_eta_sandwich(
    fixture$gaussian_fit, fixture$binary_fit, fixture$association_fit
  )
  reverse_association <- associate_pairs(
    fixture$binary_fit, fixture$gaussian_fit,
    kernel = latent_normal(), association = ~1
  )
  reverse <- drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
    fixture$binary_fit, fixture$gaussian_fit, reverse_association
  )
  expected_labels <- c(
    "gaussian_mu:(Intercept)", "gaussian_mu:x",
    "gaussian_sigma:(Intercept)",
    "bernoulli_mu:(Intercept)", "bernoulli_mu:x",
    "association:(Intercept)"
  )
  expect_identical(forward$status, "ok")
  expect_equal(routed$covariance, forward$covariance, tolerance = 1e-12)
  expect_identical(reverse$status, "ok")
  expect_identical(colnames(forward$covariance), expected_labels)
  expect_identical(colnames(reverse$covariance), expected_labels)
  expect_equal(forward$scores, reverse$scores, tolerance = 1e-11)
  expect_equal(forward$bread, reverse$bread, tolerance = 1e-10)
  expect_equal(forward$covariance, reverse$covariance, tolerance = 1e-9)
  expect_gt(max(abs(forward$bread[6L, 1:5])), 0)
  expect_equal(forward$meat, crossprod(forward$scores) / nrow(forward$scores),
    tolerance = 1e-12
  )
})

test_that("Gaussian x Bernoulli adapter fails closed and exposes valid public intervals", {
  fixture <- gaussian_bernoulli_sandwich_fixture()
  successful <- drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
    fixture$gaussian_fit, fixture$binary_fit, fixture$association_fit
  )
  expect_identical(successful$status, "ok")

  tampered_provenance <- fixture$association_fit
  tampered_provenance$provenance$data_hash <- "not-the-frozen-data-hash"
  expect_identical(
    drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
      fixture$gaussian_fit, fixture$binary_fit, tampered_provenance
    ),
    list(status = "unavailable", reason = "provenance_mismatch")
  )

  tampered_margin <- fixture$association_fit
  tampered_margin$components$gaussian_sigma[[1L]] <-
    tampered_margin$components$gaussian_sigma[[1L]] + 0.01
  expect_identical(
    drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
      fixture$gaussian_fit, fixture$binary_fit, tampered_margin
    ),
    list(status = "unavailable", reason = "frozen_margin_mismatch")
  )

  bounded <- fixture$association_fit
  bounded$association_coefficients[] <- 8
  expect_identical(
    drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
      fixture$gaussian_fit, fixture$binary_fit, bounded
    ),
    list(status = "unavailable", reason = "association_boundary")
  )

  expect_error(
    drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
      fixture$gaussian_fit, fixture$binary_fit, list()
    ),
    "Gaussian x literal-Bernoulli"
  )
  expect_warning(
    expect_true(all(is.finite(vcov(fixture$association_fit)))),
    class = "drmTMB_association_inference_warning"
  )
  expect_warning(
    expect_true(all(is.finite(confint(fixture$association_fit)))),
    class = "drmTMB_association_inference_warning"
  )
  unstable <- drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
    fixture$gaussian_fit, fixture$binary_fit, fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(),
      list(derivative_relative_tolerance = 0, derivative_absolute_tolerance = 0)
    )
  )
  expect_match(unstable$reason, "association_step_unstable")
  rank_failed <- drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
    fixture$gaussian_fit, fixture$binary_fit, fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(), list(rcond_min = 1)
    )
  )
  expect_identical(
    rank_failed,
    list(status = "unavailable", reason = "bread_or_meat_unstable")
  )
})
