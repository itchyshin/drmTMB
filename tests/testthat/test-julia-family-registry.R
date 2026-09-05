# A0.5 (2026-09-05): the six hand-maintained family lists in R/julia-bridge.R
# became ONE registry. This file pins that the refactor changed NOTHING -- each
# derived list is byte-identical to the vector it replaced. Behaviour change
# (admitting a family) is A4's job and must fail these expectations on purpose,
# one row at a time, with its own receipts.

test_that("registry-derived lists equal the 2026-09-05 hand-maintained vectors exactly", {
  expect_identical(drmTMB:::drm_julia_phylo_only_families(),
                   c("poisson", "nbinom2", "gamma", "beta", "binomial"))
  expect_identical(drmTMB:::drm_julia_locscale_phylo_families(),
                   c("gaussian", "nbinom2", "gamma", "beta"))
  expect_identical(sort(drmTMB:::drm_julia_slope_phylo_families()),
                   sort(c("nbinom2", "gamma", "beta", "poisson")))
  expect_identical(drmTMB:::drm_julia_dispersionless_families(),
                   c("poisson", "binomial", "cumulative_logit"))
  expect_identical(drmTMB:::drm_julia_structured_families(),
                   c("gaussian", "poisson", "nbinom2", "gamma"))
  # A4 (2026-09-05): truncated_nbinom2 then zero_one_beta admitted AFTER the
  # 2026-09-05 pin -- fixed-effect route only, so they appear in this one list.
  expect_identical(drmTMB:::drm_julia_registry_families("fe"),
                   c("gaussian", "biv_gaussian", "student", "lognormal",
                     "poisson", "nbinom2", "gamma", "beta", "binomial",
                     "truncated_nbinom2", "zero_one_beta", "tweedie",
                     "beta_binomial", "cumulative_logit"))
})

test_that("drm_julia_family_tag() admits and refuses exactly what it did before", {
  for (f in c("gaussian", "student", "lognormal", "poisson", "nbinom2", "gamma", "beta", "binomial",
              "truncated_nbinom2", "zero_one_beta", "tweedie",
              "beta_binomial", "cumulative_logit"))  # A4 rows, 2026-09-05
    expect_identical(drmTMB:::drm_julia_family_tag(f), f)
  # refused outright (the remaining A4 targets), same message class as before
  for (f in c("skew_normal"))
    expect_error(drmTMB:::drm_julia_family_tag(f), "currently supports Workflow G")
})

test_that("every registry row has a unique family and a drmjl_tag", {
  reg <- drmTMB:::drm_julia_family_registry()
  fam <- vapply(reg, `[[`, character(1L), "family")
  expect_false(anyDuplicated(fam) > 0)
  expect_true(all(nzchar(vapply(reg, `[[`, character(1L), "drmjl_tag"))))
})
