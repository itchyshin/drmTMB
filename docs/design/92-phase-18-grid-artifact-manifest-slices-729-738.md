# Phase 18 Grid-Artifact Manifest Slices 729-738

Reader: `drmTMB` contributors checking that first-wave simulation report
staging can audit grid outputs before reading aggregate, replicate, interval,
or failure tables.

Slices 729-738 validate grid-artifact manifests on the first-wave writers. The
implementation is already present in the current dirty tree: grid writers return
one artifact-manifest row per CSV path with file-existence status and CSV row
counts, and the shared helper keeps zero-row optional artifacts visible.

## Source Evidence

- `phase18_grid_artifact_manifest()` validates the surface name and artifact
  paths, records one row per artifact, records file existence, and reads row
  counts for CSV artifacts.
- `phase18_bind_grid_artifact_manifests()` accepts either manifest data frames
  or full grid-writer results, checks required columns, binds them, and labels
  the rows as `artifact_grain = "grid_artifact_manifest"`.
- `phase18_summarise_grid_artifact_manifests()` reports missing artifacts,
  zero-row CSV artifacts, and total CSV rows by surface.
- First-wave grid-writer tests check manifest presence and file existence across
  Gaussian location-scale, `meta_V(V = V)`, paired count `mu` random effects,
  simple Gaussian/spatial random slopes, Student-t shape, bivariate residual
  `rho12`, spatial q2, and animal/`relmat()` q2/q4 writers.
- Optional interval-heavy writers keep zero-row files visible, including empty
  failure ledgers and zero-row Wald or profile coverage artifacts.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 729-731 | Validate per-writer artifact manifests | Grid-writer tests passed |
| 732-734 | Validate manifest CSV row counts | `phase18-sim-runner` manifest tests and writer row-count checks passed |
| 735-736 | Validate zero-row optional artifact handling | `phase18-sim-runner`, animal/`relmat()` q2/q4, and spatial q2 tests passed |
| 737-738 | Validate manifest binding readiness for report staging | `phase18-sim-runner` binding/status tests passed |

## Commands

```sh
nl -ba inst/sim/R/sim_runner.R | sed -n '529,635p'
nl -ba tests/testthat/test-phase18-sim-runner.R | sed -n '260,340p'
nl -ba tests/testthat/test-phase18-gaussian-ls-grid-writer.R | sed -n '60,90p'
nl -ba tests/testthat/test-phase18-animal-relmat-q2-grid-writer.R | sed -n '35,70p'
nl -ba tests/testthat/test-phase18-animal-relmat-q4-grid-writer.R | sed -n '35,72p'
Rscript -e "devtools::test(filter = 'phase18-(sim-runner|gaussian-ls-grid-writer|meta-v-grid-writer|count-mu-random-effect-grid-writer|random-slope-grid-writers|student-shape-grid-writer|biv-rho12-grid-writer|animal-relmat-q2-grid-writer|animal-relmat-q4-grid-writer|spatial-q2-grid-writer)', reporter = 'summary')"
```

## Result

The focused manifest/grid-writer bundle completed with exit code 0. The passing
files were:

- `phase18-animal-relmat-q2-grid-writer`
- `phase18-animal-relmat-q4-grid-writer`
- `phase18-biv-rho12-grid-writer`
- `phase18-count-mu-random-effect-grid-writer`
- `phase18-gaussian-ls-grid-writer`
- `phase18-meta-v-grid-writer`
- `phase18-random-slope-grid-writers`
- `phase18-sim-runner`
- `phase18-spatial-q2-grid-writer`
- `phase18-student-shape-grid-writer`

This closes Slices 729-738 as manifest-readiness validation. It does not add a
new report, new first-wave table bundle, automatic broad grid execution,
formula grammar, likelihood code, roxygen topics, or new user-facing API.
