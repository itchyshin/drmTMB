# After Task: Relmat Sigma One-Slope Fixture Parity

## Goal

Move exactly one structured residual-scale one-slope bridge evidence tier from
planned to deterministic fixture parity:

`relmat(1 + x | id, K = K)` in Gaussian `sigma`, ML, same-target native/direct
DRM.jl/R-via-Julia fixture.

## Implemented

- Added `phase18_structured_re_sigma_slope_payload_fixture()` for the relmat
  sigma one-slope cell only.
- Added `phase18_structured_re_sigma_slope_parity_fixture_contract()` with one
  row, `sigma_slope_relmat_same_target_ml`.
- Added the dashboard sidecar
  `docs/dev-log/dashboard/structured-re-sigma-slope-parity-fixture.tsv`.
- Moved only `qseries_relmat_q1_sigma_one_slope` to
  `bridge_status = fixture_parity`; phylo, spatial, and animal sigma one-slope
  bridge status remains planned.
- Updated the bridge-fixture test, q-series conversion contract,
  mission-control validator, dashboard README, check log, and q-series map.

## Mathematical Contract

The deterministic fixture records the same four-target coefficient order as the
native relmat sigma one-slope runtime cell:

```text
sigma:(Intercept)
sigma:x
sd_sigma:structured(Intercept)
sd_sigma:structured(x)
```

The matrix contract is a user covariance `K`. Runtime K/Q parity is supplied by
the native relmat sigma test, but this fixture itself is the K-matrix bridge
contract. It is not relmat Q bridge marshalling and not a matched `mu+sigma`
structured slope covariance cell.

## Files Changed

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-sigma-slope-parity-fixture.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

Results:

- `structured-re-bridge-fixtures` passed with 322 assertions.
- `structured-re-conversion-contracts` passed with 1509 assertions.
- `python3 tools/validate-mission-control.py` passed and reported 1 structured
  RE sigma-slope parity-fixture row.
- `git diff --check` passed.

## Tests Of The Tests

The new bridge-fixture test reconstructs native, direct DRM.jl, and R-via-Julia
fixture payloads and checks zero coefficient/log-likelihood deltas through
`phase18_structured_re_parity_status()`. It also checks that unsupported
provider expansion (`structured_type = "phylo"`) and REML requests error before
payload construction. The conversion test separately verifies that the TSV has
one relmat-only sigma row and that only the relmat sigma q-series cell moved to
`fixture_parity`.

## Consistency Audit

The q-series support-cell row now points to
`docs/dev-log/dashboard/structured-re-sigma-slope-parity-fixture.tsv`. The
mission-control validator reads the new sidecar, checks the relmat-only row,
requires the sigma coefficient order, and keeps interval and coverage statuses
planned.

## GitHub Issue Maintenance

No new GitHub issue was opened. The previous direct search for
`relmat sigma structured slope q-series` returned `[]`, and this fixture slice
is an internal evidence-tier update for the same relmat sigma cell.

## What Did Not Go Smoothly

The existing fixture helper was named around `mu` slopes. The cleanest small
move was to add a relmat-only sigma helper and a separate sidecar instead of
generalizing the whole fixture table before other providers have sigma fixture
rows.

## Team Learning

Endpoint-specific fixture sidecars are safer than widening a helper and then
trusting prose to keep claims narrow. The table itself now encodes that the
relmat sigma fixture exists while other sigma provider fixtures remain planned.

## Known Limitations

- No broad bridge support.
- No relmat Q bridge marshalling claim.
- No phylo, spatial, or animal sigma-slope fixture parity.
- No matched `mu+sigma` structured slope cells.
- No labelled structured slope covariance.
- No interval reliability or coverage.
- No REML, AI-REML, DRAC execution, or SR150 evidence.

## Next Actions

1. Add provider-specific sigma fixture rows only after each provider gets an
   explicit same-target fixture contract.
2. Add endpoint identity metadata before matched `mu+sigma` slope diagnostics.
3. Keep interval and coverage promotion blocked until calibrated denominator
   and MCSE evidence exist.
