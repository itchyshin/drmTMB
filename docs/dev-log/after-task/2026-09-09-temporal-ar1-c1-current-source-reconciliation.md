# After Task: temporal AR1 C1 current-source reconciliation

**Branch:** `codex/temporal-ou-v1-20260908`

**Date:** 2026-09-09

**Scope:** reconcile the historical C1 Hessian failure with the current AR1
transition implementation, then independently diagnose the remaining
current-source unavailable-covariance case.

## 1. Goal

Establish which C1 failures are obsolete numerical artifacts and which remain
live boundary cases before changing OU interval claims.

## 2. Implemented

Added a five-seed current-source replay for the historical C1 data and a
44-attempt dense marginal likelihood profile for current-source seed
`2026091101`. Updated the C1 notes and OU ledger to preserve source-specific
denominators.

## 3a. Decisions and Rejected Alternatives

The old lower objective is not retained as an ML candidate because it conflicts
with the independent dense oracle. Conversely, the current non-PD case is not
repaired by choosing a conditional covariance, imposing a residual lower bound,
or silently counting a finite nearby result as a Wald interval.

## 4. Files Touched

Added two diagnostic runners, two retained artifact directories, this report,
and the current-source reconciliation note. Corrected the C1 boundary,
start-profile, dense-profile, replication, ledger, check-log, and prior report
wording where it had pooled historical and current-source results.

## 5. Checks Run

The historical-seed replay emitted
`TEMPORAL_AR1_C1_CURRENT_SOURCE_RECHECK_PASS`: five selected fits and ten
starts, all with finite covariance and intervals. The dense current-boundary
runner emitted `TEMPORAL_AR1_C1_CURRENT_BOUNDARY_PASS`: 40 fixed-scale and four
free-scale fits. Its fixed-scale objective is flat through `1e-4` and rises at
larger residual SD.

## 6. Tests of the Tests

Both runners reject pre-existing required evidence, require all selected rows
and exactly two or four retained starts as declared, and require positive finite
elapsed time or finite selected objectives. The dense preflight measured 1.28
seconds for four fixed-scale fits before the 44-fit run.

## 7a. Issue Ledger

No issue was opened or edited. This is an unpushed local implementation lane.

## 8. Consistency Audit

The historical current-source objective matches the first dense oracle within
about `6e-8`. The fresh current-source failure has persistence `0.189`, so it
cannot be attributed to the historical near-persistence transition calculation.
Its separate dense profile has the same residual-boundary geometry.

## 9. What Did Not Go Smoothly

Earlier C1 notes treated a pre-repair lower numerical objective as a valid ML
candidate and pooled historical with current-source availability. The new
oracles contradicted both interpretations, so the documentation was corrected
rather than preserving a convenient failure narrative.

## 10. Known Residuals

This corrects the numerical diagnosis but does not qualify AR1 or OU Wald
coverage. G7 remains open; G14 and G15 remain external campaign gates. A
boundary-aware profile, bootstrap, or changed residual-scale estimand would be
a new inference scope requiring its own plan and calibration.

## 11. Team Learning

When numerical-stability code changes a boundary-sensitive likelihood, every
historical availability denominator must be replayed at the new source before
it can support a current inferential decision.

## 12. Cross-Product Coverage

This work covers current-source Gaussian AR1 C1 likelihood and covariance
diagnosis only. It does NOT cover coverage calibration, public profile or
bootstrap intervals, variance-component intervals, OU inference, REML,
non-Gaussian families, forecasts, new-data prediction, other temporal
structures, or gllvmTMB.
