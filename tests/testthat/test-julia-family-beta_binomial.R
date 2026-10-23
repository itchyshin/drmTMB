# A4 (2026-09-05): `beta_binomial()` admitted through `engine = "julia"` on the
# fixed-effect (Workflow G) route -- ONE row in R/julia-family-registry.R.
#
# What this file pins, in two tiers (validation-harness discipline):
#   * no-Julia tests: the registry row, the family-tag admission, the payload
#     the bridge would send (dpars mu/sigma with base-R coefficient labels per
#     design 258), and the scope fence -- phylo() with this family still refuses
#     BEFORE Julia is reached. These run in CI with no engine.
#   * live tests (DRMTMB_JULIA_TESTS=true + DRM_JL_PATH): same-target parity vs
#     engine = "tmb" on the committed fixture shape -- coefficients and logLik
#     within 1e-4, per-coefficient Wald SEs within 1e-3 relative, and the
#     estimator label equal to what DRM.jl's `estim_method` reports.
#
# The data-generating process and the call shape are copied from
# tests/testthat/test-beta-binomial.R (`new_beta_binomial_data()`, the first
# fixed-effect fit there) so the Julia route is measured on a fit the native
# engine is already known to complete -- a malformed call looks identical to a
# missing capability, so the shape is never invented here.
#
# NOT covered here, on purpose (the leaf's scope fence): random effects
# `(1 | g)` and `phylo()` with this family. phylo() refuses pre-Julia (tested
# below). Ordinary `(1 | g)` is NOT refused by the bridge for any fixed-effect
# family and is NOT claimed for this one -- it is A5's measurement, not A4's.

a4_beta_binomial_data <- function(n = 1200, seed = 20260510) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    trials = sample(8:24, n, replace = TRUE)
  )
  mu <- stats::plogis(-0.20 + 0.70 * dat$x)
  sigma <- exp(-1.10 + 0.25 * dat$z)
  phi <- 1 / sigma^2
  p <- stats::rbeta(n, shape1 = mu * phi, shape2 = (1 - mu) * phi)
  dat$success <- stats::rbinom(n, size = dat$trials, prob = p)
  dat$failure <- dat$trials - dat$success
  dat
}

a4_beta_binomial_formula <- function() bf(cbind(success, failure) ~ x, sigma ~ z)

test_that("beta_binomial has exactly one registry row, fixed-effect route only", {
  reg <- drmTMB:::drm_julia_family_registry()
  rows <- Filter(function(s) identical(s$family, "beta_binomial"), reg)
  expect_length(rows, 1L)
  row <- rows[[1L]]
  expect_true(row$fe)
  expect_identical(row$drmjl_tag, "beta_binomial")
  # scope fence: nothing beyond fixed effects is claimed by this row
  expect_false(row$phylo_only)
  expect_false(row$locscale_phylo)
  expect_false(row$slope_phylo)
  expect_false(row$structured)
  # the family HAS a free dispersion dpar (sigma), so it must not be in the
  # dispersionless set -- otherwise the label defaulter would refuse `sigma ~ z`
  expect_false(row$dispersionless)
  expect_false("beta_binomial" %in% drmTMB:::drm_julia_dispersionless_families())
  expect_false("beta_binomial" %in% drmTMB:::drm_julia_phylo_only_families())
})

test_that("drm_julia_family_tag() admits beta_binomial with and without a phylo term", {
  expect_identical(drmTMB:::drm_julia_family_tag("beta_binomial"), "beta_binomial")
  expect_identical(
    drmTMB:::drm_julia_family_tag("beta_binomial", has_phylo = TRUE),
    "beta_binomial"
  )
})

test_that("the bridge payload for beta_binomial carries mu and sigma with base-R labels (design 258)", {
  dat <- a4_beta_binomial_data(n = 60)
  fml <- a4_beta_binomial_formula()
  # `bf()` already returns the parsed bundle (`$entries`) the producer reads.
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = fml,
    data = dat,
    env = environment(),
    family_type = "beta_binomial"
  )
  expect_named(labels, c("mu", "sigma"))
  expect_identical(as.character(labels$mu), c("(Intercept)", "x"))
  expect_identical(as.character(labels$sigma), c("(Intercept)", "z"))
  # both data columns of cbind(success, failure) are marshalled
  expect_identical(
    drmTMB:::drm_julia_expand_response_columns("cbind(success, failure)"),
    c("success", "failure")
  )
})

test_that("beta_binomial with phylo() still refuses before Julia is reached (scope fence)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  skip_if_not_installed("ape")
  dat <- a4_beta_binomial_data(n = 120)
  tree <- ape::rtree(12)
  tree$tip.label <- paste0("s", seq_len(12))
  dat$sp <- factor(paste0("s", rep(seq_len(12), each = 10)))
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x + phylo(1 | sp, tree = tree), sigma ~ 1),
      family = beta_binomial(),
      data = dat,
      engine = "julia"
    ),
    "can marshal `phylo\\(\\)` only for"
  )
})

test_that("live: beta_binomial same-target parity vs engine = 'tmb' (coef, logLik, SE, estimator)", {
  drm_skip_live_julia()
  dat <- a4_beta_binomial_data()
  fml <- a4_beta_binomial_formula()
  ft <- drmTMB(fml, family = beta_binomial(), data = dat, engine = "tmb")
  fj <- drmTMB(fml, family = beta_binomial(), data = dat, engine = "julia")

  expect_s3_class(fj, "drmTMB_julia")
  expect_identical(fj$engine, "julia")
  expect_identical(fj$model$model_type, "beta_binomial")
  expect_identical(fj$model$dpars, c("mu", "sigma"))

  # G3: coefficients and logLik agree within 1e-4 (same tolerance as
  # DRM.jl tools/parity_fixture.R)
  ct <- unlist(fixef(ft))
  cj <- unlist(fixef(fj))
  expect_identical(names(ct), names(cj))
  expect_lt(max(abs(ct - cj)), 1e-4)
  expect_lt(abs(as.numeric(logLik(ft)) - as.numeric(logLik(fj))), 1e-4)
  expect_identical(fj$df, ft$df)

  # G4: per-coefficient Wald SEs agree within 1e-3 relative (parity_se.R bar)
  se_of <- function(f) {
    v <- diag(as.matrix(vcov(f)))
    names(v) <- sub(":", "_", names(v), fixed = TRUE)
    sqrt(v)
  }
  st <- se_of(ft)
  sj <- se_of(fj)
  expect_setequal(names(st), names(sj))
  sj <- sj[names(st)]
  expect_true(all(is.finite(st)) && all(st > 1e-6))
  expect_lt(max(abs(st - sj) / pmax(abs(st), abs(sj))), 1e-3)

  # G5: the estimator label equals what the engine reports
  expect_identical(fj$estimator, "ML")
  expect_identical(toupper(as.character(fj$bridge$estim_method)[1L]), "ML")

  # trials travel as per-row context, not as a dpar (DRM.jl _bridge_trials)
  expect_length(fj$bridge$trials, nrow(dat))
  expect_equal(as.numeric(fj$bridge$trials), dat$success + dat$failure)
})
