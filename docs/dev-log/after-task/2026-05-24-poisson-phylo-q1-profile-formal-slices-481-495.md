# After Task: Poisson Phylogenetic q1 Profile And Formal Admission, Slices 481-495

## Goal

Add opt-in direct profile-interval artifacts and a formal-grid admission wrapper
for the fitted ordinary Poisson q=1 phylogenetic `mu` route:

```r
bf(count ~ x + phylo(1 | species, tree = tree))
```

This task makes the next formal recovery run easier to dispatch, read back, and
audit. It does not add a new likelihood route, does not admit NB2 or other
structured count models, and does not claim formal recovery or coverage
evidence.

## Implemented

The Poisson q1 fit summariser now maps `log_sd_phylo` to the public
`sd:mu:phylo(1 | species)` row and can request direct profile intervals for
that structured-SD target. The smoke summary and grid writer now save profile
interval, profile coverage, interval-evidence, interval-diagnostics, and
interval-failure CSVs beside the existing aggregate, replicate, manifest,
failure-ledger, Wald interval, Wald coverage, and profile-target files.

`phase18_write_poisson_phylo_q1_formal_grid_outputs()` writes the same artifact
family plus `poisson-phylo-q1-formal-spec.csv`. The formal spec records the
condition grid, `n_rep`, target replicate count, profile requests, MCSE
requirement, and whether the 500-replicate formal recovery gate is met.
`phase18_read_poisson_phylo_q1_grid_outputs()` and
`phase18_qa_poisson_phylo_q1_grid_outputs()` read and check artifact sets.
`phase18_poisson_phylo_q1_promotion_decision()` returns `hold_smoke_only` when
artifacts pass QA but the formal replicate gate is not met.

The manual GitHub Actions task `poisson_phylo_q1_formal` now dispatches this
formal-grid wrapper. The workflow excludes it from `task = "all"` so routine
Phase 18 dispatch does not accidentally launch the larger count-phylogeny grid.

## Mathematical Contract

The fitted model remains:

```text
y_i ~ Poisson(mu_i)
log(mu_i) = offset_i + x_i beta + a_species[i]
a ~ Normal(0, sigma_phylo^2 K_phylo)
```

The profiled target is the direct TMB `log_sd_phylo` parameter, reported to the
simulation artifacts as the public structured-SD row
`sd:mu:phylo(1 | species)`. The q=1 route still has no latent-correlation row
for `corpairs()`.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/fit/sim_summarise_poisson_phylo_q1.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_run_poisson_phylo_q1_smoke.R`
- `inst/sim/run/sim_summary_poisson_phylo_q1_smoke.R`
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
- `docs/dev-log/after-task/2026-05-24-poisson-phylo-q1-profile-formal-slices-481-495.md`

## Checks Run

```sh
air format .github/workflows/phase18-simulation-grid.yaml NEWS.md ROADMAP.md inst/sim/README.md inst/sim/fit/sim_summarise_poisson_phylo_q1.R inst/sim/run/sim_run_actions_cell.R inst/sim/run/sim_run_poisson_phylo_q1_smoke.R inst/sim/run/sim_summary_poisson_phylo_q1_smoke.R inst/sim/run/sim_write_poisson_phylo_q1_grid.R tests/testthat/test-phase18-poisson-phylo-q1.R vignettes/source-map.Rmd docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/70-phase-18-poisson-structured-q1-ademp.md docs/design/72-poisson-phylo-q1-runner-contract.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-24-poisson-phylo-q1-profile-formal-slices-481-495.md
Rscript -e "devtools::test(filter = 'phase18-poisson-phylo-q1')"
Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect|poisson-mean|nongaussian-structured-boundary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n 'NB2 .*structured.*(now fits|now fit|is fitted|implemented)|spatial\(.*poisson.*(now fits|now fit|is fitted|implemented)|animal\(.*poisson.*(now fits|now fit|is fitted|implemented)|relmat\(.*poisson.*(now fits|now fit|is fitted|implemented)|structured count slopes.*(now fit|now fits|fitted|implemented)|structured `zi` random effects.*(now fit|now fits|fitted|implemented)|structured `hu` random effects.*(now fit|now fits|fitted|implemented)' README.md ROADMAP.md NEWS.md docs/design vignettes inst/sim -g '!*.html'
rg -n 'poisson.*phylo.*(formal operating-characteristic evidence|formal recovery claim|formal coverage claim|ready for broad|admitted for broad)' README.md ROADMAP.md NEWS.md docs/design vignettes inst/sim -g '!*.html'
rg -n '481|495|poisson_phylo_q1_formal|formal-grid|profile-interval|poisson-phylo-q1-formal' pkgdown-site/ROADMAP.html pkgdown-site/articles/source-map.html pkgdown-site/news/index.html
rg -n 'NB2 .*structured.*(now fits|now fit|is fitted|implemented)|spatial\(.*poisson.*(now fits|now fit|is fitted|implemented)|animal\(.*poisson.*(now fits|now fit|is fitted|implemented)|relmat\(.*poisson.*(now fits|now fit|is fitted|implemented)|structured count slopes.*(now fit|now fits|fitted|implemented)|structured `zi` random effects.*(now fit|now fits|fitted|implemented)|structured `hu` random effects.*(now fit|now fits|fitted|implemented)' pkgdown-site -g '*.html'
rg -n 'poisson.*phylo.*(formal operating-characteristic evidence|formal recovery claim|formal coverage claim|ready for broad|admitted for broad)' pkgdown-site -g '*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "poisson phylo q1" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "Phase 18 Poisson" --limit 20 --json number,title,state,url,labels
git diff --check
```

Results:

- `air format` completed without output.
- `devtools::test(filter = 'phase18-poisson-phylo-q1')` passed with 77
  expectations.
- `devtools::test(filter = 'phase18-poisson-mu-random-effect|poisson-mean|nongaussian-structured-boundary')`
  passed with 189 expectations.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site()` completed and wrote the updated ROADMAP, source-map,
  and NEWS pages.
- The source stale-support and broad-claim scans returned no hits.
- The rendered-page scan found the 481 and 495 ROADMAP rows, the
  `poisson_phylo_q1_formal` task, the formal-spec CSV, and NEWS/source-map
  profile/formal wording.
- The generated-site stale-support and broad-claim scans returned no hits.
- The direct Poisson q1 issue search returned no open issues. The broader
  Phase 18 Poisson search returned #128, which is about random-effect slope
  capacity and did not need action for this profile/formal-admission slice.
- `git diff --check` was clean.

## Tests Of The Tests

The focused tests now request `profile_parameters = "log_sd_phylo"` in the
grid-writer path, assert that profile rows are recorded as `ok` or `failed`,
and verify that interval-evidence and interval-diagnostics files are written.
The formal wrapper test writes a one-replicate artifact set, reads it back,
checks expected replicate counts, and confirms that the promotion decision is
`hold_smoke_only` when the formal gate is not met. The Actions test verifies a
dry-run plan for `--task=poisson_phylo_q1_formal` with a profile request.

## Consistency Audit

ROADMAP, NEWS, source-map, simulation README, validation-debt register, Phase
18 programme, readiness matrix, ADEMP sheet, runner contract, check log, and
this report now agree on the bounded claim: profile and formal-admission
infrastructure exists for ordinary Poisson phylogenetic q=1 `mu`, but formal
operating-characteristic evidence is still unavailable.

## GitHub Issue Maintenance

Checked open issues with:

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "poisson phylo q1" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "Phase 18 Poisson" --limit 20 --json number,title,state,url,labels
```

The direct Poisson q1 search returned no open issues. The broader Phase 18
search returned #128, "Clarify random-effect slope capacity across location
and scale blocks". That issue is about slope capacity and did not need a
comment or closure for this profile/formal-admission slice.

## What Did Not Go Smoothly

The crash left a coherent but undocumented dirty tree. Recovery had to separate
the already-committed grid-writer closeout from the uncommitted profile/formal
follow-up before continuing. The formal task also needed an explicit
`task = "all"` guard so a routine Actions run would not launch the larger
Poisson phylogeny grid by accident.

## Team Learning

Ada should name manual-only Actions jobs in the source docs and matrix guard at
the same time. Rose should keep formal-admission helpers separate from formal
evidence claims, especially when a helper records the 500-replicate gate but no
large grid has been run.

## Known Limitations

The formal wrapper does not run a formal simulation by itself. No 500-replicate
cell has been run or audited in this slice, so there is no formal recovery,
coverage, or operating-characteristic claim. The slice still does not admit
NB2, zero-inflated, hurdle, spatial, animal, `relmat()`, slope, q2, q4,
scale, shape, ordinal, bounded-response, or mixed-response structured count
routes.

## Next Actions

If compute time is available, dispatch `poisson_phylo_q1_formal` manually with
a small pilot first, then a 500-replicate grid only after reviewing runtime,
failure-ledger, and interval-diagnostic artifacts from the pilot.
