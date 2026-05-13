# After Task: Slice 8F Hidden q=4 Profile-Target Scaffold

## Goal

Keep profile target naming aligned with the hidden q=4 `corpairs()` scaffold,
while still keeping q4 out of public fitted-model support.

## Implemented

`R/profile.R` now skips dormant covariance-block registry pairs whose
`tmb_parameter` or `tmb_index` fields are missing. This mirrors the
registry-backed `corpairs()` rule from Slice 8E and prevents guarded q > 2
registries from producing internal profile-target errors before the likelihood
path has fitted metadata to report.

`tests/testthat/test-profile-targets.R` now includes an internal fitted-like q=4
endpoint scaffold. The test attaches six q4 registry pair rows and matching
`corpars` entries to a bivariate Gaussian fit object, adds synthetic optimizer
parameter names to mark those targets as ready, and checks that
`profile_targets()` formats the six expected random-effect correlation targets.
It also checks `ready_only` filtering and a mixed registry where one pair is
fitted and the other five scaffold rows remain dormant.

`tests/testthat/test-covariance-block-registry.R` now includes the same
mixed-registry guard for `corpairs()`, closing Rose's residual-risk note from
Slice 8E.

## Team Roles

Ada integrated the slice. Emmy checked that `corpairs()` and
`profile_targets()` now share the same dormant-row rule. Curie checked the
focused target inventory and mixed-registry coverage. Rose's earlier mixed-row
risk is now covered by tests.

## Scope Boundary

This is not ordinary q4 fitted-model support. The production q4 likelihood path
still needs to populate registry pair metadata and `corpars` entries from real
fits. There is no public q > 2 formula syntax, no reader-facing example, and no
q6/q8 random-slope endpoint claim.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-8f-hidden-q4-profile-target-scaffold.md`

## Checks Run

- `Rscript -e 'devtools::test(filter =
  "profile-targets|covariance-block-registry")'`: passed with 388
  expectations, 0 failures, 0 warnings, and 0 skips.
- `air format R/profile.R tests/testthat/test-profile-targets.R
  tests/testthat/test-covariance-block-registry.R ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md
  docs/design/30-labelled-covariance-block-assembler.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-8f-hidden-q4-profile-target-scaffold.md`:
  passed.
- `git diff --check`: passed.

## Next Actions

1. Treat Slice 8 as internally complete enough for a push-and-Actions checkpoint,
   then begin the next slice on ordinary q4 fitted-path registry wiring or the
   phylogenetic q4 state, depending on review feedback.
