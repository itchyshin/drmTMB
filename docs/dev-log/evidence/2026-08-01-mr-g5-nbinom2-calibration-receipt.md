# MR-G5 NB2 cohort calibration receipt

## Scope

This receipt records the Rorqual G5 NB2 cohort under the frozen
missing-response G3 design. It records positive and negative evidence at the
exact route-by-target-by-information-rung scope; it is not a route-wide
capability or model inference-tier transition.

## Reconciled result

The durable artifact
`~/g4g5/artifacts/g5-nbinom2-reconciled-v1.rds` contains 15 exact cells and
all 18,000 planned attempts: 1,200 deterministic attempts per cell. Its
`mr-g4g5-v2` provenance receipt records the runner, frozen target manifest,
G4 records, and all 15 durable input receipts.

Ten exact cells pass `mr-g5-calibration-v1`: every
`fixef:mu:(Intercept)` and `fixef:mu:x` rung; the 2x
`fixef:sigma:(Intercept)`, `fixef:sigma:z`, and `sd:mu:(1 | id)` rungs. Their
unconditional coverage is 0.93500--0.95417 and all MCSE values are at most
0.00712. These pass results are usable positive evidence for those exact
frozen NB2 response-mask cells.

The remaining five cells fail because the all-attempt interval-availability
rule is not met: `fixef:sigma:(Intercept)` at 0.5x and 1x,
`fixef:sigma:z` at 0.5x and 1x, and `sd:mu:(1 | id)` at 0.5x and 1x. Their
coverage values remain in the artifact but do not override unusable intervals;
all 1,200 attempts per cell remain in the denominator.

## Boundary

The G3 DGPs, targets, seeds, profile interval method, and all-attempt
denominator were not changed. The receipt supports only the exact passing
cells described above. It does not assert a route-wide missing-response claim
or a model inference tier, which require the campaign's remaining evidence and
fresh D-43 review.
