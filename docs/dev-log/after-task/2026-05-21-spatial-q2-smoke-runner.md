# After Task: Spatial Q2 Smoke Runner

## Goal

Turn the newly admitted coordinate-spatial q=2 Phase 18 design into a runnable
seeded smoke surface that fits the same public syntax users see in examples.

## Implemented

Added a bivariate spatial q=2 DGP, fit summarizer, and smoke runner under
`inst/sim/`. The smoke runner fits matching
`spatial(1 | p | site, coords = coords)` terms in `mu1` and `mu2`, records
fixed `mu1`/`mu2` coefficients, public residual scales, spatial SDs, spatial
correlation, and residual `rho12`, and keeps profile intervals visible as
`not_requested` unless explicitly requested.

The DGP supports simple coordinate geometries (`ring`, `stretched`, and
`clustered`) so later grids can separate site count, replication, geometry
stress, spatial SD, spatial correlation, and residual `rho12`.

## Mathematical Contract

For site-level spatial effects,

```text
Cov(u_a[s], u_b[t]) = S[a, b] * K_space[s, t]
```

where `K_space` is derived from the coordinate precision helper and `S` contains
the two spatial SDs and spatial correlation. Residual `rho12` is still an
observation-level residual correlation and remains separate from
`corpairs(level = "spatial")`.

## Files Changed

- `inst/sim/dgp/sim_dgp_spatial_q2.R`
- `inst/sim/fit/sim_summarise_spatial_q2.R`
- `inst/sim/run/sim_run_spatial_q2_smoke.R`
- `tests/testthat/test-phase18-spatial-q2-smoke.R`
- `inst/sim/README.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/56-phase-18-spatial-q2-ademp.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-spatial-q2-smoke-runner.md`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_spatial_q2.R inst/sim/fit/sim_summarise_spatial_q2.R inst/sim/run/sim_run_spatial_q2_smoke.R tests/testthat/test-phase18-spatial-q2-smoke.R
Rscript -e "devtools::test(filter = 'phase18-spatial-q2-smoke')"
Rscript -e "devtools::test(filter = 'spatial-gaussian|phase18-spatial-q2-smoke')"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
rg -n 'spatial q=2.*need(s)? a dedicated DGP|broad q=2 reports still need a dedicated DGP|DGP/helper/artifact slice|formal Phase 18 DGP and writer should live|simulation programme has not decided|fitted but waits for a dedicated ADEMP|waiting for an ADEMP row' docs/design/16-phylo-spatial-common-math.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/56-phase-18-spatial-q2-ademp.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-spatial-q2-ademp-admission.md docs/dev-log/after-task/2026-05-21-spatial-q2-smoke-runner.md inst/sim/README.md
rg -n 'spatial q=2.*need(s)? a dedicated DGP|broad q=2 reports still need a dedicated DGP|DGP/helper/artifact slice|formal Phase 18 DGP and writer should live|simulation programme has not decided|fitted but waits for a dedicated ADEMP|waiting for an ADEMP row' docs/design/16-phylo-spatial-common-math.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/56-phase-18-spatial-q2-ademp.md inst/sim/README.md
```

Outcomes:

- The first focused test run failed because the test expected the word
  "correlation" in a shared validator error that actually says "absolute value
  below 1".
- After narrowing the expectation to the real error text, the final focused
  test passed 20 expectations with no warnings or skips.
- The broader neighboring run `spatial-gaussian|phase18-spatial-q2-smoke`
  passed 118 expectations.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.
- The stale-status scan returned only the previous Slice H after-task/check-log
  text that was true when written. Current design docs now say the DGP and
  smoke runner exist; the current-design-only scan returned no matches.

## Tests Of The Tests

The DGP test checks seeded reproducibility, coordinate row names, covariance
truth against `drm_spatial_coords_precision()`, and residual covariance truth.
The runner test fits one q=2 spatial smoke cell and checks that the summary
contains the fixed effects, residual scales, spatial SDs, spatial correlation,
and residual `rho12` rows. The validation test covers malformed site count,
negative spatial SD, invalid spatial correlation, malformed cells, and invalid
replicate count.

## Consistency Audit

Ada and Rose updated the ADEMP sheet, simulation programme, readiness matrix,
spatial parity ladder, and `inst/sim/README.md`. The current status is now:
spatial q=2 has design admission plus DGP/smoke-runner evidence; CSV artifacts,
interval-status tables, and broad coverage reports remain planned.

## GitHub Issue Maintenance

No issue update was attempted for this internal simulation-runner slice. The
local check log and this after-task report carry the handoff.

## What Did Not Go Smoothly

The only failed run was a test-expectation mismatch against shared validator
wording. The implementation path itself fit the smoke cell on the first run.

## Team Learning

Pat's useful-user check helped keep the public spelling central: the smoke
runner fits `spatial(1 | p | site, coords = coords)` rather than only a helper
matrix. Fisher and Curie kept interval claims out of this slice because no CSV
artifact writer or profile-status table has landed yet.

## Known Limitations

This slice does not add CSV grid artifacts, interval-status tables, formal
coverage, mesh/SPDE, multiple spatial slopes, spatial `sigma`, spatial q=4,
spatial direct-SD surfaces, or spatial `corpair()` regression.

## Next Actions

- Add a spatial q=2 grid writer with aggregate, replicate, manifest, failure,
  Wald, profile-status, interval-evidence, interval-diagnostic, and
  interval-failure CSVs.
- Add a small opt-in profile smoke for one spatial SD, the spatial correlation,
  and residual `rho12`.
