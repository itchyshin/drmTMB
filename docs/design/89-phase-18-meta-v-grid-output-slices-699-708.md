# Phase 18 Meta-V Grid Output Slices 699-708

Reader: `drmTMB` contributors checking that the known-sampling-covariance
meta-analysis surface has repeatable Phase 18 grid artifacts before larger
operating-characteristic runs.

Slices 699-708 validate the repeatable `meta_V(V = V)` grid-output writer. The
implementation is already present in the current dirty tree: the writer saves
aggregate, replicate, manifest, failure-ledger, Wald interval, and Wald
coverage CSV artifacts beside resumable per-replicate RDS files.

## Source Evidence

- `phase18_write_meta_v_grid_outputs()` validates `output_dir` and `overwrite`,
  creates separate `results` and `tables` directories, and defines the six
  expected table artifacts.
- The writer calls `phase18_summarise_meta_v_smoke()` with `result_dir`,
  `overwrite`, `cores`, and `backend`, so saved per-replicate RDS output and
  bounded runner metadata stay connected to the grid output.
- `phase18_summarise_meta_v_smoke()` returns aggregate rows, replicate rows,
  manifest rows, failure rows, Wald interval rows, and Wald coverage rows.
- `phase18_run_meta_v_smoke()` fits the existing Gaussian
  `bf(yi ~ x + meta_V(V = V), sigma ~ 1)` surface and uses
  `phase18_run_replicates()` for resumable execution.
- The grid-writer tests cover vector and dense known-`V` conditions, table
  existence, row counts, artifact-manifest existence, serial fallback metadata,
  overwrite rejection, overwrite replacement, and malformed writer inputs.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 699-701 | Validate grid-output directory and artifact contract | `phase18-meta-v-grid-writer` passed |
| 702-704 | Validate resumable replicate-runner forwarding | `phase18-meta-v-runner` and grid-writer metadata checks passed |
| 705-706 | Validate aggregate and replicate table evidence | `phase18-sim-aggregate` and grid-writer row checks passed |
| 707-708 | Validate Wald interval and coverage artifacts | `phase18-sim-uncertainty`, summary-smoke, and grid-writer row checks passed |

## Commands

```sh
nl -ba inst/sim/run/sim_write_meta_v_grid.R | sed -n '1,100p'
nl -ba inst/sim/run/sim_summary_meta_v_smoke.R | sed -n '1,90p'
nl -ba inst/sim/run/sim_run_meta_v_smoke.R | sed -n '1,100p'
nl -ba tests/testthat/test-phase18-meta-v-grid-writer.R | sed -n '1,150p'
Rscript -e "devtools::test(filter = 'phase18-(meta-v-grid-writer|meta-v-runner|meta-v-summary-smoke|meta-v-dgp|sim-aggregate|sim-uncertainty)', reporter = 'summary')"
```

## Result

The focused `meta_V(V = V)` grid-output bundle completed with exit code 0. The
passing files were:

- `phase18-meta-v-dgp`
- `phase18-meta-v-grid-writer`
- `phase18-meta-v-runner`
- `phase18-meta-v-summary-smoke`
- `phase18-sim-aggregate`
- `phase18-sim-uncertainty`

This closes Slices 699-708 as grid-output validation for the already-supported
Gaussian known-`V` meta-analysis smoke surface. It does not add non-Gaussian
known covariance, proportional sampling variance, phylogenetic-plus-study
extensions, formula grammar, likelihood code, roxygen topics, or new
user-facing API.
