# After Task: Phylogenetic Prior NLL Helper

## Goal

Add a pure-R algebra helper for the Gaussian prior contribution of augmented
phylogenetic effects, so the future C++/TMB prior block has an exact tested
target.

## Implemented

- Added `drm_phylo_precision_nll()` as an internal helper.
- The helper takes an augmented latent-effect vector, a
  `drm_phylo_augmented_precision()` object, and `log_sd`.
- It computes the negative log density for
  `z ~ MVN(0, sigma_phylo^2 A)` on the augmented precision scale.
- Added tests comparing the helper to the explicit precision-density formula.
- Added an edge-increment quadratic check for the tiny tree.

## Mathematical Contract

For `Q_A`, the augmented correlation-scale precision, and
`sigma_phylo = exp(log_sd)`:

```text
nll_phylo =
  0.5 * [
    n log(2 pi)
    + 2 n log_sd
    - logdet(Q_A)
    + exp(-2 log_sd) z' Q_A z
  ]
```

The quadratic term is also checked against the Brownian edge increments:

```text
z' Q_A z = H sum_edges (z_child - z_parent)^2 / l_edge
```

with the root fixed at zero.

## Files Changed

- `R/phylo-utils.R`
- `tests/testthat/test-phylo-utils.R`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`: 43 passed.
- `Rscript -e "devtools::test()"`: 463 passed.
- `git diff --check`: passed.
- `air format .`: not run because `air` is not installed locally.
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`: no
  problems found; site built successfully.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

- The test uses the same exact tiny tree as the dense comparator and augmented
  precision tests.
- It verifies the quadratic as an edge-increment sum, independent of the helper
  implementation.
- It verifies the NLL against the full precision-density expression.
- It checks malformed effect-vector length and malformed `log_sd` inputs.

## Consistency Audit

- The design note now records the same prior NLL equation as the helper.
- Known limitations now say the helper exists but fitted phylogenetic models
  still do not.
- No user-facing function was exported, so no roxygen, `_pkgdown.yml`, or
  `NEWS.md` update was needed.

## What Did Not Go Smoothly

This slice was smooth because the previous augmented-precision work had already
settled the root, scaling, and determinant conventions. The main risk was
getting the determinant sign wrong; the test pins the sign explicitly.

## Team Learning

- The next C++ block should be written directly against this equation, not
  re-derived casually.
- Every structured-effect prior should have an R-side algebra test before a
  TMB template is touched.
- Rose should keep watching for internal helpers being described as fitted
  model support.

## Known Limitations

- No TMB code uses the helper yet.
- No fitted phylogenetic model is available yet.
- The helper assumes the precision object is already valid and Brownian.

## Next Actions

1. Add the C++/TMB structured-effect prior block and compare it against this
   R helper on the tiny tree.
2. Add model-builder plumbing for one univariate Gaussian `mu` phylogenetic
   random intercept.
3. Add simulation recovery before advertising `phylo()` as implemented.
