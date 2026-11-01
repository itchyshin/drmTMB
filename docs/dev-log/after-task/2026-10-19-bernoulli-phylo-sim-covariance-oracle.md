# After Task: Bernoulli phylogenetic SD covariance oracle

## Goal

Independently check that native Bernoulli phylogenetic SD simulation uses the fitted normalized tree covariance when branch lengths do not have unit height.

## Implemented

The simulation regression test now rescales its synthetic tree to root-to-tip height 2.5, checks that the fitted precision inverse reproduces the normalized tip covariance, and verifies that this result differs from the raw-height covariance. Existing deterministic draw, binary-response, prediction, and save/reload assertions remain in place.

## Mathematical Contract

For this route, the augmented precision is scaled so its inverse has tip block `A / h`, where `A` is the shared-path covariance and `h` is tree height. The modeled SD multiplies the latent field after this normalized covariance is defined; this test does not change kernel scaling or fitted models.

## Files Changed

- `tests/testthat/test-binomial-phylo-sd-simulation.R`
- `docs/dev-log/check-log.d/2026-10-19-bernoulli-phylo-sim-covariance-oracle.md`
- `docs/dev-log/after-task/2026-10-19-bernoulli-phylo-sim-covariance-oracle.md`

## Checks Run

- Focused `devtools::test()` filter for `binomial-phylo-sd-simulation`: PASS, 11 expectations, no failures or skips.
- `git diff --check`: PASS.

## Tests Of The Tests

The assertion compares the inverse fitted sparse precision, independently converted to a dense covariance, against the tip covariance API. A height of 2.5 makes the raw and normalized kernels numerically distinct, so the paired negative comparison would detect a missing normalization.

## Consistency Audit

No model behavior, formula syntax, capability claim, or public documentation changed. The existing Bernoulli phylogenetic test and surrounding formula documentation remain consistent. Julia parity and uncertainty claims remain explicitly outside this test.

## GitHub Issue Maintenance

No issue action: this is a validation-only strengthening of an existing internal regression test, with no matching user-facing defect being resolved in this slice.

## What Did Not Go Smoothly

The first lease attempt could not write the shared lease registry under the workspace sandbox. The required lease was then created through the approved elevated command; the test and evidence paths are narrowly leased.

## Team Learning

For structured covariance tests, use a deliberately non-unit kernel scale and compare against an independent precision-inversion oracle. Merely drawing from the same fitted precision can preserve a shared scaling error.

## Known Limitations

This is one native Bernoulli phylogenetic simulation route. It does not establish Julia live parity, prediction/extraction parity for all structured providers, recovery across seeds, or calibrated uncertainty.

## Next Actions

Continue the cross-family and cross-engine capability ledger. Resolve ownership before changing the shared Julia bridge, and keep Bernoulli calibration and structured-effect breadth gates open until their full evidence requirements pass.
