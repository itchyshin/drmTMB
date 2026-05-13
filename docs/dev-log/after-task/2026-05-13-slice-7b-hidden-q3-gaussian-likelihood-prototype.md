# After Task: Slice 7B Hidden q=3 Gaussian Likelihood Prototype

## Goal

Prove that a hidden q=3 labelled covariance block can feed an ordinary Gaussian
likelihood branch after the block transform is computed, while keeping q > 2
syntax and extractor support closed.

## Implemented

`src/drmTMB.cpp` now has hidden `model_type == 96`. It reuses the q=3 registry
contribution map from `model_type == 97`, then routes members with
`component == "mu"` into the Gaussian location predictor and members with
`component == "sigma"` into the log-scale predictor before evaluating the usual
Gaussian density.

`tests/testthat/test-covariance-block-registry.R` adds a deterministic test that
reconstructs the q=3 transform in R. The test checks the reported contribution
matrix, `mu`, `log_sigma`, `obs_sigma`, objective value, and finite gradient.

## What q Means

In this design, q is the number of random-effect members in a shared covariance
block. It is not the number of correlations. A q=3 block has three members and
three pairwise correlations. The full two-response double-hierarchical endpoint
with `mu1`, `mu2`, `sigma1`, and `sigma2` is q=4, which has six pairwise
correlations.

## Files Changed

- `src/drmTMB.cpp`
- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-7b-hidden-q3-gaussian-likelihood-prototype.md`

## Checks Run

- `air format src/drmTMB.cpp tests/testthat/test-covariance-block-registry.R`:
  passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 57 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 955 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Consistency Audit

This remains internal scaffolding. There is still no public q > 2 covariance
syntax, no `corpairs()` output for q > 2 blocks, and no simulation recovery for a
fitted larger block. Those are still required before claiming support.

## Next Actions

1. Add a hidden random-effect likelihood prototype that passes
   `u_re_cov_probe` through TMB's `random` argument while the Gaussian likelihood
   uses the transformed member contributions.
2. Move from q=3 to the q=4 `mu1`/`mu2`/`sigma1`/`sigma2` target only after the
   hidden q=3 likelihood path has recovery evidence.
