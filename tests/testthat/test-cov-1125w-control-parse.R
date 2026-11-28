# Coverage for R/control.R drm_parse_control().

test_that("drm_parse_control() wraps optimizer lists and refuses storage fields", {
  parsed <- drmTMB:::drm_parse_control(list())
  expect_s3_class(parsed, "drm_control")
  expect_identical(parsed$optimizer, list())

  parsed_eval <- drmTMB:::drm_parse_control(list(eval.max = 1000L))
  expect_equal(parsed_eval$optimizer$eval.max, 1000L)

  expect_error(drmTMB:::drm_parse_control(1), "must be a list")
  expect_error(drmTMB:::drm_parse_control("list"), "must be a list")
  expect_error(drmTMB:::drm_parse_control(list(se = FALSE)), "reserved")
  expect_error(drmTMB:::drm_parse_control(list(keep_data = FALSE)), "reserved")
})

test_that("drm_control() rejects reserved names inside optimizer", {
  expect_error(
    drm_control(optimizer = list(se = FALSE)),
    "reserved"
  )
  expect_error(
    drm_control(optimizer = list(multi_start = 2L)),
    "reserved"
  )
})