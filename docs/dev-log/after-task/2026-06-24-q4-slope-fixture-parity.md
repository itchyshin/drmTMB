# After Task: Q4 All-Four One-Slope Fixture Parity

Date: 2026-06-24

Branch: `codex/structured-relmat-kq-mu-slope-fixture`

## Goal

Move the exact bivariate Gaussian structured all-four one-slope q8-shaped cells
from native point-fit/extractor evidence to deterministic same-target fixture
parity for:

- `phylo(1 + x | p | species, tree = tree)`;
- fixed-covariance `spatial(1 + x | p | site, coords = coords)`;
- A-matrix `animal(1 + x | p | id, A = A)`; and
- K-matrix `relmat(1 + x | p | id, K = K)`.

## Implemented

- Added `phase18_structured_re_q4_slope_payload_fixture()` and
  `phase18_structured_re_q4_slope_parity_fixture_contract()` in
  `inst/sim/R/sim_structured_re_bridge_fixtures.R`.
- Added `docs/dev-log/dashboard/structured-re-q4-slope-parity-fixture.tsv`
  with one row each for `phylo()`, fixed-covariance `spatial()`, A-matrix
  `animal()`, and K-matrix `relmat()`.
- Moved the four q-series all-four one-slope support cells to
  `route = native_direct_bridge_fixture`, `bridge_status = fixture_parity`,
  and `denominator_policy = fixture_not_coverage`.
- Kept `structured-re-q4-slope-identity-preflight.tsv` as the
  runtime/extractor identity ledger, not the bridge evidence source.
- Updated dashboard, q-series map, README, ROADMAP, NEWS, conversion tests,
  bridge-fixture tests, and mission-control validation.

## Mathematical Contract

The fixture estimates the exact shared-label all-four block:

```r
mu1 = y1 ~ x + provider(1 + x | p | group, ...)
mu2 = y2 ~ x + provider(1 + x | p | group, ...)
sigma1 = ~ x + provider(1 + x | p | group, ...)
sigma2 = ~ x + provider(1 + x | p | group, ...)
```

The endpoint members are
`mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x`,
`sigma1:(Intercept)`, `sigma1:x`, `sigma2:(Intercept)`, and `sigma2:x`.
The fixture records eight endpoint coefficients, eight direct SD targets, and
28 derived labelled correlations. It is not a partial block, a two-slope q6/q8
route, a public bridge route, or an interval/coverage result.

## Files Changed

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-q4-slope-parity-fixture.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 -m py_compile tools/validate-mission-control.py
python3 tools/validate-mission-control.py
git diff --check
rg -n "<q4-slope overclaim pattern>" README.md NEWS.md ROADMAP.md docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-q4-slope-parity-fixture.tsv tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R
```

Results:

- `structured-re-bridge-fixtures`: 498 assertions passed.
- `structured-re-conversion-contracts`: 2608 assertions passed.
- `python3 tools/validate-mission-control.py`: passed, with 4 structured RE
  q4 slope parity-fixture rows.
- `git diff --check`: passed.
- The overclaim scan returned no hits.

## Tests Of The Tests

The bridge-fixture test reconstructs native, direct DRM.jl, and R-via-Julia
fixture payloads for each provider and requires zero coefficient and
log-likelihood deltas. The conversion-contract test checks the sidecar schema,
44-term coefficient order, eight SD terms, 28 correlation terms, provider
matrix slots, q-series linkage, and planned interval/coverage statuses.

## Consistency Audit

README, ROADMAP, NEWS, the dashboard README, and the q-series completion map
now describe the exact all-four one-slope rows as fixture-parity evidence, not
native-only evidence. The mission-control validator reads the new sidecar
directly and requires each linked q-series cell to remain exact-cell fixture
evidence.

## Claim Boundary

This slice is deterministic same-target fixture evidence for the exact
shared-label q8-shaped all-four one-slope ML cells only. It does not promote
pedigree/Ainv animal bridge marshalling, relmat Q bridge marshalling,
range-estimating spatial support, block-diagonal all-four one-slope layouts,
partial labelled endpoint layouts, two-slope q6/q8 cells, interval reliability,
coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML,
non-Gaussian REML, broad bridge support, public optimizer controls, DRAC
execution, SR150 coverage readiness, PR undrafting/merging, or an Ayumi-facing
reply.

## Next Gate

Use the exact q4-slope fixture rows for target-level interval diagnostic
planning only. Coverage denominators, calibrated coverage, q4 REML, AI-REML,
broad bridge support, relmat Q bridge marshalling, pedigree/Ainv animal
marshalling, and range-estimating spatial support all remain separate slices.
