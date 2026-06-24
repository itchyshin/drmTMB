# After Task: Structured Mu-Slope Phylo Parity Fixture

## Goal

Bank the first same-target bridge/parity fixture for the q-series one-slope
Gaussian structured `mu` lane. The exact cell is
`phylo(1 + x | species, tree = tree)` with ML estimation and one independent
structured location slope.

This task was deliberately narrow. It turns the already-audited phylo
one-slope artifact evidence into a deterministic native/direct/R-via-Julia
fixture contract, while leaving `spatial()`, `animal()`, and `relmat()` as
planned rows.

## Implemented

- Added `phase18_structured_re_mu_slope_payload_fixture()` for the exact
  phylo one-slope `mu` ML payload.
- Added `phase18_structured_re_mu_slope_parity_fixture_contract()` with one
  implemented phylo row and planned `spatial()`, `animal()`, and `relmat()`
  rows.
- Added `docs/dev-log/dashboard/structured-re-mu-slope-parity-fixture.tsv`.
- Updated `qseries_phylo_q1_mu_one_slope` in
  `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` to mark
  `bridge_status = fixture_parity` for the exact deterministic fixture only.
- Wired the new sidecar into `tools/validate-mission-control.py`.
- Added an R dashboard contract test that keeps the phylo row at
  `fixture_parity` and the non-phylo rows at `planned`.
- Updated `docs/design/218-structured-q-series-completion-map.md` and
  `docs/dev-log/dashboard/README.md` so narrative status follows the new
  sidecar.
- Updated `docs/dev-log/check-log.md` with the checks and next-slice plan.

## Mathematical Contract

The fixture is a deterministic same-target contract. It verifies that the
native, direct DRM.jl, and R-via-Julia reconstructions use the same coefficient
order:

`mu:(Intercept);mu:x;sd_mu:structured(Intercept);sd_mu:structured(x)`.

It is not a new likelihood derivation, not a calibrated simulation result, and
not an interval or coverage result. It does not imply residual-scale
structured slopes, labelled structured slope covariance, structured q4/q6/q8
slope support, REML, or AI-REML.

## Files Changed

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-mu-slope-parity-fixture.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tools/validate-mission-control.py`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-structured-mu-slope-phylo-parity-fixture.md`

This work sits on the existing dirty PR #638 stack. No files were staged or
committed.

## Checks Run

- `air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R`
- `python3 -m py_compile tools/validate-mission-control.py`
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"`
  passed with 277 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1480 assertions.
- `python3 -m py_compile tools/validate-mission-control.py && rm -rf tools/__pycache__`
  passed.
- `python3 tools/validate-mission-control.py` passed and reports 69 structured
  RE q-series cells, 4 structured RE mu-slope audit rows, and 4 structured RE
  mu-slope parity-fixture rows.
- `git diff --check` passed.
- `gh pr checks 638 --repo itchyshin/drmTMB --json name,state,workflow,link,bucket`
  showed Ubuntu, macOS, and Windows R-CMD-check jobs passing.
- `gh pr view 638 --repo itchyshin/drmTMB --json title,isDraft,headRefOid,mergeStateStatus,url`
  showed PR #638 is draft, merge-clean, and at head
  `009528d609519039bb8df13d84db779408f06499`.

## Tests Of The Tests

The bridge-fixture test reconstructs the phylo same-target payload through
native, direct DRM.jl, and R-via-Julia routes, then checks zero coefficient and
log-likelihood deltas. It also asserts that non-phylo payload requests still
error as design rows.

The dashboard conversion test reads the TSV sidecar and verifies the
implemented/planned split: phylo is `fixture_parity`, while spatial, animal,
and relmat remain `planned`.

## Consistency Audit

The q-series support-cell row now points to the parity-fixture sidecar for the
exact phylo one-slope `mu` cell. The dashboard README, design note, R helper,
R tests, Python validator, check-log, and after-task report all use the same
boundary: one deterministic phylo same-target fixture, no broader support
claim.

## GitHub Issue Maintenance

No GitHub issue, PR body, PR comment, or Ayumi-facing reply was created or
updated. PR #638 remains draft.

## What Did Not Go Smoothly

The first validator pass failed because the relmat planned row did not state
the implementation gate with the exact required wording. The fix was to tighten
the row, not weaken the validator. The R-side contract was then aligned to the
same relmat next-gate text.

## Team Learning

Same-target parity fixtures should be provider-specific. A source-tested
artifact writer can tell us a cell is worth attempting, but it should not
promote the bridge row until the native/direct/R-via-Julia coefficient order,
matrix source, and route boundary are explicit.

## Known Limitations

This slice does not add broad structured bridge support, `sigma` slope support,
labelled structured slope covariance, structured q4/q6/q8 slopes, q4 interval
reliability, q4 interval coverage, q4 native-TMB REML, q4 AI-REML,
HSquared AI-REML, non-Gaussian AI-REML, public optimizer controls, DRAC
execution, or SR150 evidence.

## Next Actions

1. Implement the fixed-covariance `spatial()` same-target one-slope `mu`
   native/direct/R-via-Julia fixture.
2. Add the `animal()` A-matrix same-target one-slope `mu` fixture.
3. Resolve the relmat K-versus-Q source boundary before adding the relmat
   same-target one-slope `mu` fixture.
4. Keep `sigma` one-slope cells separate until the exact `mu` provider
   fixtures are banked.
