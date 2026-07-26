gaussian_nbinom2_sandwich_fixture <- function(
  n = 132L,
  eta = 0.32,
  seed = 20260725
) {
  set.seed(seed)
  x <- seq(-1, 1, length.out = n)
  z_g <- stats::rnorm(n)
  z_n <- eta * z_g + sqrt(1 - eta^2) * stats::rnorm(n)
  gaussian_sigma <- exp(-0.1 + 0.1 * x)
  nbinom2_mu <- exp(0.35 + 0.25 * x)
  nbinom2_sigma <- exp(-0.45 + 0.08 * x)
  dat <- data.frame(
    x = x,
    gaussian_y = 0.2 + 0.45 * x + gaussian_sigma * z_g,
    nbinom2_y = drmTMB:::drm_pair_nbinom2_quantile_from_normal(
      z_n, nbinom2_mu, nbinom2_sigma
    )
  )
  gaussian_fit <- drmTMB(
    bf(mu = gaussian_y ~ x, sigma = ~x), gaussian(), dat
  )
  nbinom2_fit <- drmTMB(
    bf(mu = nbinom2_y ~ x, sigma = ~x), nbinom2(), dat
  )
  association_fit <- associate_pairs(
    gaussian_fit, nbinom2_fit, kernel = latent_normal(), association = ~1
  )
  list(
    gaussian_fit = gaussian_fit,
    nbinom2_fit = nbinom2_fit,
    association_fit = association_fit
  )
}

# An independent bivariate-normal integral, deliberately not the package's
# CDF-jump helper, anchors the private one-row association derivatives.
gaussian_nbinom2_sandwich_oracle_logprob <- function(q, gaussian_y, nbinom2_y) {
  a <- q[[1L]]
  m <- q[[2L]]
  tau_g <- q[[3L]]
  xi_n <- q[[4L]]
  tau_n <- q[[5L]]
  sigma_g <- exp(tau_g)
  mu_n <- exp(xi_n)
  sigma_n <- exp(tau_n)
  eta <- 0.999999 * tanh(a)
  z_g <- (gaussian_y - m) / sigma_g
  size <- sigma_n^(-2)
  quantile <- function(log_cdf, log_survival) {
    if (log_cdf <= log(0.5)) {
      return(stats::qnorm(log_cdf, log.p = TRUE))
    }
    stats::qnorm(log_survival, lower.tail = FALSE, log.p = TRUE)
  }
  upper <- quantile(
    stats::pnbinom(nbinom2_y, size = size, mu = mu_n, log.p = TRUE),
    stats::pnbinom(
      nbinom2_y, size = size, mu = mu_n, lower.tail = FALSE, log.p = TRUE
    )
  )
  lower <- if (nbinom2_y == 0L) {
    -Inf
  } else {
    quantile(
      stats::pnbinom(nbinom2_y - 1L, size = size, mu = mu_n, log.p = TRUE),
      stats::pnbinom(
        nbinom2_y - 1L, size = size, mu = mu_n,
        lower.tail = FALSE, log.p = TRUE
      )
    )
  }
  bivariate_density <- function(z_n) {
    exp(
      -(z_g^2 - 2 * eta * z_g * z_n + z_n^2) /
        (2 * (1 - eta^2))
    ) / (2 * pi * sqrt(1 - eta^2))
  }
  log(stats::dnorm(gaussian_y, m, sigma_g)) - log(stats::dnorm(z_g)) +
    log(stats::integrate(bivariate_density, lower, upper)$value)
}

test_that("Gaussian x ordinary-NB2 analytic margin scores and bread match derivatives", {
  y_g <- 0.9
  y_n <- 7L
  q <- c(m = 0.2, tau_g = log(0.8), xi_n = 0.45, tau_n = log(0.55))
  margin_loglik <- function(x) {
    stats::dnorm(y_g, x[[1L]], exp(x[[2L]]), log = TRUE) +
      stats::dnbinom(
        y_n, size = exp(x[[4L]])^(-2), mu = exp(x[[3L]]), log = TRUE
      )
  }
  block <- drmTMB:::drm_pair_gaussian_nbinom2_sandwich_margin_blocks(
    gaussian_y = y_g,
    nbinom2_y = y_n,
    gaussian_mu = q[[1L]],
    gaussian_sigma = exp(q[[2L]]),
    nbinom2_mu = exp(q[[3L]]),
    nbinom2_sigma = exp(q[[4L]]),
    x_g = matrix(1),
    z_g = matrix(1),
    x_n = matrix(1),
    z_n = matrix(1)
  )
  score <- c(
    block$score_g_mu, block$score_g_sigma,
    block$score_n_mu, block$score_n_sigma
  )
  bread <- rbind(
    cbind(block$bread_g_mm, block$bread_g_ms, 0, 0),
    cbind(block$bread_g_ms, block$bread_g_ss, 0, 0),
    cbind(0, 0, block$bread_n_mm, block$bread_n_ms),
    cbind(0, 0, block$bread_n_ms, block$bread_n_ss)
  )
  expect_equal(score, numDeriv::grad(margin_loglik, q), tolerance = 1e-7)
  expect_equal(bread, -numDeriv::hessian(margin_loglik, q), tolerance = 2e-5)
})

test_that("Gaussian x ordinary-NB2 row kernel and mixed derivatives match an independent oracle", {
  q <- c(a = 0.28, m = -0.15, tau_g = log(0.75), xi_n = 0.35, tau_n = log(0.6))
  production <- function(x) {
    drmTMB:::drm_pair_gaussian_nbinom2_sandwich_row_logprob(
      gaussian_y = 0.6,
      nbinom2_y = 6L,
      m = x[[2L]],
      tau_g = x[[3L]],
      xi_n = x[[4L]],
      tau_n = x[[5L]],
      a = x[[1L]]
    )
  }
  oracle <- function(x) gaussian_nbinom2_sandwich_oracle_logprob(
    x, gaussian_y = 0.6, nbinom2_y = 6L
  )
  production_derivatives <- drmTMB:::drm_pair_sandwich_derivatives(
    production, q, 1e-2
  )
  expect_equal(production_derivatives$gradient, numDeriv::grad(oracle, q),
    tolerance = 5e-4
  )
  expect_equal(production_derivatives$hessian, numDeriv::hessian(oracle, q),
    tolerance = 5e-3
  )
  expect_gt(max(abs(production_derivatives$hessian[1L, 2:5])), 1e-5)
})

test_that("Gaussian x ordinary-NB2 row kernel factorizes at eta zero and stays finite in a tail", {
  a <- atanh(c(-0.55, 0, 0.55) / 0.999999)
  values <- vapply(a, function(a_i) {
    drmTMB:::drm_pair_gaussian_nbinom2_sandwich_row_logprob(
      gaussian_y = 0.4,
      nbinom2_y = 35L,
      m = -0.1,
      tau_g = log(0.7),
      xi_n = log(4.5),
      tau_n = log(0.7),
      a = a_i
    )
  }, numeric(1L))
  expect_true(all(is.finite(values)))
  expect_equal(
    values[[2L]],
    stats::dnorm(0.4, -0.1, 0.7, log = TRUE) +
      stats::dnbinom(35L, size = 0.7^(-2), mu = 4.5, log = TRUE),
    tolerance = 1e-10
  )
})

test_that("Gaussian x ordinary-NB2 adapter has canonical labels and swap-equivalent blocks", {
  fixture <- gaussian_nbinom2_sandwich_fixture()
  forward <- drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
    fixture$gaussian_fit, fixture$nbinom2_fit, fixture$association_fit
  )
  routed <- drmTMB:::drm_pair_general_eta_sandwich(
    fixture$gaussian_fit, fixture$nbinom2_fit, fixture$association_fit
  )
  reverse_association <- associate_pairs(
    fixture$nbinom2_fit, fixture$gaussian_fit,
    kernel = latent_normal(), association = ~1
  )
  reverse <- drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
    fixture$nbinom2_fit, fixture$gaussian_fit, reverse_association
  )
  expected_labels <- c(
    "gaussian_mu:(Intercept)", "gaussian_mu:x",
    "gaussian_sigma:(Intercept)", "gaussian_sigma:x",
    "nbinom2_mu:(Intercept)", "nbinom2_mu:x",
    "nbinom2_sigma:(Intercept)", "nbinom2_sigma:x",
    "association:(Intercept)"
  )
  expect_identical(forward$status, "ok")
  expect_equal(routed$covariance, forward$covariance, tolerance = 1e-12)
  expect_identical(reverse$status, "ok")
  expect_identical(colnames(forward$covariance), expected_labels)
  expect_identical(colnames(reverse$covariance), expected_labels)
  expect_equal(forward$scores, reverse$scores, tolerance = 1e-11)
  expect_equal(forward$bread, reverse$bread, tolerance = 1e-10)
  expect_equal(forward$covariance, reverse$covariance, tolerance = 1e-8)
  expect_gt(max(abs(forward$bread[9L, 1:8])), 0)
  expect_equal(forward$meat, crossprod(forward$scores) / nrow(forward$scores),
    tolerance = 1e-12
  )
})

test_that("Gaussian x ordinary-NB2 adapter fails closed and exposes no public output", {
  fixture <- gaussian_nbinom2_sandwich_fixture()
  successful <- drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
    fixture$gaussian_fit, fixture$nbinom2_fit, fixture$association_fit
  )
  expect_identical(successful$status, "ok")

  tampered_provenance <- fixture$association_fit
  tampered_provenance$provenance$data_hash <- "not-the-frozen-data-hash"
  expect_identical(
    drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
      fixture$gaussian_fit, fixture$nbinom2_fit, tampered_provenance
    ),
    list(status = "unavailable", reason = "provenance_mismatch")
  )

  tampered_margin <- fixture$association_fit
  tampered_margin$components$nbinom2_sigma[[1L]] <-
    tampered_margin$components$nbinom2_sigma[[1L]] + 0.01
  expect_identical(
    drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
      fixture$gaussian_fit, fixture$nbinom2_fit, tampered_margin
    ),
    list(status = "unavailable", reason = "frozen_margin_mismatch")
  )

  bounded <- fixture$association_fit
  bounded$association_coefficients[] <- 8
  expect_identical(
    drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
      fixture$gaussian_fit, fixture$nbinom2_fit, bounded
    ),
    list(status = "unavailable", reason = "association_boundary")
  )

  expect_error(
    drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
      fixture$gaussian_fit, fixture$nbinom2_fit, list()
    ),
    "Gaussian x ordinary-NB2"
  )
  expect_error(vcov(fixture$association_fit), "unavailable")
  expect_error(confint(fixture$association_fit), "unavailable")
  unstable <- drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
    fixture$gaussian_fit, fixture$nbinom2_fit, fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(),
      list(derivative_relative_tolerance = 0, derivative_absolute_tolerance = 0)
    )
  )
  expect_match(unstable$reason, "association_step_unstable")
  rank_failed <- drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
    fixture$gaussian_fit, fixture$nbinom2_fit, fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(), list(rcond_min = 1)
    )
  )
  expect_identical(
    rank_failed,
    list(status = "unavailable", reason = "bread_or_meat_unstable")
  )
})
