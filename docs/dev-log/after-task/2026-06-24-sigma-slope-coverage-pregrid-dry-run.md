# After Task: Sigma-Slope Coverage Pregrid Dry Run

## Goal

Freeze a dry-run manifest for a future sigma-only one-slope coverage pregrid
without executing coverage fits, submitting DRAC jobs, or promoting interval
reliability, calibrated coverage, REML, AI-REML, matched `mu+sigma` support,
q4/q8 support, broad bridge support, or SR150 readiness.

## Implemented

Added `tools/run-structured-re-sigma-slope-coverage-pregrid-dry-run.R`. The
script reads the sigma-only replicated-denominator rule and writes:

- `docs/dev-log/dashboard/structured-re-sigma-slope-coverage-pregrid-dry-run.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-coverage-pregrid-dry-run/structured-re-sigma-slope-coverage-pregrid-seed-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-coverage-pregrid-dry-run/structured-re-sigma-slope-coverage-pregrid-cell-manifest.tsv`

The dry run declares 150 seeds and 1050 not-executed target-replicate cells for
the seven eligible targets. Animal `sigma:x` remains a visible holdout and is
not included in the cell manifest.

## Mathematical Contract

The manifest is for future Gaussian sigma-only structured one-slope cells:

```r
y ~ x
sigma ~ provider(1 + x | group, K_or_source = ...)
```

At nominal coverage 0.95, 150 replicates give MCSE 0.017795. The 0.01 MCSE
threshold requires 475 replicates, so SR150 is not enough for coverage wording.

## Files Changed

- `tools/run-structured-re-sigma-slope-coverage-pregrid-dry-run.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/structured-re-sigma-slope-coverage-pregrid-dry-run.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-coverage-pregrid-dry-run/structured-re-sigma-slope-coverage-pregrid-seed-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-coverage-pregrid-dry-run/structured-re-sigma-slope-coverage-pregrid-cell-manifest.tsv`

## Checks Run

- `air format tools/run-structured-re-sigma-slope-coverage-pregrid-dry-run.R`
- `Rscript --vanilla tools/run-structured-re-sigma-slope-coverage-pregrid-dry-run.R`
- `air format tools/run-structured-re-sigma-slope-replicated-denominator-rule.R tools/run-structured-re-sigma-slope-coverage-pregrid-dry-run.R tests/testthat/test-structured-re-conversion-contracts.R`
- `python3 -m py_compile tools/validate-mission-control.py`
- `python3 tools/validate-mission-control.py`
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
- Sigma-only replicated-denominator/pregrid overclaim scan across dashboard,
  design, README, ROADMAP, NEWS, tests, and mission-control validator.
- `git diff --check`

All checks passed. Mission-control reported eight structured RE sigma-slope
coverage-pregrid dry-run rows, and the focused test completed with 2513
assertions.

## Tests Of The Tests

The new test locks the pregrid schema, seed sequence, seed role, 1050 cell rows,
seven eligible targets, one animal `sigma:x` holdout, not-executed execution
status, `coverage_evaluable = FALSE`, `coverage_status = not_evaluated`, and
unchanged linked q-series interval and coverage statuses.

## Consistency Audit

The dashboard README and q-series completion map now describe the dry-run as a
manifest only. They explicitly keep SR150 blocked because its nominal MCSE is
above 0.01.

## GitHub Issue Maintenance

No GitHub issue was opened or updated. The manifest is local planning evidence
inside the active q-series completion branch.

## What Did Not Go Smoothly

No execution issue arose. The key guard was making sure the animal `sigma:x`
holdout stayed out of the cell manifest even though it has stronger stability
probe evidence.

## Team Learning

A pregrid dry run should include both target-level rows and executable
target-replicate rows. That makes holdouts inspectable without accidentally
including them in future execution.

## Known Limitations

No coverage fits were run. This does not provide calibrated coverage,
coverage-evaluable denominator evidence, interval reliability, REML, AI-REML,
q4/q8 support, matched `mu+sigma` support, broad bridge support,
range-estimating spatial support, pedigree/Ainv bridge marshalling, relmat Q
bridge marshalling, DRAC execution, or SR150 readiness.

## Next Actions

Run focused validation and overclaim scans. The next implementation slice should
return to unfilled q-series runtime cells rather than executing this dry-run
manifest.
