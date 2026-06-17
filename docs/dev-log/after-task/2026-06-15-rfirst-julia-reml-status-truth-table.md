# R-First Julia REML Status Truth Table

## Goal

Bank the first `drmTMB#555` R-side hardening slice before broad Julia speed work:
make `engine = "julia"` report the estimator it actually fitted, keep REML as a
Gaussian-only claim, and stop warning text from implying that native
`engine = "tmb"` is a full REML fallback for every Julia-gated cell.

## Changes

- Added `drm_julia_reml_supported()` as the bridge-local REML admission helper.
- Added `drm_julia_reml_cell_label()` so unsupported non-Gaussian phylo cells are
  labelled as non-Gaussian, not as phylogenetic Gaussian cells.
- `drmTMB_julia` and `drmTMB_julia_xfam` objects now record:
  `estimator`, `REML`, `requested_REML`, and `effective_REML`.
- `print.drmTMB_julia()` now displays the effective estimator.
- Unsupported Julia REML requests now warn that the bridge is fitting ML and
  that native TMB REML fallback is limited to its documented univariate Gaussian
  REML slice.
- Added a mocked q4 bivariate response-mask test proving the R bridge admits
  `missing = miss_control(response = "include")` without dropping rows before
  Julia and still forwards `method = "REML"` only for the supported q4 cell.

## Evidence

Commands run from `/tmp/drmtmb-rfirst-555`:

```sh
air format R/julia-bridge.R tests/testthat/test-julia-bridge.R tests/testthat/test-julia-sigma-phylo-reml.R
```

```sh
/Library/Frameworks/R.framework/Resources/bin/Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R"); testthat::test_file("tests/testthat/test-julia-sigma-phylo-reml.R"); testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R")'
```

Result: `test-julia-bridge.R` passed 97 expectations;
`test-julia-sigma-phylo-reml.R` passed 42 expectations with one guarded live
round-trip skip because the default local DRM.jl path predates sigma-phylo REML
support; `test-julia-gate-vs-engine.R` passed 55 expectations.

```sh
/Library/Frameworks/R.framework/Resources/bin/Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-xfam-bridge.R"); testthat::test_file("tests/testthat/test-julia-structured.R")'
```

Result: `test-xfam-bridge.R` passed 38 expectations with three guarded live-Julia
skips; `test-julia-structured.R` passed 47 expectations.

## Claim Boundary

This slice improves R-side truthfulness. It does not make native
`engine = "tmb"` a full REML fallback for Ayumi's bivariate q4 phylogenetic
location-scale model, and it does not claim that the 10k-tip Julia route is fast.
The next user-visible speed statement still needs exact q4 benchmark evidence
with point estimates, objective/logLik, convergence, CI/status rows, thread and
version metadata, and failure rows.

## Review Perspectives

- Boole found the original non-Gaussian phylo REML warning label and native-TMB
  fallback advice drift; this slice fixes and tests both.
- Rose confirmed the R-first priority and flagged the remaining native REML
  rejection-branch tests and vignette/status wording cleanup as next slices.
- Fisher boundary: `pdHess = FALSE` remains an inference-status problem, not an
  automatic point-estimate failure.

## Next Slices

1. Add compact tests for every `drm_validate_reml_spec()` rejection branch:
   structured Gaussian, q > 2 labelled covariance, sparse fixed matrices,
   Gaussian aggregation, explicit missing-data engines, and rank-deficient
   dense `mu`.
2. Align the Julia bridge vignette and roxygen text around the exact
   profile/bootstrap targets now supported: univariate Gaussian phylo SD and all
   four q4 bivariate Gaussian phylogenetic axes.
3. Add an Ayumi q4 status row separating native TMB ML point/profile diagnostics,
   native TMB REML unsupported, Julia q4 REML forwarding, Wald-unsafe states,
   and missing 10k benchmark evidence.
