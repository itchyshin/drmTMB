# Phase 18 Artifact-Grain Preflight

## Task Goal

Add a conservative first-wave report-staging check for issue #255 so Phase 18
simulation reports can tell which artifacts are replicate-ready before any
replicate-error clouds are drawn.

## Files Changed

- `inst/sim/run/sim_write_first_wave_table_bundle.R` now writes
  `phase18-first-wave-artifact-grain-status.csv` beside the bundled artifact
  tables.
- `inst/sim/run/sim_render_first_wave_summary_report.R` passes the grain-status
  CSV path into the summary-report parameters.
- `inst/sim/reports/phase18-first-wave-summary-report.Rmd` reads and displays
  the artifact-grain status table before aggregate operating characteristics.
- `tests/testthat/test-phase18-first-wave-table-bundle.R` covers replicate,
  aggregate, missing, empty, mixed-grain, and missing-grain classifications.
- `tests/testthat/test-phase18-first-wave-summary-render-helper.R` checks the
  new path and parameter wiring.
- `inst/sim/README.md`, `docs/design/41-phase-18-simulation-programme.md`,
  `ROADMAP.md`, and `docs/dev-log/check-log.md` record the new preflight.

## Checks Run

```sh
Rscript --vanilla -e "files <- c('inst/sim/run/sim_write_first_wave_table_bundle.R', 'inst/sim/run/sim_render_first_wave_summary_report.R'); invisible(lapply(files, parse)); cat('ok parse\n')"
Rscript --vanilla -e "devtools::test(filter = '^phase18-first-wave-table-bundle$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^phase18-first-wave-(table-bundle|summary-render-helper)$', reporter = 'summary')"
air format inst/sim/run/sim_write_first_wave_table_bundle.R inst/sim/run/sim_render_first_wave_summary_report.R tests/testthat/test-phase18-first-wave-table-bundle.R tests/testthat/test-phase18-first-wave-summary-render-helper.R inst/sim/reports/phase18-first-wave-summary-report.Rmd inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-phase18-artifact-grain-preflight.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n "phase18-first-wave-artifact-grain-status|artifact-grain status|artifact_grain|replicate-error clouds|fake.*cloud|pseudo-replicate|aggregate-only" inst/sim README.md ROADMAP.md NEWS.md docs vignettes tests/testthat
git diff --check
```

Outcomes:

- The parse check passed.
- The focused table-bundle package test passed after the current worktree was
  loaded.
- The adjacent table-bundle plus summary-render-helper tests passed before and
  after formatting.
- `air format` completed with no output.
- `pkgdown::check_pkgdown()` returned `No problems found`.
- The artifact-grain stale-wording scan found the new preflight language plus
  older historical pseudo-replicate audit notes; no current report wording
  claims aggregate rows can produce replicate clouds.
- `git diff --check` passed.

## Consistency Audit

The new preflight keeps Phase 18 report staging conservative:

- `artifact_grain = "replicate"` becomes `grain_status = "replicate_ready"` and
  `plot_geometry = "replicate_clouds_allowed"`.
- `artifact_grain = "aggregate"` becomes `grain_status = "aggregate_only"` and
  `plot_geometry = "aggregate_points_bars_mcse_only"`.
- Missing, empty, mixed-grain, and untagged artifacts do not permit replicate
  clouds.

The change does not add a new family, likelihood, formula grammar, or
missing-data handling. It does not dispatch simulations or promote operating
characteristic evidence.

## Tests Of The Tests

The grain-status tests use synthetic CSVs for the intended cases instead of
checking only object class:

- aggregate CSV with `artifact_grain = "aggregate"`;
- replicate CSV with `artifact_grain = "replicate"`;
- mixed CSV with both aggregate and replicate grain values;
- legacy CSV with no `artifact_grain` column;
- empty CSV with zero rows;
- absent artifact path.

The render-helper test verifies that the staged grain-status path exists and is
passed through `phase18_first_wave_summary_report_params()`.

## What Did Not Go Smoothly

A direct `testthat::test_file()` run first sourced the installed package copy
via `system.file()`, so it exercised stale code and failed. The package-level
`devtools::test()` path loaded the current worktree and passed. This is a test
invocation issue, not a package-code failure.

## Team Learning And Process Improvements

The first-wave table bundle is now the right place for display-grain preflight
because it already sees every selected source artifact before report rendering.
Future report helpers should consume the grain-status CSV rather than
re-reading arbitrary table files and guessing whether clouds are allowed.

## Design And Documentation Updates

The Phase 18 README and design note now state that table bundling writes the
artifact-grain status preflight. ROADMAP row 1829 records the slice as a
staging gate, not as new simulation evidence.

## pkgdown And Site Updates

No pkgdown navigation changed. The affected files are internal simulation
infrastructure, report templates, and design/dev-log documentation.

## GitHub Issue Maintenance

This slice directly advances issue #255 by adding a concrete preflight artifact
for the replicate-level versus aggregate-only display boundary. PR #458 was
opened with `Refs #255`, and issue #255 received a sync comment with the PR link
and the remaining boundary. The issue stays open because broader first-wave
report and figure consumers still need to use the preflight in rendered
simulation outputs.

## Known Limitations And Next Actions

- The status table is a preflight artifact; it does not repair missing
  `artifact_grain` columns.
- The current summary report displays the grain status but does not yet create
  a final Florence-reviewed replicate-error figure.
- A later slice should make first-wave figure helpers require
  `grain_status = "replicate_ready"` before drawing clouds.
