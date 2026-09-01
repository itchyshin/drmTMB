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
  expect_identical(out[[1L]], "DRM.drm_bridge_joint")
})
