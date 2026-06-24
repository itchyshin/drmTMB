# After Task: Q2 Known Structured Bridge Parity

## Goal

Unblock the q2 `animal()` and `relmat()` known-covariance rows from
direct-only evidence to narrow native/direct/R-via-Julia parity evidence, while
leaving aggregate q2 acceptance blocked on the missing q2 `spatial()` bridge
route.

## Implemented

- Added a bivariate Gaussian known-structured R bridge route for q2
  `animal()` and `relmat()` fixtures.
- Kept q2 `spatial()` bridge support rejected before JuliaCall because the
  range-estimating spatial route and fixed-covariance bridge route are still
  unimplemented.
- Collapsed structured-block labels for q2 bridge formulas so labelled
  `relmat()` and `animal()` terms translate to the Julia formula grammar without
  treating the block label as a data column.
- Extended bridge reconstruction metadata so `corpairs()` can report q2
  `relmat` and `animal` structured-correlation levels.
- Updated DRM.jl q2 formula and direct-export fixture support in the active
  Julia pilot worktree.
- Updated dashboard row contracts so `phylo`, `animal`, and `relmat` q2 rows
  can be experimental fixtures while q2 `spatial` remains planned or blocked.

## Mathematical Contract

This is complete-response exact-Gaussian ML fixture evidence only. The banked
rows compare the same q2 residual-correlation target across native R/TMB, direct
DRM.jl, and R-via-Julia bridge routes for one K-matrix `relmat()` fixture and
one A-matrix `animal()` fixture. The rows do not promote q2 REML, q4, HSquared
AI-REML, interval reliability, interval coverage, range-estimating q2 spatial
support, relmat Q precision marshalling, animal pedigree/Ainv bridge
marshalling, non-Gaussian q2 covariance, or broad public bridge support.

## Files Changed

- R bridge implementation: `R/julia-bridge.R`.
- R bridge and contract tests: `tests/testthat/test-julia-structured.R`,
  `tests/testthat/test-julia-gate-vs-engine.R`,
  `tests/testthat/test-julia-tmb-parity.R`, and
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Mission-control validator: `tools/validate-mission-control.py`.
- Dashboard ledgers for q2 payloads, provenance, direct export, acceptance,
  balance, Julia twin sync, executable evidence, closeout, status, sweep, and
  widget version.
- DRM.jl pilot worktree files: `src/DRM.jl`, `src/bridge.jl`,
  `src/coevolution_q.jl`, `src/gaussian_bivariate.jl`, and
  `test/test_bridge_q2_direct_export.jl`.

## Checks Run

- `julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot test/test_bridge_q2_direct_export.jl`
  passed 111 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'julia-structured|julia-gate-vs-engine')"`
  passed 204 assertions with one optional skip.
- `DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot DRM_JL_RELMAT_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot Rscript --vanilla -e "devtools::test(filter = 'julia-tmb-parity')"`
  passed 111 assertions with no skips.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts|julia-structured|julia-gate-vs-engine')"`
  passed 646 assertions with one optional skip.
- `python3 tools/validate-mission-control.py` passed with 16 Julia gate rows,
  16 bridge rejection-message rows, 4 q2 acceptance-gate rows, and 52
  executable-evidence rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  served the widget at `http://127.0.0.1:8765/`; live fetches returned
  `version.txt = r30`, `status.json`, `sweep.json`,
  `structured-re-q2-acceptance-gate.tsv`,
  `structured-re-q2-direct-drmjl-export.tsv`,
  `structured-re-q2-payload-provenance.tsv`, and
  `bridge-rejection-messages.tsv`.

## Tests Of The Tests

The q2 relmat/animal live parity test reached the new public
`drmTMB(..., engine = "julia")` route and initially failed on an unsupported
`testthat` `info` argument, not on the fitted target. Removing that test-only
argument let the same route pass against native R/TMB and direct DRM.jl. The
fast gate tests include the negative path: q2 `spatial()` still rejects before
JuliaCall with a row-specific planned-route reason.

## Consistency Audit

Stale wording scans used:

```sh
rg -n "spatial animal and relmat R-via-Julia|spatial/animal/relmat R-via-Julia|spatial/animal/relmat direct and R-via-Julia|animal and relmat.*remain planned|non-phylo q2 rows remain planned|R q2 phylo parity 82/82|q2 102/102|143 assertions passed|narrow phylo fixture|beyond the narrow phylo|Add spatial animal and relmat|Implement spatial animal and relmat" docs/dev-log/dashboard docs/design tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py
```

The intended remaining stale hits are historical after-task notes that were true
when written. Current dashboard surfaces now say q2 `animal()` and `relmat()`
are narrow known-covariance fixtures and q2 `spatial()` remains the aggregate
q2 blocker.

## GitHub Issue Maintenance

No GitHub issue or Ayumi reply was posted. The issue-facing boundary stays
unchanged until the current issue text is reviewed and the user approves exact
reply text.

## What Did Not Go Smoothly

The first q2 bridge probe exposed a formula-label collapse bug: the R bridge was
passing the q2 block label as a data variable. The fix was to collapse labelled
structured terms for all structured markers before building the Julia formula.
The second snag was stale row-contract logic that treated all non-phylo q2 rows
as planned; the validator now distinguishes `spatial` from `animal` and
`relmat`.

## Team Learning

Q2 status needs row-specific vocabulary. Saying "non-phylo q2" was too coarse:
`spatial` is a range/fixed-covariance route-design problem, while `animal` and
`relmat` can carry known-covariance bridge fixture evidence without promoting
pedigree/Ainv or Q precision marshalling.

## Known Limitations

- Q2 `spatial()` has no R-via-Julia same-target route.
- Aggregate q2 acceptance remains blocked.
- The `animal()` bridge accepts an A matrix, not pedigree/Ainv marshalling.
- The `relmat()` bridge accepts a K matrix, not Q precision marshalling.
- No q2 REML, q4, HSquared AI-REML, interval reliability, interval coverage,
  non-Gaussian q2 covariance, public optimizer, commit, PR, or Ayumi reply is
  promoted.

## Next Actions

1. Decide whether q2 `spatial()` gets a fixed-covariance bridge route or an
   explicit exclusion row before aggregate q2 acceptance can move.
2. If spatial gets a route, add the native/direct/R-via-Julia same-target
   fixture and tolerance row before changing SR130.
