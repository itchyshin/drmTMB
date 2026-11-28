# Optimizer control and fit-storage helpers in R/control.R.

mini_fit <- function() {
  set.seed(6)
  dat <- data.frame(y = rnorm(10), x = rnorm(10))
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE, keep_data = TRUE, keep_model_frame = TRUE)
  )
}

test_that("drm_control_optimizer_preset() returns budget lists", {
  expect_equal(drmTMB:::drm_control_optimizer_preset("default"), list())
  careful <- drmTMB:::drm_control_optimizer_preset("careful")
  expect_equal(careful$iter.max, 1000L)
})

test_that("drm_control_optim() rejects unknown BFGS controls", {
  expect_error(
    drmTMB:::drm_control_optim(list(bad = 1), "BFGS"),
    "unsupported"
  )
  out <- drmTMB:::drm_control_optim(list(reltol = 1e-6), "BFGS")
  expect_equal(out$maxit, 1000L)
})

test_that("drm_sanitize_nlminb_controls() drops unknown names with suggestion", {
  cleaned <- suppressWarnings(
    drmTMB:::drm_sanitize_nlminb_controls(list(iter.max = 200L, typoctl = 1))
  )
  expect_false("typoctl" %in% names(cleaned))
  expect_true("iter.max" %in% names(cleaned))
})

test_that("drm_apply_storage_control() respects keep_* flags", {
  fit <- mini_fit()
  ctl <- fit$control
  stripped <- drmTMB:::drm_apply_storage_control(fit, modifyList(ctl, list(keep_data = FALSE)))
  expect_null(stripped$data)
  slim <- drmTMB:::drm_apply_storage_control(fit, modifyList(ctl, list(keep_model_frame = FALSE)))
  expect_null(slim$model$model_frame)
  bare <- drmTMB:::drm_apply_storage_control(fit, modifyList(ctl, list(keep_tmb_object = FALSE)))
  expect_null(bare$obj)
})

test_that("drm_control_flag() validates logical scalars", {
  expect_true(drmTMB:::drm_control_flag(TRUE, "se"))
  expect_error(
    drmTMB:::drm_control_flag(NA, "se"),
    class = "rlang_error"
  )
})

test_that("drm_drop_model_frames() clears nested model frames", {
  fit <- mini_fit()
  fit$model$random_scale <- list(list(model_frame = data.frame(a = 1)))
  trimmed <- drmTMB:::drm_drop_model_frames(fit)
  expect_null(trimmed$model$random_scale[[1]]$model_frame)
})