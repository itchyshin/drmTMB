# After Task: Phase 6c Support Matrix And Pkgdown Refresh

## Goal

Close the next planning slice for #438 by making the random-slope support
matrix labels explicit, fixing pkgdown-facing inconsistencies found by the
agent team, and rebuilding both rendered pkgdown mirrors.

## Implemented

- Added a #438 support-matrix label table to
  `docs/design/80-four-week-random-slope-digital-twin-sprint.md`, separating
  fitted, simulation-ready, smoke/source-only, diagnostic-only, design-only, and
  blocked cells.
- Updated README, model-map, implementation-map, meta-analysis, which-scale,
  location-scale, formula-grammar, phylogenetic, count, and source-map prose so
  fitted one-slope Gaussian structured paths are not described as wholly
  planned.
- Added the `meta_V(V = V) + sigma ~ moderator` Hessian caveat to public docs,
  known limitations, and meta-analysis design notes.
- Corrected `GLLVM.jl`/local `gllvmTMB.jl` checkout wording in the sister-repo
  lesson memo, its after-task note, and the check log.
- Updated the project-local prose-review skill and team-improvement log so
  future prose reviews use `meta_V(V = V)` as current and rebuild rendered
  pkgdown mirrors when stale generated pages are part of the audit.

## Mathematical Contract

No likelihood, parser, formula grammar, TMB, or extractor code changed. The
change is a status and documentation correction. It records that first
univariate Gaussian `mu` one-slope paths exist for `phylo()`, `spatial()`,
`animal()`, and `relmat()`, while multiple structured slopes, structured slope
correlations, residual-scale structured slopes, structured `rho12`, and
non-Gaussian structured slopes remain planned or blocked.

## Files Changed

- `.agents/skills/prose-style-review/SKILL.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/08-meta-analysis.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/48-phase-18-meta-v-ademp.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/design/67-sdstar-p8-poisson-q1.md`
- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md`
- `docs/dev-log/team-improvements.md`
- `vignettes/count-nbinom2.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/implementation-map.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/meta-analysis.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-models.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/source-map.Rmd`
- `vignettes/which-scale.Rmd`

## Checks Run

```sh
git diff --check
rg -n "gllvmTMB\\.jl is|GLLVM\\.jl / gllvmTMB\\.jl|phylogenetic slopes such as|intercept-only phylogenetic|spatial structured effects\\.|spatial, animal, or" README.md vignettes docs/design .agents/skills -g '!docs/pkgdown/**'
rg -n "usual interval routes$|usual interval routes \\||meta_known_V\\(V = V\\).*stable|Keep terms stable:.*meta_known|phylo\\(1 \\+ x \\| species, tree = tree\\).*remains planned|phylo\\(1 \\+ x \\| species, tree = tree\\).*planned" README.md vignettes docs/design .agents/skills -g '!docs/pkgdown/**'
Rscript --vanilla -e "pkgdown::build_site()"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "pkgdown::build_site(override = list(destination = 'pkgdown-site/dev'))"
rg -n "usual interval routes|phylogenetic slopes such as|implemented path is an intercept-only phylogenetic|intercept-only phylogenetic effect|gllvmTMB\\.jl is|GLLVM\\.jl / gllvmTMB\\.jl" pkgdown-site/index.html pkgdown-site/articles pkgdown-site/ROADMAP.html pkgdown-site/search.json pkgdown-site/dev/index.html pkgdown-site/dev/articles pkgdown-site/dev/ROADMAP.html pkgdown-site/dev/search.json
rg -n "meta_V\\(V = V\\).*pdHess = FALSE|sigma ~ moderator|offset\\(0\\.5 \\* log\\(v\\)\\)|Issue #438 Support-Matrix Labels|source/diagnostic first slices" README.md vignettes docs/design docs/dev-log/known-limitations.md pkgdown-site/index.html pkgdown-site/articles pkgdown-site/dev/index.html pkgdown-site/dev/articles pkgdown-site/ROADMAP.html pkgdown-site/dev/ROADMAP.html
```

`git diff --check` passed. The source stale-pattern scan returned no
unresolved current-doc hits; remaining matches were narrow current contexts or
historical design records. `pkgdown::build_site()` and
`pkgdown::check_pkgdown()` both completed, with `check_pkgdown()` returning
`No problems found`. The development mirror was rebuilt separately because it
is not overwritten by the normal release build.

## Tests Of The Tests

No package tests were run because this slice changed prose, ledgers, and
pkgdown source pages only. The useful validation is rendered-page freshness,
stale-term scans, and explicit support-matrix labels.

## Team Review

- Grace required release and development pkgdown mirror rebuilds after Carson
  found stale rendered HTML.
- Rose caught the remaining structured-slope and sister-repo naming drift.
- Fisher/Mendel supplied the #438 support-matrix labels and evidence
  categories.
- Boole kept `meta_V(V = V)` current and `meta_known_V(V = V)` deprecated.

## Next Actions

1. Comment on #438 with the new support-matrix label table and rendered-page
   evidence.
2. Use #439 and #440 to move from support labels to capability-specific
   closeout checks.
3. Keep #417 open for the underlying `meta_V(V = V) + sigma ~ moderator`
   Hessian/inference limitation; this slice documents the caveat but does not
   fix the numerical issue.
