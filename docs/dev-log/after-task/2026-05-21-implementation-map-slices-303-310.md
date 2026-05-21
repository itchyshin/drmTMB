# After Task: Implementation Map Slices 303-310

## Goal

Answer whether the next slices should implement random effects for `zi`, `hu`,
future `zoi`, or future `coi`, and close Slices 303-310 as conservative
planning/documentation work rather than new likelihood expansion.

## Result

Slice 307 is now a no-fit decision gate. `zi`, `hu`, future `zoi`, and future
`coi` remain fixed-effect-only or planned for now. The new design note
`docs/design/62-implementation-map-slices-303-310.md` records the evidence
needed before those components should get random effects: clear applied use
case, family-specific recovery tests, boundary diagnostics, prediction
semantics, interval-status rules, and tutorial guidance.

The implementation map now lists Slices 303-310 as roadmap rows:

- 303 generic `sd*()` design;
- 304 p8/q8 location-scale planning;
- 305 spatial and relatedness q=4 parity plan;
- 306 q=4 interval policy;
- 307 inflation and hurdle random-effect gate;
- 308 non-Gaussian structured-dependence candidate map;
- 309 implementation-map maintenance gate;
- 310 user-route examples.

## User Usefulness

This keeps the package focused. Users who need zero-inflated or hurdle models
can use fixed-effect `zi ~ ...` and `hu ~ ...` without being invited into weak
latent models. The next modelling energy stays on direct-SD clarity, p8/q8
design, q=4 structured parity, and carefully chosen non-Gaussian structured
dependence.

## Standing Roles

Ada kept the slices scoped to docs and planning. Pat checked that the map tells
users what to fit now. Darwin asked whether the deferred random effects answer
real biological questions yet. Boole kept syntax names stable. Fisher kept
simulation admission behind evidence. Gauss and Noether watched covariance and
latent-layer claims. Grace owns the pkgdown check. Rose recorded the no-fit
decision so later slices do not quietly reopen it.

## Checks

Local checks run:

```sh
air format NEWS.md ROADMAP.md vignettes/implementation-map.Rmd docs/design/62-implementation-map-slices-303-310.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-implementation-map-slices-303-310.md
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n "Slice 307|fixed-effect-only|zoi|coi|p8/q8|q=4 interval|Generic.*sd" pkgdown-site/articles/implementation-map.html pkgdown-site/ROADMAP.html
rg -n 'zi.*random effects are (fitted|supported|available)|hu.*random effects are (fitted|supported|available)|zoi.*random effects are (fitted|supported|available)|coi.*random effects are (fitted|supported|available)|inflation random effects are fitted|hurdle random effects are fitted' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat -g '!*.html'
git diff --check
```

`pkgdown::check_pkgdown()` reported no problems, and `pkgdown::build_site()`
wrote the updated rendered pages. The rendered-page scan found Slice 307,
fixed-effect-only, `zoi`, `coi`, p8/q8, q=4 interval, and generic `sd*()`
roadmap wording. The refined stale-support scan found no claims that `zi`,
`hu`, future `zoi`, or future `coi` random effects are fitted, supported, or
available. `git diff --check` was clean.

## Remaining Boundaries

This task does not implement generic `sd*()` syntax, p8/q8 covariance, spatial
q=4, animal/`relmat()` q=4 extensions, q=4 profile intervals, non-Gaussian
structured dependence, or random effects in `zi`, `hu`, future `zoi`, or future
`coi`.
