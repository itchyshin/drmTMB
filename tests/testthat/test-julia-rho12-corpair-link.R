# #1190 (decision 16): the bridge's residual rho12 corpair reports its link value
# on the native engine's map, rho12 = 0.999999 * tanh(eta), so
# eta = atanh(rho / 0.999999). Before the fix it used atanh(rho), which differs
# from the native link by about 1e-6 * rho / (1 - rho^2) and diverges near |rho| = 1.
# The TMB constant is deliberately unchanged.

drm_rho12_stub_julia <- function(rho) {
  structure(
    list(
      corpairs = rho,
      coefficients = list(rho12 = c("(Intercept)" = 0)),
      formula = list(entries = list(
        list(dpar = "mu1", response = "y1"),
        list(dpar = "mu2", response = "y2")
      ))
    ),
    class = "drmTMB_julia"
  )
}

test_that("julia residual rho12 corpair uses the native guarded link (#1190)", {
  for (rho in c(-0.9, 0.3375, 0.62, 0.99)) {
    row <- corpairs(drm_rho12_stub_julia(rep(rho, 4L)), level = "residual")
    expect_identical(nrow(row), 1L)
    expect_equal(row$estimate, rho)
    expect_equal(row$link_estimate, atanh(rho / 0.999999), tolerance = 1e-14)
    # Round trip through the native inverse link recovers the estimate.
    expect_equal(0.999999 * tanh(row$link_estimate), rho, tolerance = 1e-14)
  }
  # The pre-fix value atanh(rho) is measurably different near the boundary.
  row <- corpairs(drm_rho12_stub_julia(0.99), level = "residual")
  expect_gt(abs(row$link_estimate - atanh(0.99)), 1e-5)
})

test_that("julia residual rho12 link equals the native residual_rho12 link on the same rho (#1190)", {
  rho <- c(0.2, 0.5, 0.8)
  row <- corpairs(drm_rho12_stub_julia(rho), level = "residual")
  native_eta <- atanh(rho / 0.999999)
  expect_equal(row$link_estimate, mean(native_eta), tolerance = 1e-14)
  expect_equal(row$link_min, min(native_eta), tolerance = 1e-14)
  expect_equal(row$link_max, max(native_eta), tolerance = 1e-14)
})
