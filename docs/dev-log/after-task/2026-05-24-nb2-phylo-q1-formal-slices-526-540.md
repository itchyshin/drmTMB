# After Task: NB2 Phylogenetic q1 Formal-Admission Lane

## Goal

Finish Slices 526-540 by adding an overdispersion-aware Phase 18 evidence lane
for the ordinary NB2 q=1 phylogenetic `mu` route:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

The lane should keep `sigma` as fixed-effect NB2 overdispersion, expose direct
`log_sd_phylo` profile-target status, record an ordinary grouped
species-intercept comparator, and stop short of formal recovery or coverage
claims until the 500-replicate grid is run and audited.

## Implemented

- Added `docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md`.
- Added the private Phase 18 DGP, summariser, smoke runner, summary helper, and
  grid/formal writer:
  `inst/sim/dgp/sim_dgp_nbinom2_phylo_q1.R`,
  `inst/sim/fit/sim_summarise_nbinom2_phylo_q1.R`,
  `inst/sim/run/sim_run_nbinom2_phylo_q1_smoke.R`,
  `inst/sim/run/sim_summary_nbinom2_phylo_q1_smoke.R`, and
  `inst/sim/run/sim_write_nbinom2_phylo_q1_grid.R`.
- Added the manual `nbinom2_phylo_q1_formal` Actions task to
  `inst/sim/run/sim_run_actions_cell.R` and
  `.github/workflows/phase18-simulation-grid.yaml`; it is excluded from
  `task = "all"`.
- Added `tests/testthat/test-phase18-nbinom2-phylo-q1.R`.
- Synced `inst/sim/README.md`, `vignettes/source-map.Rmd`,
  `docs/design/34-validation-debt-register.md`,
  `docs/design/41-phase-18-simulation-programme.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`, `ROADMAP.md`, and
  `NEWS.md`.

## Mathematical Contract

The DGP uses a standardized phylogenetic tip-correlation matrix `C`:

```text
a ~ Normal(0, sd_phylo^2 * C)
eta_mu_sk = beta0 + beta1 * x_sk + a_s
mu_sk = exp(eta_mu_sk)
eta_sigma_sk = gamma0 + gamma1 * z_sk
sigma_sk = exp(eta_sigma_sk)
count_sk ~ NB2(mu_sk, size = 1 / sigma_sk^2)
```

The fitted target has `phylo(1 | species, tree = tree)` in `mu` and fixed-effect
`sigma ~ z`. The comparator is `count ~ x + (1 | species), sigma ~ z`, recorded
as an evidence row for unstructured species heterogeneity, not as a new fitted
feature claim.

## Files Changed

The new code lives only under `inst/sim/` and tests. No likelihood,
formula-grammar, TMB, or exported R API files were changed. Public and developer
docs were updated to record the new simulation-evidence lane and the remaining
NB2 boundaries.

## Checks Run

```sh
Rscript tools/codex-checkpoint.R --goal "finish NB2 slices 511-540" --next "add NB2 phylogenetic q1 ADEMP/runner lane"
Rscript -e "files <- c('inst/sim/dgp/sim_dgp_nbinom2_phylo_q1.R','inst/sim/fit/sim_summarise_nbinom2_phylo_q1.R','inst/sim/run/sim_run_nbinom2_phylo_q1_smoke.R','inst/sim/run/sim_summary_nbinom2_phylo_q1_smoke.R','inst/sim/run/sim_write_nbinom2_phylo_q1_grid.R','inst/sim/run/sim_run_actions_cell.R'); invisible(lapply(files, parse)); cat('parse ok\n')"
Rscript -e "devtools::test(filter = 'phase18-nbinom2-phylo-q1', reporter = 'summary')"
air format NEWS.md ROADMAP.md inst/sim/README.md vignettes/source-map.Rmd docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md inst/sim/dgp/sim_dgp_nbinom2_phylo_q1.R inst/sim/fit/sim_summarise_nbinom2_phylo_q1.R inst/sim/run/sim_run_nbinom2_phylo_q1_smoke.R inst/sim/run/sim_summary_nbinom2_phylo_q1_smoke.R inst/sim/run/sim_write_nbinom2_phylo_q1_grid.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-nbinom2-phylo-q1.R .github/workflows/phase18-simulation-grid.yaml
Rscript -e "files <- c('inst/sim/dgp/sim_dgp_nbinom2_phylo_q1.R','inst/sim/fit/sim_summarise_nbinom2_phylo_q1.R','inst/sim/run/sim_run_nbinom2_phylo_q1_smoke.R','inst/sim/run/sim_summary_nbinom2_phylo_q1_smoke.R','inst/sim/run/sim_write_nbinom2_phylo_q1_grid.R','inst/sim/run/sim_run_actions_cell.R','tests/testthat/test-phase18-nbinom2-phylo-q1.R'); invisible(lapply(files, parse)); cat('parse ok\n')"
Rscript -e "devtools::test(filter = 'phase18-nbinom2-phylo-q1', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'phase18-actions-runner', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'nbinom2-location-scale|nongaussian-structured-boundary|phase18-nbinom2-sigma-random-effect|phase18-poisson-phylo-q1', reporter = 'summary')"
git diff --check
rg -n '526|540|nbinom2_phylo_q1|nbinom2-phylo-q1|NB2 phylogenetic q1|nbinom2_phylo_q1_formal|grouped-comparator|grouped comparator|Phase 18 NB2 Phylogenetic' NEWS.md ROADMAP.md inst/sim/README.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md vignettes/source-map.Rmd .github/workflows/phase18-simulation-grid.yaml inst/sim tests/testthat/test-phase18-nbinom2-phylo-q1.R
rg -n 'NB2 q1 phylogeny still needs|NB2 phylogeny planned|NB2 phylogenetic q1.*still needs|nbinom2_phylo_q1.*planned|nbinom2_phylo_q1_formal.*task = "all"|formal recovery.*now|coverage claims.*now|broad.*NB2.*phylo.*ready|NB2 sigma phylogeny.*now fit|zero-inflated NB2 phylogeny.*now fit' NEWS.md ROADMAP.md README.md inst/sim/README.md docs/design vignettes tests -g '!*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "NB2 phylo q1" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "nbinom2 phylo" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "Phase 18 NB2" --limit 20 --json number,title,state,url,labels
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n '526|540|nbinom2_phylo_q1|nbinom2-phylo-q1|NB2 phylogenetic q1|nbinom2_phylo_q1_formal|grouped-comparator|grouped comparator|overdispersion-aware NB2 q1|Phase 18 NB2 Phylogenetic' pkgdown-site/ROADMAP.html pkgdown-site/articles/source-map.html pkgdown-site/news/index.html
rg -n 'NB2 q1 phylogeny still needs|NB2 phylogeny planned|NB2 phylogenetic q1.*still needs|nbinom2_phylo_q1.*planned|formal recovery.*now|coverage claims.*now|broad.*NB2.*phylo.*ready|NB2 sigma phylogeny.*now fit|zero-inflated NB2 phylogeny.*now fit' pkgdown-site -g '*.html'
git diff --check
Rscript -e "devtools::check(error_on = 'never')"
```

Results:

- The recovery checkpoint was written successfully.
- Both parse smokes printed `parse ok`.
- `devtools::test(filter = 'phase18-nbinom2-phylo-q1')` passed before and after
  formatting.
- `devtools::test(filter = 'phase18-actions-runner')` passed.
- The adjacent NB2, non-Gaussian structured-boundary, NB2 log-`sigma`, Poisson
  q1, and filter-adjacent truncated NB2 tests passed.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site()` completed.
- Source and rendered positive scans found the new Slices 526-540 rows, NB2 q1
  helper files, profile-target artifacts, Actions task, comparator wording, and
  NEWS/source-map updates.
- The source stale scan returned only expected historical ROADMAP lines: Slice
  508 describes a previous stale-claim scan, and Slice 537 says the manual
  Actions task is excluded from `task = "all"`.
- The rendered stale scan returned only the same historical Slice 508 sentence.
- `git diff --check` was clean.
- `devtools::check(error_on = 'never')` completed in about 5m19s with 0 errors,
  0 warnings, and 0 notes.

## Tests Of The Tests

The new focused test suite checks DGP reproducibility, target and grouped
comparator summary rows, direct `log_sd_phylo` target mapping, CSV artifact
creation, formal read-back QA, promotion-decision hold status below the
500-replicate gate, Actions dry-run planning, overwrite protection, and malformed
inputs for bad tree shape, bad species count, negative SD, missing cell columns,
bad output directory, bad overwrite flag, and malformed profile-parameter
requests.

## Consistency Audit

The new lane changes simulation evidence, not likelihood grammar. The source
map, readiness matrix, validation-debt register, NEWS, ROADMAP, and simulation
README now say the same thing: ordinary NB2 q=1 phylogenetic `mu` has an
overdispersion-aware smoke/formal-admission artifact path with fixed-effect
`sigma`; NB2 phylogenetic slopes, NB2 `sigma` phylogeny, zero-inflated NB2
phylogeny, spatial/animal/`relmat()` count routes, and count cross-parameter
covariance remain planned.

## GitHub Issue Maintenance

Issue searches:

- `NB2 phylo q1`: no open issue results.
- `nbinom2 phylo`: no open issue results.
- `Phase 18 NB2`: returned #59, #60, and #128.

No issue was mutated. The local slice is a narrow artifact lane under the broad
Phase 18 simulation framework, and it does not close the broad comparator,
random-slope, or Phase 18 issues.

## What Did Not Go Smoothly

One stale-scan command accidentally used shell backticks around `sigma`; zsh
tried to execute `sigma` before `rg` ran. The scan was rerun with single quotes
and no command-substitution hazard. I also launched `pkgdown::check_pkgdown()`
and `pkgdown::build_site()` at the same time; both completed cleanly, but future
closeout passes should run them sequentially when the site build is part of the
evidence trail.

## Team Learning

For NB2 structured-count work, the comparator belongs in the artifact schema,
not just in prose. Recording an ordinary grouped species-intercept SD beside the
phylogenetic SD gives Fisher and Rose a simple way to see when unstructured
heterogeneity could explain the same marginal species variation.

## Known Limitations

This lane is not broad NB2 structured parity. It does not add NB2 phylogenetic
slopes, labelled q=2/q=4 count blocks, zero-inflated NB2 phylogeny, NB2
`sigma` phylogeny, spatial/animal/`relmat()` count structure, or count-side
cross-parameter covariance. It also does not make formal recovery or coverage
claims until the 500-replicate formal grid is run and audited.

## Next Actions

Run `nbinom2_phylo_q1_formal` manually with `--profile-parameters=log_sd_phylo`
when compute time is available, inspect the formal artifacts and comparator
rows, and only then decide whether the NB2 q1 route can move beyond
formal-admission evidence.
