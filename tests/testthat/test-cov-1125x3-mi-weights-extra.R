# Extra coverage for R/mi-weights.R beyond test-mi-weights-1459.R.

test_that("drm_eval_call_weights() reads scalar and row weights from the call", {
  f <- drmTMB:::drm_eval_call_weights
  dat <- data.frame(y = 1:3, x = 1:3)
  call_scalar <- quote(drmTMB(y ~ x, weights = 2))
  expect_equal(f(call_scalar, dat, parent.frame()), 2)
  call_vec <- quote(drmTMB(y ~ x, weights = c(1, 2, 1)))
  expect_equal(f(call_vec, dat, parent.frame()), c(1, 2, 1))
  expect_null(f(quote(drmTMB(y ~ x)), dat, parent.frame()))
  expect_null(f(NULL, dat, parent.frame()))
})

test_that("drm_abort_julia_mi_nonunit_weights() is silent on unit weights", {
  g <- drmTMB:::drm_abort_julia_mi_nonunit_weights
  expect_false(g(NULL))
  expect_false(g(rep(1, 4)))
  expect_error(g(2), class = "drmTMB_julia_mi_weights_unsupported")
  expect_error(g(c(1, 2, 1)), class = "drmTMB_julia_mi_weights_unsupported")
})

test_that("drm_mi_quadrature slot and family guards surface expected values", {
  expect_identical(
    drmTMB:::drm_mi_quadrature_abort_families(),
    c("gamma", "beta", "zero_one_beta")
  )
  expect_equal(drmTMB:::drm_mi_quadrature_inaccurate_beta_mu_boundary(), 0.10)
  expect_equal(drmTMB:::drm_mi_quadrature_inaccurate_gamma_cv(), 3)
  expect_identical(
    drmTMB:::drm_mi_quadrature_slot_names(1L),
    list(beta = "beta_mi", log_sigma = "log_sigma_mi")
  )
  mp <- list(enabled = TRUE, family = "gamma")
  expect_true(drmTMB:::drm_mi_term_uses_quadrature_abort(mp))
  spec <- list(missing_predictor = mp, missing_predictor2 = list(enabled = FALSE))
  expect_true(drmTMB:::drm_spec_uses_mi_quadrature_abort(spec))
  expect_false(drmTMB:::drm_spec_uses_mi_quadrature_abort(list(missing_predictor = list(enabled = FALSE))))
})

test_that("drm_abort_mi_quadrature and rethrow helpers format errors", {
  expect_error(
    drmTMB:::drm_abort_mi_quadrature_guard_nonfinite("bad row"),
    "bad row"
  )
  expect_error(
    drmTMB:::drm_abort_mi_quadrature_nonfinite("detail row"),
    class = "drmTMB_mi_quadrature_nonfinite"
  )
  err <- simpleError("inner failure")
  expect_error(drmTMB:::drm_rethrow_mi_quadrature_error(err), "inner failure")
})