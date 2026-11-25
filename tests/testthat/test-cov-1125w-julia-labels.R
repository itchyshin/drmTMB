# Coverage for R/julia-coefficient-labels.R variance-component prefix helper.

test_that("drm_julia_bridge_variance_component_prefixes() lists bridge VC prefixes", {
  expect_identical(
    drmTMB:::drm_julia_bridge_variance_component_prefixes(),
    c("resd_", "recov_", "phylocov_")
  )
})