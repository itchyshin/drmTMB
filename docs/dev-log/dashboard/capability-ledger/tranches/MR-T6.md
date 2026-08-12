# MR-T6 missing-response ledger summary

_Generated; do not hand-edit._

| Tranche | Routes | Backlog | Implemented unverified | Verified | Next gate |
|---|---:|---:|---:|---:|---|
| MR-T6 | 3 | 0 | 0 | 3 | Follow each route's evidence and next-gate fields |

## Route accounting

| Route | Runtime state | Evidence gate | Work state | Next gate |
|---|---|---:|---|---|
| `zi_poisson` | implemented | G5 ✓ | verified | G5 is the ceiling of this axis's ladder (README: G0-G5). Extending this claim to additional `cumulative_logit` targets or any other missing_response route requires its own exhaustive, defect-free G5 reconciliation and a fresh D-43 panel. |
| `zi_nbinom2` | implemented | G3 ✓ | verified | Under mr-g5-calibration-v2 (complete & precise & in-band & availability >= 0.99), 1/24 campaign cells fail on the availability floor (< 0.99); G3 stands until availability is fixed and the route re-passes exhaustively. |
| `hurdle_nbinom2` | implemented | G3 ✓ | verified | Under mr-g5-calibration-v2 (complete & precise & in-band & availability >= 0.99), 1/24 campaign cells fail on the availability floor (< 0.99); G3 stands until availability is fixed and the route re-passes exhaustively. |

## Does not cover

This summary does not promote intervals, coverage, model inference tiers, missing-predictor support, REML, or structured-effect claims.
