nbinom2_nbinom2_oracle <- function(y_1, mu_1, sigma_1, y_2, mu_2, sigma_2, eta) {
  endpoints <- function(y, mu, sigma) {
    size <- drmTMB:::drm_nbinom2_size(sigma)
    q <- function(value) {
      lcdf <- stats::pnbinom(value, size = size, mu = mu, log.p = TRUE)
      lsurv <- stats::pnbinom(value, size = size, mu = mu, lower.tail = FALSE, log.p = TRUE)
      if (lcdf <= log(0.5)) stats::qnorm(lcdf, log.p = TRUE) else stats::qnorm(lsurv, lower.tail = FALSE, log.p = TRUE)
    }
    c(if (y == 0L) -Inf else q(y - 1L), q(y))
  }
  a <- endpoints(y_1, mu_1, sigma_1)
  b <- endpoints(y_2, mu_2, sigma_2)
  as.numeric(mvtnorm::pmvnorm(lower = c(a[[1]], b[[1]]), upper = c(a[[2]], b[[2]]),
    mean = c(0, 0), sigma = matrix(c(1, eta, eta, 1), 2, 2)))
}

test_that("ordinary-NB2 x ordinary-NB2 direct rectangles match mvtnorm and factorize", {
  skip_if_not_installed("mvtnorm")
  cases <- list(c(0L, 1.2, .7, 0L, 2.5, .4, -.55),
    c(3L, 1.2, .7, 8L, 2.5, .4, .4), c(18L, 9, .25, 2L, .9, .8, .75))
  for (case in cases) {
    actual <- do.call(drmTMB:::drm_pair_nbinom2_nbinom2_rectangle_probability, as.list(case))
    expect_identical(actual$status, "ok")
    oracle <- do.call(nbinom2_nbinom2_oracle, as.list(case))
    expect_equal(actual$probability, oracle, tolerance = 2e-8)
  }
  actual <- drmTMB:::drm_pair_nbinom2_nbinom2_rectangle_probability(3L, 1.2, .7, 8L, 2.5, .4, 0)
  expect_identical(actual$branch, "factorized")
  expect_equal(actual$probability,
    stats::dnbinom(3, size = drmTMB:::drm_nbinom2_size(.7), mu = 1.2) *
      stats::dnbinom(8, size = drmTMB:::drm_nbinom2_size(.4), mu = 2.5), tolerance = 1e-14)
})

test_that("ordinary-NB2 x ordinary-NB2 association preserves pair order and deterministic simulation", {
  set.seed(20260723)
  n <- 40L
  x <- stats::rnorm(n)
  z_1 <- stats::rnorm(n)
  z_2 <- .35 * z_1 + sqrt(1 - .35^2) * stats::rnorm(n)
  data <- data.frame(x = x,
    count_1 = drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_1, exp(.2 + .1 * x), rep(.6, n)),
    count_2 = drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_2, exp(.4 - .1 * x), rep(.45, n)))
  fit_1 <- drmTMB(bf(mu = count_1 ~ x, sigma = ~1), nbinom2(), data)
  fit_2 <- drmTMB(bf(mu = count_2 ~ x, sigma = ~1), nbinom2(), data)
  forward <- associate_pairs(fit_1, fit_2, kernel = latent_normal(), association = ~1)
  reverse <- associate_pairs(fit_2, fit_1, kernel = latent_normal(), association = ~1)
  expect_identical(forward$pair_descriptor$pair_class, "nbinom2_nbinom2")
  expect_equal(forward$logLik, reverse$logLik, tolerance = 1e-7)
  expect_equal(forward$eta, reverse$eta, tolerance = 1e-7)
  expect_equal(fitted(forward), data.frame(count_1 = forward$components$nbinom2_mu_1,
    count_2 = forward$components$nbinom2_mu_2))
  expect_equal(predict(forward), fitted(forward))
  expect_equal(fitted(reverse), data.frame(count_2 = reverse$components$nbinom2_mu_1,
    count_1 = reverse$components$nbinom2_mu_2))
  expect_equal(predict(reverse), fitted(reverse))
  expect_named(forward$diagnostics$count_interval$row_numerics,
    c("row", "status", "integration_error", "relative_integration_error", "count_1_lower", "count_1_upper", "count_2_lower", "count_2_upper"))
  forward$status <- "interior"; forward$eta <- forward$eta_internal <- 0
  observed <- simulate(forward, seed = 918)
  set.seed(918)
  expected <- data.frame(count_1 = drmTMB:::drm_pair_nbinom2_quantile_from_normal(stats::rnorm(n),
    forward$components$nbinom2_mu_1, forward$components$nbinom2_sigma_1))
  expected$count_2 <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(stats::rnorm(n),
    forward$components$nbinom2_mu_2, forward$components$nbinom2_sigma_2)
  expect_equal(observed, expected)
})

test_that("ordinary-NB2 x ordinary-NB2 fails closed on numerical contract failures", {
  bad <- drmTMB:::drm_pair_nbinom2_nbinom2_rectangle_probability(0L, 1, .5, 0L, 1, .5, 1)
  expect_identical(bad$status, "invalid_input")
  rejected <- drmTMB:::drm_pair_nbinom2_nbinom2_rectangle_probability(18L, 9, .25, 2L, .9, .8, .75,
    integration_rel_tol = 1e-20, integration_abs_tol = 1e-30)
  expect_identical(rejected$status, "integration_error_exceeds_tolerance")

  components <- list(pair_class = "nbinom2_nbinom2",
    descriptor = drmTMB:::drm_pair_descriptor("nbinom2_nbinom2"),
    nbinom2_y_1 = 0L, nbinom2_mu_1 = 1e-300, nbinom2_sigma_1 = 1e-150,
    nbinom2_y_2 = 0L, nbinom2_mu_2 = 1, nbinom2_sigma_2 = .5)
  fit <- drmTMB:::drm_pair_fit_eta(components)
  rows <- fit$diagnostics$count_interval$row_numerics
  expect_identical(fit$status, "boundary_unresolved")
  expect_true(fit$diagnostics$endpoint_failure)
  expect_match(fit$diagnostics$count_interval$endpoint_failure_message,
    "endpoints are numerically unresolved")
  expect_named(rows, c("row", "status", "integration_error", "relative_integration_error",
    "count_1_lower", "count_1_upper", "count_2_lower", "count_2_upper"))
  expect_identical(rows$status, "endpoint_failure")
})
