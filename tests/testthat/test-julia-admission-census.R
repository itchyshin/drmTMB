# Arc 1 slice S2 (leaf-S2; destination D2): the admission census is
# COMPUTED HERE, every run, never read from a stored list (D-277). No live
# Julia anywhere -- `census_run_cell()` clears every Julia path/option and
# recognises `drm_julia_setup()`'s own "no DRM.jl checkout" abort as the
# admit boundary (see tools/julia-admission-census.R's header). A future
# admission change -- a gap closed, or a new one opened -- fails this test
# on the next run, not on the next hand audit.
#
# `census_admission_census()` regenerates the census (source checkout: a few
# seconds; skipped gracefully, not failed, if `tools/` is unreachable --
# tools/ is .Rbuildignore'd, the same edge case test-parity-matrix.R already
# handles for its own `sys.source()`). It is called once per `test_that()`
# below (recomputed each time, not shared file-scope state), so the whole
# file stays well under its 60s budget even though it is called several
# times -- each run is under a second.

# Memoised for THIS test-file run only (a plain environment, reset on every
# fresh R session/test run) -- not a stored list. `test_that()` blocks below
# call this repeatedly; computing the ~290-cell grid once and sharing it
# keeps the whole file's runtime well inside its 60s budget instead of
# recomputing it eight times over.
.census_admission_cache <- new.env(parent = emptyenv())

census_admission_census <- function() {
  path <- testthat::test_path("..", "..", "tools", "julia-admission-census.R")
  testthat::skip_if_not(file.exists(path), "tools/ unreachable (not a source checkout)")
  if (is.null(.census_admission_cache$value)) {
    env <- new.env(parent = globalenv())
    sys.source(path, envir = env)
    root <- testthat::test_path("..", "..")
    .census_admission_cache$value <- env$census_run(root = root, out_path = NULL, progress = NULL)
  }
  .census_admission_cache$value
}

census_cell_keys <- function(df) {
  paste(df$family, df$structure, df$dpar, sep = " | ")
}

test_that("admission census has the pinned columns and only the four decisions", {
  census <- census_admission_census()
  expect_identical(
    names(census),
    c("family", "structure", "dpar", "formula", "decision", "gate_id", "ledger_row")
  )
  expect_true(all(census$decision %in% c("ADMIT", "REFUSE", "REFUSE_UNGATED", "NOT_APPLICABLE")))
})

test_that("admission census covers every family in the registry (leaf-S2 G1)", {
  census <- census_admission_census()
  reg <- drmTMB:::drm_julia_family_registry()
  reg_families <- unique(vapply(reg, function(x) x$family, character(1L)))
  expect_gt(length(reg_families), 0L)
  expect_identical(setdiff(reg_families, census$family), character(0L))
  # One passing expectation PER family (D2's `sum(passed) >= nf`), not just
  # one aggregate assertion for the whole registry.
  for (fam in reg_families) {
    expect_true(fam %in% census$family, info = fam)
  }
})

test_that("every REFUSE row names a gate_id that exists in julia-gates.tsv", {
  census <- census_admission_census()
  gate_ids <- drmTMB:::drm_julia_intentional_gates()$gate_id
  refuse <- census[census$decision == "REFUSE", , drop = FALSE]
  expect_gt(nrow(refuse), 0L)
  expect_true(all(nzchar(refuse$gate_id)))
  expect_true(all(refuse$gate_id %in% gate_ids))
})

# ---- ADMIT rows: ledgered, or on the explicit S5 list ----------------------
#
# Every ADMIT cell either joins a ledger row, or is named here with a reason
# -- so a NEW unledgered gap fails (not in this list) and a FIXED one also
# fails (still in this list after S5 ledgers it), exactly the tripwire
# leaf-S2 G2 asks for. Categories, all measured on this run:
#
#   * Gaussian ordinary bars beyond the three already-ledgered shapes
#     (random slope on sigma, phylo on sigma, spatial/animal on mu): the
#     same "fe = TRUE admits before phylo_only/locscale_phylo/slope_phylo/
#     structured are checked" mechanism finding 6 names, just not yet
#     exercised by a ledgered receipt.
#   * biv_gaussian ordinary bars and bivariate phylo (q2, q4 dense, q4
#     block-diagonal): `fe_fence_exempt` (R/julia-family-registry.R) grants
#     biv_gaussian relief from the fe-only fence so its OWN predictor-scope
#     cells can fit, and that exemption reaches ordinary `(1 | g)`/
#     `(1 + x | g)` bars too, with no ledger row of its own. The two
#     bivariate-phylo rows repeat hypothesis (b)/finding 5: q4
#     block-diagonal is admitted identically to q4 dense (see that test
#     below), and the only ledgered bivariate-phylo row (biv_q4_phylo_reml)
#     covers REML = TRUE only, not the ML route this census exercises.
#   * poisson/nbinom2/gamma/beta ordinary `(1 | g)`/`(1 + x | g)`/
#     `animal()` on mu (and nbinom2/gamma/beta on sigma): hypothesis (a),
#     finding 6 -- these families escape the fe-only fence via their OWN
#     phylo_only/locscale_phylo/slope_phylo/structured registry columns,
#     which the fence was never meant to gate ordinary bars for.
#   * binomial ordinary `(1 | g)`/`(1 + x | g)` on mu: same mechanism as
#     poisson (phylo_only escapes the fence).
#
# Cite: Arc 1 plan S5 ("Ledger rows for admitted-but-unledgered routes found
# by S2/S3") is the slice that ledgers or gates each of these.
EXPECTED_UNLEDGERED_FOR_S5 <- c(
  "gaussian | (1+x|g) | sigma" = "Arc 1 plan S5: Gaussian correlated random slope on sigma, same fe-admits-first mechanism as the three already-ledgered Gaussian RE shapes",
  "gaussian | phylo | sigma" = "Arc 1 plan S5: Gaussian phylo() on sigma (location-scale-scale via phylo, not sd()); admitted, unledgered",
  "gaussian | spatial | mu" = "Arc 1 plan S5: Gaussian spatial() random intercept on mu; admitted (general-covariance route), unledgered",
  "gaussian | animal | mu" = "Arc 1 plan S5: Gaussian animal() random intercept on mu; admitted (general-covariance route), unledgered",
  "biv_gaussian | (1|g) | mu1" = "Arc 1 plan S5: biv_gaussian ordinary (1|g) on mu1, reachable via fe_fence_exempt with no ledger row",
  "biv_gaussian | (1|g) | sigma1" = "Arc 1 plan S5: biv_gaussian ordinary (1|g) on sigma1, same fe_fence_exempt gap",
  "biv_gaussian | (1+x|g) | mu1" = "Arc 1 plan S5: biv_gaussian ordinary (1+x|g) on mu1, same fe_fence_exempt gap",
  "biv_gaussian | (1+x|g) | sigma1" = "Arc 1 plan S5: biv_gaussian ordinary (1+x|g) on sigma1, same fe_fence_exempt gap",
  "biv_gaussian | bivariate q2 phylo | mu1,mu2" = "Arc 1 plan S5: biv_gaussian q2 phylo on mu1/mu2; admitted, unledgered (the ledgered biv_q4_phylo_reml row is q4 REML only)",
  "biv_gaussian | bivariate q4 dense phylo | mu1,mu2,sigma1,sigma2" = "Arc 1 plan S5: biv_gaussian q4 dense phylo under ML; the ledgered biv_q4_phylo_reml row covers REML = TRUE only, not this ML route",
  "biv_gaussian | bivariate q4 block-diagonal phylo | mu1,mu2,sigma1,sigma2" = "Arc 1 plan S5 + finding 5/hypothesis (b): admitted identically to q4 dense (drm_julia_biv_phylo_dimension() ignores the covariance-block tag), and unledgered under ML for the same reason as the dense cell",
  "poisson | (1|g) | mu" = "Arc 1 plan S5, hypothesis (a): ordinary (1|g) on poisson escapes the fe-only fence via phylo_only/structured",
  "poisson | animal | mu" = "Arc 1 plan S5: poisson animal() random intercept on mu; admitted (general-covariance route), unledgered",
  "nbinom2 | (1|g) | mu" = "Arc 1 plan S5, hypothesis (a): ordinary (1|g) on nbinom2 mu",
  "nbinom2 | (1|g) | sigma" = "Arc 1 plan S5, hypothesis (a): ordinary (1|g) on nbinom2 sigma",
  "nbinom2 | (1+x|g) | mu" = "Arc 1 plan S5, hypothesis (a): ordinary (1+x|g) on nbinom2 mu",
  "nbinom2 | (1+x|g) | sigma" = "Arc 1 plan S5, hypothesis (a): ordinary (1+x|g) on nbinom2 sigma",
  "nbinom2 | animal | mu" = "Arc 1 plan S5: nbinom2 animal() random intercept on mu; admitted (general-covariance route), unledgered",
  "gamma | (1|g) | mu" = "Arc 1 plan S5, hypothesis (a): ordinary (1|g) on gamma mu",
  "gamma | (1|g) | sigma" = "Arc 1 plan S5, hypothesis (a): ordinary (1|g) on gamma sigma",
  "gamma | (1+x|g) | mu" = "Arc 1 plan S5, hypothesis (a): ordinary (1+x|g) on gamma mu",
  "gamma | (1+x|g) | sigma" = "Arc 1 plan S5, hypothesis (a): ordinary (1+x|g) on gamma sigma",
  "gamma | animal | mu" = "Arc 1 plan S5: gamma animal() random intercept on mu; admitted (general-covariance route), unledgered",
  "beta | (1|g) | mu" = "Arc 1 plan S5, hypothesis (a): ordinary (1|g) on beta mu",
  "beta | (1|g) | sigma" = "Arc 1 plan S5, hypothesis (a): ordinary (1|g) on beta sigma",
  "beta | (1+x|g) | mu" = "Arc 1 plan S5, hypothesis (a): ordinary (1+x|g) on beta mu",
  "beta | (1+x|g) | sigma" = "Arc 1 plan S5, hypothesis (a): ordinary (1+x|g) on beta sigma",
  "binomial | (1|g) | mu" = "Arc 1 plan S5, hypothesis (a): ordinary (1|g) on binomial mu",
  "binomial | (1+x|g) | mu" = "Arc 1 plan S5, hypothesis (a): ordinary (1+x|g) on binomial mu"
)

test_that("every unledgered ADMIT cell is named on the explicit S5 list (leaf-S2 G2)", {
  census <- census_admission_census()
  admit <- census[census$decision == "ADMIT", , drop = FALSE]
  unledgered <- admit[!nzchar(admit$ledger_row), , drop = FALSE]
  expect_setequal(census_cell_keys(unledgered), names(EXPECTED_UNLEDGERED_FOR_S5))
})

# ---- REFUSE_UNGATED rows: on the explicit list, with reasons ---------------
#
# An abort that matches no `julia-gates.tsv` `message_pattern` is a real
# refusal drmTMB never documented as a gate. Categories measured here:
#
#   * biv_student's own native-scope refusal ("allows fixed-effect mu1/mu2
#     only") on a phylo/q2/q4 shape carrying a sigma1/sigma2 predictor: a
#     real, working refusal, just not a `julia-gates.tsv` row.
#   * biv_gaussian's q2 known-structured route refusing a marker on ONE
#     axis only ("require matching structured terms in mu1 and mu2"): the
#     relmat/animal/spatial analogue of the gated `biv_invalid_partial_phylo`,
#     itself ungated.
#   * the generic phylo() family allowlist ("can marshal phylo() only for
#     univariate Gaussian, Poisson, NB2, Gamma, Beta, Binomial, or
#     bivariate Gaussian (q=4)"), hit by every fe-only-cohort family
#     (student, lognormal, truncated_nbinom2, zero_one_beta, tweedie,
#     beta_binomial, cumulative_logit, skew_normal) and by biv_student/
#     biv_lognormal's phylo and bivariate-phylo shapes.
#   * "phylo()/relmat()/spatial()/animal() only in the mu formula": the
#     structured/phylo payload builders admit the marker on `mu` only,
#     REFUSING a sigma-side marker for the very families
#     (gaussian/nbinom2/gamma/beta) the mu-side route ledgers.
#   * "spatial() only for Gaussian fits": poisson/nbinom2/gamma pass the
#     structured-family allowlist (they ARE relmat/animal families) but
#     fail spatial()'s own, narrower, Gaussian-only inner check.
EXPECTED_UNGATED_REFUSALS <- c(
  "biv_student | phylo | sigma1" = "native scope refusal (biv_student() fixed-effect mu1/mu2 only), not a julia-gates.tsv row",
  "biv_student | bivariate q4 dense phylo | mu1,mu2,sigma1,sigma2" = "same native scope refusal on the q4 dense sigma1/sigma2 shape",
  "biv_student | bivariate q4 block-diagonal phylo | mu1,mu2,sigma1,sigma2" = "same native scope refusal on the q4 block-diagonal sigma1/sigma2 shape",
  "biv_gaussian | relmat | mu1" = "biv_gaussian q2 known-structured route: single-axis relmat refused as unmatched, ungated (relmat analogue of biv_invalid_partial_phylo)",
  "biv_gaussian | relmat | sigma1" = "same q2 known-structured 'matching terms' refusal, sigma1 axis",
  "biv_gaussian | spatial | mu1" = "same q2 known-structured 'matching terms' refusal, spatial marker",
  "biv_gaussian | spatial | sigma1" = "same q2 known-structured 'matching terms' refusal, spatial marker, sigma1 axis",
  "biv_gaussian | animal | mu1" = "same q2 known-structured 'matching terms' refusal, animal marker",
  "biv_gaussian | animal | sigma1" = "same q2 known-structured 'matching terms' refusal, animal marker, sigma1 axis",
  "student | phylo | mu" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "student | phylo | sigma" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "lognormal | phylo | mu" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "lognormal | phylo | sigma" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "truncated_nbinom2 | phylo | mu" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "truncated_nbinom2 | phylo | sigma" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "zero_one_beta | phylo | mu" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "zero_one_beta | phylo | sigma" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "tweedie | phylo | mu" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "tweedie | phylo | sigma" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "beta_binomial | phylo | mu" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "beta_binomial | phylo | sigma" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "cumulative_logit | phylo | mu" = "phylo() family allowlist refuses the fe-only cohort; ungated (dispersionless, no sigma cell)",
  "skew_normal | phylo | mu" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "skew_normal | phylo | sigma" = "phylo() family allowlist refuses the fe-only cohort; ungated",
  "biv_student | phylo | mu1" = "phylo() family allowlist refuses biv_student (not biv_gaussian); ungated",
  "biv_student | bivariate q2 phylo | mu1,mu2" = "phylo() family allowlist refuses biv_student; ungated",
  "biv_lognormal | phylo | mu1" = "phylo() family allowlist refuses biv_lognormal; ungated",
  "biv_lognormal | bivariate q2 phylo | mu1,mu2" = "phylo() family allowlist refuses biv_lognormal; ungated",
  "gaussian | relmat | sigma" = "relmat() admitted on mu only; sigma-side refused, ungated",
  "gaussian | spatial | sigma" = "spatial() admitted on mu only; sigma-side refused, ungated",
  "gaussian | animal | sigma" = "animal() admitted on mu only; sigma-side refused, ungated",
  "nbinom2 | phylo | sigma" = "phylo() admitted on mu only for nbinom2; sigma-side refused, ungated",
  "nbinom2 | relmat | sigma" = "relmat() admitted on mu only; sigma-side refused, ungated",
  "nbinom2 | spatial | sigma" = "spatial() admitted on mu only; sigma-side refused, ungated",
  "nbinom2 | animal | sigma" = "animal() admitted on mu only; sigma-side refused, ungated",
  "gamma | phylo | sigma" = "phylo() admitted on mu only for gamma; sigma-side refused, ungated",
  "gamma | relmat | sigma" = "relmat() admitted on mu only; sigma-side refused, ungated",
  "gamma | spatial | sigma" = "spatial() admitted on mu only; sigma-side refused, ungated",
  "gamma | animal | sigma" = "animal() admitted on mu only; sigma-side refused, ungated",
  "beta | phylo | sigma" = "phylo() admitted on mu only for beta; sigma-side refused, ungated",
  "poisson | spatial | mu" = "spatial() restricted to Gaussian/biv_gaussian fits even though poisson passes the relmat/animal/spatial family allowlist; ungated",
  "nbinom2 | spatial | mu" = "same Gaussian-only spatial() inner check, nbinom2",
  "gamma | spatial | mu" = "same Gaussian-only spatial() inner check, gamma"
)

test_that("every REFUSE_UNGATED cell is named on the explicit list, with a reason", {
  census <- census_admission_census()
  ungated <- census[census$decision == "REFUSE_UNGATED", , drop = FALSE]
  expect_setequal(census_cell_keys(ungated), names(EXPECTED_UNGATED_REFUSALS))
})

test_that("hypothesis (a): ordinary (1|g) on poisson/nbinom2/binomial/gamma/beta is admitted with no ledger row", {
  census <- census_admission_census()
  for (fam in c("poisson", "nbinom2", "binomial", "gamma", "beta")) {
    row <- census[census$family == fam & census$structure == "(1|g)" & census$dpar == "mu", , drop = FALSE]
    expect_equal(nrow(row), 1L, info = fam)
    expect_identical(row$decision, "ADMIT", info = fam)
    expect_identical(row$ledger_row, "", info = fam)
  }
})

test_that("hypothesis (b): q4 block-diagonal phylo is admitted on biv_gaussian, identically to q4 dense (finding 5)", {
  census <- census_admission_census()
  block <- census[
    census$family == "biv_gaussian" & census$structure == "bivariate q4 block-diagonal phylo",
    ,
    drop = FALSE
  ]
  dense <- census[
    census$family == "biv_gaussian" & census$structure == "bivariate q4 dense phylo",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(block), 1L)
  expect_equal(nrow(dense), 1L)
  expect_identical(block$decision, "ADMIT")
  # drm_julia_biv_phylo_dimension() classifies by the dpar SET alone and
  # ignores the covariance-block tag (p vs ps): block-diagonal is fitted as
  # the dense model, so the two admission decisions are identical.
  expect_identical(block$decision, dense$decision)
})

test_that("hypothesis (c): truncated_nbinom2 + hu is admitted in R (finding 7)", {
  census <- census_admission_census()
  hu_row <- census[census$family == "truncated_nbinom2" & census$dpar == "hu", , drop = FALSE]
  expect_equal(nrow(hu_row), 1L)
  expect_identical(hu_row$decision, "ADMIT")
  # Ledgered as "hurdle_nbinom2" (pm_modifier_routes()'s bridge_family =
  # "nbinom2" + modifier = "hu" route) -- r_bridge_status on that row is
  # "partial", not "supported"; this pure-R census cannot boot Julia to
  # re-verify finding 7's "fails inside Julia" half (native drmTMB spells
  # this family truncated_nbinom2(), but the bridge tags it "nbinom2" for
  # DRM.jl, which has no `hu` case).
  expect_identical(hu_row$ledger_row, "hurdle_nbinom2")
})
