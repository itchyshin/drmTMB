# After Task: Slice 7C Hidden q=3 Random-Effect Likelihood Prototype

## Goal

Prove that the hidden q=3 Gaussian likelihood prototype can run with
`u_re_cov_probe` as a TMB random-effect vector, not only as fixed test
parameters.

## Implemented

`tests/testthat/test-covariance-block-registry.R` now builds hidden
`model_type == 96` with `u_re_cov_probe` passed through TMB's `random` argument.
The test checks that the random-effect vector drops out of the fixed optimizer
parameter list, appears in TMB's random-effect indices, and finds a nonzero mode
under the Gaussian likelihood.

The test reconstructs the q=3 contribution matrix from that optimized mode and
checks that TMB reports the same `mu`, `log_sigma`, and `obs_sigma`. This keeps
the slice focused on the internal Laplace path: the test does not expose q > 2
syntax, extractor rows, or public examples.

## Files Changed

- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-7c-hidden-q3-random-effect-likelihood-prototype.md`

## Checks Run

- `air format tests/testthat/test-covariance-block-registry.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 66 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 964 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Consistency Audit

This is still a hidden q=3 bridge. It proves that the Gaussian likelihood can use
the optimized q=3 random-effect mode, but it does not provide simulation
recovery, q=4 `mu1`/`mu2`/`sigma1`/`sigma2` support, `corpairs()` rows, examples,
or public formula support.

## Next Actions

1. Add a hidden simulation-style recovery check for the q=3 likelihood path, or
   first add a deterministic q=4 algebra/registry probe if the next goal is the
   full two-mean/two-scale endpoint.
2. Keep public q > 2 claims closed until recovery tests, extractor rows, and
   reader-facing examples exist.
