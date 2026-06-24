# After Task: Q2 Spatial Fixed-Covariance Bridge Parity

## Goal

Close the q2 spatial bridge gap for one complete-response exact-Gaussian ML
fixture without promoting range-estimating spatial support, q2 REML, q4,
interval reliability, interval coverage, or broad public bridge support.

## Implemented

The R-to-Julia bridge now admits matching bivariate Gaussian `mu1`/`mu2`
`spatial(1 | p | id, coords = coords)` formulas for a fixed-covariance q2
fixture. The bridge computes the native coordinate-spatial precision, converts
it to a covariance matrix, sends the direct Julia target through a `relmat()`
payload, and preserves the original `spatial` structured label for user-facing
extractors and dashboard provenance.

DRM.jl q2 direct-export status now marks `phylo`, `spatial`, `animal`, and
`relmat` rows as experimental fixture evidence. The spatial row is explicitly
fixed-covariance only.

## Mathematical Contract

The banked cell is a q2 bivariate Gaussian location-location covariance fixture:
`mu1` and `mu2` carry matching structured intercepts, `sigma1`, `sigma2`, and
`rho12` are intercept-only, and the estimator is ML. Spatial coordinates are
used only to form a fixed covariance matrix before the Julia call. This is not a
range-estimating spatial model, mesh/SPDE model, q2 REML route, q4 route,
AI-REML route, interval-reliability result, or coverage result.

## Files Changed

- `R/julia-bridge.R`
- `tests/testthat/test-julia-structured.R`
- `tests/testthat/test-julia-gate-vs-engine.R`
- `tests/testthat/test-julia-tmb-parity.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q2-*.tsv`
- `docs/dev-log/dashboard/structured-re-balance-matrix.tsv`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-julia-twin-status.tsv`
- `docs/dev-log/dashboard/structured-re-julia-twin-sync.tsv`
- `docs/dev-log/dashboard/structured-re-closeout-package.tsv`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/README.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/216-structured-random-effect-finish-100-slices.md`
- DRM.jl `src/bridge.jl`
- DRM.jl `test/test_bridge_q2_direct_export.jl`

## Checks Run

- `git status --short --branch` in both active worktrees.
- `git diff --check` in both active worktrees before editing.
- `julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot test/test_bridge_q2_direct_export.jl`: passed 116/116 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'julia-structured|julia-gate-vs-engine')"`: passed 202 assertions with one optional skip.
- `DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot DRM_JL_RELMAT_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot Rscript --vanilla -e "devtools::test(filter = 'julia-tmb-parity')"`: passed 126/126 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'julia-structured|julia-gate-vs-engine|structured-re-conversion-contracts')"`: passed 648 assertions with one optional skip.
- `python3 tools/validate-mission-control.py`: passed with 4 q2 acceptance rows, 4 q2 direct-export rows, 7 q2 bridge-boundary rows, 10 Julia twin-status rows, 36 closeout-package rows, and 52 executable-evidence rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json` and `python3 -m json.tool docs/dev-log/dashboard/sweep.json`: parsed cleanly.
- `sh -n tools/start-mission-control.sh`: passed.
- `git diff --check`: passed in both active worktrees.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`: refreshed the served copy at `http://127.0.0.1:8765/`.
- Direct HTTP fetches passed for `version.txt` (`r31`), `status.json`, `sweep.json`, `structured-re-q2-acceptance-gate.tsv`, `structured-re-q2-direct-drmjl-export.tsv`, and `structured-re-q2-bridge-boundary.tsv`.

## Tests Of The Tests

The R live parity test now exercises `relmat`, `animal`, and fixed-covariance
`spatial` q2 bridge fixtures in the same parity harness. The structured payload
test checks that the user-facing formula can be spatial while the direct Julia
payload uses `relmat(1 | id)` plus the computed fixed covariance matrix. The
dashboard contract tests fail if a spatial row regresses to `planned`, loses the
fixed-covariance boundary, or implies range-estimating spatial support.

## Consistency Audit

The q2 spatial gate was removed from the intentional Julia rejection registry
because it is no longer an intentional pre-JuliaCall rejection. The q2
acceptance gate, coefficient-order map, payload contract, payload provenance,
direct DRM.jl status, balance matrix, finish slices, executable evidence,
Julia twin sync rows, closeout package, README, status JSON, sweep JSON, and two
design summaries were updated to the same narrow claim.

## GitHub Issue Maintenance

No GitHub comment, PR, commit, or Ayumi reply was made. The current work remains
local dashboard and bridge evidence.

## What Did Not Go Smoothly

The spatial bridge truth was repeated across many validator-owned ledgers. The
old blocker wording survived in the dashboard README, design matrix, sweep JSON,
R contract tests, and validator after the R and Julia code already passed. This
is a useful warning: q2 acceptance changes need TSV, JSON, design, and validator
updates as one unit.

## Team Learning

Rose's drift audit mattered here: changing a bridge row is not enough when the
dashboard has separate status, provenance, closeout, and human-readable
surfaces. Emmy's bridge boundary also mattered: preserving the user-facing
`spatial` label while sending a direct `relmat` payload is acceptable only
because the payload records the fixed covariance and the claim boundary says
what was translated.

## Known Limitations

The banked evidence is one fixed-covariance exact-Gaussian ML fixture. It does
not cover range estimation, mesh/SPDE spatial models, spatial slopes,
scale-side q2 spatial blocks, q2 REML, q4, non-Gaussian q2, Q precision
marshalling, pedigree/Ainv marshalling, interval reliability, interval
coverage, public optimizer controls, or broad bridge support.

## Next Actions

Run the final mission-control validator, focused R contract tests, JSON syntax
checks, shell syntax check, served-widget fetches, and post-edit `git diff
--check` in both worktrees. Then keep moving toward q4 interval-reliability and
coverage-denominator gates without widening q2 spatial wording.
