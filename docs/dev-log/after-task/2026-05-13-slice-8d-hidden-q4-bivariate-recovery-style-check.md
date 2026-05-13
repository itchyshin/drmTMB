# After Task: Slice 8D Hidden q=4 Bivariate Recovery-Style Check

## Goal

Add the first recovery-style evidence for the hidden q=4 bivariate endpoint
path while keeping q4 out of public syntax and extractor output.

## Implemented

`tests/testthat/test-covariance-block-registry.R` now includes a deterministic
hidden q=4 bivariate Gaussian recovery-style test. The test simulates paired
responses from one intercept-level covariance block across `mu1`, `mu2`,
`sigma1`, and `sigma2`, with an orthogonal deterministic residual basis and
fixed residual `rho12`. It then fits the hidden `model_type == 95` Laplace
branch with `u_re_cov_probe` registered as a TMB random-effect vector.

The test checks that recovered endpoint predictor signals improve over
no-random-effect baselines for `mu1`, `mu2`, `log(sigma1)`, and `log(sigma2)`.
It also checks positive correlation between recovered and simulated endpoint
signals, optimizer convergence, finite objective values, and finite gradients.

## Team Roles

Ada integrated the slice. Gauss checked that residual `rho12` remains separate
from the group-level q4 endpoint block and that scale effects stay on
`log(sigma1)` and `log(sigma2)`. Curie kept the recovery check deterministic
and CRAN-sized. Rose checked that this is described as hidden recovery-style
evidence, not public q4 support.

## Scope Boundary

This is still hidden machinery. It does not expose q > 2 formula syntax, add
q4 `corpairs()` rows, add user examples, or cover random-slope q6/q8 endpoint
blocks. The next user-relevant milestone remains an ordinary q4 endpoint path
with extractor/reporting support, followed by the phylogenetic q4 state for the
mammalian and avian protocol use case.

## Files Changed

- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-8d-hidden-q4-bivariate-recovery-style-check.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 139 expectations, 0 failures, 0 warnings, and 0 skips.
- `air format tests/testthat/test-covariance-block-registry.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8d-hidden-q4-bivariate-recovery-style-check.md`:
  passed.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian")'`: passed with 623 expectations, 0
  failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Next Actions

1. Decide whether Slice 8 needs one more hidden internal step before beginning
   q4 reporting/extractor work.
