# After Task: Slice 6E Mapped-Off q=3 Probe No-Op Guard

## Goal

Add a narrow guard showing that the hidden q=3 probe parameter introduced in
slice 6D cannot change ordinary fitted likelihoods while it remains mapped off.

## Implemented

`tests/testthat/test-covariance-block-registry.R` now rebuilds a simple ordinary
Gaussian TMB object with `u_re_cov_probe = 7`, while preserving the default
`factor(NA)` map used by `drmTMB()`. The test checks that the optimizer
parameter names remain unchanged and that the objective and gradient match the
original fitted object to numerical tolerance.

This is deliberately a guard on absence of behavior. It does not add q > 2
covariance syntax, does not add production random-effect likelihood
contributions, and does not make `u_re_cov_probe` visible to ordinary
optimizers.

## Files Changed

- `tests/testthat/test-covariance-block-registry.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-6e-mapped-off-q3-probe-no-op-guard.md`

## Checks Run

- `air format tests/testthat/test-covariance-block-registry.R`: passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 44 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 942 expectations, 0 failures, 0 warnings, and 0 skips.

## Consistency Audit

This slice keeps the package in the planned-but-not-implemented state for q > 2
covariance blocks. The hidden probe remains an internal compiled contract only;
reader-facing support still needs production likelihood wiring, simulation
recovery, `corpairs()` rows, examples, and full review before it can be claimed.

## Next Actions

1. Decide whether the next implementation slice should turn
   `u_re_cov_probe` into an internal random-effect vector for the hidden probe.
2. Keep q > 2 work away from ordinary model syntax until simulation recovery and
   extractor/reporting behavior exist.
