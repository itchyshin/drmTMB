# After-Task Report: Animal/Relmat All-Four One-Slope Runtime Gate

Date: 2026-06-24

Branch: `codex/structured-relmat-kq-mu-slope-fixture`

## Purpose

Move the remaining relatedness-provider rows beyond identity preflight:

- `animal(1 + x | p | id, A = A)` in `mu1`, `mu2`, `sigma1`, and `sigma2`;
- `relmat(1 + x | p | id, K = K)` / `Q = Q` in `mu1`, `mu2`, `sigma1`, and
  `sigma2`.

Both cells are eight-member q8-shaped endpoint maps:

`mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x`,
`sigma1:(Intercept)`, `sigma1:x`, `sigma2:(Intercept)`, and `sigma2:x`.

## Implementation

- Added a focused animal/relmat runtime/extractor test for the exact all-four
  one-slope cells.
- Reused the provider-neutral all-four one-slope structured detector opened by
  the phylo and fixed-covariance spatial gates.
- Checked A-matrix animal runtime and relmat K/Q same-target runtime parity.
- Promoted only the exact A-matrix animal and K/Q relmat q-series rows to
  native ML point-fit and extractor evidence.
- Left pedigree/Ainv animal bridge marshalling, relmat Q bridge marshalling,
  bridge parity, intervals, coverage, REML, AI-REML, broader q8 layouts, and
  public support planned.

## Evidence

The focused animal/relmat test verifies:

- convergence and finite native ML objectives with `se = FALSE`;
- `q = 8`;
- endpoint-member identity in `structured_effects()`;
- eight direct SD target labels for each provider route;
- 28 derived latent animal or relatedness correlations;
- derived correlation intervals remain unavailable;
- prediction contributions for `mu1` and `sigma2` include both intercept and
  slope endpoint members; and
- relmat K/Q same-target log-likelihood and structured-SD parity.

## Checks Run

```sh
air format tests/testthat/test-animal-relmat-gaussian.R tests/testthat/test-structured-re-conversion-contracts.R
Rscript --vanilla -e "devtools::test(filter = 'animal-relmat-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 -m py_compile tools/validate-mission-control.py
python3 tools/validate-mission-control.py
git diff --check
```

Results: 425 `animal-relmat-gaussian` assertions passed.
The conversion-contract test passed with 2557 assertions. Mission-control
validation passed with all four q4-slope identity rows at
`runtime_test`/`point_fit`. `git diff --check` passed.

## Claim Boundary

This slice is native point-fit and extractor evidence for the exact shared-label
A-matrix animal and K/Q relmat all-four one-slope cells only. It does not
promote pedigree/Ainv animal bridge marshalling, relmat Q bridge marshalling,
block-diagonal all-four one-slope layouts, partial labelled endpoint layouts,
bridge parity, interval reliability, coverage, q4 REML, native-TMB q4 REML,
q4 AI-REML, HSquared AI-REML, non-Gaussian REML, broad bridge support, public
optimizer controls, DRAC execution, SR150 coverage readiness, PR
undrafting/merging, or an Ayumi-facing reply.

## Next Gate

Add same-target bridge fixture evidence for the exact phylo, fixed-covariance
spatial, A-matrix animal, and K-matrix relmat q4-slope runtime cells before any
interval diagnostics, coverage, REML, or public-support work. Keep relmat Q
bridge marshalling and pedigree/Ainv animal bridge marshalling as separate
provider-boundary rows.
