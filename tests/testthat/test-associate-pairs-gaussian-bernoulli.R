new_arc6_1_data <- function(n = 180, eta = 0.45, seed = 20260723) {
  set.seed(seed)
  x <- stats::rnorm(n)
  z_g <- stats::rnorm(n)
  z_b <- eta * z_g + sqrt(1 - eta^2) * stats::rnorm(n)
  data.frame(
    x = x,
    trait_continuous = 0.25 + 0.55 * x + z_g,
    trait_binary = as.integer(z_b > stats::qnorm(0.62))
  )
}

fit_arc6_1_pair <- function(data = new_arc6_1_data()) {
  gaussian_fit <- drmTMB(
    bf(mu = trait_continuous ~ x, sigma = ~1),
    family = gaussian(),
    data = data
  )
  binary_fit <- drmTMB(
    bf(mu = trait_binary ~ x),
    family = binomial(),
    data = data
  )
  list(
    gaussian = gaussian_fit,
    binary = binary_fit,
    association = associate_pairs(
      gaussian_fit, binary_fit,
      kernel = latent_normal(), association = ~1
    )
  )
}

test_that("Gaussian x Bernoulli association freezes identical margins", {
  fits <- fit_arc6_1_pair()
  association_fit <- fits$association

  expect_s3_class(association_fit, "drm_pair_association")
  expect_equal(
    association_fit$margins$fit_1$coefficients,
    fits$gaussian$coefficients
  )
  expect_equal(
    association_fit$margins$fit_2$coefficients,
    fits$binary$coefficients
  )
  expect_equal(
    association_fit$margins$fit_1$fitted$mu,
    predict(fits$gaussian, dpar = "mu", type = "response")
  )
  expect_equal(
    association_fit$margins$fit_2$fitted$mu,
    predict(fits$binary, dpar = "mu", type = "response")
  )
  expect_length(association_fit$provenance$fit_hashes, 2L)
  expect_match(association_fit$provenance$data_hash, "^[0-9a-f]{32}$")
  expect_equal(nrow(fitted(association_fit)), nrow(fits$gaussian$data))
  expect_named(fitted(association_fit), c("trait_continuous", "trait_binary"))
})

test_that("Gaussian x Bernoulli association is symmetric in input order", {
  fits <- fit_arc6_1_pair()
  reverse_fit <- associate_pairs(
    fits$binary, fits$gaussian,
    kernel = latent_normal(), association = ~1
  )

  expect_equal(reverse_fit$eta, fits$association$eta, tolerance = 1e-8)
  expect_equal(
    names(fitted(reverse_fit)),
    c("trait_binary", "trait_continuous")
  )
  expect_equal(
    names(simulate(reverse_fit, seed = 1)),
    c("trait_binary", "trait_continuous")
  )
})

test_that("Gaussian x Bernoulli likelihood has product-margin and normalization limits", {
  components <- list(
    gaussian_y = c(-0.6, 0.1, 1.2),
    binary_y = c(0, 1, 1),
    gaussian_mu = c(-0.2, 0, 0.4),
    gaussian_sigma = c(0.8, 1.1, 0.6),
    binary_p = c(0.2, 0.45, 0.8)
  )
  loglik_zero <- drmTMB:::drm_pair_gaussian_bernoulli_loglik(0, components)
  expected_zero <- sum(
    stats::dnorm(
      components$gaussian_y,
      components$gaussian_mu,
      components$gaussian_sigma,
      log = TRUE
    ) +
      stats::dbinom(components$binary_y, 1, components$binary_p, log = TRUE)
  )
  expect_equal(loglik_zero, expected_zero, tolerance = 1e-12)

  eta <- 0.7
  p <- 0.23
  conditional_sum <- function(z) {
    drmTMB:::drm_pair_gaussian_bernoulli_conditional_prob(z, p, eta, 0) +
      drmTMB:::drm_pair_gaussian_bernoulli_conditional_prob(z, p, eta, 1)
  }
  expect_equal(
    stats::integrate(
      function(z) stats::dnorm(z) * conditional_sum(z),
      -Inf,
      Inf
    )$value,
    1,
    tolerance = 1e-9
  )
  expect_equal(
    stats::integrate(
      function(z) {
        stats::dnorm(z) *
          drmTMB:::drm_pair_gaussian_bernoulli_conditional_prob(z, p, eta, 1)
      },
      -Inf,
      Inf
    )$value,
    p,
    tolerance = 1e-8
  )

  independent_oracle <- function(alpha, components) {
    eta <- 0.999999 * tanh(alpha)
    vapply(seq_along(components$gaussian_y), function(i) {
      z_g <- (components$gaussian_y[[i]] - components$gaussian_mu[[i]]) /
        components$gaussian_sigma[[i]]
      threshold <- stats::qnorm(1 - components$binary_p[[i]])
      limits <- if (components$binary_y[[i]] == 1L) {
        c(threshold, Inf)
      } else {
        c(-Inf, threshold)
      }
      bivariate_density <- function(z_b) {
        exp(
          -(z_g^2 - 2 * eta * z_g * z_b + z_b^2) /
            (2 * (1 - eta^2))
        ) / (2 * pi * sqrt(1 - eta^2))
      }
      log(stats::dnorm(
        components$gaussian_y[[i]],
        components$gaussian_mu[[i]],
        components$gaussian_sigma[[i]]
      )) - log(stats::dnorm(z_g)) + log(stats::integrate(
        bivariate_density, lower = limits[[1L]], upper = limits[[2L]]
      )$value)
    }, numeric(1L)) |> sum()
  }
  expect_equal(
    drmTMB:::drm_pair_gaussian_bernoulli_loglik(atanh(0.35), components),
    independent_oracle(atanh(0.35), components),
    tolerance = 1e-8
  )
})

test_that("Gaussian x Bernoulli simulation uses frozen margins and the fitted kernel", {
  fits <- fit_arc6_1_pair()
  association_fit <- fits$association
  association_fit$eta <- 0
  association_fit$eta_internal <- 0
  observed <- simulate(association_fit, seed = 918)

  set.seed(918)
  n <- nrow(observed)
  z_g <- stats::rnorm(n)
  z_b <- stats::rnorm(n)
  expected <- data.frame(
    trait_continuous = association_fit$components$gaussian_mu +
      association_fit$components$gaussian_sigma * z_g,
    trait_binary = as.integer(
      z_b > stats::qnorm(1 - association_fit$components$binary_p)
    )
  )
  expect_equal(observed, expected)
})

test_that("Gaussian x Bernoulli diagnostics retain near-boundary outcomes", {
  components <- list(
    gaussian_y = seq(-2, 2, length.out = 40),
    binary_y = as.integer(seq(-2, 2, length.out = 40) > 0),
    gaussian_mu = rep(0, 40),
    gaussian_sigma = rep(1, 40),
    binary_p = rep(0.5, 40)
  )
  fit <- drmTMB:::drm_pair_fit_eta(components)

  expect_true(fit$status %in% c("near_boundary", "boundary_unresolved"))
  expect_true(
    fit$diagnostics$near_boundary || fit$diagnostics$boundary_unresolved
  )
  expect_length(fit$diagnostics$multistart_objectives, 3L)
})

test_that("Gaussian x Bernoulli association fences unsupported public methods", {
  fits <- fit_arc6_1_pair()
  association_fit <- fits$association

  expect_snapshot(error = TRUE, rho12(association_fit))
  expect_snapshot(error = TRUE, vcov(association_fit))
  expect_snapshot(error = TRUE, confint(association_fit))
  expect_snapshot(error = TRUE, quantile(association_fit))
  expect_snapshot(error = TRUE, update(association_fit))
  expect_snapshot(error = TRUE, emmeans::recover_data(association_fit))
  expect_snapshot(
    error = TRUE,
    predict(association_fit, newdata = data.frame(x = 0))
  )
  expect_snapshot(
    error = TRUE,
    associate_pairs(
      fits$gaussian,
      fits$binary,
      kernel = latent_normal(),
      association = ~x
    )
  )
  expect_snapshot(error = TRUE, associate_pairs(fits$gaussian, fits$binary))
  expect_snapshot(
    error = TRUE,
    associate_pairs(fits$gaussian, fits$binary, kernel = latent_normal())
  )
})

test_that("Gaussian x Bernoulli association rejects different rows and trials", {
  fits <- fit_arc6_1_pair()
  data_other <- new_arc6_1_data(seed = 20260724)
  binary_other <- drmTMB(
    bf(mu = trait_binary ~ x),
    family = binomial(),
    data = data_other
  )
  expect_snapshot(
    error = TRUE,
    associate_pairs(
      fits$gaussian, binary_other,
      kernel = latent_normal(), association = ~1
    )
  )

  trial_data <- transform(
    fits$gaussian$data,
    successes = 2L * trait_binary,
    trials = 2L
  )
  trial_gaussian <- drmTMB(
    bf(mu = trait_continuous ~ x, sigma = ~1),
    family = gaussian(), data = trial_data
  )
  trial_fit <- drmTMB(
    bf(mu = cbind(successes, trials - successes) ~ x),
    family = binomial(),
    data = trial_data
  )
  expect_snapshot(
    error = TRUE,
    associate_pairs(
      trial_gaussian, trial_fit,
      kernel = latent_normal(), association = ~1
    )
  )
})

test_that("Gaussian x Bernoulli association rejects every first-slice fit exclusion", {
  fits <- fit_arc6_1_pair()
  construct <- function(gaussian = fits$gaussian, binary = fits$binary) {
    associate_pairs(
      gaussian, binary,
      kernel = latent_normal(), association = ~1
    )
  }

  weighted <- fits$gaussian
  weighted$model$weights <- rep(2, weighted$nobs)
  expect_error(construct(gaussian = weighted), "unit weights")

  offset <- fits$gaussian
  offset$model$offset <- list(mu = rep(0.25, offset$nobs))
  expect_error(construct(gaussian = offset), "offset")

  reml <- fits$gaussian
  reml$REML <- TRUE
  expect_error(construct(gaussian = reml), "fixed-effect ML")

  random <- fits$gaussian
  random$random_effects <- list(id = 0)
  expect_error(construct(gaussian = random), "random or structured")

  structured <- fits$gaussian
  structured$model$random_names <- "phylo_mu"
  expect_error(construct(gaussian = structured), "random or structured")

  incomplete <- fits$gaussian
  incomplete$model$keep[[1L]] <- FALSE
  expect_error(construct(gaussian = incomplete), "complete analysis data")
})
