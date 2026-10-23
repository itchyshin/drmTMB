# After Task: temporal OU point-recovery fixture

**Branch:** `codex/temporal-ou-v1-20260908`

**Date:** 2026-09-09

**Scope:** retain bounded point-recovery evidence for both admitted Gaussian OU forms.

## 1. Goal

Exercise the new elapsed-time OU provider on fixed, irregular-time data while preserving every optimizer start, warning, and source fingerprint. This fixture is deliberately separate from the unresolved temporal Wald interval and coverage work.

## 2. Implemented

`tools/run-temporal-ou-recovery.R` generates six fixed decay conditions (`0.15` through `1.10`) for each of OU-only and ordinary-intercept-plus-OU models. Each condition uses 80 independent series at elapsed times `0`, `0.5`, `1.5`, `3`, `5`, and `8`, with process SD `0.8`, residual SD `0.4`, and ordinary-intercept SD `0.6` when admitted. The runner writes selected estimates, both decay starts, warnings, convergence codes, criteria, source provenance, session information, and an RDS bundle.

## 3a. Decisions and Rejected Alternatives

The fixture uses broad predeclared point-recovery thresholds and does not select seeds after seeing results. It does not discard an ordinary-plus-OU O05 false-convergence selection: its lower finite objective wins under the production two-start rule, and the warning plus both starts remain visible. Replacing it with the converged but higher-objective start would manufacture a cleaner result and misrepresent the fitting rule.

## 4. Files Touched

The recovery runner and its G8 verifier are in `tools/`. Retained evidence is under `docs/dev-log/simulation-artifacts/2026-09-09-temporal-ou-local-recovery/`. The OU Unlazy ledger and check log identify this fixture as point-recovery evidence only.

## 5. Checks Run

| Check | Outcome |
| --- | --- |
| `Rscript --vanilla tools/run-temporal-ou-recovery.R` | `TEMPORAL_OU_RECOVERY_PASS` in 25 seconds. |
| `Rscript --vanilla tools/temporal-ou-gates.R G8` | `TEMPORAL_OU_G8_PASS`. |
| Retained criteria | 12 finite selected fits, 24 positive-decay starts, fixed-effect error `0.0758`, SD error `0.0374`, decay error `0.0400`; all pass. |
| Source provenance | Runner hash `f7363a0db29b664f96f35212c83bc050` at source `5eada6c03a41ecaed0f96b98224c9511f9ae6a4e`. |

## 6. Tests of the Tests

The runner fails after writing evidence if any predeclared criterion fails. G8 refuses missing output, mismatched runner hash, invalid source commit, absent convergence/warning/error fields, incomplete starts, non-positive starts, or failing retained criteria. The existing dense OU oracle remains the independent likelihood test; this runner tests repeated estimation and retention.

## 7a. Issue Ledger

No issue was opened or edited. This is an unpushed local implementation lane.

## 8. Consistency Audit

The G8 verifier checks the exact artifact directory and runner hash. The reader vignette continues to describe OU as a positive-decay point-fit path, and public `vcov()`, Wald `confint()`, and covariance output remain guarded while the AR1 C1 boundary makes general interval calibration unavailable.

## 9. What Did Not Go Smoothly

The first runner version only exposed the numerical convergence field, while its generic status label and the selected-estimate table hid the `false convergence` warning for O05. The runner was repaired and committed before the final deterministic rerun. The retained final CSV records both O05 attempts, labels the winning attempt `nonconverged`, and carries the warning text.

## 10. Known Residuals

The retained O05 false-convergence selection is a point-recovery diagnostic, not evidence that all temporal fits have well-conditioned Hessians. AR1 C1 remains a residual-variance boundary. G7, G9, G14, and G15 remain open; no remote campaign, interval calibration, profile inference, or forecasting was launched.

## 11. Team Learning

A two-start estimator can correctly select a finite lower objective that carries an optimizer warning. Recovery reports must retain that distinction in both the attempt and selected-estimate tables; a generic success label is not enough.

## 12. Cross-Product Coverage

This task covers Gaussian ML point recovery for the exact OU-only and ordinary-intercept-plus-OU fixture, irregular elapsed-time gaps, positive decay, and the production two-start selection rule. It does NOT cover mean-coefficient Wald covariance, profile or bootstrap intervals, calibration coverage, variance-component intervals, non-Gaussian families, REML, temporal slopes, forecasts, new-data prediction, ARMA/Toeplitz, random walks, seasonal states, Matérn, or gllvmTMB.
