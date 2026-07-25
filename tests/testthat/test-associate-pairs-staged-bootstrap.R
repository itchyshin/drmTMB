independent_nbinom2_quantile <- function(z, mu, sigma) {
  size <- sigma^-2
  log_cdf <- stats::pnorm(z, log.p = TRUE)
  log_survival <- stats::pnorm(z, lower.tail = FALSE, log.p = TRUE)
  lower_tail <- log_cdf <= log(0.5)
  out <- numeric(length(z))
  out[lower_tail] <- stats::qnbinom(
    log_cdf[lower_tail], size = size[lower_tail], mu = mu[lower_tail], log.p = TRUE
  )
  out[!lower_tail] <- stats::qnbinom(
    log_survival[!lower_tail], size = size[!lower_tail], mu = mu[!lower_tail],
    lower.tail = FALSE, log.p = TRUE
  )
  out
}

test_that("staged Bernoulli x NB2 DGP has an independent tail-safe oracle", {
  p <- c(0.04, 0.23, 0.77)
  mu <- c(0.4, 4.1, 24)
  sigma <- c(0.25, 0.55, 0.65)
  eta <- c(-0.5, 0, 0.5)
  set.seed(241)
  observed <- drmTMB:::drm_pair_simulate_bernoulli_nbinom2(p, mu, sigma, eta)
  set.seed(241)
  z_binary <- stats::rnorm(3)
  z_nbinom2 <- eta * z_binary + sqrt(1 - eta^2) * stats::rnorm(3)
  expect_identical(observed$bernoulli, as.integer(z_binary > stats::qnorm(p, lower.tail = FALSE)))
  expect_identical(observed$nbinom2, independent_nbinom2_quantile(z_nbinom2, mu, sigma))
  expect_equal(observed$latent_binary, z_binary)
  expect_equal(observed$latent_nbinom2, z_nbinom2)
})

test_that("finite staged association domain is exposed and bound hits are unresolved", {
  bounds <- drmTMB:::drm_pair_association_bounds()
  expect_identical(bounds, list(lower = -8, upper = 8, hit_tolerance = 0.01))
  components <- list(
    pair_class = "bernoulli_nbinom2",
    descriptor = drmTMB:::drm_pair_descriptor("bernoulli_nbinom2"),
    binary_y = c(0L, 1L, 0L, 1L), binary_p = rep(0.4, 4L),
    nbinom2_y = c(0L, 2L, 1L, 4L), nbinom2_mu = rep(2, 4L),
    nbinom2_sigma = rep(0.6, 4L)
  )
  fit <- drmTMB:::drm_pair_fit_eta(components)
  expect_named(fit$diagnostics$optimization_domain,
    c("lower", "upper", "hit_tolerance", "bound_hit"))
  expect_equal(unname(fit$diagnostics$optimization_domain[c("lower", "upper")]), c(-8, 8))
})

test_that("staged-eta summary retains all-attempt and conditional denominators", {
  outer <- data.frame(
    interval_available = c(TRUE, TRUE, FALSE, TRUE),
    resolved_bootstrap = c(399L, 380L, 20L, 399L),
    bootstrap_attempts = c(399L, 399L, 399L, 399L),
    alpha0_estimate = c(0.1, -0.2, 0, 0.2),
    alpha0_lower = c(-0.1, -0.3, NA, 0.1),
    alpha0_upper = c(0.2, -0.1, NA, 0.3)
  )
  summary <- drmTMB:::drm_pair_staged_eta_coverage_summary(
    outer, truth = c(alpha0 = 0), minimum_resolved = 380L
  )
  expect_equal(summary$n_outer, 4L)
  expect_equal(summary$n_available, 3L)
  expect_equal(summary$availability, 0.75)
  expect_equal(summary$coverage_all_attempt, 0.25)
  expect_equal(summary$coverage_conditional, 1 / 3)
})

test_that("full-refit bootstrap refits both margins and retains every attempt", {
  set.seed(242)
  n <- 120L
  data <- data.frame(x = seq(-1.4, 1.4, length.out = n))
  p <- stats::plogis(-0.2 + 0.3 * data$x)
  mu <- exp(0.7 + 0.2 * data$x)
  simulated <- drmTMB:::drm_pair_simulate_bernoulli_nbinom2(
    p, mu, rep(0.65, n), 0.999999 * tanh(-0.15 + 0.65 * data$x)
  )
  data$binary <- simulated$bernoulli
  data$count <- simulated$nbinom2
  result <- drmTMB:::drm_pair_full_refit_bootstrap(
    data = data, binary_response = "binary", nbinom2_response = "count",
    binary_formula = bf(mu = binary ~ x),
    nbinom2_formula = bf(mu = count ~ x, sigma = ~1),
    association = ~x, attempts = 3L, minimum_resolved = 2L, seed = 912
  )
  expect_true(result$outer_status %in% c("interior", "near_boundary"))
  expect_equal(nrow(result$attempts), 3L)
  expect_equal(length(result$diagnostics), 3L)
  expect_named(result$diagnostics[[1L]], c("simulation", "binary_margin", "nbinom2_margin", "association"))
  expect_true(all(result$attempts$simulation_status == "ok"))
  expect_true(all(result$attempts$binary_margin_status %in% c("ok", "error")))
  expect_true(all(result$attempts$nbinom2_margin_status %in% c("ok", "error")))
  expect_true(is.logical(result$interval_available))
})
