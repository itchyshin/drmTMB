# Structured Random-Effect Balance: 100-Slice Plan

## Purpose

This plan supersedes a phylo-only reading of the Ayumi follow-on arc. The goal
is structured random-effect balance across `phylo()`, `spatial()`, `animal()`,
`relmat()`, and the special q1 `phylo_interaction()` route. Balance means the
same question is tracked by structured type, input source, dimension, endpoint,
estimator, inference status, and bridge route.

The validator-owned source tables are:

- `docs/dev-log/dashboard/structured-re-balance-matrix.tsv`
- `docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`

## Current Reading

The current package already has broad but uneven structured support:

- `phylo()`, `spatial()`, `animal()`, and `relmat()` have univariate Gaussian
  q1 intercept routes for `mu`, `sigma`, and matched `mu+sigma` under ML.
- The same four structured families have bivariate Gaussian q2 location routes
  and constant all-four q4 location-scale routes in at least one input form.
- `phylo()` has a q2-plus-q2 block-diagonal fallback for bivariate location and
  scale blocks under separate labels.
- `phylo_interaction()` is a q1 pair-level structured field, not a q2/q4
  endpoint-covariance family.
- Ordinary Poisson and NB2 fit one q1 structured `mu` intercept for
  `phylo()`, `spatial()`, `animal()`, `relmat()`, and `phylo_interaction()`.

The uneven parts are just as important:

- Native REML remains exact-Gaussian and route-specific, not broad structured
  q1-q4 support.
- Structured slopes are independent univariate Gaussian `mu` paths; labelled
  structured slope covariance is not implemented.
- q4 correlation intervals are derived/unsupported unless a row-specific
  profile or bootstrap coverage study proves otherwise.
- Direct DRM.jl evidence is not R-via-Julia bridge support.
- Spatial mesh/SPDE, sparse large-pedigree animal construction, generic
  direct-SD structured grammar, non-Gaussian q2/q4 structured covariance, and
  structured `rho12` remain future work.

## Waves

The 100 slices are stored in
`docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`.

1. Rehydrate: bank the corrected scope, matrix, validator, and evidence rules.
2. Native ML q1: prove q1 intercept cells for each structured type and endpoint.
3. Native ML q2: prove q2 bivariate location/scale status and extractors.
4. Native ML q4: prove constant all-four q4 point/status without interval
   overclaim.
5. Structured slopes: separate independent one-slope `mu` paths from future
   correlated slope covariance.
6. Native REML: keep REML exact-Gaussian and row-specific.
7. Inference: separate Wald, profile, bootstrap accounting, and coverage.
8. Bridge parity: separate native R/TMB, direct DRM.jl, and R-via-Julia.
9. Docs: synchronize formula grammar, limitations, README, dashboard, and
   review notes.
10. Closeout Reply: update the Ayumi reply only after live issue refresh and
    explicit approval.

## First Execution Boundary

SR001-SR010 are banked by this note and its dashboard tables. SR011-SR020 are
banked by focused native ML q1 test evidence. SR021-SR030 are banked by native
ML q2 test and decision evidence. SR031-SR040 are banked by native ML q4
point/extractor evidence. SR041-SR050 are banked by structured-slope test and
design evidence. SR051-SR060 are banked by exact-Gaussian native REML support
and rejection evidence. SR061-SR090 are banked by inference, labelled
coverage-pilot accounting, bridge-readiness, and docs closeout notes.
SR064-SR066 are pilot-only: they bank target/failure/MCSE accounting, not
coverage reliability. SR073-SR075 remain blocked because bridge parity is not
row-complete, even though a guarded live bridge smoke passed on 2026-06-22.
SR091, SR093, SR095-SR097, and SR099 remain blocked by live issue access, draft
approval, maintainer approval, public posting, posted-URL recording, or commit
approval. SR100 is banked by the tracked 2026-06-22 check-log entry that records
the local recovery checkpoint. After the coverage unblock pass and bridge smoke
audit the ledger has 91 banked rows and 9 blocked rows. A row becomes banked
only when its evidence path exists and the validator accepts it.
