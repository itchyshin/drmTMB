# After Task: Q1 Spatial Mu ML Parity

## 1. Goal

Bank SR116 by turning q1 Gaussian coordinate-spatial mean-side bridge evidence
into row-specific ML parity across native R/TMB, direct DRM.jl, and
R-via-Julia.

## 2. Implemented

Changed the Gaussian `spatial(1 | site, coords = coords)` Julia bridge payload
to preserve native drmTMB's target. The bridge now computes the same fixed-range
spatial covariance K from coords that native drmTMB uses, sends an internal
`relmat(1 | site)` plus `K` payload to DRM.jl, and reconstructs the returned SD
under the user's original `spatial(1 | site)` label.

Added tests for the fixed-range K payload and for one live q1 Gaussian spatial
ML parity fixture across native R/TMB, direct DRM.jl, and R-via-Julia.

## 3a. Decisions and Rejected Alternatives

I did not compare native drmTMB's fixed-range spatial model against DRM.jl's
coordinate-spatial estimated-range model. A scratch run showed direct DRM.jl and
R-via-Julia agreed with each other but not with native TMB, because the targets
were different. The accepted route instead converts coords to native fixed-range
K before the DRM.jl call.

I did not promote mesh/SPDE, REML, interval, sigma-side, q2, q4, or
non-Gaussian spatial support.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-structured.R`
- `tests/testthat/test-julia-tmb-parity.R`
- `docs/dev-log/dashboard/bridge-parity-smoke-status.tsv`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/structured-re-balance-matrix.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-julia-twin-sync.tsv`
- `docs/dev-log/dashboard/structured-re-q1-parity-fixture-contract.tsv`
- `docs/dev-log/dashboard/sweep.json`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/200-ayumi-julia-bridge-balance-readiness.md`
- `docs/design/216-structured-random-effect-finish-100-slices.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-22-q1-spatial-mu-ml-parity.md`

## 5. Checks Run

```sh
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  Rscript --vanilla -e "devtools::test(filter = 'julia-structured|julia-tmb-parity')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R \
  docs/dev-log/after-task/2026-06-22-q1-spatial-mu-ml-parity.md
```

Result: `julia-structured` and `julia-tmb-parity` passed with 122 assertions,
0 failures, 0 warnings, and 0 skips in 137.3 seconds.
`tools/validate-mission-control.py` passed with 11 bridge parity-smoke rows and
20 executable-evidence rows. `status.json` and `sweep.json` parsed as JSON,
`sh -n tools/start-mission-control.sh` passed, `git diff --check` was clean in
both active worktrees, and the after-task report validator passed.

## 6. Tests of the Tests

Before the bridge change, the scratch spatial fixture showed native TMB
log-likelihood `-5.732337` while direct DRM.jl and R-via-Julia reported
`-5.554093`; the structured SDs also differed because DRM.jl estimated the
spatial range. After converting coords to native fixed-range K, all three
routes reported `-5.732337` and the same structured SD.

The new tests would fail if the payload stopped converting spatial coords to
`K`, if the internal formula stopped using `relmat(1 | site)`, if the R object
lost the `spatial(1 | site)` label, or if any native/direct/bridge parity
tolerance failed.

## 7a. Issue Ledger

No GitHub issue, comment, PR, commit, or Ayumi reply was created. SR116 is
local mission-control evidence only. The next row is SR117: count phylo bridge
finite-vs-parity boundary.

## 8. Consistency Audit

The dashboard rows now say spatial q1 `mu` ML parity is covered only through
the native fixed-range K bridge target. The notes explicitly separate this from
DRM.jl's estimated-range spatial route, mesh/SPDE, intervals, REML,
sigma-side, q2/q4, and non-Gaussian support.

## 9. What Did Not Go Smoothly

The first scratch fit uncovered a genuine target mismatch. That was useful:
it prevented a misleading parity row and forced the bridge to match native
drmTMB semantics before banking SR116.

## 10. Known Residuals

This is one deterministic q1 Gaussian coordinate-spatial mean-side ML parity
fixture. It is not calibrated coverage, not interval reliability, not REML
parity, not mesh/SPDE support, not sigma-side spatial support, not q2/q4 bridge
support, and not broad public structured-bridge support.

## 11. Team Learning

Noether/Fisher: parity must compare the same likelihood target, not just the
same syntax. Emmy: R-via-Julia may legitimately translate user syntax to a
lower-level DRM.jl target when that is the only way to preserve native
semantics. Rose: record the negative scratch evidence because it explains why
the bridge behavior changed.
