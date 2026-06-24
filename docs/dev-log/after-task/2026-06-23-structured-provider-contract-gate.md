# After Task: Structured Provider-Contract Gate

## Goal

Bank the provider-contract layer for the structured random-effect q-series
completion map before adding new runtime q-cells. This slice makes
`structured_effects()` expose the fitted provider/observed level relationship,
input scale, missing-level policy, and bridge-marshalling boundary for
`phylo()`, `spatial()`, `animal()`, `relmat()`, and `phylo_interaction()`.

## Implemented

- Extended `structured_effects()` with `input_scale`, `level_alignment`,
  `missing_level_policy`, `bridge_marshalling`, `provenance_contract`,
  `provider_level_count`, `observed_level_count`, `provider_levels`, and
  `observed_levels`.
- Added provider contract helpers for tree branch-length inputs, fixed
  coordinate covariance, pedigree/A/Ainv inputs, K/Q relatedness inputs, and
  tree-pair phylogenetic interactions.
- Extended `tests/testthat/test-structured-effects.R` so each provider proves
  matrix identity, level alignment, input scale, missing-level policy,
  bridge-marshalling status, and provider-versus-observed level accounting.
- Verified the current one independent Gaussian structured `mu` slope extractor
  identity for `phylo(1 + x | species, tree = tree)`,
  `spatial(1 + x | site, coords = coords)`,
  `animal(1 + x | id, A = A)`, and `relmat(1 + x | id, K = K)`.
- Extended q2 payload provenance rows with `matrix_slot`, `input_scale`,
  `missing_level_policy`, and `bridge_marshalling`.
- Updated the mission-control validator, q-series support-cell map, NEWS,
  dashboard README, check log, and `structured_effects()` Rd output.

## Mathematical Contract

This slice does not change a likelihood, estimator, or TMB parameterization. It
records the provider contract already implied by a fitted structured marker:
which object supplied the structured relationship, whether that object was a
covariance, precision, coordinate table, tree, pedigree, or tree pair, and
whether the observed levels are equal to or a subset of the provider levels.

The contract remains provenance evidence. It is not interval evidence, coverage
evidence, REML evidence, or public bridge support.

## Files Changed

- `NEWS.md`
- `R/methods.R`
- `man/structured_effects.Rd`
- `tests/testthat/test-structured-effects.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tools/validate-mission-control.py`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-q2-payload-provenance.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-structured-provider-contract-gate.md`

This work sits on the existing dirty PR #638 stack. No files were staged or
committed.

## Checks Run

- `air format R/methods.R tests/testthat/test-structured-effects.R tests/testthat/test-structured-re-bridge-fixtures.R inst/sim/R/sim_structured_re_bridge_fixtures.R` passed.
- `air format tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `Rscript --vanilla -e "devtools::document()"` passed; unrelated generated
  Rd churn was manually removed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-effects')"`
  passed with 268 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"`
  passed with 260 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1470 assertions.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and still reports 69
  structured RE q-series cells.
- `git diff --check` passed.

## Tests Of The Tests

The first bridge-fixture rerun failed because the test expected every
missing-level policy to start with `error_if_observed`, but the spatial row
correctly names its coordinate-specific rule:
`error_if_coords_missing_observed_group_or_vary_within_group`. The test now
asserts the exact four provider policies.

The conversion-contract rerun failed because its expected q2 payload
provenance schema still omitted the four new contract columns. The test now
requires those columns, so a future sidecar drift will fail loudly.

## Consistency Audit

`docs/design/218-structured-q-series-completion-map.md` now marks the provider
contract gate as banked and clarifies that one-slope `mu` support is verified at
extractor level only. The q-series support-cell rows for `phylo()`,
`spatial()`, `animal()`, `relmat()`, and `phylo_interaction()` point at the
focused extractor tests, while `bridge_status`, `interval_status`, and
`coverage_status` remain unchanged.

`docs/dev-log/dashboard/README.md` now describes the q2 payload provenance
columns as matrix-slot, input-scale, missing-level-policy, and
bridge-marshalling evidence. `NEWS.md` and `man/structured_effects.Rd` name the
new `structured_effects()` metadata fields without promoting runtime support.

## GitHub Issue Maintenance

No GitHub issue, PR body, PR comment, or Ayumi-facing reply was created or
updated. PR #638 remains draft.

## What Did Not Go Smoothly

`devtools::document()` rewrote unrelated Rd files because the local roxygen
version differs from the repository baseline. Those unrelated changes were
removed manually, keeping only `man/structured_effects.Rd`.

## Team Learning

Provider contracts need to name two identities separately: the user-facing
input object and the resolved fitted precision. A covariance route and a
precision route can share the same downstream precision fingerprint while still
having different bridge and provenance obligations.

## Known Limitations

This slice does not add residual-scale structured slopes, labelled structured
slope covariance, structured q4 slope blocks, structured q6/q8 support, broad
R bridge support, q4 interval reliability, q4 interval coverage, q4
native-TMB REML, q4 AI-REML, HSquared AI-REML, non-Gaussian AI-REML, or SR150.

## Next Actions

Continue with fixture parity for the exact one independent structured `mu`
slope cells. After that, evaluate `sigma` one-slope cells as separate rows
rather than borrowing evidence from `mu` or from matched q4/q1-plus-q1 examples.
