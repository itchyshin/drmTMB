arc6_integration_data <- function(n = 120L, seed = 20260724) {
  set.seed(seed)
  x <- stats::rnorm(n)
  z_1 <- stats::rnorm(n)
  z_2 <- .30 * z_1 + sqrt(1 - .30^2) * stats::rnorm(n)
  z_3 <- -.25 * z_1 + sqrt(1 - .25^2) * stats::rnorm(n)
  z_4 <- .35 * z_1 + sqrt(1 - .35^2) * stats::rnorm(n)
  z_5 <- .20 * z_4 + sqrt(1 - .20^2) * stats::rnorm(n)
  p_1 <- stats::plogis(-.2 + .35 * x)
  p_2 <- stats::plogis(.1 - .25 * x)
  data.frame(
    x = x,
    continuous = .2 + .5 * x + z_1,
    binary_1 = as.integer(z_2 > stats::qnorm(p_1, lower.tail = FALSE)),
    binary_2 = as.integer(z_3 > stats::qnorm(p_2, lower.tail = FALSE)),
    count_1 = drmTMB:::drm_pair_nbinom2_quantile_from_normal(
      z_4, exp(.3 + .15 * x), rep(.55, n)
    ),
    count_2 = drmTMB:::drm_pair_nbinom2_quantile_from_normal(
      z_5, exp(.1 - .1 * x), rep(.45, n)
    )
  )
}

arc6_integration_margins <- function(data = arc6_integration_data()) {
  list(
    gaussian = drmTMB(bf(mu = continuous ~ x, sigma = ~1), gaussian(), data),
    binary_1 = drmTMB(bf(mu = binary_1 ~ x), binomial(), data),
    binary_2 = drmTMB(bf(mu = binary_2 ~ x), binomial(), data),
    count_1 = drmTMB(bf(mu = count_1 ~ x, sigma = ~1), nbinom2(), data),
    count_2 = drmTMB(bf(mu = count_2 ~ x, sigma = ~1), nbinom2(), data)
  )
}

test_that("Arc 6.8 matrix preserves one post-fit contract across admitted pairs", {
  margins <- arc6_integration_margins()
  cases <- list(
    list(class = "gaussian_bernoulli", left = "gaussian", right = "binary_1"),
    list(class = "gaussian_nbinom2", left = "gaussian", right = "count_1"),
    list(class = "bernoulli_bernoulli", left = "binary_1", right = "binary_2"),
    list(class = "bernoulli_nbinom2", left = "binary_1", right = "count_1"),
    list(class = "nbinom2_nbinom2", left = "count_1", right = "count_2")
  )

  for (case in cases) {
    left <- margins[[case$left]]
    right <- margins[[case$right]]
    fit <- associate_pairs(left, right,
      kernel = latent_normal(), association = ~1)
    reverse <- associate_pairs(right, left,
      kernel = latent_normal(), association = ~1)

    expect_s3_class(fit, "drm_pair_association")
    expect_identical(fit$components$pair_class, case$class)
    expect_equal(fit$margins$fit_1$coefficients, left$coefficients)
    expect_equal(fit$margins$fit_2$coefficients, right$coefficients)
    expect_equal(fit$logLik, reverse$logLik, tolerance = 1e-7)
    expect_equal(fit$eta, reverse$eta, tolerance = 1e-7)
    expect_identical(names(fitted(fit)), unlist(c(left$model$response_name, right$model$response_name), use.names = FALSE))
    expect_equal(predict(fit), fitted(fit))
    expect_warning(
      association_vcov <- vcov(fit),
      class = "drmTMB_association_inference_warning"
    )
    expect_identical(
      dim(association_vcov),
      rep(length(fit$association_coefficients), 2L)
    )
    expect_true(all(is.finite(association_vcov)))
    expect_warning(
      association_interval <- confint(fit),
      class = "drmTMB_association_inference_warning"
    )
    expect_identical(nrow(association_interval), length(fit$association_coefficients))
    expect_warning(
      eta_interval <- confint(fit, type = "eta"),
      class = "drmTMB_association_inference_warning"
    )
    expect_identical(rownames(eta_interval), "eta")
    expect_equal(
      unname(eta_interval),
      0.999999 * tanh(unname(association_interval)),
      tolerance = 1e-12
    )
    expect_warning(
      eta_prediction <- predict(
        fit,
        type = "eta",
        se.fit = TRUE,
        interval = "confidence"
      ),
      class = "drmTMB_association_inference_warning"
    )
    expect_identical(dim(eta_prediction$fit), c(nrow(fit$association_design$matrix), 3L))
    expect_length(eta_prediction$se.fit, nrow(fit$association_design$matrix))
    expect_true(all(is.finite(eta_prediction$se.fit)))
    expect_true(all(eta_prediction$se.fit > 0))
    expect_true(all(abs(eta_prediction$fit[, c("lwr", "upr")]) < 1))
    expect_equal(
      unname(eta_prediction$fit[1L, c("lwr", "upr")]),
      as.vector(eta_interval),
      tolerance = 1e-12
    )
    expect_error(rho12(fit), "not mixed pair associations")
    if (identical(case$class, "bernoulli_nbinom2")) {
      expect_length(predict(fit, newdata = data.frame(x = 0)), 1L)
    } else {
      expect_error(predict(fit, newdata = data.frame(x = 0)), "frozen analysis rows")
    }

    fit$status <- "interior"
    fit$eta <- fit$eta_internal <- 0
    expect_equal(simulate(fit, seed = 918), simulate(fit, seed = 918))
  }
})

test_that("Arc 6.8 keeps exact-special rho12 routes separate from eta", {
  skip_if_not_installed("mvtnorm")
  set.seed(20260724)
  dat <- data.frame(
    x = stats::rnorm(80),
    y1 = exp(.2 + stats::rnorm(80, sd = .25)),
    y2 = exp(-.1 + stats::rnorm(80, sd = .30))
  )
  lognormal_fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    biv_lognormal(), dat
  )
  expect_true(all(is.finite(rho12(lognormal_fit))))
  expect_error(association(lognormal_fit), "no applicable method")
})
