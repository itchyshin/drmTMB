# AOI-2 local non-empty smoke receipt

## Authority and boundary

Shinichi explicitly authorized one local, non-empty AOI-2 smoke on 2026-07-29.
This receipt records that smoke only. It authorizes neither a DRAC campaign nor
an uncertainty/public-inference claim. The source branch was
`codex/aoi-full-fixed` at `93fa9812d`; the AOI-1 implementation is
`90c186611`.

## Design

One known-truth complete paired Bernoulli × ordinary-NB2 dataset (`n = 360`) was
generated separately for each association formula:

1. `~ x1 + x2`;
2. `~ x1 + habitat`;
3. `~ x1 + habitat + x1:habitat`;
4. `~ x1 + x2 + x1:x2`;
5. `~ x1 + I(x2^2)`.

Each cell refit both fixed-effect ML margins and `associate_pairs()`, checked
interior status, exact coefficient order, and finite five-row `newdata`
predictions. It did not construct SEs, intervals, coverage, covariance, or a
capability status.

## Results

| Formula | Status | Max absolute alpha error |
| --- | --- | ---: |
| additive | interior | 0.3339527 |
| mixed | interior | 0.1819969 |
| factor interaction | interior | 0.1284507 |
| numeric interaction | interior | 0.2620398 |
| transformation | interior | 0.3269888 |

These are one-dataset smoke diagnostics, not point-recovery evidence. No
acceptance threshold was applied.

## Retained correction

The first source-loaded harness attempt exposed a rank-deficient transformation
DGP: a two-valued `x2` made `I(x2^2)` constant. The harness was corrected to use
three `x2` values before the recorded run. This is a DGP-design validity
correction, not an estimator failure or a discarded recovery attempt. An earlier
invocation loaded the installed baseline package and is excluded because it did
not exercise the AOI source.

## Next gate

The owner must separately approve a preregistered DRAC point-recovery campaign.
That campaign must retain all attempts and use the AOI-2/AOI-3 protocol; this
receipt does not start it.
