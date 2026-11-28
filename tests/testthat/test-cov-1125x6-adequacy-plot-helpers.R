# Non-ggplot adequacy helpers in R/adequacy-plots.R.

test_that("drm_adequacy_plot_dots() rejects stray arguments", {
  expect_error(drmTMB:::drm_adequacy_plot_dots(list(seed = 1)), "reserved")
  expect_invisible(drmTMB:::drm_adequacy_plot_dots(list()))
})

test_that("drm_adequacy_require_ggplot2() surfaces install guidance", {
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    expect_invisible(drmTMB:::drm_adequacy_require_ggplot2())
  } else {
    expect_error(drmTMB:::drm_adequacy_require_ggplot2(), "ggplot2")
  }
})

test_that("drm_adequacy_envelope_layers() returns ggplot layer objects", {
  skip_if_not_installed("ggplot2")
  env <- data.frame(
    theoretical = seq(-2, 2, length.out = 5),
    ymin = -1.5,
    ymax = 1.5
  )
  layers <- drmTMB:::drm_adequacy_envelope_layers(env)
  expect_type(layers, "list")
  expect_length(layers, 3L)
  expect_s3_class(layers[[1]], "LayerInstance")
})