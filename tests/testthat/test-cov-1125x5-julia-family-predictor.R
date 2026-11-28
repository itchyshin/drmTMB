# Julia family registry helpers in R/julia-family-registry.R.

test_that("drm_julia_family_predictor_dpars() returns rows or NULL", {
  f <- drmTMB:::drm_julia_family_predictor_dpars
  gauss <- f("gaussian")
  expect_true(is.character(gauss) && length(gauss) > 0L)
  expect_null(f("not_a_drm_family_tag_xyz"))
  biv <- f("biv_gaussian")
  expect_true(is.character(biv))
  expect_false(identical(biv, "*"))
})

test_that("drm_julia_registry_family_object() resolves constructors", {
  obj <- drmTMB:::drm_julia_registry_family_object("gaussian")
  expect_null(obj)
  st <- drmTMB:::drm_julia_registry_family_object("student")
  expect_s3_class(st, "drm_family")
  expect_null(drmTMB:::drm_julia_registry_family_object("poisson"))
  expect_null(drmTMB:::drm_julia_registry_family_object("gamma"))
})

test_that("drm_julia_family_registry_problems() is empty on the shipped registry", {
  problems <- drmTMB:::drm_julia_family_registry_problems()
  expect_type(problems, "character")
  expect_length(problems, 0L)
})

test_that("drm_julia_registry_families() filters registry columns", {
  fe <- drmTMB:::drm_julia_registry_families("fe")
  expect_type(fe, "character")
  expect_true("gaussian" %in% fe)
  none <- drmTMB:::drm_julia_registry_families("not_a_column_xyz")
  expect_length(none, 0L)
})