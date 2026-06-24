# After Task: Q4 All-Four One-Slope Interval Smoke Status

## 1. Goal

Bank the first deterministic direct-SD interval smoke for the exact shared-label
bivariate Gaussian all-four one-slope q8-shaped structured cells in `phylo()`,
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`.

## 2. Implemented

- Added `tools/run-structured-re-q4-slope-interval-smoke.R`.
- Added
  `docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-smoke/structured-re-q4-slope-interval-smoke-results.tsv`
  with 96 method rows: 32 direct-SD targets times Wald, profile, and bootstrap.
- Added
  `docs/dev-log/dashboard/structured-re-q4-slope-interval-diagnostic-status.tsv`
  with 32 direct-SD status rows.
- Corrected the q4 all-four one-slope sigma-axis direct-SD profile-target labels
  in `structured-re-q4-slope-interval-diagnostic-plan.tsv` from
  `sd:sigma:sigma*` to `sd:mu:sigma*`, matching the shared q8 structured
  covariance namespace exposed by `profile_targets()`.
- Wired the new status sidecar into mission-control validation and
  `test-structured-re-conversion-contracts.R`.
- Updated the dashboard README, the q-series completion map, and the check log.

All four provider fits converged, but all four returned `pdHess = FALSE`. The
sidecar therefore records all interval methods as `not_run_pdhess_false` with
zero finite intervals. This is negative diagnostic evidence, not interval
readiness.

## 3a. Decisions and Rejected Alternatives

I first tried running the full Wald/profile/bootstrap smoke without a Hessian
gate. The phylo fit converged with `pdHess = FALSE`; the Wald interval was
nonfinite, the first profile target could still return a finite row, and the
bootstrap step became the long pole. I rejected treating those rows as interval
evidence because a finite profile row under a non-positive-definite Hessian is
not a reliability signal. The runner now records all methods as blocked when
`pdHess = FALSE`.

I also corrected the q4 plan profile-target identity instead of preserving the
old `sd:sigma:sigma*` labels. The existing q4 profile-target bridge map and
runtime tests already use `sd:mu:sigma*` for the all-four structured block, so
the support-cell map now follows the implemented extractor identity.

## 4. Files Touched

- `tools/run-structured-re-q4-slope-interval-smoke.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q4-slope-interval-diagnostic-plan.tsv`
- `docs/dev-log/dashboard/structured-re-q4-slope-interval-diagnostic-status.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-smoke/structured-re-q4-slope-interval-smoke-results.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-24-q4-slope-interval-smoke-status.md`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-q4-slope-interval-smoke.R` passed
  and wrote the artifact/status TSVs. The run reported 18 warnings; the status
  sidecar records the diagnostic result as Hessian-blocked.
- `air format tools/run-structured-re-q4-slope-interval-smoke.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 2713 assertions.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 32 structured
  RE q4 slope interval-diagnostic status rows.
- `git diff --check` passed.
- The q4-slope interval overclaim scan for unsupported interval, coverage,
  REML, AI-REML, and supported-status wording returned no hits.

## 6. Tests of the Tests

The new R contract test checks the sidecar row count, the 96 method rows, the
corrected `sd:mu:sigma*` profile labels, target observation for all 32
direct-SD rows, zero `pdHess` rows, zero finite intervals, and the
diagnostic-only claim boundary. It would fail if the old `sd:sigma:sigma*`
target labels returned, if any row promoted interval readiness, or if the
linked q-series rows moved beyond `interval_status = planned`.

## 7a. Issue Ledger

No GitHub issue was opened or updated in this slice. The work is internal
dashboard evidence for the active q-series completion lane and remains inside
the draft PR branch.

## 8. Consistency Audit

Neighbouring q4 profile-target evidence already used `sd:mu:sigma*`, so the
q4 slope interval plan was corrected to that identity. The dashboard README,
q-series completion map, mission-control validator, conversion-contract test,
check log, and after-task note now all describe the same boundary: direct-SD
smoke status exists, derived-correlation intervals remain blocked, and q-series
interval/coverage statuses remain planned.

## 9. What Did Not Go Smoothly

The first runner attempt failed because endpoint covariance dimnames were lost
during matrix multiplication. The second attempt exposed a worse operational
problem: a `pdHess = FALSE` q8 fit can still spend time in profile/bootstrap
calls. Adding progress messages and the Hessian gate made the diagnostic honest
and fast.

## 10. Known Residuals

All four q8 direct-SD smoke fits are Hessian-blocked in this deterministic run.
No q4 all-four one-slope direct-SD interval is finite, no denominator is
admitted, and no coverage or reliability claim is made. Derived-correlation
interval reconstruction remains unavailable. q4 REML, native-TMB q4 REML,
q4 AI-REML, HSquared AI-REML, non-Gaussian REML, broad bridge support, public
optimizer controls, DRAC execution, and SR150 coverage readiness remain
unpromoted.

## 11. Team Learning

For q8-shaped structured all-four blocks, profile-target labels follow the
shared structured covariance namespace, so sigma endpoint SD targets are
`sd:mu:sigma*`, not `sd:sigma:sigma*`. Future support-cell rows should be
checked against `profile_targets()` output before being treated as interval
plan truth.
