# Phase 18 First-Wave Table Bundle Slices 769-778

Reader: `drmTMB` contributors checking that first-wave report staging can
combine selected CSV artifacts across grid outputs without losing provenance.

Slices 769-778 validate the first-wave table-bundle writer. The implementation
is already present in the current dirty tree: selected artifact CSVs are read
from grid-writer outputs, row-bound with missing columns filled by `NA`, written
as bundle CSVs, and returned with `source_surface` and `source_artifact`
columns first.

## Source Evidence

- `phase18_first_wave_table_artifacts()` lists the default artifact names the
  bundle can collect.
- `phase18_write_first_wave_table_bundle()` validates `output_dir`,
  `overwrite`, `grid_outputs`, and `artifacts`, writes one bundle CSV per
  selected artifact, and returns an artifact manifest for the bundle itself.
- `phase18_collect_first_wave_table()` skips missing files and zero-row tables
  while returning a stable empty table with provenance columns when nothing can
  be collected.
- `phase18_row_bind_fill()` row-binds heterogeneous tables, fills missing
  columns with `NA`, and keeps `source_surface` and `source_artifact` first.
- Tests cover two aggregate tables with different metric columns, an empty
  failures table, a missing requested artifact, artifact-manifest output,
  overwrite rejection, overwrite replacement, and malformed inputs.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 769-771 | Validate selected artifact collection | `phase18-first-wave-table-bundle` passed |
| 772-774 | Validate source provenance and column fill | `phase18-first-wave-table-bundle` passed |
| 775-776 | Validate empty/missing artifact outputs | `phase18-first-wave-table-bundle` passed |
| 777-778 | Validate overwrite and malformed input boundaries | `phase18-first-wave-table-bundle` passed |

## Commands

```sh
nl -ba inst/sim/run/sim_write_first_wave_table_bundle.R | sed -n '1,190p'
nl -ba tests/testthat/test-phase18-first-wave-table-bundle.R | sed -n '1,145p'
Rscript -e "devtools::test(filter = 'phase18-first-wave-table-bundle', reporter = 'summary')"
```

## Result

The focused first-wave table-bundle writer test completed with exit code 0.
This closes Slices 769-778 as table-bundle validation. It does not add a
statistical summary report, figures, operating-characteristic interpretation,
automatic broad grid execution, formula grammar, likelihood code, roxygen
topics, or new user-facing API.
