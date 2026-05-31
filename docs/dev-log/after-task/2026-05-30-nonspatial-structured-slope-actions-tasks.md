# After Task: Non-Spatial Structured Slope Actions Tasks

## Goal

Wire the non-spatial Gaussian structured `mu` one-slope artifact writers into
manual Phase 18 Actions tasks, without changing fitted model syntax or claiming
recovery, accuracy, coverage, or power.

## Implemented

The manual Phase 18 simulation workflow now accepts `phylo_mu_slope`,
`animal_mu_slope`, and `relmat_mu_slope` beside `spatial_mu_slope`. Each task
loads the existing DGP, summariser, smoke helper, summary helper, and grid
writer for its route, writes the standard aggregate, replicate, manifest, and
failure-ledger artifact set, and remains excluded from `task = "all"`.

The structured workflow registry now maps the `gaussian_phylo_mu_one_slope`,
`gaussian_animal_mu_one_slope`, and `gaussian_relmat_mu_one_slope` rows to their
manual tasks. The structured-dependence workflow plan reports seven existing
tasks and zero wrapper targets for the current registry.

## Mathematical Contract

No likelihood, formula grammar, parameter transform, or extractor contract
changed. The fitted models remain one-response Gaussian `mu` models with one
structured intercept field and one independent numeric structured slope field.
The tasks are dispatch and artifact-routing evidence only; they do not estimate
intercept-slope correlations, multiple structured slopes, residual-scale
structured slopes, structured residual `rho12`, mesh/SPDE fields, or
non-Gaussian structured slopes.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `tests/testthat/test-phase18-structured-dependence-wrapper-readiness.R`
- `README.md`, `NEWS.md`, `ROADMAP.md`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/148-phase6c-structured-one-slope-ademp.md`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- regenerated `pkgdown-site/` pages for home, ROADMAP, news, model map, and
  phylogenetic/spatial content in both the main and `dev/` mirrors.

## Checks Run

```sh
Rscript --vanilla -e "files <- c('inst/sim/run/sim_run_actions_cell.R','inst/sim/run/sim_phase18_structured_workflow_registry.R','inst/sim/run/sim_phase18_structured_dependence_wrapper_readiness.R','tests/testthat/test-phase18-actions-runner.R','tests/testthat/test-phase18-structured-workflow-registry.R','tests/testthat/test-phase18-structured-dependence-wrapper-readiness.R'); invisible(lapply(files, parse)); cat('actions dispatch parse ok\n')"
Rscript --vanilla -e "devtools::test(filter = '^phase18-(actions-runner|structured-workflow-registry|structured-dependence-wrapper-readiness)$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::build_site(lazy = TRUE, preview = FALSE)"
Rscript --vanilla -e "pkgdown::build_site(lazy = TRUE, preview = FALSE, devel = TRUE)"
rg -n 'only `spatial_mu_slope` currently|`spatial_mu_slope` is the only manual Actions task|remaining non-Actions wrapper targets|while remaining non-Actions wrapper targets|no standalone one-slope Actions task|local wrapper-target artifact writer only|All three remain outside Actions dispatch|The coordinate-spatial path has this first one-slope baseline; the phylogenetic path does not yet|while leaving .*one-slope rows as wrapper targets|current fitted paths are the phylogenetic, coordinate-spatial, and first|structured random intercept from a precomputed' README.md ROADMAP.md NEWS.md docs/design inst/sim/README.md vignettes pkgdown-site/index.html pkgdown-site/news/index.html pkgdown-site/dev/news/index.html pkgdown-site/ROADMAP.html pkgdown-site/dev/ROADMAP.html pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/dev/articles/phylogenetic-spatial.html pkgdown-site/articles/model-map.html pkgdown-site/dev/articles/model-map.html
git diff --check
```

## Tests Of The Tests

The new Actions-runner tests cover three failure-prone surfaces: dry-run task
acceptance, source dependency lists, and real dispatch through stubbed writer
functions. The registry tests assert that all four Gaussian structured
one-slope rows are `ready_existing_task` rows with the expected task names. The
readiness tests also keep a synthetic wrapper-target fixture, so the helper
still fails closed for any future structured-dependence wrapper target that
lacks a known artifact contract.

## Consistency Audit

README, NEWS, ROADMAP, the Phase 18 design notes, the Phase 6c sprint and ADEMP
notes, the Phase 18 simulation README, the model map, and the
phylogenetic/spatial article now agree on the boundary: all four Gaussian
structured one-slope routes have manual opt-in artifact tasks; none is included
in `task = "all"`; none is recovery, coverage, or power evidence.

The generated main pkgdown pages and checked-in `pkgdown-site/dev/` mirror were
both scanned for the old "spatial-only manual task" and "non-spatial wrapper
target" wording.

## GitHub Issue Maintenance

This slice belongs to the Phase 6c structured one-slope and simulation-planning
issues: #442, #446, and #436, with PR #445 as the active review surface. The
issue comments should describe dispatch availability, not promote any recovery
or coverage status.

## What Did Not Go Smoothly

`pkgdown::build_site()` updated the main site but did not refresh the checked-in
`pkgdown-site/dev/` mirror. The generated dev pages had to be synchronized
mechanically after the build.

## Team Learning

When a source-doc change touches status text that appears in both main and dev
pkgdown mirrors, Grace should scan both rendered paths before closeout. The
team-improvements log now records this as a generated-site mirror check.

## Known Limitations

The manual tasks have not been dispatched in GitHub Actions in this slice. They
are also not part of `task = "all"`. No recovery, accuracy, coverage, power,
multiple-slope, slope-correlation, residual-scale structured-slope, sparse
large-pedigree speed, mesh/SPDE, or non-Gaussian structured-slope claim is made.

## Next Actions

Run one small manual artifact dispatch for each non-spatial task when runner
capacity is available, then audit the manifests and failure ledgers before any
stronger simulation-evidence language is considered.
