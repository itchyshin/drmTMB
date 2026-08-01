# MR-G5 Gamma cohort calibration receipt

## Scope

This receipt records the Rorqual G5 Gamma cohort under the frozen
missing-response G3 design. It is a calibration receipt, not a capability,
test-gate, or inference-tier transition.

## Reconciled result

The reconciled artifact contains 15 exact route-by-target-by-information-rung
cells and all 18,000 planned attempts: 1,200 deterministic attempts per cell.
Every cell retained all attempted fits and had 1,200 usable intervals.

Twelve cells pass the prospective `mr-g5-calibration-v1` policy. The three
`fixef:mu:(Intercept)` cells, at 0.5x, 1x, and 2x information, have coverage
1.000 and therefore fail the predeclared 0.925--0.975 calibration band. Those
failures are retained in the reconciled artifact rather than omitted or
redefined. The remaining exact target-rung cells pass with coverage from
0.94083 to 0.96167 and Monte Carlo standard error at or below 0.00663.

The durable reconciliation artifact is
`~/g4g5/artifacts/g5-gamma-reconciled-v1.rds`.

## Boundary

The frozen G3 DGPs, targets, seeds, profile interval method, and unconditional
1,200-attempt denominator remain unchanged. This cohort does not promote a
missing-response test gate, a capability-ledger row, or a model inference tier.
Every public missing-response route therefore remains G3 pending complete
campaign reconciliation and a fresh D-43 review.
