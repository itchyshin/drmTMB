# Phase 18 First-Wave Status Report Slices 759-768

Reader: `drmTMB` contributors checking that first-wave simulation report
staging has a preflight page before broader report templates consume grid
artifacts.

Slices 759-768 validate the first-wave artifact-status report template. The
template is already present in the current dirty tree: it reads a bound
artifact-manifest CSV and surface-status CSV, renders a status page for complete
artifacts, and fails clearly when required artifacts are missing.

## Source Evidence

- `phase18-first-wave-status-report.Rmd` requires `artifact_manifest_csv` and
  `artifact_status_csv` params.
- The setup chunk verifies that both CSVs exist and contain required columns.
- With `require_complete = TRUE`, the template stops when any surface has
  `n_missing > 0`.
- The report displays surface status, artifact manifest rows, missing or empty
  artifacts, reader checks, and an interpretation boundary.
- The tests check template installation, key sections, successful HTML render
  with complete artifacts, note propagation, surface-name rendering, and the
  missing-artifact failure path.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 759-761 | Validate template installation and required parameters | `phase18-first-wave-status-report` passed |
| 762-764 | Validate complete-artifact HTML render | `phase18-first-wave-status-report` passed |
| 765-766 | Validate missing-artifact failure path | `phase18-first-wave-status-report` passed |
| 767-768 | Validate interpretation boundary wording | Source read and template tests passed |

## Commands

```sh
nl -ba inst/sim/reports/phase18-first-wave-status-report.Rmd | sed -n '1,130p'
nl -ba tests/testthat/test-phase18-first-wave-status-report.R | sed -n '1,145p'
Rscript -e "devtools::test(filter = 'phase18-first-wave-status-report', reporter = 'summary')"
```

## Result

The focused first-wave status-report test completed with exit code 0. Test
output included the expected `Quitting from ... [setup]` line from the
deliberate missing-artifact render, and the test still completed successfully.

This closes Slices 759-768 as status-report template validation. It does not add
first-wave table-bundle consumption, statistical summary-report rendering,
automatic broad grid execution, formula grammar, likelihood code, roxygen
topics, or new user-facing API.
