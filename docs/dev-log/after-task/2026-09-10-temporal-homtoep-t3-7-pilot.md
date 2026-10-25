# After-task report: homogeneous Toeplitz T3-7 timed pilot

## 1. Goal

Measure a source-faithful five-seed-per-cell Toeplitz pilot, including runtime,
memory, denominator completeness, warnings, and profile-interval availability.

## 2. Implemented

`tools/run-temporal-homtoep-pilot.R` generates three frozen 80-series,
six-occasion cells with five disjoint seeds each. It retains 15 fit records,
one start per fit, profile availability, warnings, provenance, session data, and
a separate `/usr/bin/time -l` resource receipt. T3-7 verifies those immutable
outputs and the runner's source identity without launching another pilot.

## 3a. Decisions and Rejected Alternatives

The runner leaves profile intervals deliberately guarded. It records zero
available profile intervals rather than bypassing the public guard or treating
an error as missing output. The pilot does not pass an inference claim: all 15
fits have `pd_hessian = FALSE` and each reports `NaNs produced`, so a campaign
cannot be proposed until an inference-specific diagnosis is complete.

## 4. Files Touched

`tools/run-temporal-homtoep-pilot.R`, `tools/temporal-homtoep-gates.R`, the
final-source pilot artifact directory, the Unlazy ledger, check log, and this
report.

## 5. Checks Run

- The committed runner emitted `TEMPORAL_HOMTOEP_PILOT_PASS`.
- `Rscript --vanilla tools/temporal-homtoep-gates.R T3-7` emitted
  `TEMPORAL_HOMTOEP_T3_7_PASS`.
- `/usr/bin/time -l` recorded 39.42 seconds wall time, 438 MB peak memory, and
  15/15 retained fits and starts.
- All selected objectives were finite; profile availability was 0/15 by the
  intended guard; all Hessian flags were false and all runs warned `NaNs produced`.

## 6. Tests of the Tests

The verifier checks source commit existence and presence of the runner at that
commit, current runner MD5, required output files, 15 fit and 15 start
denominators, finite selected objectives and positive timings, all expected
profile guards, and the operating-system memory receipt.

## 7a. Issue Ledger

No external issue was opened or changed. The false Hessian flags are a local
Toeplitz inference blocker, not evidence about the separate phylogenetic OU
work.

## 8. Consistency Audit

The runner, provenance table, results, summary, resource receipt, gate, ledger,
and check log all report the same three cells, five seeds per cell, one retained
start per fit, and the same guarded-profile status.

## 9. What Did Not Go Smoothly

Although all fits converged to finite objectives, every pilot fit produced a
`NaNs produced` warning and a false Hessian flag. The result is retained as the
pilot's main diagnostic rather than hidden behind convergence status.

## 10. Known Residuals

T3-8's profile-calibration contract and T3-9 campaign authorization cannot
advance until a bounded inference diagnosis establishes a usable observed-
information path. No profile interval, coverage, Wald interval, forecast,
ordinary-intercept Toeplitz, phylogenetic, or spatial claim is supported here.

## 11. Team Learning

Finite optimization convergence does not establish inference readiness. Timed
pilots must preserve warnings and Hessian status alongside runtime and memory,
or they can make an unusable campaign look ready.

## 12. Cross-Product Coverage

This work covers local direct univariate Gaussian ML homogeneous Toeplitz pilot
measurement for complete, common six-occasion schedules. It does NOT cover
REML, penalties, Julia, missing data, other families, ordinary intercept
composition, phylogenetic or spatial structures, calibrated intervals, campaign
coverage, forecasts, or newdata prediction.
