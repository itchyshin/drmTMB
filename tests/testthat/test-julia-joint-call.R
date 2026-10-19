test_that("joint bridge reports an actionable old-DRM capability error", {
  expect_error(
    drmTMB:::drm_julia_require_joint_capability(FALSE),
    "DRM.jl checkout is too old.*drm_bridge_joint.*update",
    ignore.case = TRUE
  )
  expect_invisible(drmTMB:::drm_julia_require_joint_capability(TRUE))
})

test_that("joint call checks the DRM capability after setup and before dispatch", {
  events <- character()
  local_mocked_bindings(
    drm_julia_setup = function(...) events <<- c(events, "setup"),
    drm_julia_require_joint_capability = function(...) {
      events <<- c(events, "capability")
      invisible(TRUE)
    },
    .package = "drmTMB"
  )
  local_mocked_bindings(
    julia_call = function(...) {
      events <<- c(events, "call")
      list(...)
    },
    .package = "JuliaCall"
  )
  out <- drmTMB:::drm_julia_call_joint(list(contract = "test"))
  expect_identical(events, c("setup", "capability", "call"))
  expect_identical(out[[1L]], "drmTMB_backend.drm_bridge_joint")
})

test_that("engine = 'julia' refuses a weighted mi() fit with a classed error", {
  # DRModels' joint missing-predictor route has no weights slot
  # (src/joint_missing_bridge.jl, drm_bridge_joint), so a weighted mi() fit
  # would silently drop the weights from the response and the mi() prior.
  # The refusal runs before any Julia setup, so it needs no Julia install.
  local_mocked_bindings(
    drm_julia_joint_prepare = function(...) {
      stop("preparation must not run for a weighted mi() fit")
    },
    drm_julia_call_joint = function(...) {
      stop("Julia must not be called for a weighted mi() fit")
    },
    .package = "drmTMB"
  )
  dat <- data.frame(
    y = c(0.2, 0.5, 1.1, 1.4, 0.9, 1.6),
    x = c(0.1, NA, 0.8, 1.2, NA, 1.5),
    z = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )
  expect_error(
    drmTMB(
      bf(y ~ mi(x), sigma ~ 1),
      data = dat,
      weights = c(1, 2, 1, 1, 2, 1),
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model"),
      engine = "julia"
    ),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
})
