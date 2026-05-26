# Phase 18 Count Mu Random-Effect Grid Output Slices 709-718

Reader: `drmTMB` contributors checking that the ordinary count location
random-effect surfaces have repeatable Phase 18 grid artifacts before larger
operating-characteristic runs.

Slices 709-718 validate the paired Poisson/NB2 `mu` random-effect grid-output
writer. The implementation is already present in the current dirty tree: the
writer saves aggregate, replicate, manifest, failure-ledger, Wald interval,
Wald coverage, direct-SD profile interval, and profile coverage CSV artifacts
beside resumable per-replicate RDS files.

## Source Evidence

- `phase18_write_count_mu_re_grid_outputs()` validates `output_dir` and
  `overwrite`, creates separate `results` and `tables` directories, and defines
  the eight expected table artifacts.
- The writer calls `phase18_summarise_count_mu_re_pilot()` with `result_dir`,
  `overwrite`, `cores`, and `backend`, so saved per-replicate RDS output and
  bounded runner metadata stay connected to the grid output.
- `phase18_summarise_count_mu_re_pilot()` splits the result directory into
  Poisson and NB2 subdirectories, runs both admitted surfaces, and binds
  aggregate, replicate, manifest, failure, Wald, and profile outputs.
- The Poisson surface fits ordinary non-zero-inflated location random effects
  with `bf(count ~ x + (1 | id) + (0 + x | id))`.
- The NB2 surface fits ordinary non-zero-inflated location random effects with
  `bf(count ~ x + (1 | id) + (0 + x | id), sigma ~ z)`, leaving `sigma` as a
  fixed-effect overdispersion submodel in this lane.
- The grid-writer tests cover paired Poisson/NB2 outputs, table existence,
  artifact-manifest existence, row counts, profile interval artifacts, serial
  fallback metadata, overwrite rejection, and malformed writer inputs.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 709-711 | Validate paired grid-output directory and artifact contract | `phase18-count-mu-random-effect-grid-writer` passed |
| 712-714 | Validate Poisson/NB2 resumable runner forwarding | `phase18-count-mu-random-effect-pilot`, `phase18-poisson-mu-random-effect`, and `phase18-nbinom2-mu-random-effect` passed |
| 715-716 | Validate aggregate, replicate, manifest, and failure outputs | `phase18-sim-aggregate` and grid-writer row checks passed |
| 717-718 | Validate Wald and direct-SD profile artifacts | `phase18-sim-uncertainty`, surface summaries, and grid-writer row checks passed |

## Commands

```sh
nl -ba inst/sim/run/sim_write_count_mu_random_effect_grid.R | sed -n '1,125p'
nl -ba inst/sim/run/sim_summary_count_mu_random_effect_pilot.R | sed -n '1,115p'
nl -ba inst/sim/run/sim_run_poisson_mu_random_effect_smoke.R | sed -n '35,95p'
nl -ba inst/sim/run/sim_run_nbinom2_mu_random_effect_smoke.R | sed -n '35,100p'
nl -ba tests/testthat/test-phase18-count-mu-random-effect-grid-writer.R | sed -n '1,115p'
Rscript -e "devtools::test(filter = 'phase18-(count-mu-random-effect-grid-writer|count-mu-random-effect-pilot|poisson-mu-random-effect|nbinom2-mu-random-effect|sim-aggregate|sim-uncertainty)', reporter = 'summary')"
```

## Result

The focused count `mu` random-effect grid-output bundle completed with exit
code 0. The passing files were:

- `phase18-count-mu-random-effect-grid-writer`
- `phase18-count-mu-random-effect-pilot`
- `phase18-nbinom2-mu-random-effect`
- `phase18-poisson-mu-random-effect`
- `phase18-sim-aggregate`
- `phase18-sim-uncertainty`

This closes Slices 709-718 as grid-output validation for the already-supported
ordinary Poisson/NB2 location random-effect smoke surfaces. It does not add
zero-inflated counts, hurdle counts, zero-truncated NB2 random effects,
correlated count slopes, NB2 `sigma` slopes, NB2 `sigma` phylogeny, q4 count
covariance, formula grammar, likelihood code, roxygen topics, or new
user-facing API.
