test_that("fixed-only Student-t priors use the explicit v2 bridge payload", {
  student <- drm_prior_student_t(
    dpar = "mu", coef = "x", mean = 0.25, scale = 1.4, df = 4.5
  )
  normal <- drm_prior_normal(dpar = "mu", coef = "(Intercept)", mean = 0, sd = 2)
  resolved <- data.frame(
    dpar = c("mu", "mu"), coefficient = c("x", "(Intercept)"),
    matrix_column = c(2L, 1L), mean = c(0.25, 0), sd = c(1.4, 2),
    precision = c(1 / 1.4^2, 1 / 2^2), df = c(4.5, NA_real_),
    reason = c("exact column", "exact column"), kind = c("student_t", "normal")
  )

  options <- drm_fixed_prior_bridge_options(list(student, normal), resolved)
  testthat::expect_identical(options$priors, list(
    list(kind = "student_t", dpar = "mu", coef = "x",
      location = 0.25, scale = 1.4, df = 4.5),
    list(kind = "normal", dpar = "mu", coef = "(Intercept)",
      mean = 0, sd = 2)
  ))
  testthat::expect_identical(options$prior_expected, list(
    list(dpar = "mu", coef = "x"),
    list(dpar = "mu", coef = "(Intercept)")
  ))
  testthat::expect_false(drm_prior_uses_native_only_targets(list(student, normal)))
  testthat::expect_true(drm_prior_uses_native_only_targets(list(
    student, drm_prior_sd_gamma("mu", "site", shape = 2, rate = 3)
  )))
  testthat::expect_true(drm_prior_uses_native_only_targets(list(
    drm_prior_student_t("mu1", "x", mean = 0, scale = 1, df = 4)
  )))
})

test_that("fixed-effect-priors v2 validates targets and Student-t parameters", {
  resolved <- data.frame(
    dpar = c("mu", "mu"), coefficient = c("x", "(Intercept)"),
    matrix_column = c(2L, 1L), mean = c(0.25, 0), sd = c(1.4, 2),
    precision = c(1 / 1.4^2, 1 / 2^2), df = c(4.5, NA_real_),
    reason = c("exact column", "exact column"), kind = c("student_t", "normal")
  )
  result <- list(
    fixed_prior_contract = "fixed_effect_priors_v2",
    resolved_priors = list(
      list(dpar = "mu", coef = "x", index = 2L, matrix_column = 2L,
        location = 0.25, scale = 1.4, df = 4.5, kind = "student_t", reason = "exact"),
      list(dpar = "mu", coef = "(Intercept)", index = 1L, matrix_column = 1L,
        mean = 0, sd = 2, precision = 0.25, kind = "normal", reason = "exact")
    ),
    fixed_prior_penalty = -stats::dt((0.75 - 0.25) / 1.4, df = 4.5, log = TRUE) +
      log(1.4) - stats::dnorm(-0.2, mean = 0, sd = 2, log = TRUE),
    penalized_objective = 8.5 - stats::dt((0.75 - 0.25) / 1.4, df = 4.5, log = TRUE) +
      log(1.4) - stats::dnorm(-0.2, mean = 0, sd = 2, log = TRUE),
    loglik = -8.5,
    coef = c("mu_x" = 0.75, "mu_(Intercept)" = -0.2),
    coef_names = c("mu_(Intercept)", "mu_x"),
    likelihood_gradient = c(0.3, -0.4), prior_gradient = c(0.1, 0.2),
    penalized_gradient = c(0.4, -0.2), estim_method = "MAP"
  )

  testthat::expect_silent(drm_julia_validate_fixed_priors_v2_result(result, resolved))

  bad <- result
  bad$fixed_prior_contract <- "fixed_effect_priors_v1"
  testthat::expect_error(
    drm_julia_validate_fixed_priors_v2_result(bad, resolved), "contract"
  )
  bad <- result
  bad$resolved_priors[[1]]$df <- 5
  testthat::expect_error(
    drm_julia_validate_fixed_priors_v2_result(bad, resolved), "prior record"
  )
  bad <- result
  bad$resolved_priors[[1]]$coef <- "wrong"
  testthat::expect_error(
    drm_julia_validate_fixed_priors_v2_result(bad, resolved), "prior target"
  )
  bad <- result
  bad$estim_method <- "ML"
  testthat::expect_error(
    drm_julia_validate_fixed_priors_v2_result(bad, resolved), "estimator"
  )
  bad <- result
  bad$fixed_prior_penalty <- bad$fixed_prior_penalty + 1
  testthat::expect_error(
    drm_julia_validate_fixed_priors_v2_result(bad, resolved), "fixed prior penalty"
  )
  bad <- result
  bad$penalized_gradient[[1]] <- bad$penalized_gradient[[1]] + 1
  testthat::expect_error(
    drm_julia_validate_fixed_priors_v2_result(bad, resolved), "gradient decomposition"
  )
})

test_that("the existing normal fixed-prior bridge remains v1", {
  normal <- drm_prior_normal(dpar = "mu", coef = "x", mean = 0.5, sd = 2)
  resolved <- data.frame(dpar = "mu", coefficient = "x")
  options <- drm_fixed_prior_bridge_options(list(normal), resolved)
  testthat::expect_identical(options$priors, list(list(
    kind = "normal", dpar = "mu", coef = "x", mean = 0.5, sd = 2
  )))
  testthat::expect_identical(options$prior_expected, list(list(dpar = "mu", coef = "x")))
})

test_that("fixed-priors v2 checks global coefficient indices across parameters", {
  expected <- data.frame(
    dpar = "sigma", coefficient = "(Intercept)", matrix_column = 1L,
    mean = 0.1, sd = 0.8, precision = 1 / 0.8^2, df = 3.5,
    reason = "exact column", kind = "student_t"
  )
  beta <- -0.3
  penalty <- log(0.8) - stats::dt((beta - 0.1) / 0.8, df = 3.5, log = TRUE)
  result <- list(
    fixed_prior_contract = "fixed_effect_priors_v2",
    resolved_priors = list(list(
      dpar = "sigma", coef = "(Intercept)", index = 2L, matrix_column = 1L,
      location = 0.1, scale = 0.8, df = 3.5, kind = "student_t", reason = "exact"
    )),
    fixed_prior_penalty = penalty, penalized_objective = 4 + penalty,
    loglik = -4, coef = c("mu_(Intercept)" = 1, "sigma_(Intercept)" = beta),
    coef_names = c("mu_(Intercept)", "sigma_(Intercept)"),
    likelihood_gradient = c(0.1, 0.2), prior_gradient = c(0.3, 0.4),
    penalized_gradient = c(0.4, 0.6), estim_method = "MAP"
  )
  testthat::expect_silent(drm_julia_validate_fixed_priors_v2_result(result, expected))
})

test_that("Julia accepts a fixed-only Student-t table through the v2 reply", {
  testthat::skip_if_not(identical(Sys.getenv("DRM_FIXED_PRIOR_V2_LIVE"), "1"))
  data <- data.frame(x = rep(c(-1, 0, 1), 4))
  data$y <- c(0.4, 0.9, 1.2, 1.0, 1.3, 2.0, 1.8, 2.2, 2.9, 2.4, 3.1, 3.8)
  priors <- drm_priors(
    drm_prior_student_t(dpar = "mu", coef = "x", mean = 0, scale = 1, df = 4),
    drm_prior_normal(dpar = "mu", coef = "(Intercept)", mean = 0, sd = 2)
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = data, priors = priors, engine = "julia")
  testthat::expect_identical(fit$estimator, "MAP")
  testthat::expect_equal(
    fit$penalized_objective,
    -fit$logLik + fit$fixed_prior_penalty,
    tolerance = 1e-8
  )
  testthat::expect_equal(nrow(fit$resolved_priors), 2L)
})
