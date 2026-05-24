# After Task: Poisson Phylogenetic q1 Grid Writer, Slices 466-480

## Goal

Add repeatable CSV artifacts for the fitted ordinary Poisson q=1 phylogenetic
`mu` smoke route:

```r
bf(count ~ x + phylo(1 | species, tree = tree))
```

This task makes the smoke run easier to rerun and inspect. It does not add a
new likelihood route, does not admit NB2 or other structured count models, and
does not claim formal recovery or coverage evidence.

## Implemented

`phase18_write_poisson_phylo_q1_grid_outputs()` writes aggregate,
replicate-level, manifest, failure-ledger, fixed-effect Wald interval, Wald
coverage, and direct `log_sd_phylo` profile-target CSV files beside resumable
per-replicate RDS files. It rejects existing artifact paths unless
`overwrite = TRUE` and records requested versus actual worker counts through
the underlying smoke runner.

## Mathematical Contract

The fitted model remains

```text
y_i ~ Poisson(mu_i)
log(mu_i) = offset_i + x_i beta + a_species[i]
a ~ Normal(0, sigma_phylo^2 K_phylo)
```

The grid writer changes only artifact storage for this existing route. The
structured-SD target is the direct TMB parameter `log_sd_phylo`; q=1 has no
latent-correlation row for `corpairs()`.

## Files Changed

- `inst/sim/run/sim_write_poisson_phylo_q1_grid.R`
- `tests/testthat/test-phase18-poisson-phylo-q1.R`
- `inst/sim/README.md`
- `vignettes/source-map.Rmd`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/70-phase-18-poisson-structured-q1-ademp.md`
- `docs/design/72-poisson-phylo-q1-runner-contract.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format NEWS.md ROADMAP.md inst/sim/README.md inst/sim/run/sim_write_poisson_phylo_q1_grid.R tests/testthat/test-phase18-poisson-phylo-q1.R vignettes/source-map.Rmd docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/70-phase-18-poisson-structured-q1-ademp.md docs/design/72-poisson-phylo-q1-runner-contract.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-24-poisson-phylo-q1-grid-writer-slices-466-480.md
Rscript -e "devtools::test(filter = 'phase18-poisson-phylo-q1')"
Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect|poisson-mean|nongaussian-structured-boundary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n 'NB2 .*structured.*(now fits|now fit|is fitted|implemented)|spatial\(.*poisson.*(now fits|now fit|is fitted|implemented)|animal\(.*poisson.*(now fits|now fit|is fitted|implemented)|relmat\(.*poisson.*(now fits|now fit|is fitted|implemented)|structured count slopes.*(now fit|now fits|fitted|implemented)|structured `zi` random effects.*(now fit|now fits|fitted|implemented)|structured `hu` random effects.*(now fit|now fits|fitted|implemented)' README.md ROADMAP.md NEWS.md docs/design vignettes inst/sim -g '!*.html'
rg -n 'poisson.*phylo.*(formal operating-characteristic evidence|formal recovery claim|formal coverage claim|ready for broad|admitted for broad)' README.md ROADMAP.md NEWS.md docs/design vignettes inst/sim -g '!*.html'
rg -n "466-480|Poisson phylogenetic q1 grid writer|sim_write_poisson_phylo_q1_grid|poisson-phylo-q1" pkgdown-site/ROADMAP.html pkgdown-site/articles/source-map.html pkgdown-site/news/index.html
rg -n 'NB2 .*structured.*(now fits|now fit|is fitted|implemented)|spatial\(.*poisson.*(now fits|now fit|is fitted|implemented)|animal\(.*poisson.*(now fits|now fit|is fitted|implemented)|relmat\(.*poisson.*(now fits|now fit|is fitted|implemented)|structured count slopes.*(now fit|now fits|fitted|implemented)|structured `zi` random effects.*(now fit|now fits|fitted|implemented)|structured `hu` random effects.*(now fit|now fits|fitted|implemented)' pkgdown-site -g '*.html'
rg -n 'poisson.*phylo.*(formal operating-characteristic evidence|formal recovery claim|formal coverage claim|ready for broad|admitted for broad)' pkgdown-site -g '*.html'
git diff --check
```

Results:

- `air format` completed without output.
- `devtools::test(filter = 'phase18-poisson-phylo-q1')` passed with 59
  expectations.
- `devtools::test(filter = 'phase18-poisson-mu-random-effect|poisson-mean|nongaussian-structured-boundary')`
  passed with 189 expectations.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site()` completed and wrote the updated ROADMAP, source-map,
  and NEWS pages.
- The source stale-claim scans returned no hits.
- The rendered-page scan found the 466-480 roadmap row and
  `sim_write_poisson_phylo_q1_grid.R` source-map text.
- The generated-site stale-support and broad-claim scans returned no hits.
- `git diff --check` was clean.

## Tests Of The Tests

The new focused tests create a one-replicate, three-cell smoke output folder,
assert row counts for every CSV artifact, assert that the artifact manifest
sees each file, check requested versus actual worker counts, and verify that
existing artifact paths and invalid writer inputs error.

## Consistency Audit

ROADMAP, NEWS, the source map, validation-debt register, Phase 18 programme,
readiness matrix, ADEMP sheet, runner contract, and simulation README now say
the same thing: repeatable smoke artifacts exist for ordinary Poisson
phylogenetic q=1 `mu`, while formal recovery grids and broader structured
non-Gaussian routes remain future work.

## GitHub Issue Maintenance

Checked open issues with:

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "poisson phylo q1" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "Phase 18 Poisson" --limit 20 --json number,title,state,url,labels
gh issue view 128 --repo itchyshin/drmTMB --json number,title,state,url,body,labels
```

The direct Poisson q1 search returned no open issues. The broader Phase 18
search returned #128, which is about random-slope capacity and structured slope
boundaries; this grid-writer slice does not resolve it, so no issue comment or
closure was appropriate.

## What Did Not Go Smoothly

The previous thread crashed after code/tests and some roadmap/news/source-map
edits had been started. Recovery found ROADMAP rows claiming check-log,
after-task, README, readiness, and design-doc sync before those files were
actually updated. This report records that correction explicitly.

## Team Learning

Ada should verify roadmap "Done locally" rows against `git status` and `git
diff --name-only` after a crash before continuing. Rose should keep checking
that artifact slices do not let smoke-level evidence drift into broad support
language.

## Known Limitations

The grid writer is a repeatable smoke-artifact writer, not a formal simulation
study. It does not run 500-replicate cells, estimate Monte Carlo standard
errors for coverage claims, add direct SD profile intervals, or admit NB2,
zero-inflated, hurdle, spatial, animal, `relmat()`, slope, q2, q4, scale,
shape, ordinal, bounded-response, or mixed-response structured count routes.

## Next Actions

Run the focused Poisson q1 tests, neighbouring count-route tests, pkgdown
preflight, stale-claim scans, and `git diff --check`. If those pass, commit the
grid-writer slice or open a small PR.
