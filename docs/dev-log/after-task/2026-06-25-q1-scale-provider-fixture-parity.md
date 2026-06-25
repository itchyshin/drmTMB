# After Task: Q1 Scale Provider Fixture Parity

## 1. Goal

Balance the Gaussian q1 scale-side intercept evidence across structured
providers by adding deterministic fixture-parity rows for spatial and animal
`sigma` and matched `mu+sigma` cells, while preserving the already-banked relmat
boundary and avoiding any public support, interval, coverage, REML, or broad
bridge claim.

## 2. Implemented

Expanded the q1 scale fixture test in
`tests/testthat/test-structured-re-bridge-fixtures.R` so it checks `sigma` and
`mu_sigma` payloads for `spatial`, `animal`, and `relmat` across deterministic
`native_tmb`, `direct_drmjl`, and `r_via_julia` fixture routes.

Added four rows to
`docs/dev-log/dashboard/structured-re-q1-parity-fixture-contract.tsv`:

- `q1_sigma_spatial_gaussian_fixture`
- `q1_mu_sigma_spatial_gaussian_fixture`
- `q1_sigma_animal_gaussian_fixture`
- `q1_mu_sigma_animal_gaussian_fixture`

Updated the q-series authority rows for the corresponding spatial and animal
q1 `sigma` and matched `mu+sigma` intercept cells to
`bridge_status = fixture_parity`, `route = native_direct_bridge_fixture`, and
`denominator_policy = fixture_not_coverage`.

## 3a. Decisions and Rejected Alternatives

I kept this slice at the deterministic fixture tier. The runtime files already
show native coordinate-spatial and animal known-matrix point-fit/extractor
behavior, but this branch does not claim row-specific live bridge parity,
range-estimating spatial support, mesh/SPDE support, pedigree/Ainv bridge
marshalling, intervals, coverage, REML, AI-REML, or broad public support.

I did not add new runtime model routes. The supported code path already existed;
the gap was that q-series rows and q1 fixture inventory had not caught up for
the exact spatial and animal scale-side intercept cells.

## 4. Files Touched

- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q1-parity-fixture-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-q1-scale-provider-fixture-parity.md`

## 5. Checks Run

```sh
air format tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts|spatial-gaussian|animal-relmat-gaussian', stop_on_failure = TRUE)"
python3 tools/validate-mission-control.py
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-25-q1-scale-provider-fixture-parity.md
```

The focused R test command passed with 4,787 assertions, 0 failures, 0 warnings,
and 0 skips. `python3 tools/validate-mission-control.py` passed and reported 13
q1 parity-fixture rows. `git diff --check` passed. The after-task checker passed
for this report.

## 6. Tests of the Tests

The fixture test would fail if any spatial, animal, or relmat scale-side q1
payload lost provider metadata, changed estimator, changed matrix ID, omitted the
scale fixed coefficient, or failed deterministic native/direct/R-via-Julia
agreement.

The dashboard contract test would fail if the six provider scale-side q1 rows
were not marked covered/experimental, disappeared from the q1 acceptance
inventory, or lost provider-specific boundary wording for fixed-covariance
spatial, range-estimating spatial, A-matrix animal, pedigree/Ainv, K-matrix
relmat, or Q bridge marshalling.

## 7a. Issue Ledger

No GitHub issue or Ayumi-facing reply was created. This is a stacked drmTMB
q-series evidence slice.

## 8. Consistency Audit

The q1 parity sidecar, q-series support-cell table, dashboard README, design
map, and tests now agree that Gaussian q1 scale-side intercept fixture parity is
banked for spatial, animal, and relmat. The phylo rows were already present.
This gives q1 intercept scale-side fixture inventory balance without changing
interval, coverage, REML, AI-REML, q2, q4, q6, q8, or public support status.

## 9. What Did Not Go Smoothly

The main risk was over-reading native point-fit tests as bridge support. I kept
the rows explicitly at deterministic fixture parity and required the tests to
preserve provider-specific "remain separate" wording.

## 10. Known Residuals

Live bridge parity for spatial and animal scale-side q1 cells remains unbanked.
Range-estimating spatial, mesh/SPDE, pedigree/Ainv bridge marshalling, Q
precision bridge marshalling, calibrated interval diagnostics, coverage
denominators, REML, AI-REML, structured q6/q8, and broader public support remain
outside this slice.

## 11. Team Learning

Rose/Emmy: when one provider receives a fixture-parity correction, scan the
neighboring providers for the same drift. Fisher/Gauss: point-fit evidence and
fixture-parity evidence are useful but still below interval or coverage
readiness. Grace: mission-control row counts are a fast sanity check, but the
focused runtime tests still need to run for the providers named in the claim.
