# After Task: Slice 20 Bivariate Q4 And Phylo Simulate Smoke Tests

## Goal

Add focused `simulate()` coverage for the new fitted bivariate covariance
surfaces without adding more model fits to the test suite.

## Implemented

- Added simulation checks inside the existing ordinary q=4
  `biv_gaussian()` test.
- Added simulation checks inside the existing bivariate phylogenetic
  `mu1`/`mu2` test.
- Checked paired output column names, row counts, numeric finite values, and
  seed reproducibility.

## Mathematical Contract

These checks use the current conditional simulation contract. Given fitted
linear predictors:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
Omega_i[1, 2] = rho12_i sigma1_i sigma2_i
```

`simulate()` draws new residual response pairs around the fitted conditional
`mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12`. For q4 and phylogenetic fits,
the fitted random effects are already included in the predictions used by the
simulator.

## Files Changed

- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-phylo-gaussian.R`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format tests/testthat/test-biv-gaussian.R tests/testthat/test-phylo-gaussian.R`
- `Rscript -e 'devtools::test(filter = "biv-gaussian|phylo-gaussian", reporter = "summary")'`
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`
- `git diff --check`

## Tests Of The Tests

The new checks exercise an exported user surface, not only internals. They
would catch broken bivariate simulation column naming, nonnumeric output,
non-finite simulated values, row-count drift, or seed reproducibility regressions
for q4 and bivariate phylogenetic fits.

## Consistency Audit

No user-facing syntax changed. The simulation docs already state that
bivariate Gaussian simulation uses fitted `mu1`, `mu2`, `sigma1`, `sigma2`, and
residual `rho12`; these tests make that contract cover the new covariance
surfaces.

## What Did Not Go Smoothly

No implementation issue. This slice was intentionally a small verification
layer.

## Team Learning

Curie gets more coverage from the fitted models already present in the suite
instead of adding another expensive optimizer run.

## Known Limitations

- These tests simulate conditional responses given the fitted random effects.
- They do not draw new q4 or phylogenetic random-effect vectors from the fitted
  covariance model.

## Next Actions

Continue with either broader grouped covariance verification or design-only
work for random-slope covariance dimensions.
