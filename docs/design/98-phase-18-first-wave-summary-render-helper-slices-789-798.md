# Phase 18 First-Wave Summary Render Helper Slices 789-798

Reader: `drmTMB` contributors checking that first-wave report staging can
orchestrate status outputs, table bundles, and optional HTML rendering from
grid-writer outputs.

Slices 789-798 validate the first-wave summary-report render helper. The helper
is already present in the current dirty tree: it writes artifact-status outputs,
writes first-wave table bundles, optionally renders the summary HTML, and
returns the staged paths.

## Source Evidence

- `phase18_render_first_wave_summary_report()` validates `output_dir`,
  `overwrite`, `render`, `require_complete`, and `notes`.
- It creates separate `status`, `tables`, and `report` directories under the
  requested output directory.
- It calls `phase18_write_first_wave_artifact_status()` and
  `phase18_write_first_wave_table_bundle()` before optional rendering.
- With `render = FALSE`, it stages status and table outputs without producing
  HTML.
- With `render = TRUE`, it checks for `rmarkdown` and Pandoc, renders
  `phase18-first-wave-summary-report.Rmd`, and rejects overwriting an existing
  report unless `overwrite = TRUE`.
- Tests cover staging-only mode, parameter construction, optional missing paths,
  HTML rendering, overwrite rejection, and malformed inputs.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 789-791 | Validate status/table staging orchestration | `phase18-first-wave-summary-render-helper` passed |
| 792-794 | Validate parameter mapping and optional paths | `phase18-first-wave-summary-render-helper` passed |
| 795-796 | Validate optional HTML render and overwrite boundary | `phase18-first-wave-summary-render-helper` passed |
| 797-798 | Validate malformed input boundaries | `phase18-first-wave-summary-render-helper` passed |

## Commands

```sh
nl -ba inst/sim/run/sim_render_first_wave_summary_report.R | sed -n '1,130p'
nl -ba tests/testthat/test-phase18-first-wave-summary-render-helper.R | sed -n '1,210p'
Rscript -e "devtools::test(filter = 'phase18-first-wave-summary-render-helper', reporter = 'summary')"
```

## Result

The focused first-wave summary-render helper test completed with exit code 0.
This closes Slices 789-798 as orchestration-helper validation. It does not add a
real multi-surface smoke run, public simulation article, final
operating-characteristic claim, formula grammar, likelihood code, roxygen
topics, or new user-facing API.
