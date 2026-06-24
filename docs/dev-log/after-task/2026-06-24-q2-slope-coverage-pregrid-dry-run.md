# After Task: Q2 Slope Coverage Pregrid Dry Run

## Goal

Freeze the executable manifest shape for a future bivariate Gaussian
structured q2 slope coverage pre-grid, without running coverage fits,
submitting DRAC jobs, or promoting interval reliability, calibrated coverage,
REML, AI-REML, q4/q8, SR150 readiness, or broad bridge support.

## Implemented

- Added `tools/run-structured-re-q2-slope-coverage-pregrid-dry-run.R`, a
  rerunnable dry-run manifest generator.
- Wrote
  `docs/dev-log/dashboard/structured-re-q2-slope-coverage-pregrid-dry-run.tsv`
  with 12 target rows.
- Wrote
  `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-coverage-pregrid-dry-run/structured-re-q2-slope-coverage-pregrid-seed-manifest.tsv`
  with 150 predeclared seeds.
- Wrote
  `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-coverage-pregrid-dry-run/structured-re-q2-slope-coverage-pregrid-cell-manifest.tsv`
  with 1500 target-by-seed dry-run cells for the 10 currently eligible
  targets.
- Wired the sidecar and manifests into `tools/validate-mission-control.py` and
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Updated the dashboard README, q-series completion map, and check log.

## Mathematical Contract

The dry run inherits target admission from
`structured-re-q2-slope-replicated-denominator-rule.tsv`. Ten targets are
included in the executable cell manifest with 150 planned replicates each. The
animal and relmat correlation targets remain visible holdouts with zero
planned cells until their earlier smoke endpoint-profile failures are
reconciled.

The dry run records the MCSE arithmetic before any coverage run:

```text
nominal_mcse_at_150 = sqrt(0.95 * 0.05 / 150) = 0.017795
replicates_for_mcse_threshold = ceiling(0.95 * 0.05 / 0.01^2) = 475
```

Therefore SR150 can be a local pre-grid only; it is not enough for 0.01-MCSE
coverage wording at nominal 0.95 coverage.

## Files Changed

- `tools/run-structured-re-q2-slope-coverage-pregrid-dry-run.R`
- `docs/dev-log/dashboard/structured-re-q2-slope-coverage-pregrid-dry-run.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-coverage-pregrid-dry-run/structured-re-q2-slope-coverage-pregrid-seed-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-coverage-pregrid-dry-run/structured-re-q2-slope-coverage-pregrid-cell-manifest.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-q2-slope-coverage-pregrid-dry-run.R
air format tools/run-structured-re-q2-slope-coverage-pregrid-dry-run.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

## Evidence Result

The generator wrote 12 dashboard rows, 150 seed-manifest rows, and 1500
cell-manifest rows. Ten targets are `pregrid_target` rows with 150 planned
cells each. The animal and relmat correlation targets are `visible_holdout`
rows with zero planned cells. Every dashboard and cell-manifest row keeps
`execution_status = not_executed`, `coverage_evaluable = FALSE`, and
`coverage_status = not_evaluated`.

## Tests Of The Tests

The R conversion-contract test checks the 12-row dashboard sidecar, the
150-row seed manifest, the 1500-row cell manifest, the 10/2 target/holdout
split, the 730001..730150 seed range, the absence of held-out targets from the
cell manifest, the MCSE arithmetic, and unchanged q-series interval, coverage,
and denominator-policy statuses. The Python validator independently checks
the same manifest sizes, exact source paths, target identities,
provider-specific claim boundaries, and non-execution status.

## Consistency Audit

The dashboard README and q-series completion map call this an execution
planning dry run, not coverage evidence. The artifact explicitly records that
SR150 is not enough for the 0.01 MCSE threshold and does not move q2 support
cell coverage or interval status.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is internal q-series evidence-ladder
work.

## What Did Not Go Smoothly

The only correction was numerical: the MCSE replicate threshold needs a stable
analytic value of 475 replicates, not a floating-point-rounded 476. The
generator now subtracts a tiny tolerance before `ceiling()` so the manifest
stays mathematically stable.

## Team Learning

Pre-grid manifests should record both their executable shape and their
insufficiency for support claims. That prevents a dry-run seed count from
turning into accidental coverage language later.

## Known Limitations

This slice does not execute any coverage cells. It does not provide calibrated
coverage, coverage MCSE, interval reliability, REML, AI-REML, broad bridge
support, range-estimating spatial support, pedigree/Ainv bridge marshalling,
relmat Q bridge marshalling, intercept-plus-slope q4/q8 structured slope
support, two-slope support, or non-Gaussian structured slope support.

## Next Actions

Review whether the q2 pre-grid should run locally in a very small rehearsal
first, or whether the next runtime slice should return to structured sigma
one-slope intervals. Keep SR150 blocked until executed denominator evidence
and MCSE-calibrated coverage evidence exist.
