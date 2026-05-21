# After Task: Spatial Q2 Grid Artifacts

## Goal

Make the coordinate-spatial q=2 Phase 18 smoke surface useful to applied users
and reviewers by writing repeatable CSV artifacts, interval-status ledgers, and
row-count tests beside the resumable per-replicate RDS files.

## Implemented

The implemented claim is narrow: `phase18_write_spatial_q2_grid_outputs()` now
writes smoke-grid artifacts for the fitted bivariate Gaussian
`spatial(1 | p | site, coords = coords)` `mu1`/`mu2` location-covariance path.
It does not claim formal 500-replicate coverage, spatial `sigma`, q=4 spatial
blocks, mesh/SPDE support, direct-SD spatial grammar, or spatial `corpair()`
regression.

## Mathematical Contract

The model keeps two covariance layers separate. The spatial layer is a q=2
site-level location covariance for `mu1` and `mu2`; residual `rho12` is still an
observation-level residual correlation. Fixed `mu1` and `mu2` coefficients use
formula-coefficient Wald intervals. Spatial SDs, the spatial correlation,
residual `rho12`, and residual scales use profile-status rows that are either
`not_requested`, `ok`, or `failed`.

## Files Changed

- `inst/sim/run/sim_summary_spatial_q2_smoke.R`
- `inst/sim/run/sim_write_spatial_q2_grid.R`
- `tests/testthat/test-phase18-spatial-q2-grid-writer.R`
- `inst/sim/README.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/56-phase-18-spatial-q2-ademp.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/run/sim_summary_spatial_q2_smoke.R inst/sim/run/sim_write_spatial_q2_grid.R tests/testthat/test-phase18-spatial-q2-grid-writer.R
Rscript -e "devtools::test(filter = 'phase18-spatial-q2-smoke|phase18-spatial-q2-grid-writer')"
Rscript -e "devtools::test(filter = 'spatial-gaussian|phase18-spatial-q2-smoke|phase18-spatial-q2-grid-writer')"
gh issue list --search "spatial q2 simulation OR spatial q=2 simulation OR interval-status" --limit 20
rg -n 'broad q=2 reports still need CSV artifacts|CSV artifacts and interval-status tables remain|after a CSV artifact writer|CSV artifact writer and interval-status tables are added|A later artifact slice should add CSV writers|still need CSV artifacts|CSV writers and interval-status artifacts remain the next gate' docs/design/16-phylo-spatial-common-math.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/56-phase-18-spatial-q2-ademp.md inst/sim/README.md
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

- The focused spatial q=2 smoke/grid-writer run passed 57 expectations with no
  warnings or skips.
- The neighboring spatial Gaussian run passed 155 expectations with no
  warnings or skips.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.

## Tests Of The Tests

The grid-writer test checks the artifact manifest, file existence, CSV row
counts, default `not_requested` profile-status rows, fixed-effect Wald rows,
the overwrite failure path, malformed `output_dir`, and malformed `overwrite`.
The opt-in profile smoke requests `spatial:sd1`, `spatial:cor`, and `rho12`, so
the test exercises both default status ledgers and requested profile evidence.

## Consistency Audit

`inst/sim/README.md`, the spatial parity design note, the Phase 18 simulation
programme, the readiness matrix, and the spatial q=2 ADEMP sheet now agree that
CSV artifacts and interval-status tables exist. They also agree that formal
broad reports still require larger replicate runs and interpretation.

The stale-wording scan for current design sources returned no matches for
phrases that still described CSV artifacts as missing.

## GitHub Issue Maintenance

`gh issue list --search "spatial q2 simulation OR spatial q=2 simulation OR interval-status" --limit 20`
returned broad neighboring issues such as structured-effect implementation,
remaining slopes, and visualization work, but no dedicated spatial q=2
simulation issue that needed a comment for this internal artifact slice.

## What Did Not Go Smoothly

No test failure occurred in this slice. The main risk was wording drift: the
previous smoke-runner slice correctly said CSV artifacts were still missing,
and this slice had to update those claims without converting smoke artifacts
into formal operating-characteristic evidence.

## Team Learning

Pat's useful-user check is concrete here: a grid writer matters because applied
users and reviewers can inspect CSV rows for convergence, failures, fixed-effect
coverage, and profile-status evidence without loading internal RDS objects.
Rose should keep pairing every new artifact writer with a stale-wording scan
for the exact "still missing" phrases from the previous slice.

## Known Limitations

The current default grid is a smoke artifact, not a formal simulation report.
Spatial SDs, the spatial correlation, residual `rho12`, and residual scales
need explicit profile requests before they contribute coverage rows. Mesh/SPDE,
multiple spatial slopes, spatial `sigma`, spatial q=4, direct-SD spatial
syntax, and spatial `corpair()` regression remain planned or unsupported.

## Next Actions

Run a small n-replicate spatial q=2 artifact pilot when runtime allows, then
summarize fixed-effect Wald coverage and profile-status rates in the Phase 18
simulation ledger. Keep the first user-facing example ecological rather than
matrix-first.
