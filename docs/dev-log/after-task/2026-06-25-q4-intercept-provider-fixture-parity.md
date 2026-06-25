# After Task: Q4 Intercept Provider Fixture Parity

## 1. Goal

Close the Gaussian q4 all-four intercept fixture gap for fixed-covariance
spatial, animal A-matrix, and relmat K-matrix provider cells without promoting
q4 interval reliability, q4 interval coverage, REML, AI-REML, broad bridge
support, public support, or provider-specific marshalling that is still
unbanked.

## 2. Implemented

Added deterministic q4 all-four intercept payload and parity-contract helpers
to `inst/sim/R/sim_structured_re_bridge_fixtures.R`. The payload records four
fixed endpoint intercept terms, four direct structured SD terms, and six
labelled structured correlation terms for the exact q4 endpoint map.

Added `tools/run-structured-re-q4-intercept-parity-fixture.R` and generated
`docs/dev-log/dashboard/structured-re-q4-intercept-parity-fixture.tsv` with
four provider rows for `phylo`, `spatial`, `animal`, and `relmat`.

Updated the spatial, animal, and relmat q4 all-four intercept support-cell rows
to `route = native_direct_bridge_fixture`,
`bridge_status = fixture_parity`, and
`denominator_policy = fixture_not_coverage`. The phylo support-cell row already
points at the older q4 parity acceptance gate, so this slice did not move that
authority row.

## 3a. Decisions and Rejected Alternatives

I treated q4 all-four intercepts as a separate support-cell family from q4
all-four one-slope cells. The one-slope cells are q8-shaped because they carry
eight endpoint members; the intercept cells are q4-shaped and carry fourteen
coefficient labels. Sharing the slope fixture would have hidden that difference.

I kept this at deterministic fixture parity. The change does not add live bridge
execution, interval diagnostics, coverage denominators, q4 REML, native-TMB q4
REML, q4 AI-REML, HSquared AI-REML, non-Gaussian REML, range-estimating spatial
support, pedigree/Ainv bridge marshalling, relmat Q bridge marshalling, broad
bridge support, public support, DRAC/Totoro execution, or an Ayumi-facing reply.

## 4. Files Touched

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-q4-intercept-parity-fixture.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-q4-intercept-parity-fixture.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-q4-intercept-provider-fixture-parity.md`

## 5. Checks Run

```sh
air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R tools/run-structured-re-q4-intercept-parity-fixture.R
Rscript --vanilla tools/run-structured-re-q4-intercept-parity-fixture.R
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts', stop_on_failure = TRUE)"
python3 tools/validate-mission-control.py
git diff --check
```

The focused R test command passed with 4,176 assertions, 0 failures, 0
warnings, and 0 skips. `python3 tools/validate-mission-control.py` passed and
reported 4 q4 intercept parity-fixture rows. `git diff --check` passed.

## 6. Tests of the Tests

The fixture test would fail if a q4 intercept payload changed dimension, lost
any of the four fixed endpoint intercept terms, lost any of the four structured
SD terms, lost any of the six structured correlation terms, changed provider
matrix metadata, or failed deterministic native/direct/R-via-Julia agreement.

The conversion-contract and mission-control tests would fail if the generated
TSV changed schema, lost provider-specific boundaries, promoted intervals or
coverage, or if the spatial, animal, and relmat q4 all-four intercept support
cells stopped pointing to the new fixture-parity evidence.

## 7a. Issue Ledger

No GitHub issue was opened or commented on. This is a narrow stacked q-series
evidence slice. No Ayumi-facing reply was drafted or sent.

## 8. Consistency Audit

The support-cell map, q4 intercept parity fixture sidecar, dashboard README,
design map, bridge fixture tests, conversion-contract tests, and
mission-control validator now agree on the same exact claim: spatial, animal,
and relmat q4 all-four intercept cells have deterministic same-target fixture
parity, while q4 intervals, coverage, REML, AI-REML, broad bridge support, and
public support remain unpromoted.

I also checked the neighboring q4 slope fixture lane. It remains separate
because its exact endpoint-member set is q8-shaped, not q4 intercept-shaped.

## 9. What Did Not Go Smoothly

The main sharp edge was avoiding a false equivalence between q4 intercepts and
q4 all-four one-slope cells. The validator now keeps their coefficient counts
separate: fourteen terms for q4 intercept fixtures and forty-four terms for q4
all-four one-slope fixtures.

## 10. Known Residuals

This slice does not supply calibrated interval diagnostics, finite interval
denominators, coverage-evaluable denominators, MCSE-calibrated coverage grids,
q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, non-Gaussian REML,
range-estimating spatial support, pedigree/Ainv bridge marshalling, relmat Q
bridge marshalling, broad bridge support, public support, or DRAC/Totoro
execution.

## 11. Team Learning

Ada/Emmy: keep q-dimension and endpoint-member count visible in every support
cell. Fisher/Gauss: fixture parity is useful point evidence, but it is still
below interval or coverage evidence. Rose/Grace: the validator should enforce
the exact coefficient count whenever a nearby q-cell could be mistaken for a
neighboring one.
