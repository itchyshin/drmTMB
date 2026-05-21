# After Task: Implementation Map

## Goal

Create a reader-facing implementation map that answers what can be fitted now
across random effects, structural dependence, q, random slopes, `corpairs()`,
zero inflation, and hurdle components, while keeping planned surfaces out of
analysis claims.

## Result

`vignettes/implementation-map.Rmd` now gives the package a dedicated availability
ledger. It separates fitted, first-slice, fixed-effect-only, planned, and
blocked surfaces for:

- one-response and bivariate Gaussian models;
- ordinary Gaussian and count random effects;
- ordinary and structured `corpairs()` layers;
- `phylo()`, coordinate `spatial()`, `animal()`, and `relmat()` routes;
- direct phylogenetic SD formulas;
- fixed-effect `zi` and `hu` count components;
- non-Gaussian scale, shape, zero-inflation, hurdle, ordinal, and bounded
  surfaces that remain fixed-effect only or planned.

The page is linked from the pkgdown Model Guides menu, the article index, the
README, and `model-map`. ROADMAP Slice 302 and NEWS now treat the page as the
maintenance surface for future parity slices.

## User Usefulness

This is useful for applied users because it stops the common mistake of reading
a nearby fitted row as a broader fitted model. A user can now see, for example,
that Poisson/NB2 ordinary `mu` slopes are fitted, `zi` and `hu` are fixed-effect
only, one-slope Gaussian `phylo()`/`animal()`/`relmat()` routes are fitted, and
non-Gaussian structured dependence remains planned.

## Standing Roles

Ada integrated the map with README, pkgdown, ROADMAP, NEWS, and the check-log.
Pat and Darwin read the tables as user route guidance. Boole checked that q,
component names, and formula examples stay parseable. Fisher separated fitted
evidence from simulation and interval debt. Gauss and Noether guarded the
random-effect and covariance claims. Grace owns the pkgdown check. Rose recorded
the stale-status risk that the page is meant to prevent.

## Checks

Local checks run:

```sh
air format _pkgdown.yml README.md ROADMAP.md NEWS.md vignettes/model-map.Rmd vignettes/implementation-map.Rmd docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-implementation-map.md
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
git diff --check
```

`pkgdown::check_pkgdown()` reported no problems, and `pkgdown::build_site()`
wrote `pkgdown-site/articles/implementation-map.html`. The rendered-page scan
found the implementation map in the homepage menu, articles index, model-map
article, and sitemap. The stale-status scan found no old planned-only claims for
the first one-slope `phylo()`, `animal()`, or `relmat()` Gaussian `mu` paths.
`git diff --check` was clean.

## Remaining Boundaries

This task changes documentation only. It does not implement generic `sd*()`
direct-SD unification, p8/q8 location-scale slope models, spatial q=4
location-scale blocks, non-Gaussian structured dependence, random effects in
`zi` or `hu`, random effects in `rho12`, or derived q=4 profile intervals.
