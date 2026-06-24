# After-Task Report: Phylo All-Four One-Slope Runtime Gate

Date: 2026-06-24

Branch: `codex/structured-relmat-kq-mu-slope-fixture`

## Purpose

Move exactly one q-series cell from identity preflight to native runtime point-fit
evidence: bivariate Gaussian phylogenetic all-four `phylo(1 + x | p | species,
tree = tree)` terms in `mu1`, `mu2`, `sigma1`, and `sigma2`. This is an
eight-member q8-shaped endpoint map:

`mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x`,
`sigma1:(Intercept)`, `sigma1:x`, `sigma2:(Intercept)`, and `sigma2:x`.

## Implementation

- Allowed labelled intercept-plus-one-slope structured terms through the formula
  parser.
- Kept univariate labelled intercept-plus-one-slope structured covariance
  blocked with a runtime diagnostic unless the term participates in the exact
  all-four bivariate Gaussian block.
- Expanded the all-four structured detector from four endpoint formulas to eight
  endpoint-member columns for the shared-label one-slope case.
- Updated the bivariate structured contribution helper so predictions sum both
  endpoint members for a requested distributional parameter.
- Left block-diagonal all-four one-slope structured layouts planned.

## Evidence

The focused package test passed:

```sh
Rscript --vanilla -e "devtools::test(filter = 'phylo-gaussian')"
```

Result: 366 passed, 0 failed, 0 warnings, 0 skipped.

The new test verifies:

- finite native ML point fit with `se = FALSE`;
- `q = 8`;
- endpoint-member identity in `structured_effects()`;
- eight direct SD target labels;
- 28 derived latent phylogenetic correlations;
- derived correlation intervals remain unavailable; and
- prediction contributions for `mu1` and `sigma2` include both intercept and
  slope endpoint members.

## Claim Boundary

This slice is native point-fit and extractor evidence for the exact phylo
all-four one-slope cell only. It does not promote structured spatial, animal, or
relmat all-four one-slope runtime support; bridge parity; q4 interval
reliability; q4 coverage; q4 REML; native-TMB q4 REML; q4 AI-REML; HSquared
AI-REML; non-Gaussian AI-REML; or broad public support.

## Next Gate

Repeat the runtime/extractor gate provider-by-provider, then add same-target
bridge fixture evidence before interval diagnostics or coverage work.
