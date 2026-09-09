# After Task: temporal AR1 C1 Wald-availability replication

**Branch:** `codex/temporal-ou-v1-20260908`

**Date:** 2026-09-09

**Scope:** test whether the C1 fixed-effect Wald failure is isolated, using five
new fixed-seed C1 datasets and the unchanged free-sigma production fit.

## 1. Goal

Measure current-route Wald availability on a bounded disjoint C1 replication
before deciding whether the inherited AR1 interval requirement can be met.

## 2. Implemented

Added `tools/diagnose-temporal-ar1-c1-wald-replication.R`. It generates five
new fixed-seed C1 datasets, runs the normal two-start AR1 fit, retains both
starts, and records full-Hessian status, covariance availability, Wald
availability, residual SD, warnings, errors, provenance, and session details.

## 3a. Decisions and Rejected Alternatives

The diagnostic does not constrain residual SD, select a higher-objective
positive-definite fit, or calculate conditional intervals. Each would change
the original full-Hessian free-sigma target. It does not relabel 8/10 as a
coverage result or start the declared campaign.

## 4. Files Touched

The runner, immutable artifact directory, OU gate ledger, C1 evidence note,
check log, and this report were added or updated.

## 5. Checks Run

`Rscript --vanilla tools/diagnose-temporal-ar1-c1-wald-replication.R` emitted
`TEMPORAL_AR1_C1_WALD_REPLICATION_PASS`. It retained five selected fits and ten
starts. Four fits had finite covariance and intervals; seed `2026091101` had a
near-zero residual SD and unavailable full-Hessian covariance.

## 6. Tests of the Tests

The runner requires exactly five selected rows, exactly two retained starts per
seed, and a positive finite elapsed time for every row. It fails after writing
the diagnostic outputs if any completeness condition is violated.

## 7a. Issue Ledger

No issue was opened or edited. This is an unpushed local implementation lane.

## 8. Consistency Audit

The result agrees with the original C1 pilot and the independent dense marginal
profile. It also agrees with the public `check_drm()` message: a local Hessian
result must not be presented as a qualified coverage claim.

## 9. What Did Not Go Smoothly

One of the five fresh fits had the same near-zero residual-variance geometry as
the original C1 failure. The optimizer escalation and `NaNs produced` warning
are retained rather than suppressed.

## 10. Known Residuals

This diagnostic does not qualify the AR1 or OU interval route. G7 remains open;
G14 and G15 remain external campaign gates. A profile or constrained-scale
method would require a new inference target and calibration design.

## 11. Team Learning

A second independent boundary case matters more than a repaired local Hessian:
it distinguishes an isolated numerical accident from a recurrent likelihood
geometry under the stated primary design.

## 12. Cross-Product Coverage

This work covers only Gaussian AR1 C1 free-sigma, full-Hessian Wald
availability. It does not cover coverage calibration, variance-component
intervals, OU inference, REML, non-Gaussian families, forecasts, new-data
prediction, other temporal structures, or gllvmTMB.
