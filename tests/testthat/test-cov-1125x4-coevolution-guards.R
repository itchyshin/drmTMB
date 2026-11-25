# Refusal paths in R/coevolution-accessors.R.

test_that("drm_coevolution_refuse() raises the documented error", {
  expect_error(drmTMB:::drm_coevolution_refuse(), "Coevolution accessors")
  expect_error(drmTMB:::drm_coevolution_refuse("detail line"), "detail line")
})

test_that("drm_coevolution_sigma_a() rejects non-fits", {
  expect_error(drmTMB:::drm_coevolution_sigma_a(data.frame(a = 1)), "drmTMB")
})

test_that("drm_coevolution_sigma_a() refuses non-biv models", {
  fit <- structure(
    list(model = list(model_type = "gaussian", structured = list(phylo_mu = list(has = TRUE)))),
    class = "drmTMB"
  )
  expect_error(drmTMB:::drm_coevolution_sigma_a(fit), "Coevolution accessors")
})

test_that("coevolution accessors error on ordinary Gaussian fits", {
  fit <- structure(list(model = list(model_type = "gaussian")), class = "drmTMB")
  expect_error(coevolution_cor(fit), "Coevolution accessors")
  expect_error(coevolution_vc(fit), "Coevolution accessors")
})