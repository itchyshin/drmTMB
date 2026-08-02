# MR-G5 lognormal cohort calibration receipt

## Scope

This receipt records the Rorqual G5 lognormal cohort under the frozen
missing-response G3 design. It is a calibration receipt, not a capability,
test-gate, or inference-tier transition.

## Reconciled result

The durable reconciliation artifact contains 15 exact target-by-information-rung
cells and all 18,000 planned attempts: 1,200 deterministic attempts per cell.
Every planned attempt is retained. Fourteen cells have 1,200 usable intervals;
the `sd:mu:(1 | id)` 0.5x cell has 1,199 usable intervals and is retained as a
failed calibration cell.

Eleven cells pass the prospective `mr-g5-calibration-v1` policy. The three
`fixef:mu:(Intercept)` cells have coverage 1.000 at 0.5x, 1x, and 2x and fail
the predeclared 0.925--0.975 band. The `sd:mu:(1 | id)` 0.5x cell fails the
all-interval-available requirement. The remaining cells pass with coverage
from 0.93583 to 0.96000 and Monte Carlo standard error at or below 0.00708.

The durable reconciliation artifact is
`~/g4g5/artifacts/g5-lognormal-reconciled-v1.rds`.

## Boundary

The frozen G3 DGPs, targets, seeds, profile interval method, and unconditional
1,200-attempt denominator remain unchanged. This cohort does not promote a
missing-response test gate, a capability-ledger row, or a model inference tier.
Every public missing-response route remains G3 pending complete campaign
reconciliation and a fresh D-43 review.
