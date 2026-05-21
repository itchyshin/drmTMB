# After Task: Implementation Map Slices 356-405

## Goal

Close the fitted Gaussian spatial parity lane at Slice 380 and turn Slices
381-405 into non-Gaussian structured-dependence planning. The user corrected the
scope before count likelihood code landed, so the implementation stops at
constant coordinate-spatial q=4 and the non-Gaussian work remains a roadmap.

## Implemented

`biv_gaussian()` now accepts matching labelled `spatial(1 | p | site, coords =
coords)` terms in `mu1`, `mu2`, `sigma1`, and `sigma2`. The fitted model reports
four coordinate-spatial endpoint SDs and six latent spatial correlations through
`corpairs(level = "spatial")`, `summary()$covariance`, `profile_targets()`, and
`check_drm()`.

## Mathematical Contract

The fitted q=4 spatial route is a constant bivariate Gaussian location-scale
block. It is intercept-only, uses one coordinate-derived spatial precision, and
keeps latent spatial correlations separate from residual `rho12`. The q=4
correlation rows are derived summaries and do not have direct profile intervals.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-spatial-gaussian.R`
- `README.md`, `NEWS.md`, `ROADMAP.md`
- `vignettes/implementation-map.Rmd`, `vignettes/model-map.Rmd`,
  `vignettes/spatial-models.Rmd`, `vignettes/structural-dependence.Rmd`,
  `vignettes/phylogenetic-spatial.Rmd`, `vignettes/formula-grammar.Rmd`,
  `vignettes/drmTMB.Rmd`, `vignettes/source-map.Rmd`,
  `vignettes/figure-gallery.Rmd`
- selected design ledgers under `docs/design/`
- `docs/dev-log/check-log.md`
- `docs/design/66-implementation-map-slices-356-405.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = 'spatial-gaussian')"
air format R/drmTMB.R tests/testthat/test-spatial-gaussian.R NEWS.md ROADMAP.md README.md vignettes/implementation-map.Rmd vignettes/model-map.Rmd vignettes/spatial-models.Rmd vignettes/structural-dependence.Rmd vignettes/phylogenetic-spatial.Rmd vignettes/formula-grammar.Rmd vignettes/drmTMB.Rmd vignettes/source-map.Rmd vignettes/figure-gallery.Rmd docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/16-phylo-spatial-common-math.md docs/design/28-double-hierarchical-endpoint.md docs/design/33-phase-6c-core-random-effects.md docs/design/34-validation-debt-register.md docs/design/39-visualization-grammar.md docs/design/41-phase-18-simulation-programme.md docs/design/45-cross-dpar-correlation-gate.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/56-phase-18-spatial-q2-ademp.md docs/design/57-structural-parity-next-slices.md docs/design/64-implementation-map-slices-326-340.md docs/design/66-implementation-map-slices-356-405.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-implementation-map-slices-356-405.md
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n "356-370|371-380|381-405|Spatial q4 fitted parity|Non-Gaussian structured planning|constant q=4" pkgdown-site/articles/implementation-map.html pkgdown-site/ROADMAP.html pkgdown-site/articles/spatial-models.html pkgdown-site/articles/model-map.html
rg -n 'spatial q4.*planned but not implemented|Spatial q=4 location-scale blocks are planned|non-Gaussian structured.*now fits|Poisson.*structured.*now fits|NB2.*structured.*now fits' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat -g '!*.html'
git diff --check
```

Results: spatial-gaussian passed with 125 assertions, `air format` completed
without output, `pkgdown::check_pkgdown()` reported no problems,
`pkgdown::build_site()` completed, rendered scans found the new slice rows and
spatial q4 wording, stale-support scans found no false non-Gaussian fitted
claims or stale spatial-q4 planned wording in the scanned high-traffic files,
and `git diff --check` was clean.

## Tests Of The Tests

The new test exercises the fitted route and two failure paths. It checks endpoint
labels, q=4 model metadata, six `corpairs()` rows, six covariance-summary rows,
derived profile-target status, the `biv_spatial_q4_covariance` diagnostic, and
errors for partial or unlabelled spatial q4 blocks.

## Consistency Audit

Ada checked the implementation boundary: fitted support ends at Gaussian
coordinate-spatial q=4. Gauss and Noether checked that the existing structured
q4 backend is reused rather than a new likelihood parameterization. Fisher and
Curie checked evidence through focused tests and diagnostic rows. Pat and Darwin
checked that the map answers an applied user's question: "Can I fit this exact
spatial location-scale model today?" Grace checked that pkgdown validation is
part of the closeout. Rose checked stale fitted-versus-planned wording.

## GitHub Issue Maintenance

No new issue was opened in this slice. The work updates the existing
implementation-map and spatial parity lane on PR #293.

## What Did Not Go Smoothly

The first pass briefly drifted toward Poisson/NB2 structured q1 implementation.
That code was backed out after the user clarified the boundary. The correction
is now explicit: Slices 381-405 are planning only.

## Team Learning

The team should keep a visible "stop implementation here" row whenever a slice
set changes from fitted work to planning. That is especially important for
non-Gaussian structured dependence, where ordinary count random effects can make
broader structured support look closer than it is.

## Known Limitations

- Mesh/SPDE spatial inputs remain planned.
- Multiple spatial slopes, spatial slope correlations, and bivariate spatial
  slope blocks remain planned.
- Standalone or partial spatial `sigma` routes remain planned outside the fitted
  all-four q=4 block.
- Direct spatial SD surfaces and predictor-dependent spatial `corpair()`
  regressions remain planned.
- Non-Gaussian structured effects remain planned for Poisson, NB2, zero
  inflation, hurdle, ordinal, bounded-response, shape, and mixed-response
  routes.

## Next Actions

Use Slices 381-405 to open issue-ready non-Gaussian structured-dependence gates:
Poisson q1 `mu` structured intercept first as an algebra smoke, NB2 q1 `mu`
structured intercept second as the practical count target, then separate issues
for `zi`, `hu`, scale, shape, ordinal, bounded-response, and mixed-response
routes only after the first narrow route has evidence.
