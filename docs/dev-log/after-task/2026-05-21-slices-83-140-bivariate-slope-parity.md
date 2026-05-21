# After Task: Slices 83-140 Bivariate Slope Parity

## Goal

Finish the next post-0.1.3 structural-parity slice set by fitting the first
ordinary bivariate slope-slope covariance route, while keeping p8/q8
location-scale random slopes, generic `sd*()` direct-SD unification, and
non-Gaussian structural dependence out of the fitted claims.

## Implemented

`biv_gaussian()` now fits matching slope-only `mu1`/`mu2` random-effect blocks
such as `(0 + x | p | id)` in both location formulas. The fitted covariance
row is labelled `cor(mu1:x,mu2:x | p | id)` and appears through `sdpars$mu`,
`corpars$mu`, `ranef()`, `corpairs()`, `summary()$covariance`,
`profile_targets()`, and `check_drm()`.

## Mathematical Contract

For group `j`, the fitted slice is:

```text
mu1_ij = eta1_ij + b1_j x_ij
mu2_ij = eta2_ij + b2_j x_ij
(b1_j, b2_j)' ~ N(0, Sigma_slope)
Sigma_slope = diag(sd1, sd2) R(rho_slope) diag(sd1, sd2)
```

This is a two-endpoint q=2 slope-slope block. It is not an intercept-slope
q=4 location block, not a residual-scale slope block, and not an all-four
p8/q8 location-scale block.

## Files Changed

- `R/drmTMB.R`
- `R/check.R`
- `tests/testthat/test-biv-gaussian.R`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `man/drmTMB.Rd`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/04-random-effects.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/45-cross-dpar-correlation-gate.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/52-phase-18-bivariate-rho12-ademp.md`
- `docs/design/57-structural-parity-next-slices.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/design/61-structural-parity-slices-83-140.md`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`
- `vignettes/which-scale.Rmd`

## Checks Run

```sh
air format R/drmTMB.R R/check.R tests/testthat/test-biv-gaussian.R README.md NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/04-random-effects.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md docs/design/30-labelled-covariance-block-assembler.md docs/design/33-phase-6c-core-random-effects.md docs/design/34-validation-debt-register.md docs/design/37-worked-example-inventory.md docs/design/41-phase-18-simulation-programme.md docs/design/45-cross-dpar-correlation-gate.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/52-phase-18-bivariate-rho12-ademp.md docs/design/57-structural-parity-next-slices.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/design/61-structural-parity-slices-83-140.md vignettes/bivariate-coscale.Rmd vignettes/formula-grammar.Rmd vignettes/model-map.Rmd vignettes/source-map.Rmd vignettes/which-scale.Rmd
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'biv-gaussian', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'check-drm|profile-targets', reporter = 'summary')"
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'Bivariate random slopes are planned|bivariate random slopes remain planned|bivariate random slopes are not|Bivariate Gaussian random slopes \| Planned|No for slopes|first future bivariate slope target|first future slope target|first planned slope path|first bivariate random-slope target.*planned|matching slope-only.*remain.*rejected|before exposing\s+bivariate random slopes' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat -g '!docs/site/**' -g '!*.html'
git diff --check
gh issue list --search 'bivariate slope OR random slope OR p8 OR q8' --limit 20
```

Focused bivariate, profile-target, and diagnostic tests passed. Full
`devtools::test(reporter = 'summary')` passed. `pkgdown` reported no problems.
The stale-wording scan returned no hits after the final roadmap wording
refresh.

## Tests Of The Tests

The new bivariate Gaussian test checks a seeded data-generating process with
correlated response-specific slope deviations. It asserts convergence, finite
positive slope SD estimates, the `cor(mu1:x,mu2:x | p | id)` label, the
`slope-slope` `corpairs()` class, numeric slope values in the TMB random-effect
design, direct profile-target mapping, `check_drm()` diagnostics, and
covariance-registry metadata. The same test now checks a failure path where
`mu1` and `mu2` use different slope variables, which must error before fitting.

## Consistency Audit

High-traffic status docs were updated so the fitted column includes matching
slope-only `mu1`/`mu2` covariance. The same docs keep intercept-plus-slope q=4,
residual-scale slope covariance, p8/q8 location-scale slope blocks,
predictor-dependent slope `corpair()` regressions, non-Gaussian structured
dependence, and generic `sd*()` direct-SD unification as planned.

## GitHub Issue Maintenance

`gh issue list --search 'bivariate slope OR random slope OR p8 OR q8' --limit
20` found existing open issues #33, #128, #5, #147, #31, and #58. No duplicate
issue was opened because #33 and #5 already cover the remaining slope and
individual-difference covariance work.

## What Did Not Go Smoothly

The first documentation pass still had wording where "matching slope-only" and
"rejected" appeared on the same roadmap line. That was true only for the
remaining q4/q8 neighbours, so the line was rewritten and the stale scan was
rerun.

## Team Learning

Ada and Rose should keep using a stale-wording pattern that searches for both
old planned-only claims and accidental phrase collisions. Pat's useful-user
check was the right constraint: a new user needs to see that slope-only
`mu1`/`mu2` is fitted, but must not infer that p8/q8 is fitted.

## Known Limitations

The fitted slice is ordinary Gaussian and slope-only. It does not implement
intercept-plus-slope bivariate covariance, residual-scale slope covariance,
all-four p8/q8 location-scale random slopes, slope-correlation regressions,
random effects in `rho12`, generic structured `sd*()` direct-SD syntax, or
non-Gaussian structured dependence.

## Next Actions

Plan p8/q8 before code. The design should separate the current q=2 slope-only
route, a possible q=4 location intercept-plus-slope route, q=6 partial
location-scale routes, and the full p8/q8 endpoint with eight SDs and 28
correlations. Generic `sd*()` unification should also be planned before
renaming existing phylogenetic direct-SD syntax.
