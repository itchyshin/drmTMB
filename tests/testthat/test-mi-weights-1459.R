# #1459 — open design question. The continuous mi() prior is NOT multiplied
# by case weights. These tests pin that current behaviour and the R gates
# around it. They do not change the prior. Pending Shinichi's decision:
# should the prior be weighted so weight 2 matches a duplicated row?

test_that("unit weights are detected as unit, non-unit weights are not", {
  expect_true(drmTMB:::drm_weights_are_unit(NULL))
  expect_true(drmTMB:::drm_weights_are_unit(rep(1, 5)))
  expect_false(drmTMB:::drm_weights_are_unit(rep(2, 5)))
  expect_false(drmTMB:::drm_weights_are_unit(c(1, 1, 2)))
  expect_false(drmTMB:::drm_weights_are_unit(c(1, NA, 1)))
})

test_that("mi() plus non-unit weights emits the classed #1459 warning helper", {
  expect_false(drmTMB:::drm_warn_mi_prior_ignores_weights(NULL, TRUE))
  expect_false(drmTMB:::drm_warn_mi_prior_ignores_weights(rep(1, 4), TRUE))
  expect_false(drmTMB:::drm_warn_mi_prior_ignores_weights(rep(2, 4), FALSE))
  expect_warning(
    drmTMB:::drm_warn_mi_prior_ignores_weights(rep(2, 4), TRUE),
    class = "drmTMB_mi_weights_prior_unweighted"
  )
})

test_that("weight 0 or NA on a missing mi() covariate is a named error", {
  observed <- c(TRUE, FALSE, TRUE, FALSE)
  expect_false(drmTMB:::drm_abort_mi_zero_weight_missing(NULL, observed, "x"))
  expect_false(drmTMB:::drm_abort_mi_zero_weight_missing(rep(1, 4), observed, "x"))
  expect_false(drmTMB:::drm_abort_mi_zero_weight_missing(c(2, 1, 1, 1), observed, "x"))
  expect_error(
    drmTMB:::drm_abort_mi_zero_weight_missing(c(1, 0, 1, 1), observed, "x"),
    class = "drmTMB_mi_zero_weight_missing"
  )
  expect_error(
    drmTMB:::drm_abort_mi_zero_weight_missing(c(1, NA, 1, 1), observed, "x"),
    class = "drmTMB_mi_zero_weight_missing"
  )
  expect_error(
    drmTMB:::drm_abort_mi_zero_weight_missing(c(1, 1, 1, 0), observed, "x"),
    class = "drmTMB_mi_zero_weight_missing"
  )
})

test_that("predict/simulate refuse an explicit weights argument on an mi() fit", {
  object <- list(missing_data = list(predictors = list(x = list(variable = "x"))))
  expect_false(drmTMB:::drm_abort_mi_weights_predict(object, list()))
  expect_false(drmTMB:::drm_abort_mi_weights_predict(
    list(missing_data = list(predictors = list())),
    list(weights = 1)
  ))
  expect_error(
    drmTMB:::drm_abort_mi_weights_predict(object, list(weights = rep(2, 3))),
    class = "drmTMB_mi_weights_predict_unsupported"
  )
})
