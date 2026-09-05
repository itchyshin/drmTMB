# A4-INTEGRATION (2026-09-05): `drm_julia_bridge_default_dpar_labels()`
# (R/julia-bridge.R) previously defaulted a `nu` label ONLY for `student` --
# every other family with a native dpar beyond mu/sigma (tweedie's and
# skew_normal's `nu`, zero_one_beta's `zoi`/`coi`) was left unlabelled, so the
# SAME short formula forms native TMB accepts (a bare `bf(y ~ x)`, or
# `bf(y ~ x, sigma ~ z)`) aborted at DRM.jl's echo with `coef_labels is
# missing an entry for dpar "nu"` (G1). This file pins the generalised
# defaulter -- it reads the extra dpars off each family's OWN constructor
# (`fam$dpars`), not a hand-list -- plus the G16 informational message for the
# one measured native-refused-but-Julia-fits shape (tweedie `nu ~ z`).
# No Julia required.

drm_default_labels <- function(formula, family_type, labels = list(mu = c("(Intercept)", "x"))) {
  drmTMB:::drm_julia_bridge_default_dpar_labels(labels, formula, family_type)
}

bare_formula <- drmTMB::bf(y ~ x)

test_that("bare bf(y ~ x) defaults a nu label for every family with a native nu dpar", {
  for (ft in c("student", "tweedie", "skew_normal")) {
    labs <- drm_default_labels(bare_formula, ft)
    expect_identical(labs$nu, "(Intercept)", info = ft)
  }
})

test_that("student's default labels are unchanged by the generalisation", {
  labs <- drm_default_labels(bare_formula, "student")
  expect_identical(labs, list(mu = c("(Intercept)", "x"), sigma = "(Intercept)", nu = "(Intercept)"))
})

test_that("bare bf(y ~ x) defaults zoi and coi labels for zero_one_beta", {
  labs <- drm_default_labels(bare_formula, "zero_one_beta")
  expect_identical(labs$zoi, "(Intercept)")
  expect_identical(labs$coi, "(Intercept)")
})

test_that("families with no dpar beyond mu/sigma get no invented extra label", {
  for (ft in c("beta_binomial", "truncated_nbinom2", "lognormal", "beta", "nbinom2", "gamma")) {
    labs <- drm_default_labels(bare_formula, ft)
    expect_identical(setdiff(names(labs), c("mu", "sigma")), character(0L), info = ft)
  }
})

test_that("an explicit non-intercept nu formula is never overwritten by the defaulter", {
  fml <- drmTMB::bf(y ~ x, nu ~ z)
  labs <- drm_default_labels(fml, "tweedie")
  expect_null(labs$nu)
})

test_that("G16: engine = 'julia' informs when tweedie's nu formula is a shape native TMB refuses", {
  fml <- drmTMB::bf(y ~ x, nu ~ z)
  expect_message(
    drm_default_labels(fml, "tweedie"),
    "nu ~ z.*refuses this shape",
    perl = TRUE
  )
})

test_that("G16: the inform does NOT fire for intercept-only nu ~ 1", {
  fml <- drmTMB::bf(y ~ x, nu ~ 1)
  expect_no_message(drm_default_labels(fml, "tweedie"))
})

test_that("G16: the inform does NOT fire when nu is left to default (no formula entry)", {
  expect_no_message(drm_default_labels(bare_formula, "tweedie"))
})

