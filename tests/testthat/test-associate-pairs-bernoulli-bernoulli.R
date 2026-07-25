new_arc6_5_data <- function(n = 320, eta = 0.45, seed = 20260724) {
  set.seed(seed)
  x <- stats::rnorm(n)
  z_1 <- stats::rnorm(n)
  z_2 <- eta * z_1 + sqrt(1 - eta^2) * stats::rnorm(n)
  p_1 <- stats::plogis(-0.25 + 0.55 * x)
  p_2 <- stats::plogis(0.15 - 0.45 * x)
  data.frame(
    x = x,
    trait_binary_1 = as.integer(z_1 > stats::qnorm(p_1, lower.tail = FALSE)),
    trait_binary_2 = as.integer(z_2 > stats::qnorm(p_2, lower.tail = FALSE))
  )
}

fit_arc6_5_pair <- function(data = new_arc6_5_data()) {
  binary_1 <- drmTMB(
    bf(mu = trait_binary_1 ~ x), family = binomial(), data = data
  )
  binary_2 <- drmTMB(
    bf(mu = trait_binary_2 ~ x), family = binomial(), data = data
  )
  list(
    binary_1 = binary_1,
    binary_2 = binary_2,
    association = associate_pairs(
      binary_1, binary_2, kernel = latent_normal(), association = ~1
    )
  )
}

test_that("Bernoulli x Bernoulli association freezes margins and is symmetric", {
  fits <- fit_arc6_5_pair()
  reverse <- associate_pairs(
    fits$binary_2, fits$binary_1, kernel = latent_normal(), association = ~1
  )

  expect_s3_class(fits$association, "drm_pair_association")
  expect_equal(fits$association$margins$fit_1$coefficients, fits$binary_1$coefficients)
  expect_equal(fits$association$margins$fit_2$coefficients, fits$binary_2$coefficients)
  expect_equal(fits$association$eta, reverse$eta, tolerance = 1e-8)
  expect_equal(fits$association$logLik, reverse$logLik, tolerance = 1e-8)
  expect_named(fitted(fits$association), c("trait_binary_1", "trait_binary_2"))
  expect_named(fitted(reverse), c("trait_binary_2", "trait_binary_1"))
})

test_that("Bernoulli rectangle evaluator has product and normalization limits", {
  components <- list(
    pair_class = "bernoulli_bernoulli",
    binary_1_y = c(0L, 0L, 1L, 1L),
    binary_1_p = rep(0.23, 4L),
    binary_2_y = c(0L, 1L, 0L, 1L),
    binary_2_p = rep(0.71, 4L)
  )
  probabilities <- drmTMB:::drm_pair_bernoulli_bernoulli_probabilities(
    0, components
  )
  expected <- c((1 - 0.23) * (1 - 0.71), (1 - 0.23) * 0.71,
    0.23 * (1 - 0.71), 0.23 * 0.71)
  expect_equal(probabilities, expected, tolerance = 1e-10)
  expect_equal(sum(probabilities), 1, tolerance = 1e-10)
  expect_equal(
    drmTMB:::drm_pair_bernoulli_bernoulli_loglik(0, components),
    sum(log(expected)), tolerance = 1e-10
  )
})

test_that("Bernoulli rectangle evaluator agrees with independent mvtnorm oracle", {
  skip_if_not_installed("mvtnorm")
  eta <- 0.62
  alpha <- atanh(eta / 0.999999)
  p_1 <- 0.08
  p_2 <- 0.83
  for (y_1 in 0:1) {
    for (y_2 in 0:1) {
      observed <- drmTMB:::drm_pair_bernoulli_rectangle_probability(
        y_1, p_1, y_2, p_2, eta
      )
      lower <- c(if (y_1 == 1L) stats::qnorm(p_1, lower.tail = FALSE) else -Inf,
        if (y_2 == 1L) stats::qnorm(p_2, lower.tail = FALSE) else -Inf)
      upper <- c(if (y_1 == 1L) Inf else stats::qnorm(p_1, lower.tail = FALSE),
        if (y_2 == 1L) Inf else stats::qnorm(p_2, lower.tail = FALSE))
      oracle <- as.numeric(mvtnorm::pmvnorm(
        lower = lower, upper = upper, mean = c(0, 0),
        sigma = matrix(c(1, eta, eta, 1), 2),
        algorithm = mvtnorm::Miwa(steps = 2048L)
      ))
      expect_equal(observed, oracle, tolerance = 1e-8)
    }
  }
  components <- list(
    pair_class = "bernoulli_bernoulli",
    binary_1_y = c(0L, 1L), binary_1_p = c(0.08, 0.92),
    binary_2_y = c(1L, 0L), binary_2_p = c(0.83, 0.17)
  )
  expect_true(is.finite(drmTMB:::drm_pair_bernoulli_bernoulli_loglik(alpha, components)))
})

test_that("Bernoulli rectangle evaluator keeps rare interior tails finite", {
  expect_true(is.finite(stats::qnorm(1e-15, lower.tail = FALSE)))
  expect_true(is.finite(stats::qnorm(1 - 1e-15, lower.tail = FALSE)))
  probabilities <- vapply(expand.grid(y_1 = 0:1, y_2 = 0:1), function(state) {
    drmTMB:::drm_pair_bernoulli_rectangle_probability(
      state[[1L]], 1e-15, state[[2L]], 1 - 1e-15, 0.7
    )
  }, numeric(1L))
  expect_true(all(is.finite(probabilities)))
  expect_true(all(probabilities >= 0))
})

test_that("Bernoulli x Bernoulli simulation draws both frozen margins", {
  fits <- fit_arc6_5_pair()
  association_fit <- fits$association
  association_fit$eta <- 0
  association_fit$eta_internal <- 0
  observed <- simulate(association_fit, seed = 918)
  set.seed(918)
  n <- nrow(observed)
  expected <- data.frame(
    trait_binary_1 = as.integer(stats::rnorm(n) > stats::qnorm(association_fit$components$binary_1_p, lower.tail = FALSE)),
    trait_binary_2 = as.integer(stats::rnorm(n) > stats::qnorm(association_fit$components$binary_2_p, lower.tail = FALSE))
  )
  expect_equal(observed, expected)
})

test_that("Bernoulli x Bernoulli diagnostics and fences are explicit", {
  fits <- fit_arc6_5_pair()
  association_fit <- fits$association
  diagnostics <- association_fit$diagnostics$response_patterns
  expect_equal(sum(diagnostics$table), nrow(fits$binary_1$data))
  expect_true(is.finite(diagnostics$min_rectangle_mass))
  expect_snapshot(error = TRUE, rho12(association_fit))
  expect_snapshot(error = TRUE, vcov(association_fit))
  expect_snapshot(error = TRUE, confint(association_fit))
  expect_snapshot(error = TRUE, predict(association_fit, newdata = data.frame(x = 0)))
  expect_snapshot(error = TRUE, associate_pairs(
    fits$binary_1, fits$binary_1, kernel = latent_normal(), association = ~1
  ))
})

test_that("Arc 6.5 retained interior seed stays fail-closed at its flat boundary", {
  set.seed(650016L)
  n <- 120L
  x <- stats::rnorm(n)
  p_1 <- stats::plogis(stats::qlogis(0.2) + 0.35 * x)
  p_2 <- stats::plogis(stats::qlogis(0.7) - 0.30 * x)
  z_1 <- stats::rnorm(n)
  z_2 <- 0.5 * z_1 + sqrt(1 - 0.5^2) * stats::rnorm(n)
  data <- data.frame(
    x = x,
    y_1 = as.integer(z_1 > stats::qnorm(p_1, lower.tail = FALSE)),
    y_2 = as.integer(z_2 > stats::qnorm(p_2, lower.tail = FALSE))
  )
  fit_1 <- drmTMB(bf(mu = y_1 ~ x), binomial(), data)
  fit_2 <- drmTMB(bf(mu = y_2 ~ x), binomial(), data)
  association_fit <- associate_pairs(
    fit_1, fit_2, kernel = latent_normal(), association = ~1
  )

  expect_identical(association_fit$status, "boundary_unresolved")
  expect_true(is.na(association_fit$eta))
  expect_true(association_fit$diagnostics$multistart_disagreement)
  expect_false(association_fit$diagnostics$convergence_failure)
  expect_false(association_fit$diagnostics$weak_curvature)
  expect_false(association_fit$diagnostics$score_failure)
  expect_equal(
    as.integer(association_fit$diagnostics$response_patterns$table),
    c(36L, 0L, 59L, 25L)
  )
})
