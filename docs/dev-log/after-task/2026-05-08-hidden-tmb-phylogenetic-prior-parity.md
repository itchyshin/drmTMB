# After Task: Hidden TMB Phylogenetic Prior Parity

## Goal

Add a hidden TMB-only parity branch for the augmented phylogenetic Gaussian
prior, before any public `phylo()` model fitting path is exposed.

## Implemented

- Added sparse phylogenetic precision data and latent phylogenetic parameters
  to the TMB template.
- Added a hidden `model_type == 99` branch that evaluates only the augmented
  phylogenetic Gaussian prior NLL.
- Added dummy mapped parameters and dummy sparse data for existing Gaussian and
  bivariate Gaussian model paths.
- Added a test that compares the TMB objective with the pure-R
  `drm_phylo_precision_nll()` helper on the exact tiny tree.

## Mathematical Contract

The TMB branch implements:

```text
nll_phylo =
  0.5 * [
    n log(2 pi)
    + 2 n log_sd
    - logdet(Q_A)
    + exp(-2 log_sd) z' Q_A z
  ]
```

where `Q_A` is the augmented phylogenetic correlation-scale precision and the
root state is fixed at zero.

## Files Changed

- `src/drmTMB.cpp`
- `R/drmTMB.R`
- `tests/testthat/test-phylo-utils.R`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`: 45 passed.
- `Rscript -e "devtools::test()"`: 465 passed.
- `git diff --check`: passed.
- `air format .`: not run because `air` is not installed locally.
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`: no
  problems found; site built successfully.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

- The test constructs a `TMB::MakeADFun()` object directly with
  `model_type = 99`.
- The same precision object, latent vector, and `log_sd` are passed to TMB and
  to the R helper.
- The TMB objective must match the R helper to numerical tolerance.
- The TMB gradient must be finite.

## Consistency Audit

- The design note now records that the hidden TMB branch exists only for
  parity testing.
- Known limitations still say fitted `phylo()` terms are unavailable.
- No user-facing function, formula grammar, or pkgdown reference entry changed.
- `NEWS.md` was not updated because this is internal implementation scaffolding.

## What Did Not Go Smoothly

This slice required adding dummy data and dummy mapped parameters for all
existing model paths, because TMB data and parameters are declared at template
compile time. Keeping the branch hidden avoids changing user-facing behaviour
while still testing the C++ prior constant.

## Team Learning

- TMB parity branches are useful, but they must be clearly hidden and audited
  so users do not mistake them for supported model types.
- Future TMB additions should continue to include a small direct objective
  comparison before being wired into `drmTMB()`.
- Rose should check that dummy parameters remain mapped out of ordinary fits.

## Known Limitations

- No model-builder plumbing uses this branch.
- No fitted phylogenetic model is available yet.
- No simulation recovery has been run for fitted `phylo()` terms.

## Next Actions

1. Build the R-side model-builder plumbing for one univariate Gaussian `mu`
   phylogenetic random intercept.
2. Reuse this TMB prior expression in the ordinary Gaussian branch.
3. Add dense-comparator and simulation recovery tests before documenting
   `phylo()` as implemented.
