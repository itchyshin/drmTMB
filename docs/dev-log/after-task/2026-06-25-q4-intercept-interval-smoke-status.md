# After Task: Q4 All-Four Intercept Interval Smoke Status

## 1. Goal

Run and bank the first deterministic direct-SD interval smoke for exact
bivariate Gaussian all-four intercept q4 structured cells in `phylo()`,
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`,
without promoting interval reliability, coverage, REML, AI-REML, broad bridge
support, or public support.

## 2. Implemented

- Added `tools/run-structured-re-q4-intercept-interval-smoke.R`.
- Added
  `docs/dev-log/simulation-artifacts/2026-06-25-q4-intercept-interval-smoke/structured-re-q4-intercept-interval-smoke-results.tsv`
  with 48 method rows: 16 direct-SD targets crossed with Wald, profile, and
  bootstrap.
- Added
  `docs/dev-log/dashboard/structured-re-q4-intercept-interval-diagnostic-status.tsv`
  with 16 direct-SD status rows.
- Wired the status sidecar into `tools/validate-mission-control.py`.
- Added a dashboard contract test to
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Updated `docs/dev-log/dashboard/README.md`,
  `docs/design/218-structured-q-series-completion-map.md`, and
  `docs/dev-log/check-log.md`.

## 3a. Decisions and Rejected Alternatives

The runner attempts intervals only when the fitted object has `pdHess = TRUE`.
This follows the q4 all-four one-slope smoke precedent and rejects the weaker
alternative of treating finite profile rows under a non-positive-definite
Hessian as interval evidence. The A-matrix animal fixture did have
`pdHess = TRUE`, so the runner recorded Wald, profile, and bootstrap method
outcomes for that provider instead of forcing all providers into the same
blocked class.

## 4. Files Touched

- `tools/run-structured-re-q4-intercept-interval-smoke.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q4-intercept-interval-diagnostic-status.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-q4-intercept-interval-smoke/structured-re-q4-intercept-interval-smoke-results.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-q4-intercept-interval-smoke-status.md`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-q4-intercept-interval-smoke.R`
  passed and wrote 48 method rows plus 16 status rows.

Additional formatting, test, mission-control, after-task, and diff checks are
run in the PR verification step for this slice.

## 6. Tests of the Tests

The new conversion-contract test checks the status schema, row counts,
method-level artifact count, plan/status target identity, profile-target
presence, provider-specific Hessian and interval outcomes, diagnostic-only
claim boundaries, and unchanged q-series `planned` interval/coverage statuses.
It would fail if a row promoted coverage, changed target identity, dropped the
artifact link, or claimed public support.

## 7a. Issue Ledger

No GitHub issue was opened or updated in this slice. The work stays inside the
draft q-series completion PR stack.

## 8. Consistency Audit

The new status sidecar links directly to
`structured-re-q4-intercept-interval-diagnostic-plan.tsv`, and both the R test
and mission-control validator require plan/status identity for `cell_id`,
`formula_cell`, `endpoint_member`, `estimand`, and `profile_target`. The
q-series rows remain at `interval_status = planned` and
`coverage_status = planned`, so the dashboard keeps smoke evidence separate
from reliability or coverage claims.

## 9. What Did Not Go Smoothly

The first phylo probe showed `pdHess = FALSE`, which confirmed that the Hessian
gate was needed before running profiles or bootstrap. The full runner then
found a mixed result: phylo, spatial, and relmat stayed Hessian-blocked, while
the animal A-matrix fit allowed interval attempts. Bootstrap did not return
finite intervals for the animal targets, and the raw method warnings are kept in
the artifact.

## 10. Known Residuals

Derived-correlation interval reconstruction remains unavailable. The phylo,
fixed-covariance spatial, and K-matrix relmat q4 intercept direct-SD smoke rows
are Hessian-blocked. The A-matrix animal rows have finite Wald/profile direct-SD
intervals but nonfinite bootstrap intervals. No denominator is admitted, no
coverage or interval-reliability claim is made, and q4 REML, native-TMB q4 REML,
q4 AI-REML, HSquared AI-REML, non-Gaussian REML, broad bridge support, public
optimizer controls, DRAC/Totoro execution, and SR150 coverage readiness remain
unpromoted.

## 11. Team Learning

The q4 intercept lane is not uniformly blocked in the same way as the all-four
one-slope q8-shaped lane. The support-cell map needs provider-target evidence,
not q-neighbour inference: an animal A-matrix intercept smoke can reach finite
Wald/profile direct-SD intervals while phylo, spatial, and relmat remain blocked
on Hessian evidence in the same deterministic slice.
