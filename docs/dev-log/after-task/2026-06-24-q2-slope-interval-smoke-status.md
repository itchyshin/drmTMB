# After Task: Q2 Slope Interval Smoke Status

## Goal

Run and bank the first deterministic interval-smoke status for the bivariate
Gaussian structured slope-only q=2 `mu1`/`mu2` targets without promoting
interval reliability, coverage, REML, AI-REML, q4/q8, or broad bridge support.

## Implemented

- Added `tools/run-structured-re-q2-slope-interval-smoke.R`, a rerunnable smoke
  harness for the four slope-only q=2 provider cells.
- Wrote the method-level artifact at
  `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-interval-smoke/structured-re-q2-slope-interval-smoke-results.tsv`.
- Added
  `docs/dev-log/dashboard/structured-re-q2-slope-interval-diagnostic-status.tsv`
  with 12 target-level status rows.
- Added mission-control validation and R conversion-contract coverage for the
  status sidecar and method artifact.
- Updated the dashboard README and q-series completion map to distinguish the
  plan sidecar from deterministic interval-smoke status.

## Mathematical Contract

The smoke status covers the 12 slope-only q=2 targets formed by four providers
(`phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()`) and three endpoint members:

- `sd:mu:mu1:provider(0 + x | p | group)`
- `sd:mu:mu2:provider(0 + x | p | group)`
- `cor:provider:cor(mu1:x,mu2:x | p | group)`

Each target was checked with Wald, endpoint-profile, and bootstrap intervals
using a deterministic complete-response Gaussian fixture. Bootstrap used two
refits, so it is plumbing and finite-row evidence only, not calibrated
uncertainty.

## Files Changed

- `tools/run-structured-re-q2-slope-interval-smoke.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-interval-smoke/structured-re-q2-slope-interval-smoke-results.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-interval-diagnostic-status.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-q2-slope-interval-smoke.R
air format tools/run-structured-re-q2-slope-interval-smoke.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

Interim smoke result: the harness wrote 36 method rows and 12 dashboard status
rows. The first run exposed a slope-design runtime mismatch in the bivariate
Gaussian structured-effect contribution. After fixing the runtime/extractor
design multiplication and rerunning the harness, 10 targets had finite
Wald/profile/bootstrap intervals and two correlation targets had finite
Wald/bootstrap with endpoint-profile failure. All fits converged with
`pdHess = TRUE`. This remains diagnostic-only evidence.

## Tests Of The Tests

The conversion-contract test checks the 12-row status sidecar, the 36-row
method artifact, the finite/profile-failed pattern, the diagnostic-only claim
status, and the linked q-series rows. The Python validator independently checks
the same target identities,
provider-specific boundaries, local evidence paths, and unchanged q-series
interval/coverage statuses.

## Consistency Audit

The q-series completion map and dashboard README now say that deterministic
q2 slope interval smoke has run, but only as diagnostic evidence. The linked
support-cell rows remain at `interval_status = planned` and
`coverage_status = planned`.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is an internal evidence-ladder sidecar
under the existing q-series completion plan rather than a new user-facing
tracker.

## What Did Not Go Smoothly

The first diagnostic result looked like boundary behavior, but the stronger
probe showed fitted slope SDs were unexpectedly close to zero. Inspecting the
runtime contribution found that bivariate q2/q4 structured effects were not
multiplying the latent structured effects by the design column. The rerun is
better evidence, but it is still single-fixture diagnostic evidence rather than
support evidence.

## Team Learning

Slope-only q2 needs the same target-grain accounting as matched `mu+sigma`:
finite bootstrap rows, Wald boundary warnings, profile failures, and Hessian
status must stay separate. A finite row for one target or method must not
promote interval reliability, coverage, or neighbouring q4/q8 cells.

## Known Limitations

This slice does not provide calibrated coverage, interval reliability,
coverage MCSE, REML, AI-REML, broad bridge support, range-estimating spatial
support, pedigree/Ainv bridge marshalling, relmat Q bridge marshalling,
intercept-plus-slope q4/q8 structured slope support, or non-Gaussian
structured slope support.

## Next Actions

Repeat the q2 slope interval diagnostics with more deterministic fixtures,
denominator accounting, and MCSE-calibrated coverage design before considering
any support wording. Keep SR150 blocked until denominator evidence and
MCSE-calibrated coverage evidence exist.
