# Corpair table scaffolding from R/methods.R.

test_that("normalize_corpairs_class_filter() maps location aliases", {
  norm <- drmTMB:::normalize_corpairs_class_filter
  expect_identical(norm("location-location"), "mean-mean")
  expect_identical(norm(c("mean-mean", "location-scale")), c("mean-mean", "mean-scale"))
  expect_identical(norm(c("slope-location", "other")), c("mean-slope", "other"))
  expect_identical(norm(character()), character())
})

test_that("empty_corpairs() defines the corpairs schema", {
  empty <- drmTMB:::empty_corpairs()
  expect_s3_class(empty, "data.frame")
  expect_equal(nrow(empty), 0L)
  required <- c(
    "level", "class", "parameter", "estimate", "modelled",
    "conf.status", "interval_source"
  )
  expect_true(all(required %in% names(empty)))
  expect_type(empty$estimate, "double")
  expect_type(empty$modelled, "logical")
})