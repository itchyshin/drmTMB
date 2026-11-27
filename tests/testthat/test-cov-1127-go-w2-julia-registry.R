# refs coverage — julia-family-registry.R lookup helpers (27 Nov).

test_that("drm_julia_family_predictor_dpars() returns NULL for unknown families", {
  expect_null(drmTMB:::drm_julia_family_predictor_dpars("not_a_drm_family"))
  expect_identical(
    drmTMB:::drm_julia_family_predictor_dpars("gaussian"),
    "*"
  )
  expect_setequal(
    drmTMB:::drm_julia_family_predictor_dpars("biv_gaussian"),
    c("mu1", "mu2", "sigma1", "sigma2", "rho12")
  )
})

test_that("drm_julia_registry_family_object() resolves drmTMB constructors only", {
  nb <- drmTMB:::drm_julia_registry_family_object("nbinom2")
  expect_s3_class(nb, "drm_family")
  expect_null(drmTMB:::drm_julia_registry_family_object("gamma"))
  expect_null(drmTMB:::drm_julia_registry_family_object("absent_family"))
})

test_that("drm_julia_family_registry_problems() is empty on the shipped registry", {
  problems <- drmTMB:::drm_julia_family_registry_problems()
  expect_type(problems, "character")
  expect_length(problems, 0L)
})

test_that("drm_julia_registry_families() projects boolean registry columns", {
  phylo <- drmTMB:::drm_julia_registry_families("phylo_only")
  expect_true("poisson" %in% phylo)
  expect_false("gaussian" %in% phylo)
})