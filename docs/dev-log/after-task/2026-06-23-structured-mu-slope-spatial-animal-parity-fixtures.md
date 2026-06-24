# After Task: Structured Mu-Slope Spatial And Animal Parity Fixtures

## Goal

Extend the one-slope Gaussian structured `mu` parity-fixture lane from
`phylo()` to the next provider-safe cells: fixed-covariance `spatial()` and
A-matrix `animal()`.

The task also had to decide whether relmat could be promoted in the same pass.
It could not. The current Phase 18 relmat artifact fit uses
`relmat(1 + x | id, Q = Q)`, while the R-via-Julia bridge contract marshals
`relmat(1 + x | id, K = K)` only. That K-versus-Q boundary stays visible in
the dashboard.

## Implemented

- Updated `phase18_structured_re_mu_slope_payload_fixture()` so it accepts
  `phylo`, fixed-covariance `spatial`, and A-matrix `animal` one-slope `mu`
  fixtures.
- Kept `relmat` rejected by the payload helper with an explicit K-versus-Q
  message.
- Updated `phase18_structured_re_mu_slope_parity_fixture_contract()` so phylo,
  spatial, and animal are `fixture_parity`, while relmat remains `planned`.
- Updated `docs/dev-log/dashboard/structured-re-mu-slope-parity-fixture.tsv`.
- Promoted `qseries_spatial_q1_mu_one_slope` and
  `qseries_animal_q1_mu_one_slope` to fixture parity in
  `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`.
- Tightened `tools/validate-mission-control.py` so spatial and animal rows must
  be fixture rows and relmat must keep the K/Q next gate.
- Updated the R bridge-fixture and dashboard contract tests.
- Updated the dashboard README and q-series design note.
- Updated `docs/dev-log/check-log.md`.

## Mathematical Contract

The implemented contract is deterministic same-target parity for one
independent structured location (`mu`) slope. For phylo, fixed-covariance
spatial, and A-matrix animal, the native, direct DRM.jl, and R-via-Julia
fixture routes share this coefficient order:

`mu:(Intercept);mu:x;sd_mu:structured(Intercept);sd_mu:structured(x)`.

The contract does not estimate interval reliability or coverage. It does not
add residual-scale (`sigma`) structured slopes, labelled structured slope
covariance, structured q4/q6/q8 slopes, REML, or AI-REML.

## Files Changed

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-mu-slope-parity-fixture.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-structured-mu-slope-spatial-animal-parity-fixtures.md`

This work sits on the existing dirty PR #638 stack. No files were staged or
committed.

## Checks Run

- `git status --short --branch` showed the expected dirty PR #638 stack.
- `git diff --check` passed before and after the slice.
- `air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"`
  passed with 293 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1481 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'phase18-spatial-mu-slope')"`
  passed with 30 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'phase18-animal-mu-slope')"`
  passed with 48 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'phase18-relmat-mu-slope')"`
  passed with 48 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-effects')"`
  passed with 268 assertions.
- `python3 -m py_compile tools/validate-mission-control.py && rm -rf tools/__pycache__`
  passed.
- `python3 tools/validate-mission-control.py` passed and reports 69 structured
  RE q-series cells, 4 structured RE mu-slope audit rows, and 4 structured RE
  mu-slope parity-fixture rows.
- `gh pr checks 638 --repo itchyshin/drmTMB --json name,state,workflow,link,bucket`
  showed Ubuntu, macOS, and Windows R-CMD-check jobs passing.
- `gh pr view 638 --repo itchyshin/drmTMB --json title,isDraft,headRefOid,mergeStateStatus,url`
  showed PR #638 is draft, merge-clean, and at head
  `009528d609519039bb8df13d84db779408f06499`.

## Tests Of The Tests

The bridge-fixture test loops over phylo, spatial, and animal, reconstructs the
native, direct DRM.jl, and R-via-Julia payloads, and checks zero coefficient
and log-likelihood deltas. It also checks that relmat still errors with the
K-versus-Q boundary.

The dashboard conversion test reads the TSV sidecar and verifies the split:
phylo, spatial, and animal are `fixture_parity`, while relmat remains
`planned`.

The provider artifact tests verify the source-tested DGP/smoke/grid lanes for
spatial, animal, and relmat. The relmat test is deliberately evidence for the
current source route, not bridge-parity promotion.

## Consistency Audit

Task-specific stale-wording scans found no remaining text saying spatial or
animal one-slope `mu` parity remains planned. The relmat scan confirmed the
intended split: `R/methods.R` records `K` as the bridge-marshalled covariance
fixture and `Q` as native-TMB-only precision; `phase18_fit_relmat_mu_slope()`
currently fits the Phase 18 artifact through `Q`.

The dashboard README, design note, q-series support-cell table, parity sidecar,
validator, R helper, R tests, check-log, and this after-task report now say the
same thing.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --search "structured slope relmat mu slope"`
found existing open umbrellas #147, #33, and #491. No new issue was opened and
no issue or PR comment was posted.

## What Did Not Go Smoothly

Relmat looked tempting because the DGP stores both `K` and `Q`, but the
source-tested fit uses `Q` and the bridge contract marshals `K`. Promoting it
would have hidden the exact evidence gap that the q-series support-cell map is
supposed to expose.

## Team Learning

Provider parity rows should name the matrix source they actually validate.
For structured slopes, "relmat support" is too vague: K-covariance bridge
parity and Q-precision native-TMB artifacts are different cells until a
same-target fixture ties them together.

## Known Limitations

This slice does not add broad structured bridge support, range-estimating
spatial support, mesh/SPDE support, pedigree/Ainv bridge marshalling, relmat
K/Q bridge parity, `sigma` slope support, labelled structured slope
covariance, structured q4/q6/q8 slopes, q4 interval reliability, q4 interval
coverage, q4 native-TMB REML, q4 AI-REML, HSquared AI-REML, non-Gaussian
AI-REML, public optimizer controls, DRAC execution, or SR150 evidence.

## Next Actions

1. Add a same-target relmat K-covariance fixture, or add a paired K/Q
   reconciliation fixture, before changing relmat bridge status.
2. Start the separate `sigma` one-slope tranche only after deciding whether
   relmat K/Q parity belongs in this PR or a follow-up.
3. Keep interval and coverage rows planned until calibrated denominator and
   MCSE evidence exists.
