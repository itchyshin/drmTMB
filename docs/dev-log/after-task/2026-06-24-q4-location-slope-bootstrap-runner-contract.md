# q4 Location One-Slope Bootstrap Runner Contract

## Purpose

This slice turns the q4 location one-slope bootstrap dispatch plan into a
fail-closed dry-run runner contract. The goal is to make the selected
provider/target manifest, run log, and execution boundary explicit before any
Totoro or DRAC computation is approved.

## What Changed

- Added
  `tools/run-structured-re-q4-location-slope-bootstrap-denominator-runner.R`.
- Added
  `docs/dev-log/dashboard/structured-re-q4-location-slope-bootstrap-runner-contract.tsv`.
- Added
  `docs/dev-log/simulation-artifacts/2026-06-24-q4-location-slope-bootstrap-runner-contract/structured-re-q4-location-slope-bootstrap-runner-target-manifest.tsv`.
- Added
  `docs/dev-log/simulation-artifacts/2026-06-24-q4-location-slope-bootstrap-runner-contract/structured-re-q4-location-slope-bootstrap-runner-run-log.tsv`.
- Wired the runner-contract sidecar into mission-control validation and the
  focused structured random-effect conversion-contract tests.
- Updated the q-series completion map, dashboard README, and check log.

## Result

The runner validates the 16-row dry-run dispatch manifest for q4 location
direct-SD bootstrap targets: four endpoint members crossed with `phylo()`,
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`.
By default it writes all 16 selected targets and a one-row run log. Optional
`--provider=` and `--endpoint_member=` filters are available for future shard
selection, but the current artifact records the full target set.

The runner now treats the full 16-row contract as the reserved
`all-targets` shard. Provider-filtered dry-runs infer shard IDs such as
`provider-phylo` and write shard-specific manifest and run-log filenames
instead of overwriting the full contract artifacts. That gives the next
Totoro/DRAC review gate private dry-run files for each provider shard while
leaving the dashboard contract unchanged.

The contract is fail-closed. Only `--mode=dry-run` is implemented. A non-dry
run request exits before any refit work and reports that Totoro/DRAC execution
needs reviewed submission approval.

Every output row remains `scheduler_status = dry_run_not_submitted`,
`compute_status = not_executed`, `denominator_status = runner_contract_only`,
`coverage_evaluable = FALSE`, and `interval_claim_status = diagnostic_only`.

## Evidence

- `Rscript --vanilla tools/run-structured-re-q4-location-slope-bootstrap-denominator-runner.R`
  completed and wrote the dashboard sidecar, selected target manifest, and run
  log.
- `Rscript --vanilla tools/run-structured-re-q4-location-slope-bootstrap-denominator-runner.R --mode=execute`
  failed before execution as intended.
- Provider-filtered dry-runs for `phylo`, `spatial`, `animal`, and `relmat`
  wrote separate `provider-*` target manifests and run logs without replacing
  the 16-row dashboard contract.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 16
  structured RE q4 location slope bootstrap-runner contract rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with the new runner-contract test included.
- `git diff --check` passed.

## Boundary

This is dry-run runner-contract evidence only. It does not execute bootstrap
refits, submit Totoro jobs, submit DRAC jobs, admit all-target bootstrap
denominators, promote derived-correlation intervals, interval reliability,
interval coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML,
non-Gaussian REML, broad bridge support, public optimizer controls, public
support, partial location-scale support, Q precision marshalling, K/Q
same-target parity, broader q8 support, SR150 coverage readiness, or an
Ayumi-facing reply.

## Next Gate

Review the dry-run runner contract and selected manifest before execution. If
approved, execute one provider shard at a time, starting with Totoro unless a
reviewed DRAC/totoro submission plan is chosen. The execution artifact must
retain fit errors, nonconvergence, `pdHess = FALSE`, nonfinite intervals,
bootstrap refit attempts, and scheduler exit status before denominator
accounting or coverage-grid design.
