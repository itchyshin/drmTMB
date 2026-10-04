# After-task report: homogeneous Toeplitz T3-6 recovery

## 1. Goal

Produce source-faithful retained point-recovery evidence for AR1, non-exponential,
and negative-lag homogeneous Toeplitz temporal processes.

## 2. Implemented

A frozen twelve-fixture runner simulates and fits three replicates each for AR1,
non-exponential, negative-lag, and low-information stress cells. It retains every
selected fit, start attempt, warning, criterion, session record, runner MD5, and
source commit. T3-6 verifies artifacts without launching new fits.

## 3a. Decisions and Rejected Alternatives

The first pre-commit run is retained as a clearly marked diagnostic rehearsal,
because its source commit predated the runner. It was not used as evidence. The
identical final-source run recorded `b9dacf42d`, which contains the runner; this
is the claim-bearing artifact. Stress results are retained but excluded from the
primary thresholds.

## 4. Files Touched

`tools/run-temporal-homtoep-recovery.R`, `tools/temporal-homtoep-gates.R`, the
precommit diagnostic and final-source artifact directories, the Unlazy ledger,
check log, and this report.

## 5. Checks Run

- The committed runner emitted `TEMPORAL_HOMTOEP_RECOVERY_PASS`.
- `Rscript --vanilla tools/temporal-homtoep-gates.R T3-6` emitted
  `TEMPORAL_HOMTOEP_T3_6_PASS`.
- Final criteria: 9/9 selected finite primary fits; 12 retained attempts;
  fixed-effect MAE 0.0611; median SD error 0.0933; median lag RMSE 0.1098.

## 6. Tests of the Tests

The verifier checks the artifact file set, frozen denominators, all primary
criteria, the source commit's existence and runner path, and the current runner
MD5. It cannot accept the pre-commit rehearsal as final evidence.

## 7a. Issue Ledger

No external issue was opened or changed. This local point-recovery evidence does
not alter the separate phylogenetic-temporal OU issue.

## 8. Consistency Audit

The ledger, runner, verifier, criteria table, and check log all describe the
same twelve-fixture design and distinguish primary from stress evidence.

## 9. What Did Not Go Smoothly

The initial run exposed a provenance sequencing error: evidence was generated
before its runner was committed. Retaining and labeling it, then rerunning under
committed source, preserved the audit trail without treating weak provenance as
claim-bearing evidence.

## 10. Known Residuals

T3-7 still needs a timed pilot with memory and profile-availability reporting.
T3-8 must freeze profile-calibration cells and criteria. No interval, coverage,
forecast, `newdata`, ordinary-intercept Toeplitz, phylogenetic, or spatial claim
is supported by this recovery fixture.

## 11. Team Learning

Commit executable evidence runners before a retained run. A runner hash alone is
not enough when the recorded source revision cannot reproduce that runner.

## 12. Cross-Product Coverage

This work covers direct univariate Gaussian ML Toeplitz point recovery with
constant residual scale and complete observations. It does NOT cover REML,
penalties, Julia, missing data, aggregation, ordinary intercept composition,
phylogenetic or spatial structures, non-Gaussian models, profiles, Wald
intervals, coverage, forecasts, or newdata prediction.
