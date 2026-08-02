# MR-G5 Student-t cohort calibration receipt

## Scope

This receipt records the completed Rorqual G5 Student-t cohort under the
frozen missing-response G3 design. It is a calibration receipt, not a
capability, test-gate, or inference-tier transition.

## Reconciled result

The durable reconciliation artifact contains 16 exact target-by-information-rung
cells and all 19,200 planned attempts: 1,200 deterministic attempts per cell.
Every planned attempt is retained. Three cells pass the prospective
`mr-g5-calibration-v1` policy: `fixef:mu:x` at 2x, `fixef:sigma:z` at 2x, and
`sd:mu:(1 | id)` at 2x.

The remaining 13 cells fail. Most have one or more unusable intervals; the
three fixed-`mu` intercept rungs also have coverage from 0.99333 to 1.000, and
the 2x fixed-`sigma` intercept has coverage 0.99000. The Student-t `nu`
intercept cell has coverage 0.81583 and Monte Carlo standard error 0.01119.
Failures remain in the unconditional 1,200-attempt denominators rather than
being excluded or redefined.

The durable reconciliation artifact is
`~/g4g5/artifacts/g5-student-reconciled-v1.rds`.

## Boundary

The frozen G3 DGPs, targets, seeds, profile interval method, and unconditional
1,200-attempt denominator remain unchanged. This cohort does not promote a
missing-response test gate, a capability-ledger row, or a model inference tier.
Every public missing-response route remains G3 pending complete campaign
reconciliation and a fresh D-43 review.
