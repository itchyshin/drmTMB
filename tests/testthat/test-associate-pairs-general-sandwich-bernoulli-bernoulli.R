bb_sandwich_fixture <- function(n = 240L, eta = 0.35, seed = 20260725L) {
  set.seed(seed)
  x <- seq(-1, 1, length.out = n)
  z_l <- stats::rnorm(n)
  z_r <- eta * z_l + sqrt(1 - eta^2) * stats::rnorm(n)
  p_l <- stats::plogis(-0.25 + 0.55 * x)
  p_r <- stats::plogis(0.15 - 0.45 * x)
  data <- data.frame(
    x = x,
    y_l = as.integer(z_l > stats::qnorm(p_l, lower.tail = FALSE)),
    y_r = as.integer(z_r > stats::qnorm(p_r, lower.tail = FALSE))
  )
  fit_l <- drmTMB(bf(mu = y_l ~ x), binomial(), data)
  fit_r <- drmTMB(bf(mu = y_r ~ x), binomial(), data)
  list(
    fit_l = fit_l,
    fit_r = fit_r,
    association_fit = associate_pairs(
      fit_l, fit_r, kernel = latent_normal(), association = ~1
    )
  )
}

bb_sandwich_oracle_logprob <- function(y_l, y_r, lambda_l, lambda_r, a) {
  p_l <- stats::plogis(lambda_l)
  p_r <- stats::plogis(lambda_r)
  threshold_l <- stats::qnorm(p_l, lower.tail = FALSE)
  threshold_r <- stats::qnorm(p_r, lower.tail = FALSE)
  lower <- c(if (y_l == 1L) threshold_l else -Inf,
    if (y_r == 1L) threshold_r else -Inf)
  upper <- c(if (y_l == 1L) Inf else threshold_l,
    if (y_r == 1L) Inf else threshold_r)
  log(as.numeric(mvtnorm::pmvnorm(
    lower = lower,
    upper = upper,
    mean = c(0, 0),
    sigma = matrix(c(1, 0.999999 * tanh(a), 0.999999 * tanh(a), 1), 2)
  )))
}

test_that("Bernoulli sandwich margins use analytic scores and bread", {
  y_l <- c(0L, 1L, 1L, 0L)
  y_r <- c(1L, 0L, 1L, 0L)
  x_l <- cbind("(Intercept)" = 1, x = c(-1, 0, 0.5, 1))
  x_r <- cbind("(Intercept)" = 1, x = c(0.5, -1, 1, 0))
  beta_l <- c(-0.2, 0.4)
  beta_r <- c(0.3, -0.25)
  block <- drmTMB:::drm_pair_bernoulli_bernoulli_sandwich_margin_blocks(
    y_l, y_r, stats::plogis(x_l %*% beta_l), stats::plogis(x_r %*% beta_r),
    x_l, x_r
  )
  loglik_l <- function(beta) sum(stats::dbinom(y_l, 1L,
    stats::plogis(x_l %*% beta), log = TRUE
  ))
  loglik_r <- function(beta) sum(stats::dbinom(y_r, 1L,
    stats::plogis(x_r %*% beta), log = TRUE
  ))
  expect_equal(unname(colSums(block$score_l)), numDeriv::grad(loglik_l, beta_l), tolerance = 1e-7)
  expect_equal(unname(colSums(block$score_r)), numDeriv::grad(loglik_r, beta_r), tolerance = 1e-7)
  expect_equal(unname(block$bread_l), -numDeriv::hessian(loglik_l, beta_l) / length(y_l), tolerance = 1e-7)
  expect_equal(unname(block$bread_r), -numDeriv::hessian(loglik_r, beta_r) / length(y_r), tolerance = 1e-7)
})

test_that("Bernoulli rectangle row kernel and derivatives match an independent oracle", {
  skip_if_not_installed("mvtnorm")
  q <- c(a = 0.32, lambda_l = -0.4, lambda_r = 0.55)
  production <- function(x) drmTMB:::drm_pair_bernoulli_bernoulli_sandwich_row_logprob(
    y_l = 1L, y_r = 0L, lambda_l = x[[2L]], lambda_r = x[[3L]], a = x[[1L]]
  )
  oracle <- function(x) bb_sandwich_oracle_logprob(
    y_l = 1L, y_r = 0L, lambda_l = x[[2L]], lambda_r = x[[3L]], a = x[[1L]]
  )
  derivatives <- drmTMB:::drm_pair_sandwich_derivatives(production, q, 1e-2)
  expect_equal(derivatives$gradient, numDeriv::grad(oracle, q), tolerance = 2e-3)
  expect_equal(derivatives$hessian, numDeriv::hessian(oracle, q), tolerance = 3e-3)
  expect_gt(max(abs(derivatives$hessian[1L, 2:3])), 1e-5)
})

test_that("Bernoulli rectangle factorizes at eta zero and remains finite inside both signs", {
  for (eta in c(-0.65, 0, 0.65)) {
    for (y_l in 0:1) {
      for (y_r in 0:1) {
        observed <- drmTMB:::drm_pair_bernoulli_rectangle_probability(
          y_l, 0.23, y_r, 0.71, eta
        )
        expect_true(is.finite(observed))
        expect_gt(observed, 0)
        if (eta == 0) {
          expect_equal(
            observed,
            (if (y_l == 1L) 0.23 else 0.77) *
              (if (y_r == 1L) 0.71 else 0.29),
            tolerance = 1e-10
          )
        }
      }
    }
  }
})

test_that("literal Bernoulli sides retain L/R labels and swap by block permutation", {
  fixture <- bb_sandwich_fixture()
  forward <- drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(
    fixture$fit_l, fixture$fit_r, fixture$association_fit
  )
  routed <- drmTMB:::drm_pair_general_eta_sandwich(
    fixture$fit_l, fixture$fit_r, fixture$association_fit
  )
  reverse_fit <- associate_pairs(
    fixture$fit_r, fixture$fit_l, kernel = latent_normal(), association = ~1
  )
  reverse <- drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(
    fixture$fit_r, fixture$fit_l, reverse_fit
  )
  expect_identical(forward$status, "ok")
  expect_equal(routed$covariance, forward$covariance, tolerance = 1e-12)
  expect_identical(reverse$status, "ok")
  expect_named(
    forward$alpha_se,
    "association:(Intercept)",
    ignore.order = FALSE
  )
  expect_true(all(startsWith(colnames(forward$covariance)[1:2], "bernoulli_L_mu:")))
  expect_true(all(startsWith(colnames(forward$covariance)[3:4], "bernoulli_R_mu:")))
  permutation <- c(3L, 4L, 1L, 2L, 5L)
  expect_equal(unname(reverse$scores), unname(forward$scores[, permutation]), tolerance = 2e-7)
  expect_equal(unname(reverse$bread), unname(forward$bread[permutation, permutation]), tolerance = 2e-7)
  expect_equal(unname(reverse$covariance), unname(forward$covariance[permutation, permutation]), tolerance = 2e-7)
})

test_that("Bernoulli sandwich fails closed for frozen provenance and boundary changes", {
  fixture <- bb_sandwich_fixture()
  unresolved <- fixture$association_fit
  unresolved$status <- "boundary_unresolved"
  expect_identical(
    drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(
      fixture$fit_l, fixture$fit_r, unresolved
    ),
    list(status = "unavailable", reason = "association_unresolved")
  )
  frozen <- fixture$association_fit
  frozen$components$binary_1_y[[1L]] <- 1L - frozen$components$binary_1_y[[1L]]
  expect_identical(
    drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(
      fixture$fit_l, fixture$fit_r, frozen
    ),
    list(status = "unavailable", reason = "frozen_margin_mismatch")
  )
  provenance <- fixture$association_fit
  provenance$provenance$data_hash <- "altered"
  expect_identical(
    drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(
      fixture$fit_l, fixture$fit_r, provenance
    ),
    list(status = "unavailable", reason = "frozen_margin_mismatch")
  )
  bounded <- fixture$association_fit
  bounded$association_coefficients[] <- 8
  expect_identical(
    drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(
      fixture$fit_l, fixture$fit_r, bounded
    ),
    list(status = "unavailable", reason = "association_boundary")
  )
  expect_error(
    drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(
      fixture$fit_l, fixture$fit_r, list()
    ),
    "literal Bernoulli"
  )
  expect_warning(
    expect_true(all(is.finite(vcov(fixture$association_fit)))),
    class = "drmTMB_association_inference_warning"
  )
  expect_warning(
    expect_true(all(is.finite(confint(fixture$association_fit)))),
    class = "drmTMB_association_inference_warning"
  )
  unstable <- drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(
    fixture$fit_l, fixture$fit_r, fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(),
      list(derivative_relative_tolerance = 0, derivative_absolute_tolerance = 0)
    )
  )
  expect_match(unstable$reason, "association_step_unstable")
  rank_failed <- drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(
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
