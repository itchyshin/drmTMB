# After Task: Julia Binomial Related-Matrix Simulation Oracle

## Goal

Strengthen the Julia Binomial related-matrix SD simulation test so it detects
incorrect covariance scaling, label ordering, and group-to-row mapping.

## Implemented

The fixture now uses a labelled, non-reversal-invariant positive-definite
covariance with a non-unit diagonal. Its SD predictor assignment is randomized
across group labels to avoid aligning the fixed SD trend with the covariance
ordering. The test reconstructs a seeded marginal response draw independently
from the fitted link predictor, group SD predictions, and labelled covariance.

## Mathematical Contract

For the tested intercept route, the structured effect is `b = D z`, where
`z ~ N(0, K)` and `D` contains the predictor-dependent group SDs. The expected
Bernoulli response is drawn from the inverse-link of the fixed linear predictor
plus the group-indexed structured effect. The test aligns `K` by group labels
before drawing.

## Files Changed

- `tests/testthat/test-julia-binomial-relmat-sd-parity.R`

## Checks Run

- `devtools::test(filter = "julia-binomial-relmat-sd-parity", reporter = "summary")` passed, including one live Julia bridge fit and the independent seeded simulation oracle.
- JuliaCall emitted the existing non-fatal `LogExpFunctionsInverseFunctionsExt` precompile/dependency-install warning; the live fit and assertions completed.

## Tests Of The Tests

The oracle computes the expected latent Gaussian draw and Bernoulli response
independently of `simulate()`. Static review found that the previous reversed
Toeplitz matrix was numerically invariant to reversal, and that repeatability
alone could not detect ignored covariance. The revised matrix and exact seeded
comparison address both weaknesses.

## Consistency Audit

The read-only covariance review confirmed that simulation uses the same
group-aligned relmat matrix and multiplies its draw by the fitted SD prediction.
No formula, likelihood, or public API changed. No neighboring docs or examples
were changed by this test-only task.

## GitHub Issue Maintenance

No issue was opened or changed. This task hardens an existing internal test and
does not add a new user-facing capability.

## What Did Not Go Smoothly

The first non-unit covariance perturbation made the fixture's group-level SD
predictor too confounded with the covariance pattern, and coefficient recovery
failed. Randomizing the predictor over group labels and reducing diagonal
variation produced a better-conditioned test fixture while preserving the
independent covariance oracle.

## Team Learning

Structured simulation tests need a covariance that is both label-sensitive and
non-unit-scaled. Seed repeatability is useful but is not a covariance oracle.

## Known Limitations

This test covers one Julia Binomial related-matrix intercept route. It does not
establish broad structured-effect support, cross-family parity, recovery across
conditions, or calibrated interval coverage. JuliaCall's dependency warning
remains unresolved.

## Next Actions

Continue closing the required family, random-effect, and engine rows, with
recovery and calibrated uncertainty evidence as specified by the active goal.
