# Phase 18 First-Wave Summary Smoke Slices 809-818

Reader: `drmTMB` contributors checking that a real first-wave summary smoke can
stage grid outputs, status artifacts, bundled tables, and report artifacts
without turning smoke-scale evidence into formal operating-characteristic
claims.

Slices 809-818 validate the tiny first-wave summary smoke. The saved
`inst/sim/results/slice-809-first-wave-summary-smoke/` artifact contains the
historical Gaussian location-scale plus `meta_V(V = V)` rendered summary HTML.
The current runner has since expanded its smoke fixture to stage Gaussian
location-scale, `meta_V(V = V)`, paired Poisson/NB2 `mu` random effects,
ordinary Gaussian `mu` and `sigma` random slopes, and coordinate-spatial
Gaussian `mu` slopes.

## Source Evidence

- `phase18_run_first_wave_summary_smoke()` validates `output_dir`, `n_rep`,
  `master_seed`, and `notes`.
- The runner writes grid outputs for Gaussian location-scale,
  `meta_V(V = V)`, paired Poisson/NB2 `mu` random effects, Gaussian `mu`
  random slopes, Gaussian `sigma` random slopes, and coordinate-spatial
  Gaussian `mu` slopes.
- It calls `phase18_render_first_wave_summary_report()` to write status,
  table-bundle, and optional report artifacts.
- It writes `first-wave-parallel-summary.csv` with requested and actual worker
  counts.
- The saved `slice-809` artifact has a rendered summary HTML with
  `gaussian_ls_grid`, `meta_v_grid`, aggregate operating-characteristic rows,
  interval diagnostics, and an interpretation boundary.
- The focused runner test validates staging with `render = FALSE`, seven
  parallel-summary rows, serial fallback metadata, aggregate table rows, Wald
  coverage rows, profile coverage rows, and malformed input paths.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 809-811 | Validate saved rendered smoke artifact | Saved HTML and table files exist |
| 812-814 | Validate current runner staging across expanded first-wave surfaces | `phase18-first-wave-summary-smoke-runner` passed |
| 815-816 | Validate parallel-summary metadata | Runner test and source read passed |
| 817-818 | Validate malformed input boundaries | Runner test passed |

## Commands

```sh
find inst/sim/results -maxdepth 4 -path '*slice-809-first-wave-summary-smoke*' -type f | sort | head -n 80
test -f inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/report/phase18-first-wave-summary.html
rg -n "Slice 809|gaussian_ls_grid|meta_v_grid|Aggregate Operating Characteristics|Interval Diagnostics|Interpretation Boundary" inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/report/phase18-first-wave-summary.html
wc -l inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/status/phase18-first-wave-artifact-status.csv inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/tables/phase18-first-wave-aggregate.csv inst/sim/results/slice-809-first-wave-summary-smoke/first-wave-summary/tables/phase18-first-wave-wald-coverage.csv
nl -ba inst/sim/run/sim_run_first_wave_summary_smoke.R | sed -n '1,230p'
nl -ba tests/testthat/test-phase18-first-wave-summary-smoke-runner.R | sed -n '1,130p'
Rscript -e "devtools::test(filter = 'phase18-first-wave-summary-smoke-runner', reporter = 'summary')"
```

## Result

The focused first-wave summary smoke-runner test completed with exit code 0.
The saved `slice-809` rendered HTML exists and contains the expected Gaussian
location-scale plus `meta_V(V = V)` smoke evidence. This closes Slices 809-818
as first-wave summary-smoke validation. It does not make formal coverage,
power, or operating-characteristic claims; it also does not add formula grammar,
likelihood code, roxygen topics, or new user-facing API.
