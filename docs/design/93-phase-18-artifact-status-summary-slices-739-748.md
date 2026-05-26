# Phase 18 Artifact-Status Summary Slices 739-748

Reader: `drmTMB` contributors checking that first-wave report staging can turn
per-writer artifact manifests into a surface-level status summary before any
report consumes simulation tables.

Slices 739-748 validate manifest binding and surface-level artifact status
summaries. The implementation is already present in the current dirty tree:
manifest helpers bind artifact rows from data frames or full grid-writer
outputs, then summarize present, missing, empty, and total CSV rows by surface.

## Source Evidence

- `phase18_bind_grid_artifact_manifests()` accepts artifact-manifest data
  frames or grid-writer result objects, validates required columns, binds rows,
  and labels them with `artifact_grain = "grid_artifact_manifest"`.
- `phase18_extract_grid_artifact_manifest()` rejects objects that do not carry
  an artifact manifest.
- `phase18_summarise_grid_artifact_manifests()` validates required columns and
  computes `n_artifact`, `n_present`, `n_missing`, `n_empty_csv`, and
  `n_total_csv_rows` by surface.
- `phase18_write_first_wave_artifact_status()` exercises the same binding and
  status-summary helpers before writing the bound manifest and status tables.
- Tests cover a present zero-row CSV, a missing optional CSV, malformed
  manifest input, malformed status input, persisted manifest/status CSV row
  counts, overwrite rejection, overwrite replacement, and input validation.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 739-741 | Validate manifest extraction and binding | `phase18-sim-runner` binding tests passed |
| 742-744 | Validate surface-level present/missing/empty summaries | `phase18-sim-runner` status tests passed |
| 745-746 | Validate persisted first-wave status-smoke rows | `phase18-first-wave-artifact-status` passed |
| 747-748 | Validate malformed input and overwrite boundaries | `phase18-first-wave-artifact-status` passed |

## Commands

```sh
nl -ba inst/sim/R/sim_runner.R | sed -n '565,635p'
nl -ba inst/sim/run/sim_write_first_wave_artifact_status.R | sed -n '1,80p'
nl -ba tests/testthat/test-phase18-first-wave-artifact-status.R | sed -n '1,110p'
nl -ba tests/testthat/test-phase18-sim-runner.R | sed -n '286,337p'
Rscript -e "devtools::test(filter = 'phase18-(sim-runner|first-wave-artifact-status)', reporter = 'summary')"
```

## Result

The focused manifest-binding/status bundle completed with exit code 0. The
passing files were:

- `phase18-first-wave-artifact-status`
- `phase18-sim-runner`

This closes Slices 739-748 as first-wave artifact-status summary validation. It
does not add report rendering, table-bundle consumption, automatic broad grid
execution, formula grammar, likelihood code, roxygen topics, or new user-facing
API.
