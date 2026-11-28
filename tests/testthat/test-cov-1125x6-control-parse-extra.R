# Additional control parsing in R/control.R.

test_that("drm_control_reserved_names() lists storage keys", {
  nms <- drmTMB:::drm_control_reserved_names()
  expect_type(nms, "character")
  expect_true("keep_data" %in% nms)
  expect_true("se" %in% nms)
})

test_that("drm_parse_control() passes through drm_control objects", {
  ctl <- drm_control(se = FALSE, keep_data = TRUE)
  parsed <- drmTMB:::drm_parse_control(ctl)
  expect_false(parsed$se)
  expect_true(parsed$keep_data)
})

test_that("drm_parse_control() rejects reserved names in plain lists", {
  expect_error(drmTMB:::drm_parse_control(list(se = FALSE)), "reserved")
})

test_that("drm_control_optimizer() merges presets with overrides", {
  merged <- drmTMB:::drm_control_optimizer(
    list(iter.max = 5L),
    optimizer_preset = "careful"
  )
  expect_equal(merged$iter.max, 5L)
  expect_equal(merged$eval.max, 1000L)
  expect_type(merged, "list")
})