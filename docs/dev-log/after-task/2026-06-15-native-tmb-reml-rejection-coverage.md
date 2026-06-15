# Native TMB REML Rejection Coverage

## Goal

Add compact tests for the native `engine = "tmb"` `REML = TRUE` boundary before
using native TMB as an Ayumi-facing fallback. The intended contract is narrow:
native TMB supports the documented first univariate Gaussian REML slice, and
unsupported neighbours must reject clearly rather than drifting into ambiguous
partial fits.

## Changes

`tests/testthat/test-comparators.R` now covers the unsupported REML neighbours
that `drm_validate_reml_spec()` and the top-level REML gate are supposed to
block:

- non-Gaussian REML;
- predictor-dependent `sigma`;
- direct random-effect scale formulae;
- explicit missing-data engines;
- sparse fixed-effect matrices;
- Gaussian row aggregation;
- residual-scale random effects;
- q > 2 labelled covariance blocks;
- structured Gaussian phylogenetic effects;
- rank-deficient dense `mu` fixed-effect design.

## Evidence

Commands run from `/tmp/drmtmb-rfirst-native-reml`:

```sh
air format tests/testthat/test-comparators.R
```

```sh
/Library/Frameworks/R.framework/Resources/bin/Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-comparators.R")'
```

Result: passed locally with 123 expectations.

```sh
git diff --check
```

Result: no whitespace errors.

## Claim Boundary

This is rejection-test coverage only. It does not expand native TMB REML
support, does not implement bivariate q4 REML in TMB, and does not change the
Ayumi guidance: native TMB can help with supported ML point/profile diagnostics,
but it is not yet a full REML fallback for the bivariate q4 phylogenetic
location-scale model.

## Next Slices

1. Align Julia bridge roxygen and vignette wording around supported profile and
   bootstrap targets.
2. Add an Ayumi q4 status row separating native TMB ML diagnostics, native TMB
   REML unsupported, Julia q4 REML forwarding, Wald-unsafe states, and missing
   10k benchmark evidence.
