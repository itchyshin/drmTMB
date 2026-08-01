nn_sandwich_fixture <- function(n = 44L, eta = 0.3, seed = 20260725L) {
  set.seed(seed)
  x <- seq(-1, 1, length.out = n)
  z_l <- stats::rnorm(n)
  z_r <- eta * z_l + sqrt(1 - eta^2) * stats::rnorm(n)
  mu_l <- exp(0.25 + 0.35 * x)
  sigma_l <- exp(-0.15 + 0.12 * x)
  mu_r <- exp(0.4 - 0.25 * x)
  sigma_r <- exp(-0.25 - 0.1 * x)
  dat <- data.frame(
    x = x,
    y_l = drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_l, mu_l, sigma_l),
    y_r = drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_r, mu_r, sigma_r)
  )
  fit_l <- drmTMB(bf(mu = y_l ~ x, sigma = ~x), nbinom2(), dat)
  fit_r <- drmTMB(bf(mu = y_r ~ x, sigma = ~x), nbinom2(), dat)
  list(
    fit_l = fit_l,
    fit_r = fit_r,
    association_fit = associate_pairs(
      fit_l, fit_r, kernel = latent_normal(), association = ~1
    )
  )
}

nn_sandwich_oracle_logprob <- function(q, y_l, y_r) {
  endpoints <- function(y, mu, sigma) {
    size <- sigma^(-2)
    qnorm_tail <- function(value) {
      log_cdf <- stats::pnbinom(value, size = size, mu = mu, log.p = TRUE)
      log_survival <- stats::pnbinom(
        value, size = size, mu = mu, lower.tail = FALSE, log.p = TRUE
      )
      if (log_cdf <= log(0.5)) {
        stats::qnorm(log_cdf, log.p = TRUE)
      } else {
        stats::qnorm(log_survival, lower.tail = FALSE, log.p = TRUE)
      }
    }
    c(if (y == 0L) -Inf else qnorm_tail(y - 1L), qnorm_tail(y))
  }
  eta <- 0.999999 * tanh(q[[1L]])
  left <- endpoints(y_l, exp(q[[2L]]), exp(q[[3L]]))
  right <- endpoints(y_r, exp(q[[4L]]), exp(q[[5L]]))
  log(as.numeric(mvtnorm::pmvnorm(
    lower = c(left[[1L]], right[[1L]]),
    upper = c(left[[2L]], right[[2L]]),
    mean = c(0, 0),
    sigma = matrix(c(1, eta, eta, 1), 2L)
  )))
}

test_that("ordinary-NB2 sandwich margins use analytic scores and bread", {
  y <- c(0L, 2L, 1L, 5L)
  x <- cbind("(Intercept)" = 1, x = c(-1, 0, 0.5, 1))
  z <- cbind("(Intercept)" = 1, x = c(0.3, -0.5, 0.8, 1.1))
  q <- c(0.2, -0.35, log(0.7), 0.15)
  block <- drmTMB:::drm_pair_nbinom2_nbinom2_sandwich_margin_block(
    y = y, mu = exp(x %*% q[1:2]), sigma = exp(z %*% q[3:4]), x = x, z = z
  )
  loglik <- function(theta) {
    sum(stats::dnbinom(
      y,
      size = exp(z %*% theta[3:4])^(-2),
      mu = exp(x %*% theta[1:2]),
      log = TRUE
    ))
  }
  score <- c(colSums(block$score_mu), colSums(block$score_sigma))
  expect_equal(unname(score), numDeriv::grad(loglik, q), tolerance = 1e-6)
  expect_equal(
    unname(drmTMB:::drm_pair_nbinom2_nbinom2_sandwich_bread(block)),
    -numDeriv::hessian(loglik, q) / length(y),
    tolerance = 2e-5
  )
})

test_that("ordinary-NB2 rectangle row kernel and mixed derivatives match an independent oracle", {
  skip_if_not_installed("mvtnorm")
  q <- c(a = 0.26, xi_l = 0.2, tau_l = log(0.65), xi_r = 0.5, tau_r = log(0.45))
  production <- function(theta) {
    drmTMB:::drm_pair_nbinom2_nbinom2_sandwich_row_logprob(
      y_l = 3L, y_r = 5L,
      xi_l = theta[[2L]], tau_l = theta[[3L]],
      xi_r = theta[[4L]], tau_r = theta[[5L]], a = theta[[1L]]
    )
  }
  oracle <- function(theta) nn_sandwich_oracle_logprob(theta, 3L, 5L)
  derivatives <- drmTMB:::drm_pair_sandwich_derivatives(production, q, 1e-2)
  expect_equal(derivatives$gradient, numDeriv::grad(oracle, q), tolerance = 3e-3)
  expect_equal(derivatives$hessian, numDeriv::hessian(oracle, q), tolerance = 5e-3)
  expect_gt(max(abs(derivatives$hessian[1L, c(2L, 3L, 4L, 5L)])), 1e-5)
})

test_that("ordinary-NB2 sandwich row kernel factorizes at eta zero and stays finite in both signs", {
  q <- c(xi_l = 0.2, tau_l = log(0.65), xi_r = 0.5, tau_r = log(0.45))
  a <- atanh(c(-0.6, 0, 0.6) / 0.999999)
  values <- vapply(a, function(a_i) {
    drmTMB:::drm_pair_nbinom2_nbinom2_sandwich_row_logprob(
      y_l = 18L, y_r = 25L,
      xi_l = q[[1L]], tau_l = q[[2L]],
      xi_r = q[[3L]], tau_r = q[[4L]], a = a_i
    )
  }, numeric(1L))
  expect_true(all(is.finite(values)))
  expect_equal(
    values[[2L]],
    stats::dnbinom(18L, size = exp(q[[2L]])^(-2), mu = exp(q[[1L]]), log = TRUE) +
      stats::dnbinom(25L, size = exp(q[[4L]])^(-2), mu = exp(q[[3L]]), log = TRUE),
    tolerance = 1e-12
  )
})

test_that("literal ordinary-NB2 sides retain L/R labels and swap by block permutation", {
  fixture <- nn_sandwich_fixture()
  forward <- drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(
    fixture$fit_l, fixture$fit_r, fixture$association_fit
  )
  routed <- drmTMB:::drm_pair_general_eta_sandwich(
    fixture$fit_l, fixture$fit_r, fixture$association_fit
  )
  reverse_fit <- associate_pairs(
    fixture$fit_r, fixture$fit_l, kernel = latent_normal(), association = ~1
  )
  reverse <- drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(
    fixture$fit_r, fixture$fit_l, reverse_fit
  )
  expect_identical(forward$status, "ok")
  expect_equal(routed$covariance, forward$covariance, tolerance = 1e-12)
  expect_identical(reverse$status, "ok")
  expect_true(all(startsWith(colnames(forward$covariance)[1:4], "nbinom2_L_")))
  expect_true(all(startsWith(colnames(forward$covariance)[5:8], "nbinom2_R_")))
  expect_identical(names(forward$alpha_se), "association:(Intercept)")
  permutation <- c(5:8, 1:4, 9L)
  expect_equal(unname(reverse$scores), unname(forward$scores[, permutation]), tolerance = 2e-7)
  # Conditional-normal quadrature chooses the left integration coordinate, so
  # a literal swap keeps the block identity but can differ at its documented
  # numerical tolerance in the association-bread row.
  expect_equal(unname(reverse$bread), unname(forward$bread[permutation, permutation]), tolerance = 1e-5)
  expect_equal(unname(reverse$covariance), unname(forward$covariance[permutation, permutation]), tolerance = 1e-4)
  expect_gt(max(abs(forward$bread[9L, 1:8])), 1e-6)
  expect_equal(forward$meat, crossprod(forward$scores) / nrow(forward$scores), tolerance = 1e-12)
})

test_that("ordinary-NB2 sandwich fails closed for frozen provenance and boundary changes", {
  fixture <- nn_sandwich_fixture()
  unresolved <- fixture$association_fit
  unresolved$status <- "boundary_unresolved"
  expect_identical(
    drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(
      fixture$fit_l, fixture$fit_r, unresolved
    ),
    list(status = "unavailable", reason = "association_unresolved")
  )
  frozen <- fixture$association_fit
  frozen$components$nbinom2_sigma_1[[1L]] <-
    frozen$components$nbinom2_sigma_1[[1L]] + 0.01
  expect_identical(
    drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(
      fixture$fit_l, fixture$fit_r, frozen
    ),
    list(status = "unavailable", reason = "frozen_margin_mismatch")
  )
  provenance <- fixture$association_fit
  provenance$provenance$data_hash <- "altered"
  expect_identical(
    drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(
      fixture$fit_l, fixture$fit_r, provenance
    ),
    list(status = "unavailable", reason = "frozen_margin_mismatch")
  )
  bounded <- fixture$association_fit
  bounded$association_coefficients[] <- 8
  expect_identical(
    drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(
      fixture$fit_l, fixture$fit_r, bounded
    ),
    list(status = "unavailable", reason = "association_boundary")
  )
  expect_error(
    drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(
      fixture$fit_l, fixture$fit_r, list()
    ),
    "ordinary-NB2"
  )
  expect_warning(
    expect_true(all(is.finite(vcov(fixture$association_fit)))),
    class = "drmTMB_association_inference_warning"
  )
  expect_warning(
    expect_true(all(is.finite(confint(fixture$association_fit)))),
    class = "drmTMB_association_inference_warning"
  )
  unstable <- drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(
    fixture$fit_l, fixture$fit_r, fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(),
      list(derivative_relative_tolerance = 0, derivative_absolute_tolerance = 0)
    )
  )
  expect_match(unstable$reason, "association_step_unstable")
  rank_failed <- drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(
    fixture$fit_l, fixture$fit_r, fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(), list(rcond_min = 1)
    )
  )
  expect_identical(
    rank_failed,
    list(status = "unavailable", reason = "bread_or_meat_unstable")
  )
})
