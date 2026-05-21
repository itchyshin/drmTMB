# After Task: 0.1.3 Candidate And Spatial Q2 Covariance

## Goal

Answer how many slices remain before the `0.1.3` preview, then close the
highest-risk fitted slice: coordinate-spatial bivariate Gaussian `mu1`/`mu2`
q=2 location covariance with release-candidate evidence.

## Implemented

- Added the first fitted bivariate coordinate-spatial q=2 location covariance:
  matching `spatial(1 | p | site, coords = coords)` terms in `mu1` and `mu2`
  now share a coordinate-derived precision and estimate one spatial mean-mean
  correlation.
- Generalised the structured `mu` helper surface so spatial, phylogenetic,
  `animal`, and `relmat` structured correlations can use the same covariance
  summary and `corpairs()` plumbing while still reporting distinct levels.
- Exposed the fitted spatial row through `corpars$spatial`,
  `corpairs(level = "spatial")`, `summary(fit)$covariance`, and direct
  `profile_targets()` labels.
- Kept richer spatial paths out of scope: spatial q=4, spatial `sigma`,
  predictor-dependent spatial `corpair()` regression, direct spatial SD
  surfaces, multiple spatial slopes, and spatial slope correlations remain
  planned.
- Bumped the candidate metadata to `0.1.3`, dated `NEWS.md`, and updated README,
  pkgdown, the getting-started article, and the roadmap preview wording.
- Added the `0.1.3` preview release checklist.

## Mathematical Contract

The fitted q=2 spatial path uses two response-specific coordinate fields with
one shared coordinate precision. The estimated structured correlation is a
spatial random-effect correlation between location deviations for `mu1` and
`mu2`; it is not residual `rho12`. Residual `rho12` remains an observation-level
coscale after the two response means and residual scales are modelled.

## Files Changed

- `R/drmTMB.R`, `R/methods.R`, `R/profile.R`
- `tests/testthat/test-spatial-gaussian.R`
- `tests/testthat/test-gaussian-location-scale.R`
- `man/corpairs.Rd`
- `DESCRIPTION`, `NEWS.md`, `README.md`, `_pkgdown.yml`, `ROADMAP.md`
- `vignettes/drmTMB.Rmd`, `vignettes/formula-grammar.Rmd`,
  `vignettes/model-map.Rmd`, `vignettes/phylogenetic-spatial.Rmd`,
  `vignettes/source-map.Rmd`
- `docs/design/02-family-registry.md`,
  `docs/design/08-meta-analysis.md`,
  `docs/design/09-phylogenetic-and-spatial-speed.md`,
  `docs/design/16-phylo-spatial-common-math.md`,
  `docs/design/33-phase-6c-core-random-effects.md`,
  `docs/design/34-validation-debt-register.md`,
  `docs/design/37-worked-example-inventory.md`,
  `docs/design/41-phase-18-simulation-programme.md`,
  `docs/design/45-cross-dpar-correlation-gate.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`,
  `docs/design/53-structural-dependence-article-split.md`
- `docs/dev-log/release-checklists/2026-05-20-0.1.3-preview-release.md`
- `docs/dev-log/after-task/2026-05-20-0-1-3-candidate-and-spatial-q2.md`
- `docs/dev-log/forgotten-promises-status-2026-05-20.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/structural-dependence-parity-2026-05-20.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`

## Checks Run

```sh
git diff --check
air format R/drmTMB.R R/methods.R R/profile.R tests/testthat/test-spatial-gaussian.R tests/testthat/test-gaussian-location-scale.R
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'spatial-gaussian', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'spatial-gaussian|phylo-gaussian|profile-targets|check-drm|biv-gaussian|corpairs', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'gaussian-location-scale|spatial-gaussian', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'gaussian-location-scale|spatial-gaussian|animal-relmat-gaussian', reporter = 'summary')"
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check(document = FALSE, args = '--no-manual', error_on = 'warning')"
rg -n "0\\.1\\.2|v0\\.1\\.2|0\\.1\\.3|v0\\.1\\.3|development" DESCRIPTION README.md _pkgdown.yml NEWS.md vignettes/drmTMB.Rmd ROADMAP.md
```

## Outcomes

- Focused spatial and neighboring structural tests passed.
- Full `devtools::test(reporter = "summary")` passed after correcting one stale
  boundary-test expectation for partial bivariate spatial syntax.
- Post-bump targeted tests for `gaussian-location-scale` and `spatial-gaussian`
  passed.
- Final compact release tests for `animal-relmat-gaussian`,
  `gaussian-location-scale`, and `spatial-gaussian` passed before staging.
- Post-bump `pkgdown::check_pkgdown()` reported no problems.
- Post-bump `devtools::check()` checked package version `0.1.3` and completed
  with 0 errors, 0 warnings, and 1 NOTE: `unable to verify current time`.
- The current-facing version scan shows 0.1.3 in active README, pkgdown, NEWS,
  roadmap, and getting-started install text. Historical 0.1.2 hits remain in
  old release notes and roadmap history.
- The current structural-dependence status text now says animal/`relmat()` are
  first-slice known-matrix `mu` intercepts, not phylogenetic-parity complete.

## Issue Maintenance

- Inspected issue #5.
- Added candidate evidence in
  <https://github.com/itchyshin/drmTMB/issues/5#issuecomment-4503612901>.
- Kept issue #5 open because the full individual-difference covariance endpoint
  still needs richer `mu`/`sigma` blocks, spatial q=4, spatial `sigma`,
  predictor-dependent spatial `corpair()` regression, slope correlations,
  simulations, diagnostics, intervals, and reader-facing examples.

## Standing Review Notes

- Ada: five release slices were the right estimate. The code slice and local
  release-candidate gate are now closed; PR CI, merge, tag, and install-smoke
  remain.
- Boole: the public syntax stays narrow and parseable: matching bivariate
  coordinate-spatial intercept terms only.
- Gauss and Noether: the structured random-effect correlation is kept separate
  from residual `rho12`, and profile labels use direct `eta_cor_phylo` plumbing
  while reporting as `cor:spatial:*`.
- Curie and Fisher: the test covers dense marginal likelihood agreement,
  `corpairs()` profile intervals, prediction, simulation, summary covariance,
  and unsupported slope boundaries.
- Grace: local package tests, pkgdown check, and R CMD check are clean enough for
  a preview PR. The single R CMD check NOTE is environmental.
- Pat and Darwin: the structural-dependence article now gives an applied
  spatial ecology reader the fitted q=2 route while naming what is still planned.
- Rose: broad `air format .` produced unrelated churn during the run; the process
  improvement is to run targeted formatting for release slices.

## Known Limitations

This branch prepares the `0.1.3` preview candidate. It does not create the
annotated `v0.1.3` tag, run tag-triggered CI, run the clean tagged install smoke,
or close issue #5. Those steps must happen after the release PR merges.

## Next Actions

1. Open a focused `0.1.3` candidate PR.
2. Let GitHub Actions run R-CMD-check on macOS, Ubuntu, and Windows.
3. Merge only after CI and rendered pkgdown review pass.
4. Push annotated tag `v0.1.3`.
5. Run `Rscript tools/install-smoke.R v0.1.3 0.1.3` and record tag evidence.
