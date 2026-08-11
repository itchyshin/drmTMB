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
| `beta` | implemented | G3 ✓ | verified | Campaign-wide reconciliation is now complete (294/294 registry cells; the four previously truncated 2x cells finished with seed-exact resumes on both sides of each truncation point, design_state centre_random_effects=FALSE throughout). Under mr-g5-calibration-v2 (complete & precise & in-band & availability >= 0.99), all 15/15 beta cells now pass -- coverage 0.9308-0.9558, every cell in band, mcse <= 0.0073 throughout; five cells pass on the availability floor rather than at 1.0 (0.9967/0.9992/0.9992/0.9967/0.9992, i.e. 1-4 unusable replicates of 1200 each; under the old v1 all-1200 rule these five would fail, so beta would read 10/15 there). Two of those five are cells that did not exist when the 0.99 floor was derived, so they are out-of-sample support for the threshold, not part of its basis. No D-43 panel has reviewed this route under v2 and its dpar-parity with the G3 claim_boundary has not been checked, so this is a candidate for a future panel, not a route with an outstanding defect. |
| `binomial` | implemented | G5 ✓ | verified | G5 is the ceiling of this axis's ladder (README: G0-G5). Extending this claim to `beta`, `cumulative_logit`, or any other missing_response route requires its own exhaustive, defect-free G5 reconciliation and a fresh D-43 panel. |

## Does not cover

This summary does not promote intervals, coverage, model inference tiers, missing-predictor support, REML, or structured-effect claims.
