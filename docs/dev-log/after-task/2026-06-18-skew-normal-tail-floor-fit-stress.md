# After Task: Skew-Normal Tail-Floor Fit-Stress Diagnostic

## Goal

Add a narrow fit-level diagnostic pilot for `drmTMB#59` that tests whether
deliberately stressed fixed-effect skew-normal data lead fitted models to
evaluate observations in the `log(Phi(alpha * z) + 1e-300)` tail-floor regime.

## Implemented

Added `docs/dev-log/simulation-artifacts/2026-06-18-skew-normal-tail-floor-fit-stress/`
with a reproducible runner, fit diagnostics, coefficient summaries, tail-floor
exposure summaries, session information, and README. Updated the numerical-guard
audit, finish matrix/worklist wording, check-log, and mission-control dashboard
while leaving metrics unchanged.

## Mathematical Contract

The source guard acts on the scalar `alpha * z`, where `alpha` is the fitted
skew-normal slant and `z` is the native-scale standardized residual. The pilot
records both generating-scale and fitted-scale `alpha * z`. The floor threshold
is approximately `-37.0471`, where `Phi(alpha * z)` is about `1e-300`.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-18-skew-normal-tail-floor-fit-stress/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `inst/sim/run/sim_run_first_wave_summary_smoke.R`
- `tests/testthat/test-phase18-first-wave-summary-smoke-runner.R`

## Checks Run

- `/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-18-skew-normal-tail-floor-fit-stress/run-pilot.R`
- `/usr/local/bin/Rscript -e "devtools::load_all('.', quiet = TRUE); testthat::test_file('tests/testthat/test-skew-normal-density-contract.R')"`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript -e "pkgdown::check_pkgdown()"`
- Boundary scan for release, CRAN, coverage, power, calibrated-interval,
  `engine_control`, AI-REML, fitted-stability, and Julia-bridge wording.
- `/usr/local/bin/Rscript --vanilla -e "devtools::test(filter = '^phase18-first-wave-summary-smoke-runner$', reporter = 'summary')"`
- `/usr/local/bin/Rscript --vanilla -e "devtools::test(filter = '^(phase18-first-wave-summary-smoke-runner|phase18-student-shape-grid-writer|phase18-interval-heavy-summary-smoke-runner)$', reporter = 'summary')"`

## Tests Of The Tests

This slice is an artifact-only diagnostic. It does not change package behavior
or add reusable test helpers. The test-of-test value is the adverse diagnostic
row in the committed artifact: one ordinary-reference replicate is
non-converged with `pdHess = FALSE`, a large fixed-gradient warning, and a very
large `skew_normal_nu` diagnostic. The artifact keeps that row rather than
filtering it out.

## Consistency Audit

The wording remains diagnostic. The new artifact says the fitted-scale tail
floor was inactive in this small pilot, but it also records that estimate
stability, Hessian behavior, intervals, coverage, power, release readiness,
CRAN readiness, and Julia bridge parity are not promoted.

`tools/validate-mission-control.py` reported
`mission_control_ok: 25/68 banked_or_verified, 1 active, 17 matrix rows, 11 finish rows, 15 Julia gate rows, 9 Julia capability rows`.
`pkgdown::check_pkgdown()` passed after setting
`RSTUDIO_PANDOC=/opt/homebrew/bin`.

Draft PR #620 R-CMD-check run `27758547367` passed on macOS and Windows, but
the first Ubuntu attempt failed because the strict Phase 18 first-wave report
smoke expected complete artifact status while the first-wave smoke runner did
not stage `student_shape_grid`. The branch now includes that existing
Student-t shape grid in the first-wave smoke artifact bundle; the focused
first-wave smoke test and related Student-t/interval-heavy smoke bundle pass
locally.

## GitHub Issue Maintenance

`drmTMB#59` remains the active issue-led row. Posted the PR/evidence breadcrumb
at <https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4741806041>.

## What Did Not Go Smoothly

The ordinary reference cell produced one non-converged, non-positive-Hessian
replicate with an extreme fitted slant. This was not smoothed away. It is part
of the result and reinforces the rule that convergence and finite likelihood
values are not enough evidence.

The first PR CI attempt also exposed a strict report-fixture gap outside the
new skew-normal artifact: Ubuntu failed because `student_shape_grid` was absent
from the first-wave smoke bundle while strict report rendering expected it.
The repair stages the existing Student-t shape artifact rather than weakening
the report's completeness rule.

## Team Learning

Hao Qin's numerical-guard warning should be treated as a promotion-contract
rule for all remaining capabilities: if a numerical trick, optimizer preset,
or guard is involved, the artifact must show whether it was active and whether
fit diagnostics still support interpretation.

## Known Limitations

The pilot has only three replicates per cell and no unguarded likelihood
comparator. It cannot estimate coverage, power, interval reliability, or
default-vs-reference likelihood differences.

## Next Actions

Monitor the refreshed PR CI before any merge decision. The next numerical-guard
slices are support floors, correlation open-interval guards, Student-t
calibration depth, scale-side/structured `log(sigma)` guard depth, and
starting-value/multi-start sensitivity.
