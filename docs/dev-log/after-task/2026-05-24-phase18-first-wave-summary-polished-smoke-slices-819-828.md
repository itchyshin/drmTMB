# After Task: Phase 18 First-Wave Summary Polished Smoke Slices 819-828

## Goal

Validate and document the first-wave table-bundle provenance polish, including
the saved `slice-819` rendered summary smoke.

## Implemented

Added `docs/design/100-phase-18-first-wave-summary-polished-smoke-slices-819-828.md`
to record current source, test, and saved-artifact evidence. No likelihood,
formula grammar, public API, roxygen topic, pkgdown navigation, package site
output, or formal statistical claim changed.

## Mathematical Contract

No model changed. The checked contract is report-table provenance:
`source_surface` identifies the originating grid surface, and
`source_artifact` identifies the table type before rows from different grid
writers are combined.

## Files Changed

- `docs/design/100-phase-18-first-wave-summary-polished-smoke-slices-819-828.md`
- `docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-polished-smoke-slices-819-828.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
nl -ba inst/sim/run/sim_write_first_wave_table_bundle.R | sed -n '1,230p'
nl -ba tests/testthat/test-phase18-first-wave-table-bundle.R | sed -n '1,180p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-table-bundle|first-wave-summary-render-helper|first-wave-summary-report)', reporter = 'summary')"
Rscript -e "p <- 'inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv'; x <- read.csv(p, check.names = FALSE); cat('rows=', nrow(x), '\n', sep = ''); cat('first_cols=', paste(names(x)[seq_len(min(4L, ncol(x)))], collapse = ','), '\n', sep = '')"
rg -n "Slice 819|source_surface|source_artifact|gaussian_ls_grid|meta_v_grid|Aggregate Operating Characteristics|Interpretation Boundary" inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv inst/sim/results/slice-819-first-wave-summary-polished-smoke/first-wave-summary/tables/phase18-first-wave-wald-coverage.csv
```

Results:

- Source reads confirmed that combined first-wave tables carry
  `source_surface` and `source_artifact` before source-specific columns.
- The focused first-wave table-bundle, render-helper, and summary-report tests
  completed with exit code 0.
- The saved `slice-819` aggregate table has 13 rows; its first columns are
  `source_surface`, `source_artifact`, `surface`, and `cell_id`.
- The saved artifact-status CSV has 3 lines; aggregate and Wald-coverage bundle
  CSVs each have 14 lines including the header.
- Rendered HTML scans found `Slice 819`, `source_surface`, `source_artifact`,
  `gaussian_ls_grid`, `meta_v_grid`, aggregate operating characteristics, and
  the interpretation boundary.
- No files were staged or committed.

## Tests Of The Tests

The table-bundle test checks column order, heterogeneous aggregate columns,
empty failure tables, missing artifacts, overwrite protection, and malformed
input paths. The render-helper and summary-report tests protect downstream
consumers of the bundled tables.

## Consistency Audit

This report validates provenance and report readability only. It does not make
new model-support, likelihood, formula-grammar, or operating-characteristic
claims. The saved `slice-819` artifact remains the historical Gaussian
location-scale plus `meta_V(V = V)` smoke; expanded multi-surface runner output
belongs to later slices.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

The current reusable smoke runner has expanded since the saved `slice-819`
artifact was created. This report names the saved artifact and current table
contract separately so the provenance validation is not overstated.

## Team Learning

First-wave report tables should lead with provenance columns whenever rows from
multiple surfaces are combined. Rose should keep this as a standing check for
future report polish slices.

## Known Limitations

The saved `slice-819` smoke is not a formal simulation run. It does not cover
the later count, random-slope, or spatial first-wave surfaces.

## Next Actions

Continue with Slices 829-838 by validating the count `mu` random-effect summary
smoke if the current dirty tree contains matching evidence.
