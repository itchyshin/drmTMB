# After Task: Slice 8C Hidden q=4 Bivariate Random-Effect Boundary

## Goal

Prove that the hidden q=4 bivariate endpoint bridge can cross TMB's random-effect
boundary before adding recovery-style evidence or public syntax.

## Implemented

`tests/testthat/test-covariance-block-registry.R` now includes a hidden
`model_type == 95` bivariate Gaussian test with `u_re_cov_probe` passed through
TMB's `random` argument. The test builds a q=4 intercept-level endpoint block
across `mu1`, `mu2`, `sigma1`, and `sigma2`, starts the latent vector at zero,
and checks that TMB finds a nonzero random-effect mode under the bivariate
likelihood.

The test reconstructs the q=4 contribution matrix from the optimized mode and
checks the reported `mu1`, `mu2`, `log(sigma1)`, `log(sigma2)`, `sigma1`, and
`sigma2` values. It also checks finite objective and gradient values.

## Team Roles

Ada integrated the slice. Gauss checked that the hidden likelihood still uses
positive scale parameters and bounded `rho12`. Curie checked that the test
verifies the random-effect boundary instead of repeating the fixed-parameter
algebra from Slice 8B. Rose checked that the notes still describe q4 as hidden
and do not imply q6 or q8 random-slope support.

## Scope Boundary

This is a Laplace boundary check, not recovery evidence. It does not expose
q > 2 formula syntax, estimate q4 covariance parameters through ordinary
`drmTMB()` calls, add q4 `corpairs()` rows, or add reader-facing examples.
The finite-gradient check is for the fixed-parameter Laplace objective, not a
separate random-score stationarity check. The q4 intercept-level path remains
the priority before phylogenetic q4; q6 and q8 random-slope endpoint blocks
remain later extensions.

## Files Changed

- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-8c-hidden-q4-bivariate-random-effect-boundary.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 127 expectations, 0 failures, 0 warnings, and 0 skips.
- `air format tests/testthat/test-covariance-block-registry.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8c-hidden-q4-bivariate-random-effect-boundary.md`:
  passed.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian")'`: passed with 611 expectations, 0
  failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Next Actions

1. Add a deterministic hidden q=4 recovery-style check that shows the bivariate
   Laplace path recovers the simulated endpoint predictor signal better than a
   no-random-effect baseline.
2. Keep q4 hidden until recovery evidence, extractor rows, examples, and public
   syntax review are all present.
