# Extra registry accessors in R/julia-family-registry.R (baseline in test-julia-family-registry.R).

test_that("drm_julia_family_predictor_dpars() reflects tweedie nu fence", {
  expect_identical(
    drmTMB:::drm_julia_family_predictor_dpars("tweedie"),
    c("mu", "sigma")
  )
  expect_identical(
    drmTMB:::drm_julia_family_predictor_dpars("biv_gaussian"),
    c("mu1", "mu2", "sigma1", "sigma2", "rho12")
  )
  expect_identical(drmTMB:::drm_julia_family_predictor_dpars("student"), "*")
})

test_that("drm_julia_registry_family_object() returns drm_family objects", {
  obj <- drmTMB:::drm_julia_registry_family_object("student")
  expect_s3_class(obj, "drm_family")
  expect_equal(obj$family, "student")
  expect_true("mu" %in% obj$dpars)
  expect_null(drmTMB:::drm_julia_registry_family_object("not_a_family"))
})

test_that("drm_julia_family_registry_problems() is empty on clean registry", {
  prob <- drmTMB:::drm_julia_family_registry_problems()
  expect_type(prob, "character")
  expect_length(prob, 0L)
})

test_that("drm_julia_registry_families() filters boolean columns", {
  struct <- drmTMB:::drm_julia_registry_families("structured")
  expect_true(all(c("gaussian", "poisson", "nbinom2", "gamma") %in% struct))
  expect_false("binomial" %in% struct)
  phylo <- drmTMB:::drm_julia_registry_families("phylo_only")
  expect_true("binomial" %in% phylo)
  expect_false("student" %in% phylo)
})