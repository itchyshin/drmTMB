# drmTMB#1471: the engine = "julia" control gate compared settings with
# identical(), so a value equal to its default but stored as an integer or as
# an empty list was refused as "non-default".

test_that("settings equal to their default are not treated as changed", {
  expect_identical(drm_julia_nondefault_control_fields(drm_control()), character())
  expect_identical(
    drm_julia_nondefault_control_fields(drm_control(logsigma_clamp_margin = 3L)),
    character()
  )
  expect_identical(
    drm_julia_nondefault_control_fields(drm_control(logsigma_clamp = c(-12L, 12L))),
    character()
  )
  expect_identical(
    drm_julia_nondefault_control_fields(drm_control(start = list())),
    character()
  )
  expect_no_error(drm_julia_translate_control(drm_control(logsigma_clamp_margin = 3L)))
  expect_no_error(drm_julia_translate_control(drm_control(logsigma_clamp = c(-12L, 12L))))
  expect_no_error(drm_julia_translate_control(drm_control(start = list())))
  expect_true(drm_julia_default_control(drm_control(start = list())))
})

test_that("a genuinely changed setting is still refused", {
  expect_identical(
    drm_julia_nondefault_control_fields(drm_control(logsigma_clamp_margin = 4L)),
    "logsigma_clamp_margin"
  )
  expect_false(drm_julia_default_control(drm_control(logsigma_clamp = c(-20, 20))))
  expect_error(drm_julia_translate_control(drm_control(logsigma_clamp_margin = 4L)))
})
