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
  # biv_lognormal (2026-09-05) is the second BIVARIATE fe row; it is deliberately
  # in no other list -- native drm_build_biv_lognormal_spec() admits no phylo,
  # random-effect or structured cell for it, so there is nothing else to admit.
  # biv_student joins them (fam-biv-student leaf, same date): fixed-effect route
  # only, and it moves NO other list -- it is not dispersionless (it has
  # sigma1/sigma2/nu), and it has no phylo, slope, or structured admission.
  expect_identical(drmTMB:::drm_julia_registry_families("fe"),
                   c("gaussian", "biv_gaussian", "student", "lognormal",
                     "poisson", "nbinom2", "gamma", "beta", "binomial",
                     "truncated_nbinom2", "zero_one_beta", "tweedie",
                     "beta_binomial", "cumulative_logit", "skew_normal",
                     "biv_lognormal"))
                     "beta_binomial", "cumulative_logit",
                     "biv_student", "skew_normal"))
})

test_that("drm_julia_family_tag() admits and refuses exactly what it did before", {
  for (f in c("gaussian", "student", "lognormal", "poisson", "nbinom2", "gamma", "beta", "binomial",
              "truncated_nbinom2", "zero_one_beta", "tweedie",
              "beta_binomial", "cumulative_logit", "skew_normal",  # A4 rows, 2026-09-05
              "biv_lognormal"))
              "beta_binomial", "cumulative_logit",
              # fam-biv-student leaf (2026-09-05): DRM.jl needed no change --
              # `_bridge_family("biv_student")` already returned Student() at
              # pin 430ef64cc and the keyed mu1/mu2 parts select the bivariate
              # route, so the admission is this one registry row.
              "biv_student", "skew_normal"))
    expect_identical(drmTMB:::drm_julia_family_tag(f), f)
  # refused outright: no A4 target remains unadmitted after this merge (all six
  # fixed-effect rows above are on the registry); this loop is intentionally empty.
  for (f in character(0))
    expect_error(drmTMB:::drm_julia_family_tag(f), "currently supports Workflow G")
})

test_that("every registry row has a unique family and a drmjl_tag", {
  reg <- drmTMB:::drm_julia_family_registry()
  fam <- vapply(reg, `[[`, character(1L), "family")
  expect_false(anyDuplicated(fam) > 0)
  expect_true(all(nzchar(vapply(reg, `[[`, character(1L), "drmjl_tag"))))
})
