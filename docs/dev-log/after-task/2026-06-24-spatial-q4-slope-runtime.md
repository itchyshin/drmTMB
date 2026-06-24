# After-Task Report: Spatial All-Four One-Slope Runtime Gate

Date: 2026-06-24

Branch: `codex/structured-relmat-kq-mu-slope-fixture`

## Purpose

Move exactly one provider row beyond identity preflight: bivariate Gaussian
fixed-covariance spatial all-four `spatial(1 + x | p | site, coords = coords)`
terms in `mu1`, `mu2`, `sigma1`, and `sigma2`. This is an eight-member
q8-shaped endpoint map:

`mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x`,
`sigma1:(Intercept)`, `sigma1:x`, `sigma2:(Intercept)`, and `sigma2:x`.

## Implementation

- Reused the provider-neutral all-four one-slope structured detector already
  opened by the phylo runtime gate.
- Added a focused fixed-covariance spatial runtime/extractor test.
- Promoted only the fixed-covariance spatial q-series all-four one-slope row to
  native ML point-fit and extractor evidence.
- Left range-estimating spatial, animal, relmat, block-diagonal all-four
  one-slope layouts, bridge parity, intervals, coverage, REML, AI-REML, and
  public support planned.

## Evidence

The focused spatial test verifies:

- finite native ML point fit with `se = FALSE`;
- `q = 8`;
- endpoint-member identity in `structured_effects()`;
- eight direct SD target labels;
- 28 derived latent spatial correlations;
- derived correlation intervals remain unavailable; and
- prediction contributions for `mu1` and `sigma2` include both intercept and
  slope endpoint members.

The focused checks passed:

```sh
Rscript --vanilla -e "devtools::test(filter = 'spatial-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

Results: 243 `spatial-gaussian` assertions passed; 2557
`structured-re-conversion-contracts` assertions passed; mission-control
validation passed.

## Claim Boundary

This slice is native point-fit and extractor evidence for the exact
fixed-covariance spatial all-four one-slope cell only. It does not promote
range-estimating spatial support; animal or relmat all-four one-slope runtime
support; bridge parity; q4 interval reliability; q4 coverage; q4 REML;
native-TMB q4 REML; q4 AI-REML; HSquared AI-REML; non-Gaussian AI-REML; broad
bridge support; or public support.

## Next Gate

Add same-target bridge fixture evidence for the exact phylo/spatial runtime
cells, or continue runtime/extractor gates provider-by-provider for A-matrix
animal and K/Q relmat before any interval diagnostics or coverage work.
