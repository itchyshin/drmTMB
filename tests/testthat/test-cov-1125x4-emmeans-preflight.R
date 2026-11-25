# R/emmeans-preflight.R validation without fitting emmeans.

mini_gauss_fit <- function() {
  structure(
    list(
      model = list(
        model_type = "gaussian",
        response_names = list(mu = "y")
      ),
      coefficients = list(mu = c("(Intercept)" = 1, x = 0.1))
    ),
    class = "drmTMB"
  )
}

test_that("drm_emmeans_has_transformed_response() detects calls", {
  fit <- mini_gauss_fit()
  expect_false(drmTMB:::drm_emmeans_has_transformed_response(fit, "mu"))
  fit$model$response_names$mu <- "log(y)"
  expect_true(drmTMB:::drm_emmeans_has_transformed_response(fit, "mu"))
  fit$model$response_names$mu <- "cbind(success, failure)"
  expect_false(drmTMB:::drm_emmeans_has_transformed_response(fit, "mu"))
})

test_that("drm_emmeans_blocked_features() lists random and structured terms", {
  fit <- mini_gauss_fit()
  expect_length(drmTMB:::drm_emmeans_blocked_features(fit), 0L)
  fit$random_effects <- list(mu = list(values = 0.1))
  blocked <- drmTMB:::drm_emmeans_blocked_features(fit)
  expect_true("mu random effects" %in% blocked)
})

test_that("drm_validate_emmeans_mu_target() enforces mu-only preflight", {
  fit <- mini_gauss_fit()
  expect_invisible(drmTMB:::drm_validate_emmeans_mu_target(fit, "mu"))
  expect_error(drmTMB:::drm_validate_emmeans_mu_target(fit, "sigma"), "dpar = \"mu\"")
})

test_that("drm_validate_emmeans_mu_target() refuses unsupported families", {
  fit <- mini_gauss_fit()
  fit$model$model_type <- "lognormal"
  expect_error(drmTMB:::drm_validate_emmeans_mu_target(fit, "mu"), "not implemented")
})

test_that("drm_emmeans_misc() records inverse-link metadata", {
  misc <- drmTMB:::drm_emmeans_misc("log", dpar = "mu")
  expect_identical(misc$dpar, "mu")
  expect_identical(misc$tran, "log")
  id <- drmTMB:::drm_emmeans_misc("identity", dpar = "mu")
  expect_identical(id, list(dpar = "mu"))
})