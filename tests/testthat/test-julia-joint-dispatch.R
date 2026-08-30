test_that("public Julia entry routes joint models before legacy impute refusal", {
  testthat::local_mocked_bindings(
    drmTMB_julia_joint_bridge = function(...) list(joint_args = list(...)),
    .package = "drmTMB"
  )
  dat <- data.frame(y = 1:4, x = c(0, NA, 1, 0), z = 1:4)
  formula <- bf(y ~ z + mi(x), sigma ~ 1)
  fit <- drmTMB(formula, data = dat, family = gaussian(), engine = "julia",
    impute = list(x = x ~ z), missing = miss_control(predictor = "model"))
  expect_true(fit$joint_args$weights_missing)
  expect_identical(fit$joint_args$formula, formula)
  expect_identical(fit$joint_args$data, dat)
  expect_false(fit$joint_args$REML)
})

test_that("joint detection does not alter ordinary model routing", {
  ordinary <- bf(y ~ z, sigma ~ 1)
  marked <- bf(y ~ mi(x), sigma ~ 1)
  expect_false(drmTMB:::drm_julia_joint_requested(ordinary, NULL, miss_control()))
  expect_true(drmTMB:::drm_julia_joint_requested(marked, NULL, miss_control()))
  expect_true(drmTMB:::drm_julia_joint_requested(ordinary, list(x = x ~ z), miss_control()))
  expect_true(drmTMB:::drm_julia_joint_requested(ordinary, NULL, miss_control(predictor = "model")))
})
