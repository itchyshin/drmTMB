# After Task: Implementation Map Slices 326-340

## Goal

Complete the next implementation-map slice set as issue-ready pre-code
specifications. The work should make the next actual implementation smaller
and safer without adding new likelihood code or public fitted claims.

## Result

`docs/design/64-implementation-map-slices-326-340.md` now records:

- 326-328: generic direct-SD grammar, compatibility, parser-boundary, and test
  requirements before any structured direct-SD implementation;
- 329-331: p8/q8 endpoint registry, staged implementation options, and
  simulation gates;
- 332-333: spatial q4 parity and q4 diagnostic/interval pre-code checklists;
- 334-336: Poisson q1 structured intercept as the algebra smoke and NB2 q1
  structured intercept as the first practical count target, with an ADEMP stub
  required before simulation code;
- 337-340: user-route examples, stale-claim checks, roadmap/NEWS/check-log
  sync, and validation.

The public implementation map now gives more explicit fitted alternatives for
planned requests such as spatial direct-SD regression, p8/q8 location-scale
slopes, spatial q4, and phylogenetic/spatial count models.

## User Usefulness

This helps users because the next roadmap row now says what to do today when
the desired richer model is not fitted. It also prevents premature coding: the
first non-Gaussian structured-count route is narrowed to a q1 `mu` structured
intercept, and p8/q8 is broken into smaller endpoint classes before any public
syntax opens.

## Standing Roles

Ada integrated the map, roadmap, NEWS, check-log, and after-task notes. Boole
kept direct-SD syntax from colliding with ordinary `sd(group)`. Pat checked
that planned rows point to fitted alternatives. Darwin kept the candidate count
routes tied to real applied count questions. Fisher required simulation gates
before Phase 18 admission. Gauss and Noether kept q dimensions and covariance
claims explicit. Grace owns pkgdown validation. Rose recorded stale-support
scans and the no-new-likelihood boundary.

## Checks

Local checks run:

```sh
air format NEWS.md ROADMAP.md vignettes/implementation-map.Rmd docs/design/64-implementation-map-slices-326-340.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-implementation-map-slices-326-340.md
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n "326-328|329-331|332-333|334-336|spatial q4 parity|Poisson q1|NB2 q1" pkgdown-site/articles/implementation-map.html pkgdown-site/ROADMAP.html
rg -n 'generic sd\*.*(is implemented|now works|now accepts)|p8/q8.*(is fitted|are fitted|now fit)|spatial q4.*(is fitted|now fits)|Poisson.*structured.*now fits|NB2.*structured.*now fits|non-Gaussian structured.*now fits' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat -g '!*.html'
git diff --check
```

`pkgdown::check_pkgdown()` reported no problems, and `pkgdown::build_site()`
wrote the updated rendered pages. The rendered-page scan found the 326-328,
329-331, 332-333, and 334-336 rows, plus spatial q4 and Poisson/NB2 q1
wording. The stale-support scan found no false fitted claims for generic
`sd*()`, p8/q8, spatial q4, Poisson/NB2 structured-count routes, or
non-Gaussian structured dependence. `git diff --check` was clean.

## Remaining Boundaries

This task does not implement generic `sd*()` syntax, p8/q8 covariance, spatial
q4, q4 interval methods, Poisson or NB2 structured-count likelihoods,
non-Gaussian structured dependence, or random effects in `zi`, `hu`, future
`zoi`, or future `coi`.
