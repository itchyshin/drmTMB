# Small structured-effects accessors from R/methods.R.

test_that("structured_effects_scalar and integer coerce safely", {
  expect_equal(drmTMB:::structured_effects_scalar("phylo"), "phylo")
  expect_equal(drmTMB:::structured_effects_scalar(NULL), NA_character_)
  expect_equal(drmTMB:::structured_effects_scalar(NA), NA_character_)
  expect_equal(drmTMB:::structured_effects_integer(3L), 3L)
  expect_equal(drmTMB:::structured_effects_integer(NULL), NA_integer_)
})

test_that("structured_effects_format_number() formats finite values only", {
  fmt <- drmTMB:::structured_effects_format_number
  expect_type(fmt(0.123456789, digits = 4L), "character")
  expect_equal(fmt(Inf), NA_character_)
  expect_equal(fmt(NA_real_), NA_character_)
})

test_that("structured_effects_numeric_scalar() returns default for bad input", {
  f <- drmTMB:::structured_effects_numeric_scalar
  expect_equal(f(2.5), 2.5)
  expect_equal(f(NULL, default = 0), 0)
  expect_equal(f(c(NA, 1)), NA_real_)
})

test_that("empty_structured_effects_table() has expected columns", {
  tab <- drmTMB:::empty_structured_effects_table()
  expect_s3_class(tab, "data.frame")
  expect_gt(ncol(tab), 20L)
  expect_equal(nrow(tab), 0L)
  expect_true("marker" %in% names(tab))
  expect_true("matrix_digest" %in% names(tab))
})

test_that("structured_effects_matrix_attachment() summarizes args", {
  att <- drmTMB:::structured_effects_matrix_attachment
  expect_equal(att(list(tree = "tipA")), "tipA")
  expect_equal(att(list()), NA_character_)
  multi <- att(list(tree = "a", mesh = "m1"))
  expect_true(grepl("a", multi))
  expect_true(grepl("m1", multi))
})