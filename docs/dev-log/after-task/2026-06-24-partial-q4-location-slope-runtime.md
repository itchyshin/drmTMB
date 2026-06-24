# After-Task Report: Partial Q4 Location One-Slope Runtime

Date: 2026-06-24

Branch: `codex/structured-relmat-kq-mu-slope-fixture`

## Purpose

Open the exact bivariate Gaussian structured `mu1+mu2` intercept-plus-one-slope
q4 location cell for the current four structured providers:

`phylo(1 + x | p | species, tree = tree)`, `spatial(1 + x | p | site,
coords = coords)`, `animal(1 + x | p | id, A = A)`, and
`relmat(1 + x | p | id, K = K)` in `mu1` and `mu2`, with no structured
`sigma1` or `sigma2` terms.

## Implementation

- Added endpoint-response metadata for structured bivariate q>2 random-effect
  members.
- Routed q>2 structured contributions by endpoint family and response suffix
  instead of hard-coded first-four endpoint positions.
- Allowed matching labelled `1 + x` structured terms in `mu1` and `mu2` only
  when both terms have an explicit covariance-block label and the same
  coefficient set.
- Kept unlabelled `1 + x` bivariate structured location blocks guarded.
- Kept partial location-scale `sigma1+sigma2` structured blocks guarded.
- Updated bivariate structured start values to use endpoint identity for q>2
  starts.
- Added provider-focused tests for exact partial q4 location member identity,
  SD/correlation extractors, profile-target boundaries, and prediction
  contribution identity.

## Evidence

Focused tests passed:

```sh
Rscript --vanilla -e "devtools::test(filter = 'phylo-gaussian', stop_on_failure = TRUE)"
Rscript --vanilla -e "devtools::test(filter = 'spatial-gaussian', stop_on_failure = TRUE)"
Rscript --vanilla -e "devtools::test(filter = 'animal-relmat-gaussian', stop_on_failure = TRUE)"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"
python3 -m py_compile tools/validate-mission-control.py
python3 tools/validate-mission-control.py
git diff --check
```

Results: 385 `phylo-gaussian` assertions, 262 `spatial-gaussian` assertions,
459 `animal-relmat-gaussian` assertions, and 2,981
`structured-re-conversion-contracts` assertions passed. Mission-control
validation passed and reported 77 structured RE q-series cells.

## Claim Boundary

This slice is native ML point-fit and extractor evidence for the exact
`mu1+mu2` intercept-plus-one-slope structured q4 location cells only. It does
not promote same-target bridge parity, partial location-scale support,
interval reliability, coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,
HSquared AI-REML, non-Gaussian REML, broad bridge support, public optimizer
controls, public support, DRAC execution, SR150 coverage readiness, PR
undrafting/merging, or an Ayumi-facing reply.

## What Did Not Go Smoothly

The existing q8-shaped all-four tests did not catch that TMB contribution
routing for q>2 bivariate structured blocks was position-based rather than
endpoint-aware. Once fixed, spatial q8 convergence evidence shifted to a finite
convergence-code-1 fixture and relmat K/Q numeric equality was no longer a safe
claim for the all-four one-slope q8-shaped fixture. The tests now check shape
and endpoint identity without overclaiming K/Q numeric parity in that cell.

## Next Gate

Add deterministic same-target fixture parity for the exact partial q4 location
cells, beginning with relmat K/Q and then the remaining providers, before any
interval, coverage, or public-support promotion.
