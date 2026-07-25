staged_sandwich_fixture <- function(n = 18L, slope = FALSE) {
  set.seed(20260725)
  x <- seq(-1, 1, length.out = n)
  p <- stats::plogis(-0.15 + 0.25 * x)
  mu <- exp(0.35 + 0.15 * x)
  sigma <- rep(0.6, n)
  a <- if (slope) -0.12 + 0.22 * x else rep(0.22, n)
  eta <- 0.999999 * tanh(a)
  z_b <- stats::rnorm(n)
  z_n <- eta * z_b + sqrt(1 - eta^2) * stats::rnorm(n)
  dat <- data.frame(
    x = x,
    binary = as.integer(z_b > stats::qnorm(p, lower.tail = FALSE)),
    count = drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_n, mu, sigma)
  )
  binary_fit <- drmTMB(bf(mu = binary ~ x), binomial(), dat)
  nbinom2_fit <- drmTMB(bf(mu = count ~ x, sigma = ~1), nbinom2(), dat)
  association_fit <- associate_pairs(
    binary_fit,
    nbinom2_fit,
    kernel = latent_normal(),
    association = if (slope) ~x else ~1
  )
  list(
    binary_fit = binary_fit,
    nbinom2_fit = nbinom2_fit,
    association_fit = association_fit
  )
}

staged_sandwich_oracle_logprob <- function(
  binary_y,
  count_y,
  lambda_b,
  xi_n,
  tau_n,
  a
) {
  p <- stats::plogis(lambda_b)
  mu <- exp(xi_n)
  sigma <- exp(tau_n)
  size <- sigma^-2
  endpoint <- function(y) {
    cdf <- stats::pnbinom(y, size = size, mu = mu)
    stats::qnorm(cdf)
  }
  threshold <- stats::qnorm(p, lower.tail = FALSE)
  lower <- c(
    if (binary_y == 0L) -Inf else threshold,
    if (count_y == 0L) -Inf else endpoint(count_y - 1L)
  )
  upper <- c(if (binary_y == 0L) threshold else Inf, endpoint(count_y))
  log(as.numeric(mvtnorm::pmvnorm(
    lower = lower,
    upper = upper,
    mean = c(0, 0),
    sigma = matrix(c(1, 0.999999 * tanh(a), 0.999999 * tanh(a), 1), 2)
  )))
}

test_that("analytic staged-margin scores and bread agree with numerical derivatives", {
  y <- 4L
  mu <- 2.3
  sigma <- 0.7
  r <- sigma^-2
  xi <- log(mu)
  tau <- log(sigma)
  scalar_loglik <- function(q) {
    stats::dnbinom(y, size = exp(-2 * q[[2L]]), mu = exp(q[[1L]]), log = TRUE)
  }
  numerical_score <- numDeriv::grad(scalar_loglik, c(xi, tau))
  block <- drmTMB:::drm_pair_sandwich_margin_blocks(
    binary_y = 1L,
    nbinom2_y = y,
    p = 0.3,
    mu = mu,
    sigma = sigma,
    x_b = matrix(1),
    x_n = matrix(1),
    z_n = matrix(1)
  )
  expect_equal(
    c(block$score_n, block$score_s),
    numerical_score,
    tolerance = 1e-6
  )
  numerical_hessian <- numDeriv::hessian(scalar_loglik, c(xi, tau))
  expect_equal(
    rbind(
      cbind(block$bread_nn, block$bread_ns),
      cbind(block$bread_ns, block$bread_ss)
    ),
    -numerical_hessian,
    tolerance = 2e-5
  )
})

test_that("staged rectangle score and every mixed derivative match an independent oracle", {
  skip_if_not_installed("mvtnorm")
  q <- c(a = 0.22, lambda_b = -0.35, xi_n = 0.5, tau_n = log(0.62))
  production <- function(x) {
    drmTMB:::drm_pair_sandwich_row_logprob(
      binary_y = 1L,
      nbinom2_y = 3L,
      lambda_b = x[[2L]],
      xi_n = x[[3L]],
      tau_n = x[[4L]],
      a = x[[1L]]
    )
  }
  oracle <- function(x) {
    staged_sandwich_oracle_logprob(
      binary_y = 1L,
      count_y = 3L,
      lambda_b = x[[2L]],
      xi_n = x[[3L]],
      tau_n = x[[4L]],
      a = x[[1L]]
    )
  }
  production_derivatives <- drmTMB:::drm_pair_sandwich_derivatives(
    production,
    q,
    1e-2
  )
  oracle_gradient <- numDeriv::grad(oracle, q)
  oracle_hessian <- numDeriv::hessian(oracle, q)
  expect_equal(
    production_derivatives$gradient,
    oracle_gradient,
    tolerance = 2e-3
  )
  expect_equal(production_derivatives$hessian, oracle_hessian, tolerance = 3e-3)
  expect_gt(max(abs(production_derivatives$hessian[1L, 2:4])), 1e-5)
})

test_that("staged sandwich uses stable row derivatives and retains all score blocks", {
  fixture <- staged_sandwich_fixture()
  result <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit
  )
  reverse_fit <- associate_pairs(
    fixture$nbinom2_fit,
    fixture$binary_fit,
    kernel = latent_normal(),
    association = ~1
  )
  reverse <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$nbinom2_fit,
    fixture$binary_fit,
    reverse_fit
  )
  expect_identical(result$status, "ok")
  expect_identical(reverse$status, "ok")
  expect_equal(ncol(result$scores), 6L)
  expect_equal(dim(result$covariance), c(6L, 6L))
  expect_true(all(is.finite(result$alpha_se)))
  expect_true(all(is.finite(result$eta_se)))
  expect_gt(max(abs(result$bread[5:6, 1:4])), 0)
  expect_equal(result$meat, t(result$meat), tolerance = 1e-12)
  expect_equal(
    result$alpha_covariance,
    reverse$alpha_covariance,
    tolerance = 1e-7
  )
  expect_equal(
    result$meat,
    crossprod(result$scores) / nrow(result$scores),
    tolerance = 1e-12
  )
  expect_equal(
    result$covariance,
    solve(result$bread) %*%
      result$meat %*%
      t(solve(result$bread)) /
      nrow(result$scores),
    tolerance = 1e-12
  )
  expect_equal(
    unname(result$bread[seq_len(5L), 6L]),
    rep(0, 5L),
    tolerance = 1e-14
  )
  expect_gt(abs(result$bread[6L, 1L]), 0)
  expect_gt(abs(result$bread[6L, 3L]), 0)
  expect_gt(abs(result$bread[6L, 5L]), 0)
  expect_true(all(vapply(
    result$derivative_diagnostics,
    function(x) is.finite(x$max_step_difference),
    logical(1)
  )))
})

test_that("staged sandwich supports the one admitted association slope", {
  fixture <- staged_sandwich_fixture(n = 24L, slope = TRUE)
  result <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit
  )
  expect_identical(result$status, "ok")
  expect_named(
    result$alpha_se,
    c("association:(Intercept)", "association:x"),
    ignore.order = FALSE
  )
  expect_length(result$eta, 24L)
  expect_gt(diff(range(result$eta)), 0)
})

test_that("staged sandwich fails closed before any public uncertainty interface", {
  fixture <- staged_sandwich_fixture()
  fixture$association_fit$status <- "boundary_unresolved"
  result <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit
  )
  expect_identical(
    result,
    list(status = "unavailable", reason = "association_unresolved")
  )
  expect_error(vcov(fixture$association_fit), "unavailable")
  expect_error(confint(fixture$association_fit), "unavailable")
})

test_that("staged sandwich guards frozen margins, bounds, derivative stability, and bread rank", {
  fixture <- staged_sandwich_fixture()
  mismatched <- fixture$association_fit
  mismatched$components$binary_p[[1L]] <- mismatched$components$binary_p[[1L]] +
    0.01
  expect_identical(
    drmTMB:::drm_pair_staged_eta_sandwich(
      fixture$binary_fit,
      fixture$nbinom2_fit,
      mismatched
    ),
    list(status = "unavailable", reason = "frozen_margin_mismatch")
  )
  bounded <- fixture$association_fit
  bounded$association_coefficients[] <- 8
  expect_identical(
    drmTMB:::drm_pair_staged_eta_sandwich(
      fixture$binary_fit,
      fixture$nbinom2_fit,
      bounded
    ),
    list(status = "unavailable", reason = "association_boundary")
  )
  unstable <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(),
      list(
        derivative_relative_tolerance = 0,
        derivative_absolute_tolerance = 0
      )
    )
  )
  expect_match(unstable$reason, "association_step_unstable")
  rank_failed <- drmTMB:::drm_pair_staged_eta_sandwich(
    fixture$binary_fit,
    fixture$nbinom2_fit,
    fixture$association_fit,
    control = utils::modifyList(
      drmTMB:::drm_pair_sandwich_control(),
      list(rcond_min = 1)
    )
  )
  expect_identical(
    rank_failed,
    list(status = "unavailable", reason = "bread_or_meat_unstable")
  )
})
