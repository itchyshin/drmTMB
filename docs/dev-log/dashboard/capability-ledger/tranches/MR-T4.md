# MR-T4 missing-response ledger summary

_Generated; do not hand-edit._

| Tranche | Routes | Backlog | Implemented unverified | Verified | Next gate |
|---|---:|---:|---:|---:|---|
| MR-T4 | 2 | 0 | 0 | 2 | Follow each route's evidence and next-gate fields |

## Route accounting

| Route | Runtime state | Evidence gate | Work state | Next gate |
|---|---|---:|---|---|
| `cumulative_logit` | implemented | G3 ✓ | verified | Held by the 2026-08-11 D-43 panel on structural, not evidential, grounds: the 3 measured cells (fixef:mu:x, all rungs) pass cleanly under both the old and mr-g5-calibration-v2 gates, but this row's dpar spans 'all fitted dpars' while both ordinal cutpoint targets carry zero G5 evidence and are excluded from profile intervals by #967. Unaffected by the v2 gate change. G3 stands until the row's scope matches its evidence. |
| `beta_binomial` | implemented | G5 ✓ | verified | G5 is the ceiling of this axis's ladder (README: G0-G5). Extending this claim to `cumulative_logit` or any other missing_response route requires its own exhaustive, defect-free G5 reconciliation and a fresh D-43 panel. |

## Does not cover

This summary does not promote intervals, coverage, model inference tiers, missing-predictor support, REML, or structured-effect claims.
