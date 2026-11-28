# R/mi-weights.R branches beyond test-mi-weights-1459.R and quadrature integration.

test_that("drm_abort_mi_zero_weight_missing_in_data() scans impute variables", {
  dat <- data.frame(x = c(1, NA, 3), y = 1:3)
  impute <- list(x = impute_model(x ~ 1))
  expect_invisible(
    drmTMB:::drm_abort_mi_zero_weight_missing_in_data(dat, rep(1, 3), impute)
  )
  expect_error(
    drmTMB:::drm_abort_mi_zero_weight_missing_in_data(
      dat, c(1, 0, 1), impute
    ),
    class = "drmTMB_mi_zero_weight_missing"
  )
  expect_invisible(
    drmTMB:::drm_abort_mi_zero_weight_missing_in_data(dat, NULL, impute)
  )
  expect_invisible(
    drmTMB:::drm_abort_mi_zero_weight_missing_in_data(dat, rep(1, 3), list())
  )
})

test_that("drm_abort_julia_mi_nonunit_weights() refuses Julia weighted mi()", {
  expect_invisible(drmTMB:::drm_abort_julia_mi_nonunit_weights(NULL))
  expect_invisible(drmTMB:::drm_abort_julia_mi_nonunit_weights(rep(1, 4)))
  expect_error(
    drmTMB:::drm_abort_julia_mi_nonunit_weights(rep(2, 4)),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
})

test_that("drm_mi_quadrature_slot_names() maps the two predictor slots", {
  one <- drmTMB:::drm_mi_quadrature_slot_names(1L)
  two <- drmTMB:::drm_mi_quadrature_slot_names(2L)
  expect_equal(one$beta, "beta_mi")
  expect_equal(one$log_sigma, "log_sigma_mi")
  expect_equal(two$beta, "beta_mi2")
  expect_equal(two$log_sigma, "log_sigma_mi2")
})

test_that("drm_mi_term_uses_quadrature_abort() flags quadrature-abort families", {
  gamma <- list(enabled = TRUE, family = "gamma")
  beta <- list(enabled = TRUE, family = "beta")
  expect_true(drmTMB:::drm_mi_term_uses_quadrature_abort(gamma))
  expect_true(drmTMB:::drm_mi_term_uses_quadrature_abort(beta))
  expect_equal(
    drmTMB:::drm_mi_quadrature_abort_families(),
    c("gamma", "beta", "zero_one_beta")
  )
})

test_that("drm_probe_mi_quadrature_objective() requires finite value and gradient", {
  obj <- list(
    fn = function(par) sum(par^2),
    gr = function(par) 2 * par
  )
  expect_invisible(drmTMB:::drm_probe_mi_quadrature_objective(obj, c(0.1, -0.2), "start"))
  bad <- list(fn = function(par) NaN, gr = function(par) c(0, 0))
  expect_error(
    drmTMB:::drm_probe_mi_quadrature_objective(bad, c(0, 0), "start"),
    class = "drmTMB_mi_quadrature_nonfinite"
  )
})

test_that("drm_rethrow_mi_quadrature_error() preserves the typed condition", {
  err <- structure(simpleError("x"), class = c("drmTMB_mi_quadrature_nonfinite", "error", "condition"))
  expect_error(
    drmTMB:::drm_rethrow_mi_quadrature_error(err),
    "x",
    class = "drmTMB_mi_quadrature_nonfinite"
  )
  other <- simpleError("ordinary")
  expect_error(drmTMB:::drm_rethrow_mi_quadrature_error(other), "ordinary")
})

test_that("drm_eval_call_weights() reads literal weights from the drmTMB call", {
  env <- parent.frame()
  dat <- data.frame(y = 1:3)
  call <- quote(drmTMB(bf(y ~ 1), data = dat, weights = c(1, 2, 1)))
  w <- drmTMB:::drm_eval_call_weights(call, dat, env)
  expect_equal(w, c(1, 2, 1))
  expect_null(drmTMB:::drm_eval_call_weights(quote(drmTMB(y ~ 1)), dat, env))
})

test_that("drm_warn_mi_prior_ignores_weights() warns on unweighted Gaussian priors", {
  expect_invisible(
    drmTMB:::drm_warn_mi_prior_ignores_weights(rep(2, 3), unweighted_prior = FALSE)
  )
  expect_invisible(
    drmTMB:::drm_warn_mi_prior_ignores_weights(rep(1, 3), unweighted_prior = TRUE)
  )
  expect_warning(
    drmTMB:::drm_warn_mi_prior_ignores_weights(rep(2, 3), unweighted_prior = TRUE),
    class = "drmTMB_mi_weights_prior_unweighted"
  )
})
