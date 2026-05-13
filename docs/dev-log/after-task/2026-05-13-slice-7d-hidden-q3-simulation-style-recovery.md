# After Task: Slice 7D Hidden q=3 Simulation-Style Recovery

## Goal

Close Slice 7 by adding recovery evidence for the hidden q=3 Gaussian
likelihood path before moving to the q=4 `mu1`/`mu2`/`sigma1`/`sigma2` bridge.

## Implemented

`tests/testthat/test-covariance-block-registry.R` now has a deterministic
simulation-style recovery test for hidden `model_type == 96`. The test builds a
q=3 registry with replicated groups and member-specific design values, generates
latent q=3 contributions through the same TMB-style scaled correlation transform
used in the earlier algebra probes, and simulates Gaussian observations from
the resulting `mu` and `log_sigma` predictors.

The fitted hidden TMB object passes `u_re_cov_probe` through TMB's `random`
argument. After optimizing the fixed effects and the Laplace random-effect mode,
the test checks convergence, finite objective and gradient values, and better
recovery of the simulated `mu` and `log_sigma` predictor signal than a
no-random-effect baseline.

This is intentionally not a public q > 2 model. The q=3 covariance parameters
are still supplied as hidden probe data, not estimated from user-facing syntax.

## Files Changed

- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-7d-hidden-q3-simulation-style-recovery.md`

## Checks Run

- `air format tests/testthat/test-covariance-block-registry.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-7d-hidden-q3-simulation-style-recovery.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 73 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 971 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Consistency Audit

Slice 7 is now a hidden q=3 prototype phase: positive-definite correlation
algebra, non-centered latent transform, registry-shaped member mapping, TMB
random-effect boundary, Gaussian likelihood routing, Laplace random-effect
mode, and deterministic simulation-style predictor recovery all have local
tests. It still does not provide q=4 support, `corpairs()` rows for q > 2,
examples, public formula grammar, or fitted estimation of q > 2 covariance
parameters.

## Next Actions

1. Start Slice 8 with the smallest q=4 deterministic registry/algebra bridge
   for `mu1`, `mu2`, `sigma1`, and `sigma2`.
2. Keep the old fifteen-step roadmap as a guide, but split it when the blast
   radius changes: q=4 fitted code, extractor rows, simulation recovery, and
   reader-facing examples should remain separate reviewable slices.
