# R/adequacy-plots.R argument and layering helpers (no simulated residual draws).

test_that("drm_adequacy_plot_dots() rejects unexpected ... arguments", {
  expect_invisible(drmTMB:::drm_adequacy_plot_dots(list()))
  expect_error(drmTMB:::drm_adequacy_plot_dots(list(seed = 1)), "reserved")
  expect_error(drmTMB:::drm_adequacy_plot_dots(list(a = 1, b = 2)), "reserved")
})

test_that("drm_adequacy_envelope_layers() returns three ggplot layers", {
  skip_if_not_installed("ggplot2")
  env <- data.frame(
    theoretical = seq(-2, 2, length.out = 20),
    ymin = -0.2,
    ymax = 0.2
  )
  layers <- drmTMB:::drm_adequacy_envelope_layers(env)
  expect_length(layers, 3L)
  expect_s3_class(layers[[1]], "gg")
  expect_s3_class(layers[[2]], "gg")
  expect_s3_class(layers[[3]], "gg")
})

test_that("drm_adequacy_require_ggplot2() succeeds when ggplot2 is installed", {
  skip_if_not_installed("ggplot2")
  expect_invisible(drmTMB:::drm_adequacy_require_ggplot2())
})