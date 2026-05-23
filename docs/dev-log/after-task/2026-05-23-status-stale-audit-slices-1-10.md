# After Task: Status And Stale-Claim Audit Slices 1-10

## Goal

Recover from the crashed thread, close the already validated rendered figure QA
lane, and start the next handoff item: a focused status and stale-claim audit
across the highest-traffic public docs. The purpose was to keep implemented,
first-slice, alias, and planned surfaces distinct after several rapid
structured-effect and `meta_V()` slices.

## Implemented

PR #314, "Add family tutorial figure QA slice", had passed its GitHub checks,
so it was squash-merged first. The local branch
`codex/status-stale-audit-1-10` was then rebased onto `origin/main` at merge
commit `35e0d88b`.

The audit changed status prose and examples so `meta_V(V = V)` is the preferred
known sampling covariance spelling. `meta_known_V(V = V)` remains documented as
a compatibility alias, not a separate likelihood path. The same distinction now
appears in roxygen/Rd text for `weights()` and `sigma()`, the `check_drm()`
known-covariance note, formula grammar docs, location-scale and model-map
tutorials, likelihood and weights design docs, and known-limitations wording.

The known-limitations ledger now records constant coordinate-spatial,
animal-model, and `relmat()` q=4 location-scale blocks as fitted first slices,
while keeping richer structured slopes, direct-SD surfaces,
predictor-dependent `corpair()` regressions, mesh/SPDE spatial routes, and
non-Gaussian structured neighbours planned. It also records ordinary Poisson
q=1 phylogenetic `mu` as the only fitted structured non-Gaussian route.

No spawned subagents were used. Ada coordinated recovery and integration. Boole
checked API and formula wording. Fisher checked interval and status boundaries.
Pat checked reader-facing next-step language. Grace checked documentation,
pkgdown, vignettes, and generated Rd files. Rose checked stale status claims
and durable handoff evidence. These were role perspectives, not running agents.

## Mathematical Contract

No formula grammar, likelihood parameterization, optimizer, extractor, or
interval method changed. The code-level changes were limited to diagnostic and
roxygen wording. The audit did not add `meta_gaussian()`, `tau ~`, broad
structured count support, mesh/SPDE spatial support, or new q4 interval
coverage.

`meta_V(V = V)` and `meta_known_V(V = V)` still share the same additive known
sampling covariance route. The future proportional branch
`meta_V(..., scale = "proportional")` remains deliberately separate and
unimplemented.

## Files Changed

- `NEWS.md`
- `R/check.R`
- `R/methods.R`
- `man/sigma.drmTMB.Rd`
- `man/weights.drmTMB.Rd`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/22-likelihood-weights.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/adding-families.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/large-data.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/model-workflow.Rmd`
- `vignettes/testing-likelihoods.Rmd`
- `vignettes/which-scale.Rmd`
- `docs/dev-log/audits/2026-05-23-status-stale-audit-slices-1-10.md`
- `docs/dev-log/after-task/2026-05-23-status-stale-audit-slices-1-10.md`
- `docs/dev-log/check-log.md`

A local recovery checkpoint was also written at
`docs/dev-log/recovery-checkpoints/2026-05-23-145636-codex-checkpoint.md`.
That directory is ignored for new files unless a maintainer force-adds a
checkpoint intentionally.

## Checks Run

```sh
gh pr merge 314 --repo itchyshin/drmTMB --squash --delete-branch --subject "Add family tutorial figure QA slice (#314)"
git fetch origin
git rebase origin/main
air format R/check.R R/methods.R ROADMAP.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/16-phylo-spatial-common-math.md docs/design/22-likelihood-weights.md docs/design/34-validation-debt-register.md docs/dev-log/known-limitations.md vignettes/adding-families.Rmd vignettes/bivariate-coscale.Rmd vignettes/drmTMB.Rmd vignettes/formula-grammar.Rmd vignettes/large-data.Rmd vignettes/location-scale.Rmd vignettes/model-map.Rmd vignettes/model-workflow.Rmd vignettes/testing-likelihoods.Rmd vignettes/which-scale.Rmd
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'check-drm|meta-known-v|gaussian-aggregation')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::build_vignettes()"
air format NEWS.md docs/design/03-likelihoods.md docs/dev-log/audits/2026-05-23-status-stale-audit-slices-1-10.md docs/dev-log/after-task/2026-05-23-status-stale-audit-slices-1-10.md docs/dev-log/check-log.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript tools/codex-checkpoint.R --goal "status stale-claim audit slices 1-10" --next "review current diff, then commit or open PR for the status audit"
```

Outcomes:

- PR #314 merged successfully after its GitHub checks passed.
- `git rebase origin/main` completed successfully after skipping the already
  upstreamed rendered-figure commit.
- `devtools::document()` completed and regenerated `weights.drmTMB.Rd` and
  `sigma.drmTMB.Rd`.
- Targeted tests passed: `FAIL 0 | WARN 0 | SKIP 0 | PASS 293`.
- `git diff --check` was clean before the report files were added and again
  after final report formatting.
- `pkgdown::check_pkgdown()` reported no problems.
- `devtools::build_vignettes()` completed successfully and rebuilt the package
  vignettes.
- The final `pkgdown::check_pkgdown()` rerun after NEWS and dev-log additions
  also reported no problems.
- The local recovery checkpoint was written to
  `docs/dev-log/recovery-checkpoints/2026-05-23-145636-codex-checkpoint.md`.

## Consistency Audit

The main stale wording scan was:

```sh
rg -n 'meta_V\(\.\.\.|once the alias|alias/rename|preferred roadmap spelling|canonical marker is `meta_known|spatial q=4 blocks are still planned|bivariate spatial q=4 blocks|structured non-Gaussian random effects are not implemented' README.md ROADMAP.md NEWS.md R vignettes docs/design docs/dev-log/known-limitations.md -g '!*.html'
```

It now leaves only the intentional roadmap note for future
`meta_V(..., scale = "proportional")`.

The alias scan was:

```sh
rg -n 'meta_known_V\(V = V\)|meta_known_V\(V = vi\)|meta_known_V\(\)' README.md ROADMAP.md NEWS.md R vignettes docs/design docs/dev-log/known-limitations.md -g '!*.html'
```

Remaining hits are explicit compatibility-alias wording, historical NEWS or
roadmap entries, source-map references, and design notes where the alias itself
is under discussion.

The structured-status scan was:

```sh
rg -n 'spatial q=4|spatial q4|q4 spatial|animal q=4|animal q4|relmat q=4|relmat q4|Poisson.*phylo|phylo.*Poisson|non-Gaussian structured|structured non-Gaussian' README.md ROADMAP.md NEWS.md R vignettes docs/design docs/dev-log/known-limitations.md -g '!*.html'
```

Remaining hits describe either fitted first slices or planned neighbours. The
audit did not find a current high-traffic page that still says constant spatial
q4 is only planned, or that broad structured non-Gaussian support is fitted.

## Tests Of The Tests

The targeted test filter covers the changed diagnostic surface, the
`meta_known_V()` compatibility path, and Gaussian aggregation interactions near
known sampling covariance. The vignette build exercises the edited examples
that now use `meta_V(V = V)`. The pkgdown check catches navigation and reference
problems but is not a substitute for full `devtools::check()`.

No new unit tests were added because this task did not change parsing,
likelihoods, extractors, intervals, or exported APIs.

## Design-Doc And Documentation Updates

Formula grammar, likelihood, phylo/spatial common math, likelihood weights, and
validation-debt docs were updated where they made current-surface claims. The
location-scale, model-map, workflow, testing-likelihoods, large-data,
adding-families, bivariate-coscale, and which-scale vignettes now use the
preferred `meta_V(V = V)` spelling where they are teaching current syntax.

`NEWS.md` has a compact note because user-facing docs and generated Rd wording
changed.

## GitHub Issue Maintenance

The overlapping open trackers remain open:

- #5, "Implement covariance blocks for individual-difference models"
- #147, "Implement animal() and relmat() known-relatedness structured effects"
- #31, "Phase 6b: upgrade tutorials and user-facing learning path"

Issue searches used:

```sh
gh issue view 5 --repo itchyshin/drmTMB --json number,title,state,url
gh issue view 147 --repo itchyshin/drmTMB --json number,title,state,url
gh issue list --repo itchyshin/drmTMB --search "meta_V OR meta_known_V OR known covariance" --limit 20
gh issue list --repo itchyshin/drmTMB --search "stale claim meta_V known covariance spatial q4 implementation status" --limit 20
```

No issue was closed. The audit narrows documentation drift but does not finish
the broader feature trackers.

## What Did Not Go Smoothly

The thread crashed between the rendered figure QA closeout and the next audit
slice, so recovery had to start from repository evidence rather than chat
memory. The rebase also skipped the already upstreamed rendered-figure commit,
which was expected after PR #314 merged but worth recording for the next agent.

## Team Learning

Ada should keep treating post-crash work as a repository reconstruction task:
git state, PR state, checkpoints, check-log, and after-task reports first.
Boole and Rose should run stale syntax/status scans immediately after rapid API
or capability slices. Grace should keep pairing `pkgdown::check_pkgdown()` with
`devtools::build_vignettes()` when examples are edited, because one checks site
metadata while the other executes the vignette source.

## Known Limitations

This was not a full package check and did not rebuild the full pkgdown site. It
did not audit every historical roadmap or NEWS entry; those are allowed to
describe what was true at the time, provided current status surfaces are clear.

## Next Actions

The next small audit should continue through lower-traffic design notes that
still use `meta_known_V()` as an example without saying whether the alias or
the preferred spelling is intended. A separate feature task should handle any
real implementation gap discovered there.
