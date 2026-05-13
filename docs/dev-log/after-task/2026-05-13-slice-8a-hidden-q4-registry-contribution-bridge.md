# After Task: Slice 8A Hidden q=4 Registry Contribution Bridge

## Goal

Start Slice 8 by proving that the labelled covariance-block registry and hidden
TMB contribution path can carry the full four-member endpoint block:
`mu1`, `mu2`, `sigma1`, and `sigma2`.

## Implemented

`tests/testthat/test-covariance-block-registry.R` now has a guarded q=4 helper
that builds one hidden block across `mu1`, `mu2`, `sigma1`, and `sigma2`. The
new registry test checks that the block has four members and six pair rows:
one `mean-mean` row, four `mean-scale` rows, and one `scale-scale` row.

The new hidden TMB test uses `model_type == 97` to route a q=4 standardized
latent vector through `UNSTRUCTURED_CORR_t` plus `VECSCALE_t`, map the
transformed effects back to member-specific design columns, and compare the
reported contribution matrix to an R-side reconstruction. The test also checks
that the reported q=4 correlation matrix is symmetric, has unit diagonal, is
positive definite, and leaves finite objective and gradient values.

The q=4 test exposed a small but important test-helper issue: for q > 3, TMB's
unstructured-correlation theta vector follows row-wise strict-lower-triangle
order. The R reconstruction helper now mirrors that order. The earlier q=3
tests could not distinguish row-wise from column-wise order because both orders
are identical for three members.

## Files Changed

- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-8a-hidden-q4-registry-contribution-bridge.md`

## Checks Run

- `air format tests/testthat/test-covariance-block-registry.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8a-hidden-q4-registry-contribution-bridge.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 104 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian|gaussian-random-intercepts|phylo-utils|package-skeleton")'`:
  passed with 1002 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Consistency Audit

This is a hidden q=4 registry and contribution bridge, not fitted q=4 support.
It does not route the four-member block into the bivariate Gaussian likelihood,
does not estimate q=4 covariance parameters, does not add q > 2 `corpairs()`
rows, and does not change public formula syntax.

## Next Actions

1. Add the smallest hidden bivariate Gaussian q=4 likelihood route that sends
   `mu1`, `mu2`, `sigma1`, and `sigma2` member contributions into the existing
   bivariate predictors.
2. Keep the q=4 path hidden until fitted likelihood tests, recovery evidence,
   extractor rows, examples, and syntax review are all present.
