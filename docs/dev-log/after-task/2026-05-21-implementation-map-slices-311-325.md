# After Task: Implementation Map Slices 311-325

## Goal

Show and complete the next implementation-map slice set without opening new
likelihood code. The work should help users see the nearest fitted route while
giving future implementers a safer order for generic direct-SD syntax, p8/q8
location-scale covariance, structured q4 parity, and non-Gaussian structured
dependence.

## Result

`docs/design/63-implementation-map-slices-311-325.md` now records Slices
311-325 as planning gates. The implementation map and ROADMAP now show:

- 311-313: generic structured direct-SD syntax should use explicit level
  targeting and keep `sd_phylo*()` compatibility;
- 314-316: p8/q8 work must first separate q2, q4, q6, and q8 endpoints and
  define parameterization, diagnostics, and simulation gates;
- 317-318: spatial q4 is the main missing constant q4 parity lane, and q4
  intervals remain unavailable unless a method is explicitly fitted and tested;
- 319-320: non-Gaussian structured dependence should start with one q1 `mu`
  structured intercept candidate, using Poisson as an algebra smoke and NB2 as
  the first practical count target;
- 321-325: common planned requests now point to fitted alternatives and the
  rendered map becomes the maintenance surface.

## User Usefulness

This helps applied users avoid unsupported syntax. If they want zero-inflated
or hurdle random effects, the map points them to fixed-effect `zi ~ ...` or
`hu ~ ...` for now. If they want phylogenetic or spatial count dependence, the
map says that structural non-Gaussian likelihoods remain planned and directs
them to ordinary Poisson/NB2 `mu` random effects when a plain group is enough.

## Standing Roles

Ada kept the slice set integrated with PR #293. Boole guarded formula names and
direct-SD ambiguity. Pat checked that the map points users to fitted routes.
Darwin kept the future candidates tied to real count and structured-dependence
questions. Fisher kept simulation admission behind evidence. Gauss and Noether
made q and covariance dimensions explicit. Grace owns pkgdown. Rose recorded
the stale-claim scan and no-new-likelihood boundary.

## Checks

Local checks run:

```sh
air format NEWS.md ROADMAP.md vignettes/implementation-map.Rmd docs/design/63-implementation-map-slices-311-325.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-implementation-map-slices-311-325.md
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n "311-313|314-316|317-318|319-320|Common planned requests|Poisson as an algebra smoke|NB2 as the practical count target" pkgdown-site/articles/implementation-map.html pkgdown-site/ROADMAP.html
rg -n 'p8/q8.*are fitted for|p8/q8.*now fit|q8.*now fits|p8.*now fits|full p8.*is fitted|spatial q4.*now fits|spatial q4.*is fitted|generic sd\*.*(is implemented|now works|now accepts)|non-Gaussian structured.*now fits|zi.*random effects are (fitted|supported|available)|hu.*random effects are (fitted|supported|available)' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat -g '!*.html'
git diff --check
```

`pkgdown::check_pkgdown()` reported no problems, and `pkgdown::build_site()`
wrote the updated rendered pages. The rendered-page scan found the 311-313,
314-316, 317-318, and 319-320 rows plus the common planned-request section and
first-candidate wording. The refined stale-support scan found no false claims
that p8/q8, spatial q4, generic `sd*()`, non-Gaussian structured dependence, or
`zi`/`hu` random effects are fitted. `git diff --check` was clean.

## Remaining Boundaries

This task does not implement generic `sd*()` syntax, p8/q8 covariance, spatial
q4, q4 interval methods, non-Gaussian structured dependence, or random effects
in `zi`, `hu`, future `zoi`, or future `coi`.
