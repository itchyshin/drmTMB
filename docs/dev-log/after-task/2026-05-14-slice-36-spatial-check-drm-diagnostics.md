# After Task: Slice 36 Spatial check_drm Diagnostics

## Goal

Give the first fitted coordinate-spatial `mu` random intercept its own
diagnostic path, without describing it as a phylogenetic species effect.

## Implemented

`check_drm()` now adds `spatial_mu_diagnostics` when a univariate Gaussian model
contains `spatial(1 | site, coords = coords)` in `mu`. The row reports the
spatial group, number of fitted sites, minimum fitted observations per site,
coordinate range used by the fixed exponential covariance, the fitted spatial
SD, and the ratio between the spatial SD and residual scale.

The diagnostic returns:

- `ok` when sites are replicated and the spatial SD is positive and
  non-negligible;
- `note` when at least one site is singly observed or the spatial SD is tiny
  relative to the residual scale;
- `error` when the spatial SD is non-positive or non-finite.

## Mathematical Contract

The fitted coordinate-spatial path remains the Slice 33 model:

```r
mu = y ~ x + spatial(1 | site, coords = coords)
sigma = ~ z
```

with a latent spatial vector `u_site` governed by a fixed coordinate-derived
precision matrix and one fitted spatial SD. Slice 36 does not change the
likelihood; it adds a diagnostic view of the fitted structured-effect layer.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `man/check_drm.Rd`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `PATH=/opt/homebrew/bin:$PATH air format R/check.R tests/testthat/test-check-drm.R NEWS.md`
- `Rscript -e 'devtools::test(filter = "check-drm|spatial-gaussian", reporter = "summary")'`
- `Rscript -e 'devtools::document()'`
- `git diff --check`

All passed.

## Tests Of The Tests

The new test fits a real coordinate-spatial Gaussian model, then mutates the
fitted object to exercise the singleton-site, tiny-spatial-SD, and invalid-SD
diagnostic branches. It also asserts that spatial fits do not receive the
`phylo_mu_replication` row.

## Consistency Audit

The roxygen text, regenerated help page, NEWS bullet, and tests now describe
spatial diagnostics with spatial terminology. The row name is deliberately
separate from the phylogenetic checks so Pat does not have to explain why a
site field is reported as a species replication issue.

## What Did Not Go Smoothly

The first patch attempt was too broad and missed the exact roxygen text. Ada
split the edit into smaller hunks and reran the focused checks after test
cleanup.

## Team Learning

- Ada: keep diagnostics named by the scientific layer the user sees.
- Boole: surface spatial terminology at the R API boundary even when internals
  reuse the structured-effect backend.
- Gauss: no likelihood change was needed; the diagnostic reads fitted SDs and
  residual scales only.
- Noether: site replication is not species replication, even when both are
  structured random-effect checks.
- Curie: mutate fitted objects to force rare diagnostic branches without slow
  simulations.
- Fisher: keep the warning threshold conservative and call it a diagnostic, not
  an interval or proof of identifiability.
- Pat: readers need the message to say what to inspect next: replication,
  coordinate input, and residual-scale dominance.
- Grace: roxygen changed, so `devtools::document()` was part of the gate.
- Rose: stale layer names are easy to miss when internals are shared; search for
  user-facing names after each structured-effect slice.

## Known Limitations

This is only for the fitted univariate coordinate-spatial `mu` path. Spatial
q=4, spatial direct-SD, mesh/SPDE, and spatial `corpair()` diagnostics remain
planned.

## Next Actions

Use the new diagnostic in the spatial tutorial example, then record the mesh
and scalable spatial contract before the final Phase 5 audit.
