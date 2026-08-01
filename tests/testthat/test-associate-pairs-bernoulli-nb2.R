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
  as.numeric(mvtnorm::pmvnorm(
    lower = lower, upper = upper, mean = c(0, 0),
    sigma = matrix(c(1, eta, eta, 1), 2, 2),
    algorithm = mvtnorm::GenzBretz(
      maxpts = 250000L, abseps = 1e-12, releps = 1e-12
    ),
    keepAttr = FALSE
  ))
}

# Independent of the production rectangle helper: condition on the NB2 latent
# normal and integrate over its latent interval.  This deliberately uses the
# opposite orientation from the production CDF-scale integral.  A tight
# numerical maximum is available for finite intervals; the normal-density
# maximum is an analytic bound for the count-zero half-line.
bernoulli_nb2_conditional_oracle <- function(
  binary_y, binary_p, count_y, mu, sigma, eta
) {
  size <- drmTMB:::drm_nbinom2_size(sigma)
  if (identical(eta, 0)) {
    return(list(
      status = "ok",
      log_probability = stats::dbinom(binary_y, 1, binary_p, log = TRUE) +
        stats::dnbinom(count_y, size = size, mu = mu, log = TRUE),
      relative_integration_error = 0
    ))
  }
  endpoints <- tryCatch(
    drmTMB:::drm_pair_nbinom2_endpoints(count_y, mu, sigma),
    error = function(e) e
  )
  if (inherits(endpoints, "error")) {
    return(list(status = "oracle_unresolved", log_probability = NA_real_))
  }
  threshold <- stats::qnorm(binary_p, lower.tail = FALSE)
  s <- sqrt(1 - eta^2)
  log_integrand <- function(z) {
    if (binary_y == 1L) {
      conditional <- stats::pnorm((eta * z - threshold) / s, log.p = TRUE)
    } else {
      conditional <- stats::pnorm((threshold - eta * z) / s, log.p = TRUE)
    }
    stats::dnorm(z, log = TRUE) + conditional
  }
  log_scale <- -0.5 * log(2 * pi)
  if (is.finite(endpoints$lower) && is.finite(endpoints$upper)) {
    maximum <- tryCatch(
      stats::optimize(function(z) -log_integrand(z),
        interval = c(endpoints$lower, endpoints$upper), tol = 1e-12
      ),
      error = function(e) e
    )
    if (inherits(maximum, "error") || !is.finite(maximum$objective)) {
      return(list(status = "oracle_unresolved", log_probability = NA_real_))
    }
    log_scale <- -maximum$objective
  }
  integral <- tryCatch(
    stats::integrate(
      function(z) exp(log_integrand(z) - log_scale),
      lower = endpoints$lower, upper = endpoints$upper,
      subdivisions = 400L, rel.tol = 1e-11
    ),
    error = function(e) e
  )
  if (inherits(integral, "error") || !is.finite(log_scale) ||
      !is.finite(integral$value) || !is.finite(integral$abs.error) ||
      integral$value <= 0) {
    return(list(status = "oracle_unresolved", log_probability = NA_real_))
  }
  list(
    status = "ok",
    log_probability = log_scale + log(integral$value),
    relative_integration_error = integral$abs.error / integral$value
  )
}

bernoulli_nb2_pinned_rectangle_oracle <- function(...) {
  probability <- bernoulli_nb2_oracle(...)
  if (!is.finite(probability) || probability <= 0) {
    return(list(status = "oracle_unresolved", log_probability = NA_real_))
  }
  list(status = "ok", log_probability = log(probability))
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

test_that("Bernoulli x ordinary-NB2 CDF-scale kernel matches pinned tail oracles", {
  skip_if_not_installed("mvtnorm")
  cases <- list(
    zero_binary_0 = list(binary_y = 0L, binary_p = 0.23, count_y = 0L, mu = 4.1, sigma = 0.55, alpha = 0),
    zero_binary_1 = list(binary_y = 1L, binary_p = 0.23, count_y = 3L, mu = 4.1, sigma = 0.55, alpha = 0),
    normal_negative = list(binary_y = 0L, binary_p = 0.23, count_y = 3L, mu = 4.1, sigma = 0.55, alpha = -0.35),
    normal_positive = list(binary_y = 1L, binary_p = 0.23, count_y = 3L, mu = 4.1, sigma = 0.55, alpha = 0.35),
    tail_negative = list(binary_y = 1L, binary_p = stats::plogis(-0.35), count_y = 3L, mu = exp(0.5), sigma = 0.62, alpha = -4),
    tail_positive = list(binary_y = 0L, binary_p = stats::plogis(-0.35), count_y = 3L, mu = exp(0.5), sigma = 0.62, alpha = 4),
    zero_count_negative = list(binary_y = 0L, binary_p = 0.23, count_y = 0L, mu = 4.1, sigma = 0.55, alpha = -0.35),
    zero_count_positive = list(binary_y = 1L, binary_p = 0.23, count_y = 0L, mu = 4.1, sigma = 0.55, alpha = 0.35),
    high_count_negative = list(binary_y = 1L, binary_p = 0.04, count_y = 35L, mu = 24, sigma = 0.25, alpha = -0.35),
    high_count_positive = list(binary_y = 0L, binary_p = 0.04, count_y = 35L, mu = 24, sigma = 0.25, alpha = 0.35)
  )
  for (name in names(cases)) {
    case <- cases[[name]]
    eta <- 0.999999 * tanh(case$alpha)
    actual <- do.call(
      drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability,
      c(unname(case[1:5]), list(eta = eta))
    )
    oracle <- do.call(
      bernoulli_nb2_conditional_oracle,
      c(unname(case[1:5]), list(eta = eta))
    )
    expect_identical(oracle$status, "ok", info = name)
    expect_identical(actual$status, "ok", info = name)
    expect_equal(actual$log_probability, oracle$log_probability,
      tolerance = 1e-10, info = name)
    rectangle <- do.call(
      bernoulli_nb2_pinned_rectangle_oracle,
      c(unname(case[1:5]), list(eta = eta))
    )
    if (identical(name, "tail_negative")) {
      expect_identical(rectangle$status, "ok", info = name)
      expect_equal(actual$log_probability, rectangle$log_probability,
        tolerance = 1e-10, info = name)
      next
    }
    if (identical(rectangle$status, "ok")) {
      expect_equal(actual$log_probability, rectangle$log_probability,
        tolerance = 1e-10, info = name)
    } else {
      expect_identical(rectangle$status, "oracle_unresolved", info = name)
    }
  }
})

test_that("Bernoulli x ordinary-NB2 near-boundary kernels agree or fail closed", {
  skip_if_not_installed("mvtnorm")
  for (alpha in c(-7, 7)) {
    eta <- 0.999999 * tanh(alpha)
    actual <- drmTMB:::drm_pair_bernoulli_nbinom2_rectangle_probability(
      1L, stats::plogis(-0.35), 3L, exp(0.5), 0.62, eta
    )
    oracle <- bernoulli_nb2_conditional_oracle(
      1L, stats::plogis(-0.35), 3L, exp(0.5), 0.62, eta
    )
    if (identical(actual$status, "ok") && identical(oracle$status, "ok")) {
      expect_equal(actual$log_probability, oracle$log_probability,
        tolerance = 1e-10, info = paste("alpha", alpha))
      rectangle <- bernoulli_nb2_pinned_rectangle_oracle(
        1L, stats::plogis(-0.35), 3L, exp(0.5), 0.62, eta
      )
      if (identical(rectangle$status, "ok")) {
        expect_equal(actual$log_probability, rectangle$log_probability,
          tolerance = 1e-10, info = paste("alpha", alpha))
      } else {
        expect_identical(rectangle$status, "oracle_unresolved",
          info = paste("alpha", alpha))
      }
    } else {
      expect_true(actual$status %in% c(
        "endpoint_failure", "integration_failure", "integration_error_exceeds_tolerance"
      ), info = paste("alpha", alpha))
    }
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
  expect_true(rare_high$relative_integration_error <= rare_high$integration_rel_tol)
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

test_that("Bernoulli x ordinary-NB2 endpoint failures remain diagnostic", {
  components <- list(
    pair_class = "bernoulli_nbinom2",
    descriptor = drmTMB:::drm_pair_descriptor("bernoulli_nbinom2"),
    binary_y = 0L,
    binary_p = 0.2,
    nbinom2_y = 0L,
    nbinom2_mu = 1e-300,
    nbinom2_sigma = 1e-150
  )
  fit <- drmTMB:::drm_pair_fit_eta(components)
  rows <- fit$diagnostics$count_interval$row_numerics
  expect_identical(fit$status, "boundary_unresolved")
  expect_true(fit$diagnostics$endpoint_failure)
  expect_true(fit$diagnostics$count_interval$endpoint_failure)
  expect_match(fit$diagnostics$count_interval$endpoint_failure_message,
    "endpoints are numerically unresolved")
  expect_identical(rows$status, "endpoint_failure")
  expect_true(is.na(rows$count_lower))
  expect_true(is.na(rows$count_upper))
})

test_that("Bernoulli x ordinary-NB2 beta slope uses a row-specific latent association", {
  set.seed(20260724)
  n <- 220L
  dat <- data.frame(x = seq(-1.4, 1.4, length.out = n))
  p <- stats::plogis(-0.2 + 0.3 * dat$x)
  mu <- exp(0.7 + 0.2 * dat$x)
  sigma <- rep(0.65, n)
  association_link <- -0.15 + 0.65 * dat$x
  eta <- 0.999999 * tanh(association_link)
  z_binary <- stats::rnorm(n)
  z_count <- eta * z_binary + sqrt(1 - eta^2) * stats::rnorm(n)
  components <- list(
    pair_class = "bernoulli_nbinom2",
    descriptor = drmTMB:::drm_pair_descriptor("bernoulli_nbinom2"),
    binary_y = as.integer(z_binary > stats::qnorm(p, lower.tail = FALSE)),
    binary_p = p,
    nbinom2_y = drmTMB:::drm_pair_nbinom2_quantile_from_normal(z_count, mu, sigma),
    nbinom2_mu = mu,
    nbinom2_sigma = sigma
  )
  design <- drmTMB:::drm_pair_association_design(
    ~x, dat, "bernoulli_nbinom2"
  )
  fit <- drmTMB:::drm_pair_fit_eta(components, design)

  expect_identical(fit$status, "interior")
  expect_equal(fit$coefficients, c("(Intercept)" = -0.15, x = 0.65), tolerance = 0.35)
  expect_length(fit$eta_internal, n)
  expect_gt(diff(range(fit$eta_internal)), 0.5)

  object <- structure(list(
    status = fit$status, kernel = latent_normal(), eta = fit$eta,
    eta_internal = fit$eta_internal, alpha = fit$alpha,
    association_coefficients = fit$coefficients,
    diagnostics = fit$diagnostics
  ), class = "drm_pair_association")
  coefficients <- association(object)
  fitted_eta <- association(object, type = "fitted")
  expect_named(coefficients, c("term", "association_link", "status", "boundary"))
  expect_equal(coefficients$term, c("(Intercept)", "x"))
  expect_named(fitted_eta, c("row", "association_link", "eta", "status"))
  expect_equal(fitted_eta$eta, fit$eta_internal)
  expect_named(fit$diagnostics$score, c("(Intercept)", "x"))
  expect_named(fit$diagnostics$curvature, c("(Intercept)", "x"))
  expect_true(all(is.finite(fit$diagnostics$score)))
  expect_lte(max(abs(fit$diagnostics$score)), 1e-3)
  expect_true(all(is.finite(fit$diagnostics$curvature)))
  expect_true(all(fit$diagnostics$curvature < -1e-6))
})

test_that("Bernoulli x ordinary-NB2 beta likelihood matches a row-specific independent oracle", {
  skip_if_not_installed("mvtnorm")
  x <- seq(-1, 1, length.out = 8L)
  components <- list(
    pair_class = "bernoulli_nbinom2",
    binary_y = c(0L, 1L, 0L, 1L, 1L, 0L, 1L, 0L),
    binary_p = stats::plogis(-0.25 + 0.4 * x),
    nbinom2_y = c(0L, 1L, 3L, 2L, 7L, 1L, 5L, 4L),
    nbinom2_mu = exp(0.4 + 0.3 * x),
    nbinom2_sigma = rep(0.65, length(x))
  )
  alpha <- c("(Intercept)" = -0.2, x = 0.45)
  eta <- 0.999999 * tanh(alpha[[1L]] + alpha[[2L]] * x)
  actual <- drmTMB:::drm_pair_bernoulli_nbinom2_loglik(
    alpha[[1L]] + alpha[[2L]] * x, components
  )
  oracle <- sum(vapply(seq_along(x), function(i) {
    log(bernoulli_nb2_oracle(
      components$binary_y[[i]], components$binary_p[[i]],
      components$nbinom2_y[[i]], components$nbinom2_mu[[i]],
      components$nbinom2_sigma[[i]], eta[[i]]
    ))
  }, numeric(1L)))
  expect_equal(actual, oracle, tolerance = 2e-8)
})

test_that("Bernoulli x ordinary-NB2 association accepts full fixed-effect grammar", {
  dat <- data.frame(
    x1 = seq(-1, 1, length.out = 12L),
    x2 = rep(c(-0.8, -0.1, 0.5), length.out = 12L),
    habitat = factor(rep(c("a", "b"), length.out = 12L))
  )
  design <- drmTMB:::drm_pair_association_design(
    ~x1 + x2 + habitat + x1:habitat + I(x2^2),
    dat, "bernoulli_nbinom2"
  )
  expect_identical(nrow(design$matrix), nrow(dat))
  expect_named(design, c(
    "matrix", "terms", "varying", "contrasts", "xlevels",
    "column_names", "fingerprint"
  ))
  expect_identical(colnames(design$matrix), design$column_names)
  expect_true("habitat" %in% names(design$xlevels))

  transformed <- drmTMB:::drm_pair_association_design(
    ~scale(x1) + stats::poly(x2, 2), dat, "bernoulli_nbinom2"
  )
  replay <- drmTMB:::drm_pair_association_newdata_design(
    list(association_design = transformed), dat[seq_len(7L), , drop = FALSE]
  )
  expect_identical(colnames(replay), colnames(transformed$matrix))
  expect_equal(
    as.vector(replay),
    as.vector(transformed$matrix[seq_len(7L), , drop = FALSE])
  )

  expect_error(
    drmTMB:::drm_pair_association_design(~., dat, "bernoulli_nbinom2"),
    "fixed-effect model-matrix"
  )
  expect_error(
    drmTMB:::drm_pair_association_design(~x1 + offset(x2), dat, "bernoulli_nbinom2"),
    "fixed-effect model-matrix"
  )
  expect_error(
    drmTMB:::drm_pair_association_design(~x1 + (1 | habitat), dat, "bernoulli_nbinom2"),
    "fixed-effect model-matrix"
  )
  expect_error(
    drmTMB:::drm_pair_association_design(
      ~x1 + I(2 * x1), dat, "bernoulli_nbinom2"
    ),
    "rank deficient"
  )
  dat_missing <- dat
  dat_missing$x2[[2L]] <- NA_real_
  expect_error(
    drmTMB:::drm_pair_association_design(
      ~x1 + x2, dat_missing, "bernoulli_nbinom2"
    ),
    "complete association model frame"
  )
  expect_error(
    drmTMB:::drm_pair_association_design(~x1, dat, "gaussian_bernoulli"),
    "only for literal Bernoulli x ordinary-NB2"
  )
  z <- seq_len(nrow(dat))
  expect_error(
    drmTMB:::drm_pair_association_design(~z, dat, "bernoulli_nbinom2"),
    "frozen analysis data"
  )
})

test_that("Bernoulli x ordinary-NB2 association predicts full fixed-effect designs", {
  set.seed(20260729)
  n <- 360L
  dat <- data.frame(
    x1 = seq(-1.2, 1.2, length.out = n),
    x2 = rep(c(-0.7, 0.7), length.out = n),
    habitat = factor(rep(c("forest", "field"), each = n / 2L))
  )
  association_link <- -0.15 + 0.45 * dat$x1 - 0.2 * dat$x2 +
    ifelse(dat$habitat == "field", 0.15, 0)
  eta <- 0.999999 * tanh(association_link)
  z_binary <- stats::rnorm(n)
  z_count <- eta * z_binary + sqrt(1 - eta^2) * stats::rnorm(n)
  dat$binary <- as.integer(
    z_binary > stats::qnorm(stats::plogis(-0.2 + 0.25 * dat$x1), lower.tail = FALSE)
  )
  dat$count <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(
    z_count, exp(0.5 + 0.15 * dat$x2), rep(0.6, n)
  )
  binary_fit <- drmTMB(bf(mu = binary ~ x1 + x2), binomial(), dat)
  count_fit <- drmTMB(bf(mu = count ~ x1 + x2, sigma = ~1), nbinom2(), dat)
  association_fit <- associate_pairs(
    binary_fit, count_fit, kernel = latent_normal(),
    association = ~x1 + x2 + habitat + x1:habitat
  )
  expect_false(identical(association_fit$status, "boundary_unresolved"))
  expect_equal(
    predict(association_fit, type = "link"),
    as.vector(association_fit$association_design$matrix %*%
      association_fit$association_coefficients)
  )
  expect_equal(
    predict(association_fit, type = "response"),
    0.999999 * tanh(predict(association_fit, type = "link"))
  )
  expect_equal(predict(association_fit), fitted(association_fit))
  expect_error(
    predict(association_fit, type = "response", se.fit = TRUE),
    "uncertainty is unavailable"
  )

  newdata <- data.frame(
    x1 = c(-0.5, 0.4), x2 = c(0.7, -0.7),
    habitat = factor(c("forest", "field"), levels = levels(dat$habitat))
  )
  new_design <- drmTMB:::drm_pair_association_newdata_design(
    association_fit, newdata
  )
  expect_equal(
    predict(association_fit, newdata = newdata, type = "link"),
    as.vector(new_design %*% association_fit$association_coefficients)
  )
  expect_equal(
    predict(association_fit, newdata = newdata),
    0.999999 * tanh(as.vector(new_design %*%
      association_fit$association_coefficients))
  )
  unseen <- newdata
  unseen$habitat <- factor("wetland")
  expect_error(
    predict(association_fit, newdata = unseen, type = "response"),
    "new-data association model frame"
  )
})
