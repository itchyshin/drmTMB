# After-Task Report: Poisson Phylogenetic q1 Smoke Runner, Slices 451-465

## Purpose

Implement the first opt-in Phase 18 smoke surface for the fitted ordinary
Poisson q=1 phylogenetic `mu` route:

```r
bf(count ~ x + phylo(1 | species, tree = tree))
```

This task adds simulation infrastructure and focused tests. It does not add a
new likelihood route, does not promote NB2 or other structured count models,
and does not create formal recovery or coverage claims.

## Scope Completed

- Added `inst/sim/dgp/sim_dgp_poisson_phylo_q1.R`.
- Added `inst/sim/fit/sim_summarise_poisson_phylo_q1.R`.
- Added `inst/sim/run/sim_run_poisson_phylo_q1_smoke.R`.
- Added `inst/sim/run/sim_summary_poisson_phylo_q1_smoke.R`.
- Added `tests/testthat/test-phase18-poisson-phylo-q1.R`.
- Updated `inst/sim/README.md`, ROADMAP, NEWS, source-map, family registry,
  validation-debt, Phase 18 programme, readiness matrix, ADEMP sheet, and
  runner contract.

## Review Perspectives

Ada kept the implementation to the already fitted Poisson q1 route. Curie
checked the DGP, condition helper, runner, and focused tests. Fisher checked
that aggregate and interval outputs remain smoke evidence, not formal
operating characteristics. Boole checked the formula route and extractor names.
Grace checked validation commands. Rose checked that the documentation did not
imply NB2, spatial, animal, `relmat()`, zero-inflated, hurdle, slope, q2/q4,
scale, shape, ordinal, bounded-response, or mixed-response support. These were
role perspectives, not spawned agents.

## Remaining Boundary

The new runner returns aggregate, replicate, manifest, failure-ledger,
fixed-effect Wald interval, Wald coverage, and direct `log_sd_phylo`
profile-target status tables. It does not yet write repeatable CSV grid
outputs, run formal 500-replicate cells, or report direct SD profile coverage.

## Validation

Run before commit:

```sh
air format NEWS.md ROADMAP.md inst/sim/README.md inst/sim/dgp/sim_dgp_poisson_phylo_q1.R inst/sim/fit/sim_summarise_poisson_phylo_q1.R inst/sim/run/sim_run_poisson_phylo_q1_smoke.R inst/sim/run/sim_summary_poisson_phylo_q1_smoke.R tests/testthat/test-phase18-poisson-phylo-q1.R vignettes/source-map.Rmd docs/design/02-family-registry.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/70-phase-18-poisson-structured-q1-ademp.md docs/design/72-poisson-phylo-q1-runner-contract.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-23-poisson-phylo-q1-smoke-runner-slices-451-465.md
Rscript -e "devtools::test(filter = 'phase18-poisson-phylo-q1')"
Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect|poisson-mean|nongaussian-structured-boundary')"
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'NB2 .*structured.*(now fits|now fit|is fitted|implemented)|spatial\(.*poisson.*(now fits|now fit|is fitted|implemented)|animal\(.*poisson.*(now fits|now fit|is fitted|implemented)|relmat\(.*poisson.*(now fits|now fit|is fitted|implemented)|structured count slopes.*(now fit|now fits|fitted|implemented)|structured `zi` random effects.*(now fit|now fits|fitted|implemented)|structured `hu` random effects.*(now fit|now fits|fitted|implemented)' README.md ROADMAP.md NEWS.md docs/design vignettes inst/sim -g '!*.html'
git diff --check
```

Results:

- `air format` completed without output.
- `devtools::test(filter = 'phase18-poisson-phylo-q1')` passed with 37
  expectations.
- `devtools::test(filter = 'phase18-poisson-mu-random-effect|poisson-mean|nongaussian-structured-boundary')`
  passed with 189 expectations.
- `pkgdown::check_pkgdown()` reported no problems.
- The narrowed false-support scan returned no hits.
- `git diff --check` was clean.
