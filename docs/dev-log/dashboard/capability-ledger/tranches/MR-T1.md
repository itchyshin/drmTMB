# MR-T1 missing-response ledger summary

_Generated; do not hand-edit._

| Tranche | Routes | Backlog | Implemented unverified | Verified | Next gate |
|---|---:|---:|---:|---:|---|
| MR-T1 | 6 | 0 | 0 | 6 | Follow each route's evidence and next-gate fields |

## Route accounting

| Route | Runtime state | Evidence gate | Work state | Next gate |
|---|---|---:|---|---|
| `gaussian` | implemented | G5 ✓ | verified | G5 is the ceiling of this axis's ladder (README: G0-G5). Extending this claim to `beta`, `cumulative_logit`, or any other missing_response route requires its own exhaustive, defect-free G5 reconciliation and a fresh D-43 panel. |
| `biv_gaussian` | implemented | G5 ✓ | verified | G5 is the ceiling of this axis's ladder (README: G0-G5). Extending this claim to `beta`, `cumulative_logit`, or any other missing_response route requires its own exhaustive, defect-free G5 reconciliation and a fresh D-43 panel. |
| `poisson` | implemented | G3 ✓ | verified | Under mr-g5-calibration-v2 (complete & precise & in-band & availability >= 0.99), 1/9 campaign cells fail -- coverage only (fixef:mu:(Intercept), 0.5x rung, 0.9217, just below the [0.925, 0.975] band); no availability blocker remains under v2. G3 stands until the coverage miss is resolved and the route re-passes exhaustively. |
| `nbinom2` | implemented | G3 ✓ | verified | Under mr-g5-calibration-v2 (complete & precise & in-band & availability >= 0.99), 3/15 campaign cells fail on the availability floor (< 0.99); G3 stands until availability is fixed and the route re-passes exhaustively. |
| `beta` | implemented | G3 ✓ | verified | G5 held: route evidence is incomplete, not failing -- 11 of 15 registry cells reconciled. Under mr-g5-calibration-v2, 0 of those 11 fail (0 availability, 0 coverage). The remaining four 2x cells were truncated by an 8h walltime and are re-running. G3 stands until the full 15-cell grid reconciles. |
| `binomial` | implemented | G5 ✓ | verified | G5 is the ceiling of this axis's ladder (README: G0-G5). Extending this claim to `beta`, `cumulative_logit`, or any other missing_response route requires its own exhaustive, defect-free G5 reconciliation and a fresh D-43 panel. |

## Does not cover

This summary does not promote intervals, coverage, model inference tiers, missing-predictor support, REML, or structured-effect claims.
