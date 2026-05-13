# After Task: Slice 8B Hidden q=4 Bivariate Likelihood Bridge

## Goal

Move the q=4 endpoint bridge one step past algebra by proving that the hidden
contribution map can feed a bivariate Gaussian likelihood without changing
ordinary fitted model paths.

## Implemented

`src/drmTMB.cpp` now has a hidden `model_type == 95` branch. It reuses the
q=4 registry-shaped contribution map, then adds the four intercept-level member
contributions into `mu1`, `mu2`, `log(sigma1)`, and `log(sigma2)` before
evaluating the existing bivariate Gaussian row likelihood with `rho12` on the
Fisher-z link scale. The hidden branch also keeps the standard-normal prior for
the q=4 latent vector.

`tests/testthat/test-covariance-block-registry.R` now reconstructs the same
path independently in R. The test builds a guarded
`mu1`/`mu2`/`sigma1`/`sigma2` block, computes the TMB-style q=4 Cholesky
transform, checks the reported contribution matrix and transformed predictors,
and compares the TMB objective with the R-side bivariate Gaussian negative log
likelihood plus the latent prior.

## Team Roles

Ada integrated the slice and kept the public boundary narrow. Gauss focused on
the bivariate likelihood and correlation transform. Curie focused on the
targeted tests and finite-gradient check. Rose kept the wording honest about
what is still hidden and unsupported.

## Terminology

In these notes, q means the TMB covariance-block dimension: the number of
group-level latent coefficients in one block. The intercept-level endpoint
bridge is q=4 because it contains `mu1`, `mu2`, `sigma1`, and `sigma2`. A full
unstructured q=4 block has six possible pair rows, but a future user-facing API
may expose only a masked subset of modelled correlations. Random-slope endpoint
blocks would be q=6 when only `mu1`/`mu2` have slopes and q=8 if
`sigma1`/`sigma2` also have slopes.

## Files Changed

- `src/drmTMB.cpp`
- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-8b-hidden-q4-bivariate-likelihood-bridge.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 115 expectations, 0 failures, 0 warnings, and 0 skips.
- `air format src/drmTMB.cpp tests/testthat/test-covariance-block-registry.R`:
  passed.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|biv-gaussian")'`: passed with 599 expectations, 0
  failures, 0 warnings, and 0 skips.

## Consistency Audit

This is still a hidden probe. It does not estimate q=4 covariance parameters as
part of ordinary `drmTMB()` fitting, does not add public syntax, does not add
q > 2 `corpairs()` rows, and does not cover random-slope q=6 or q=8 endpoint
blocks.

## Next Actions

1. Add the smallest hidden q=4 fitted random-effect likelihood path so
   `u_re_cov_probe` can be optimized through TMB's `random` argument in the
   bivariate Gaussian branch.
2. Keep q=4 hidden until recovery evidence, extractor rows, examples, and
   public syntax review are all present.
3. After the non-phylogenetic q=4 endpoint path is fitted and reported, make
   the phylogenetic q=4 endpoint state the next major protocol milestone before
   q=6 or q=8 random-slope blocks.
