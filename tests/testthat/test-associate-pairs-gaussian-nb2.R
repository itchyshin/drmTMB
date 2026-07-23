new_arc6_2_data <- function(n = 240, eta = 0.4, seed = 20260723) {
  set.seed(seed)
  x <- stats::rnorm(n)
  z_g <- stats::rnorm(n)
  z_nb <- eta * z_g + sqrt(1 - eta^2) * stats::rnorm(n)
  gaussian_mu <- 0.15 + 0.45 * x
  nbinom2_mu <- exp(0.3 + 0.25 * x)
  nbinom2_sigma <- exp(-0.45 + 0.1 * x)
  data.frame(
    x = x,
    trait_continuous = gaussian_mu + exp(-0.1 + 0.08 * x) * z_g,
    trait_count = drmTMB:::drm_pair_nbinom2_quantile_from_normal(
      z_nb, nbinom2_mu, nbinom2_sigma
    )
  )
}

fit_arc6_2_pair <- function(data = new_arc6_2_data()) {
  gaussian_fit <- drmTMB(
    bf(mu = trait_continuous ~ x, sigma = ~x),
    family = gaussian(), data = data
  )
  nbinom2_fit <- drmTMB(
    bf(mu = trait_count ~ x, sigma = ~x),
    family = nbinom2(), data = data
  )
  list(
    gaussian = gaussian_fit,
    nbinom2 = nbinom2_fit,
    association = associate_pairs(
      gaussian_fit, nbinom2_fit,
      kernel = latent_normal(), association = ~1
    )
  )
}

test_that("Gaussian x ordinary-NB2 association freezes both fitted margins", {
  fits <- fit_arc6_2_pair()
  association_fit <- fits$association

  expect_s3_class(association_fit, "drm_pair_association")
  expect_equal(
    association_fit$margins$fit_1$coefficients,
    fits$gaussian$coefficients
  )
  expect_equal(
    association_fit$margins$fit_2$coefficients,
    fits$nbinom2$coefficients
  )
  expect_equal(
    association_fit$components$gaussian_mu,
    predict(fits$gaussian, dpar = "mu", type = "response")
  )
  expect_equal(
    association_fit$components$gaussian_sigma,
    predict(fits$gaussian, dpar = "sigma", type = "response")
  )
  expect_equal(
    association_fit$components$nbinom2_mu,
    predict(fits$nbinom2, dpar = "mu", type = "response")
  )
  expect_equal(
    association_fit$components$nbinom2_sigma,
    predict(fits$nbinom2, dpar = "sigma", type = "response")
  )
  expect_named(fitted(association_fit), c("trait_continuous", "trait_count"))
})

test_that("Gaussian x ordinary-NB2 association is symmetric in input order", {
  fits <- fit_arc6_2_pair()
  reverse_fit <- associate_pairs(
    fits$nbinom2, fits$gaussian,
    kernel = latent_normal(), association = ~1
  )

  expect_equal(reverse_fit$eta, fits$association$eta, tolerance = 1e-8)
  expect_equal(reverse_fit$logLik, fits$association$logLik, tolerance = 1e-8)
  expect_equal(names(fitted(reverse_fit)), c("trait_count", "trait_continuous"))
  expect_equal(names(simulate(reverse_fit, seed = 1)), c("trait_count", "trait_continuous"))
})

test_that("Gaussian x ordinary-NB2 likelihood has product-margin and oracle limits", {
  components <- list(
    gaussian_y = c(-0.6, 0.1, 1.2),
    nbinom2_y = c(0, 3, 18),
    gaussian_mu = c(-0.2, 0, 0.4),
    gaussian_sigma = c(0.8, 1.1, 0.6),
    nbinom2_mu = c(0.8, 2.4, 8.5),
    nbinom2_sigma = c(0.35, 0.6, 0.25)
  )
  loglik_zero <- drmTMB:::drm_pair_gaussian_nbinom2_loglik(0, components)
  expected_zero <- sum(
    stats::dnorm(
      components$gaussian_y,
      components$gaussian_mu,
      components$gaussian_sigma,
      log = TRUE
    ) +
      stats::dnbinom(
        components$nbinom2_y,
        size = drmTMB:::drm_nbinom2_size(components$nbinom2_sigma),
        mu = components$nbinom2_mu,
        log = TRUE
      )
  )
  expect_equal(loglik_zero, expected_zero, tolerance = 1e-12)

  eta <- 0.7
  mu <- 2.4
  sigma <- 0.6
  conditional_mass <- function(z, y) {
    drmTMB:::drm_pair_gaussian_nbinom2_conditional_prob(
      z, y = y, mu = mu, sigma = sigma, eta = eta
    )
  }
  conditional_sum <- function(z) {
    vapply(
      z,
      function(z_i) sum(vapply(
        0:80,
        function(y) conditional_mass(z_i, y),
        numeric(1L)
      )),
      numeric(1L)
    )
  }
  expect_equal(
    stats::integrate(
      function(z) stats::dnorm(z) * conditional_sum(z),
      -Inf, Inf
    )$value,
    1,
    tolerance = 1e-8
  )
  expect_equal(
    stats::integrate(
      function(z) stats::dnorm(z) * conditional_mass(z, 3),
      -Inf, Inf
    )$value,
    stats::dnbinom(3, size = drmTMB:::drm_nbinom2_size(sigma), mu = mu),
    tolerance = 1e-8
  )

  independent_oracle <- function(alpha, components) {
    eta <- 0.999999 * tanh(alpha)
    normal_quantile_from_log_tails <- function(log_cdf, log_survival) {
      if (log_cdf <= log(0.5)) {
        return(stats::qnorm(log_cdf, log.p = TRUE))
      }
      stats::qnorm(log_survival, lower.tail = FALSE, log.p = TRUE)
    }
    vapply(seq_along(components$gaussian_y), function(i) {
      z_g <- (components$gaussian_y[[i]] - components$gaussian_mu[[i]]) /
        components$gaussian_sigma[[i]]
      size <- drmTMB:::drm_nbinom2_size(components$nbinom2_sigma[[i]])
      y <- components$nbinom2_y[[i]]
      upper_log_cdf <- stats::pnbinom(
        y, size = size, mu = components$nbinom2_mu[[i]], log.p = TRUE
      )
      upper_log_survival <- stats::pnbinom(
        y, size = size, mu = components$nbinom2_mu[[i]],
        lower.tail = FALSE, log.p = TRUE
      )
      lower <- if (y == 0L) {
        -Inf
      } else {
        lower_log_cdf <- stats::pnbinom(
          y - 1, size = size, mu = components$nbinom2_mu[[i]], log.p = TRUE
        )
        lower_log_survival <- stats::pnbinom(
          y - 1, size = size, mu = components$nbinom2_mu[[i]],
          lower.tail = FALSE, log.p = TRUE
        )
        normal_quantile_from_log_tails(lower_log_cdf, lower_log_survival)
      }
      limits <- c(
        lower,
        normal_quantile_from_log_tails(upper_log_cdf, upper_log_survival)
      )
      bivariate_density <- function(z_nb) {
        exp(
          -(z_g^2 - 2 * eta * z_g * z_nb + z_nb^2) /
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
    drmTMB:::drm_pair_gaussian_nbinom2_loglik(atanh(0.35), components),
    independent_oracle(atanh(0.35), components),
    tolerance = 1e-8
  )
})

test_that("Gaussian x ordinary-NB2 simulation uses coupled latent-normal draws", {
  fits <- fit_arc6_2_pair()
  association_fit <- fits$association
  association_fit$eta <- 0
  association_fit$eta_internal <- 0
  observed <- simulate(association_fit, seed = 918)

  set.seed(918)
  n <- nrow(observed)
  z_g <- stats::rnorm(n)
  z_nb <- stats::rnorm(n)
  expected <- data.frame(
    trait_continuous = association_fit$components$gaussian_mu +
      association_fit$components$gaussian_sigma * z_g,
    trait_count = drmTMB:::drm_pair_nbinom2_quantile_from_normal(
      z_nb,
      association_fit$components$nbinom2_mu,
      association_fit$components$nbinom2_sigma
    )
  )
  expect_equal(observed, expected)
})

test_that("Gaussian x ordinary-NB2 coupled quantiles retain finite upper tails", {
  counts <- drmTMB:::drm_pair_nbinom2_quantile_from_normal(
    z = c(-9, 0, 9),
    mu = c(2.5, 2.5, 2.5),
    sigma = c(0.6, 0.6, 0.6)
  )

  expect_equal(any(!is.finite(counts)), FALSE)
  expect_gt(counts[[3L]], counts[[2L]])
})

test_that("Gaussian x ordinary-NB2 keeps zero and high-tail probabilities finite", {
  z <- c(-2.3, 0.4)
  probabilities <- vapply(
    c(0L, 35L),
    function(y) drmTMB:::drm_pair_gaussian_nbinom2_conditional_prob(
      z, y = y, mu = 4.5, sigma = 0.7, eta = 0.55
    ),
    numeric(length(z))
  )
  expect_true(all(is.finite(probabilities)))
  expect_true(all(probabilities > 0))
  expect_true(all(probabilities < 1))
})

test_that("Gaussian x ordinary-NB2 rejects malformed or unsupported NB2 margins", {
  fits <- fit_arc6_2_pair()
  construct <- function(nbinom2 = fits$nbinom2) {
    associate_pairs(
      fits$gaussian, nbinom2,
      kernel = latent_normal(), association = ~1
    )
  }

  malformed <- fits$nbinom2
  malformed$model$y[[1L]] <- -1
  expect_error(construct(malformed), "non-negative integer|ordinary.*NB2")

  zi_fit <- drmTMB(
    bf(mu = trait_count ~ x, sigma = ~x, zi = ~1),
    family = nbinom2(), data = fits$gaussian$data
  )
  expect_error(construct(zi_fit), "ordinary.*nbinom2|requires one")

  positive <- transform(fits$gaussian$data, trait_count = trait_count + 1L)
  positive_gaussian <- drmTMB(
    bf(mu = trait_continuous ~ x, sigma = ~x), gaussian(), positive
  )
  truncated_fit <- drmTMB(
    bf(mu = trait_count ~ x, sigma = ~x), truncated_nbinom2(), positive
  )
  expect_error(
    associate_pairs(
      positive_gaussian, truncated_fit,
      kernel = latent_normal(), association = ~1
    ),
    "requires one"
  )

  hurdle_fit <- drmTMB(
    bf(mu = trait_count ~ x, sigma = ~x, hu = ~1),
    truncated_nbinom2(), fits$gaussian$data
  )
  expect_error(construct(hurdle_fit), "requires one")

  grouped <- transform(fits$gaussian$data, group = gl(8, 30))
  random_fit <- drmTMB(
    bf(mu = trait_count ~ x + (1 | group), sigma = ~x),
    family = nbinom2(), data = grouped
  )
  expect_error(construct(random_fit), "random or structured")
})

test_that("Gaussian x ordinary-NB2 association remains point-estimate only", {
  fits <- fit_arc6_2_pair()
  association_fit <- fits$association

  expect_error(vcov(association_fit), "unavailable")
  expect_error(confint(association_fit), "unavailable")
  expect_error(profile(association_fit), "unavailable")
  expect_error(
    predict(association_fit, newdata = data.frame(x = 0)),
    "frozen analysis rows"
  )
  expect_error(
    associate_pairs(
      fits$gaussian,
      fits$nbinom2,
      kernel = latent_normal(), association = ~x
    ),
    "association = ~ 1"
  )
})
