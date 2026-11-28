# Julia fence and print method in R/heritability.R.

julia_like_fit <- function() {
  structure(list(model = list(model_type = "gaussian")), class = c("drmTMB_julia", "drmTMB"))
}

test_that("heritability / icc / repeatability refuse Julia engine fits", {
  fit <- julia_like_fit()
  expect_error(heritability(fit), class = "drmTMB_variance_ratio_julia_unsupported")
  expect_error(icc(fit), class = "drmTMB_variance_ratio_julia_unsupported")
  expect_error(repeatability(fit), class = "drmTMB_variance_ratio_julia_unsupported")
  expect_error(
    drmTMB:::drm_variance_ratio_julia_fence("heritability"),
    class = "drmTMB_variance_ratio_julia_unsupported"
  )
})

test_that("print.drm_heritability() formats delta-method output", {
  obj <- structure(
    list(
      quantity = "heritability",
      component = "phylo(species)",
      estimate = 0.42,
      method = "delta",
      se = 0.05,
      level = 0.95,
      lower = 0.32,
      upper = 0.52
    ),
    class = "drm_heritability"
  )
  expect_invisible(print(obj))
  bare <- structure(
    list(
      quantity = "icc",
      component = "id",
      estimate = 0.1,
      method = "profile",
      se = NA_real_,
      level = 0.95,
      lower = NA_real_,
      upper = NA_real_
    ),
    class = "drm_heritability"
  )
  expect_invisible(print(bare))
})