# MR-T6 missing-response ledger summary

_Generated; do not hand-edit._

| Tranche | Routes | Backlog | Implemented unverified | Verified | Next gate |
|---|---:|---:|---:|---:|---|
| MR-T6 | 3 | 0 | 0 | 3 | Follow each route's evidence and next-gate fields |

## Route accounting

| Route | Runtime state | Evidence gate | Work state | Next gate |
|---|---|---:|---|---|
| `zi_poisson` | implemented | G5 ✓ | verified | G5 is the ceiling of this axis's ladder (README: G0-G5). Extending this claim to `beta`, `cumulative_logit`, or any other missing_response route requires its own exhaustive, defect-free G5 reconciliation and a fresh D-43 panel. |
| `zi_nbinom2` | implemented | G3 ✓ | verified | G5 held: 6/24 campaign cells failed the all-1200 interval-usability rule (not the coverage band); G3 stands until availability is fixed and the route re-passes exhaustively. |
| `hurdle_nbinom2` | implemented | G3 ✓ | verified | G5 held: 1/24 campaign cells failed the all-1200 interval-usability rule (not the coverage band); G3 stands until availability is fixed and the route re-passes exhaustively. |

## Does not cover

This summary does not promote intervals, coverage, model inference tiers, missing-predictor support, REML, or structured-effect claims.
