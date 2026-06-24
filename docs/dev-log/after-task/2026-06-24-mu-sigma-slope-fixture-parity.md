# After Task: Matched Mu+Sigma Slope Fixture Parity

## Goal

Bank deterministic same-target bridge fixture evidence for the matched Gaussian
structured `mu+sigma` one-slope cells after their native point-fit/extractor
identity gate was opened.

## Implemented

- Added `phase18_structured_re_mu_sigma_slope_payload_fixture()` and
  `phase18_structured_re_mu_sigma_slope_parity_fixture_contract()` for
  `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
  `relmat()`.
- Added bridge-fixture tests that compare native, direct DRM.jl, and
  R-via-Julia deterministic reconstructions for the exact matched
  `q1_plus_q1` endpoint-member set.
- Added
  `docs/dev-log/dashboard/structured-re-mu-sigma-slope-parity-fixture.tsv` and
  moved the four matching support-cell rows to `bridge_status =
  fixture_parity`.
- Updated dashboard validation, conversion-contract tests, README, roadmap,
  NEWS, and design/status notes so matched one-slope fixture evidence is
  visible without widening public support claims.

## Mathematical Contract

The fixture target is `q1_plus_q1`, not labelled q2 covariance and not q4. The
coefficient order is
`mu:(Intercept);mu:x;sigma:(Intercept);sigma:x;sd_mu:structured(Intercept);sd_mu:structured(x);sd_sigma:structured(Intercept);sd_sigma:structured(x)`.
The structured matrix source is provider-specific: tree branch lengths,
coordinate-derived fixed covariance, an A matrix, or a K matrix. The relmat
fixture does not marshal Q precision through the bridge; Q remains native
runtime parity evidence only.

## Files Changed

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-mu-sigma-slope-parity-fixture.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `README.md`, `ROADMAP.md`, `NEWS.md`, and related status docs touched by
  stale-wording cleanup.

## Checks Run

```sh
air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
rg -n -F -e "bridge/inference for matched slope cells" -e "bridge support for matched slope cells" -e "matched one-slope bridge" -e "native point-fit and extractor evidence only" -e "point-fit/extractor evidence only" -e "bridge fixtures and recovery grids" README.md ROADMAP.md NEWS.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md
gh issue list --repo itchyshin/drmTMB --search "structured mu sigma slope fixture q-series" --limit 20 --json number,title,state,url,labels
```

Results: bridge-fixture tests passed with 389 assertions, conversion-contract
tests passed with 1563 assertions, mission-control validation passed with four
matched `mu+sigma` parity-fixture rows, `git diff --check` passed, the
stale-wording scan returned no current hits, and the GitHub issue search
returned `[]`.

## Tests Of The Tests

The new bridge-fixture test would fail if the payload dimension, endpoint,
coefficient order, route reconstruction, provider boundary, or unsupported
REML/invalid-provider guard drifted. The conversion-contract test and
mission-control validator independently check the TSV schema and the linked
q-series support-cell rows.

## Consistency Audit

README, ROADMAP, NEWS, the q-series completion map, dashboard README, and the
pre-simulation/status matrices now state that deterministic same-target fixture
evidence is banked for the matched one-slope cells while intervals, coverage,
REML, AI-REML, broad bridge support, labelled slope covariance, and relmat Q
bridge marshalling remain unpromoted.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --search "structured mu sigma slope fixture q-series" --limit 20 --json number,title,state,url,labels`
returned `[]`. No issue was opened because the slice is already tracked by the
q-series support-cell map and dashboard sidecars.

## What Did Not Go Smoothly

The readiness sidecar and q-series support cells briefly wanted to tell two
different stories. Keeping readiness as the identity gate and adding a separate
parity sidecar made the evidence ladder explicit.

## Team Learning

Do not overwrite a readiness row with later evidence. Add the next sidecar and
move only the support-cell row that owns the public claim tier.

## Known Limitations

This slice is fixture evidence only. It does not add interval diagnostics,
coverage denominators, REML, AI-REML, labelled structured slope covariance,
range-estimating spatial support, pedigree/Ainv bridge marshalling, relmat Q
bridge marshalling, q4/q6/q8 slope blocks, non-Gaussian structured slopes, or
public broad bridge support.

## Next Actions

Run calibrated interval diagnostics for these exact matched one-slope cells, or
move to the next q-series runtime gap: bivariate structured slope covariance.
