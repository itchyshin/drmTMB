# Slice 224 Result Directory Scan

## Goal

Allow Phase 18 saved replicate directories to be audited after a resumable run.

## What Changed

- Added `phase18_read_result_dir()` to `inst/sim/R/sim_runner.R`.
- The helper recursively reads saved `.rds` replicate results, sorts paths for
  stable output, validates each object against the manifest contract, and keeps
  the source path on each loaded result.
- Added tests showing that manifests and warning/error ledgers can be rebuilt
  from saved result files.

## Checks

- `air format inst/sim/R/sim_runner.R tests/testthat/test-phase18-sim-runner.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-224-result-directory-scan.md`
- `Rscript -e "devtools::test(filter = 'phase18-sim-runner', reporter = 'summary')"`
- `git diff --check`

## Limitations

The loader reads result objects from disk but does not yet classify optimizer
root causes, parse diagnostics, or discover aggregate CSV files. It is the disk
bridge for manifests and failure ledgers, not a full report generator.

## Standing Roles

Grace pushed for resumable-run auditability. Rose kept the path from saved RDS
files to visible failures explicit. Curie covered directory validation and
disk-read tests. Fisher kept the loader separate from denominator-based
simulation metrics. Ada kept the slice small enough to stack behind the current
Phase 18 PR queue.
