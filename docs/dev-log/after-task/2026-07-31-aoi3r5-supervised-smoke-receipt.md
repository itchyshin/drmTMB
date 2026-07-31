# AOI-3R5 supervised local-smoke receipt

## 1. Goal

Run the owner-authorized fresh-seed AOI-3R5 diagnostic smoke using the private
process supervisor with a 180-second hard wall-time limit per outer attempt.

## 2. Implemented

Frozen and preflighted the 60-seed R5 manifest against source
`69325cf1f4bb13e94358e6bd4f1078cc4e4a8944`.  The supervisor completed additive
outer 1 in 112.039 seconds, then terminated additive outer 2 at 180.021
seconds.  It wrote the exact timeout event and `INCOMPLETE` marker, and stopped
without allocating later outers or formula classes.

The private reducer now retains `supervisor-events.csv` and requires every
expected supervised outer to complete before its diagnostic-completeness gate
can pass.  R5 reduced to `AOI3R1_DIAGNOSTIC_INVALID`.

## 3a. Decisions and Rejected Alternatives

The timeout is a retained operational outcome, not discarded work, a finite
estimate, or a basis for changing optimizer tolerances.  R5's remaining seeds
will not be recycled.  No DRAC retry, wider time limit, reduced formula set,
or public uncertainty exposure is inferred from this result.

## 4. Files Touched

- `tools/summarize-aoi3r1-diagnostic-smoke.R`
- `tests/testthat/test-aoi3-full-refit-runner.R`
- `docs/dev-log/after-task/2026-07-31-aoi3r5-supervised-smoke-receipt.md`

Retained, untracked local evidence:

- `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r5-local-diagnostic-smoke/`
- `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r5-diagnostic-analysis/`

## 5. Checks Run

- R5 computational-source preflight — PASS.
- R5 manifest assertion — PASS: 60 unique seeds, disjoint from R1--R4.
- Focused runner/reducer test — PASS, 41 expectations.
- R5 supervisor event audit — PASS: additive outer 1 `outer_complete`, additive
  outer 2 `outer_wall_time_exceeded` at 180.021 seconds.
- R5 diagnostic reducer — expected non-zero exit and
  `AOI3R1_DIAGNOSTIC_INVALID` decision.

## 6. Tests of the Tests

The reducer test requires the supervisor event contract and a
`supervisor_complete` condition.  The actual R5 run exercised both the normal
child completion and hard-timeout branches, then the reducer copied the retained
events into its invalid analysis output.

## 7a. Issue Ledger

- AOI-3R5 diagnostic completeness — FAIL CLOSED: incomplete after a retained
  hard timeout.
- Additive association outer long-tail/native optimization — OPEN; no numerical
  repair authorized.
- AOI-2 HOLD and public uncertainty fence — unchanged.

## 8. Consistency Audit

R5 contains one complete outer result and one timed-out startup/event record;
it does not contain all scheduled rows and cannot support recovery, covariance,
or uncertainty calibration.  No DRAC submission, public API, ledger, article,
Lane B, or foreign Association work changed.

## 9. What Did Not Go Smoothly

The supervisor correctly solved the prior unbounded-process defect but exposed
that the approved 180-second cap is exceeded by additive outer 2.  This is an
execution observation, not a diagnosis of the estimator or a justification for
relaxing the contract.

## 10. Known Residuals

The exact mechanism behind the long attempt is unmeasured.  A future response
would require a separately approved plan to profile the private outer attempt
or redefine a scientifically defensible diagnostic design; neither is started.

## 11. Team Learning

Memory receipt: a true process wall-time limit produces actionable retained
provenance even when native code cannot be interrupted by R itself.  The
correct response to an elapsed cap is an explicit invalid run, not silent
omission or a public inference claim.  No durable brain-memory update is
warranted.

Golden Set: not in scope; this is a private diagnostic execution receipt.

## 12. Cross-Product Coverage

This receipt covers ✓ private R5 provenance, hard-timeout retention, and its
invalid completeness decision.  It does NOT cover ✗ point recovery, sandwich
validity, covariance or interval calibration, coverage, DRAC, `vcov()`,
`confint()`, standard errors, other family pairs, random/structured association
effects, missingness, weights, offsets, REML, capability promotion, or public
inference.
