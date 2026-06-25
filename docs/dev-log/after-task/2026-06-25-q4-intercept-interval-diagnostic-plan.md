# After Task: Q4 Intercept Interval Diagnostic Plan

## 1. Goal

Turn the q4 all-four intercept provider fixture parity into an explicit
target-level interval diagnostic plan without claiming finite intervals,
coverage denominators, interval reliability, interval coverage, REML,
AI-REML, broad bridge support, public support, DRAC/Totoro execution, or
Ayumi-facing resolution.

## 2. Implemented

Added
`phase18_structured_re_q4_intercept_interval_diagnostic_plan()` to
`inst/sim/R/sim_structured_re_bridge_fixtures.R`. The helper derives the
provider-scoped interval target rows from the q4 all-four intercept fixture
contract so the interval plan stays aligned with the exact `phylo`, fixed-
covariance `spatial`, A-matrix `animal`, and K-matrix `relmat` cells.

Added
`tools/run-structured-re-q4-intercept-interval-diagnostic-plan.R` and generated
`docs/dev-log/dashboard/structured-re-q4-intercept-interval-diagnostic-plan.tsv`
with 40 planned rows: four direct-SD targets and six derived-correlation
targets per provider.

Updated the four q4 all-four intercept support-cell `next_gate` fields to point
at the new interval-diagnostic plan while keeping `interval_status = planned`,
`coverage_status = planned`, and `denominator_policy = fixture_not_coverage`.

## 3a. Decisions and Rejected Alternatives

I added a plan contract only, not a status file. A status table should come from
a real deterministic smoke/probe artifact. Writing planned rows into a status
file would blur the evidence ladder and make it too easy to over-read the plan
as interval evidence.

I kept the direct-SD and derived-correlation rows separate. Direct SD targets
can be smoke-tested with Wald/profile/bootstrap machinery, but derived
correlation intervals still need interval reconstruction design before they can
enter any denominator or coverage path.

## 4. Files Touched

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-q4-intercept-interval-diagnostic-plan.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-q4-intercept-interval-diagnostic-plan.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-q4-intercept-interval-diagnostic-plan.md`

## 5. Checks Run

```sh
air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R tools/run-structured-re-q4-intercept-interval-diagnostic-plan.R
Rscript --vanilla tools/run-structured-re-q4-intercept-interval-diagnostic-plan.R
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts', stop_on_failure = TRUE)"
python3 tools/validate-mission-control.py
```

The focused R test command passed with 4,264 assertions, 0 failures, 0
warnings, and 0 skips. `python3 tools/validate-mission-control.py` passed and
reported 40 q4 intercept interval-diagnostic plan rows.

## 6. Tests of the Tests

The fixture test would fail if the generated plan lost a provider, changed the
four direct-SD intercept targets, changed the six derived-correlation targets,
or stopped keeping direct and derived blockers separate.

The conversion-contract and mission-control tests would fail if the generated
TSV schema drifted, if direct rows stopped requiring direct finite-interval
evidence, if derived rows stopped naming missing reconstruction, or if claim
boundaries stopped blocking q4 interval reliability, interval coverage, q4
REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, broad bridge support,
or calibrated coverage wording.

## 7a. Issue Ledger

No GitHub issue was opened or commented on. This is a narrow stacked q-series
evidence slice. No Ayumi-facing reply was drafted or sent.

## 8. Consistency Audit

The support-cell map, q4 intercept fixture ledger, new interval diagnostic plan,
dashboard README, design map, bridge fixture tests, conversion-contract tests,
and mission-control validator now agree on the next gate for q4 all-four
intercept cells: run deterministic target-level interval smoke before any
coverage wording, and design derived-correlation interval reconstruction before
those derived targets can move.

## 9. What Did Not Go Smoothly

The tempting shortcut was to add a status table immediately. I did not do that
because no deterministic smoke artifact exists yet for these 40 targets. The
plan/status separation keeps the evidence ladder honest.

## 10. Known Residuals

This slice does not run interval diagnostics, admit coverage denominators, claim
finite intervals, claim q4 interval reliability, claim q4 interval coverage,
add q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, non-Gaussian
REML, range-estimating spatial support, pedigree/Ainv bridge marshalling, Q
bridge marshalling, broad bridge support, public support, DRAC/Totoro
execution, SR150 coverage readiness, PR undrafting/merging, or an Ayumi-facing
reply.

## 11. Team Learning

Ada/Emmy: keep plan and status artifacts separate when no execution artifact
exists yet. Fisher/Gauss: direct SD interval smoke and derived-correlation
interval reconstruction are different inference problems. Rose/Grace: the
validator should enforce blockers as strongly as it enforces row counts.
