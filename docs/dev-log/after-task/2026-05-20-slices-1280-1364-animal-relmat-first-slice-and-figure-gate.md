# After Task: Slices 1280-1364 Animal/Relmat First Slice And Figure Gate

## Goal

Continue after the 1239-1278 Actions/figure audit without neglecting quality:
add the first fitted known-matrix `animal()` and `relmat()` Gaussian location
slice, keep structural-dependence parity promises conservative, and recheck the
rendered figure-gallery and simulation-grammar pages after the recent visual
slips.

## Implemented

- Added the first fitted univariate Gaussian `mu` known-relatedness intercept
  slice:
  `animal(1 | id, A = A)`,
  `animal(1 | id, Ainv = Ainv)`,
  `relmat(1 | id, K = K)`, and
  `relmat(1 | id, Q = Q)`.
- Kept the public model status narrow: pedigree construction, slopes, `sigma`
  relatedness models, bivariate relatedness covariance, and `corpair()` parity
  remain planned.
- Added extractor/diagnostic visibility for the first slice: fitted SDs in
  `sdpars$mu`, conditional effects through `ranef("animal_mu")` or
  `ranef("relmat_mu")`, direct SD profile targets, and `check_drm()`
  replication/matrix diagnostics.
- Added animal/`relmat()` tests and snapshots for dense and precision matrix
  routes, malformed inputs, extractor labels, direct profile targets, and
  diagnostics.
- Updated README, NEWS, ROADMAP, formula grammar, family registry, likelihood
  notes, validation-debt docs, Phase 18 admission docs, structural-dependence
  docs, reference docs, and pkgdown articles so implemented and planned
  surfaces are not blurred.
- Repaired figure recipes that still let warnings, pseudo language, tiny
  interval ambiguity, or alignment problems through the rendered pages.

## Mathematical Contract

The fitted slice is a univariate Gaussian location random-intercept model with
a known latent relatedness covariance or precision matrix. For `animal(A = A)`
and `relmat(K = K)`, the model uses a covariance matrix. For
`animal(Ainv = Ainv)` and `relmat(Q = Q)`, the model uses a precision matrix.

This is not a pedigree parser, not a random-slope model, not a residual
`sigma` relatedness model, not a bivariate covariance block, and not a
`corpairs()` correlation route. The first slice exists so the package can now
test the known-matrix likelihood, diagnostics, profile target, and
reader-facing wording before opening the larger parity ladder.

## Files Changed

- `R/drmTMB.R`
- `R/check.R`
- `R/formula-markers.R`
- `R/gaussian-aggregation.R`
- `R/phylo-utils.R`
- `R/profile.R`
- `tests/testthat/test-animal-relmat-gaussian.R`
- `tests/testthat/_snaps/animal-relmat-gaussian.md`
- `man/animal.Rd`
- `man/relmat.Rd`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/44-structured-slope-parity-gate.md`
- `docs/design/45-cross-dpar-correlation-gate.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/53-structural-dependence-article-split.md`
- `vignettes/figure-gallery.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/simulation-plot-grammar.Rmd`
- `docs/dev-log/figure-audits/2026-05-20-slices-1280-1364-structural-parity/figure-audit.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian', reporter = 'summary')"
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all('.'); pkgdown::build_article('figure-gallery', lazy = FALSE, new_process = FALSE, quiet = TRUE)"
Rscript -e "devtools::load_all('.'); pkgdown::build_article('simulation-plot-grammar', lazy = FALSE, new_process = FALSE, quiet = TRUE)"
Rscript -e "devtools::load_all('.'); pkgdown::build_article('model-map', lazy = FALSE, new_process = FALSE, quiet = TRUE)"
Rscript -e "devtools::load_all('.'); pkgdown::build_article('formula-grammar', lazy = FALSE, new_process = FALSE, quiet = TRUE)"
Rscript -e "devtools::load_all('.'); pkgdown::build_article('phylogenetic-spatial', lazy = FALSE, new_process = FALSE, quiet = TRUE)"
Rscript -e "pkgdown::check_pkgdown()"
rg -n "Warning|deprecated|geom_errorbarh|height.*translated|Error in|could not find function|pseudo-replicate|pseudo replicate|pseudo" \
  pkgdown-site/articles/figure-gallery.html \
  pkgdown-site/articles/simulation-plot-grammar.html \
  pkgdown-site/articles/model-map.html \
  pkgdown-site/articles/formula-grammar.html \
  pkgdown-site/articles/phylogenetic-spatial.html \
  vignettes/figure-gallery.Rmd \
  vignettes/simulation-plot-grammar.Rmd
rg -n "no fitted likelihood|future lower-level|Planned, not fitted yet|animal.*planned-only|relmat.*future lower-level|markers only until pedigree or known-matrix likelihoods|reserved structured-effect markers until the likelihood" \
  pkgdown-site/articles/model-map.html \
  pkgdown-site/articles/phylogenetic-spatial.html \
  pkgdown-site/articles/formula-grammar.html \
  pkgdown-site/articles/figure-gallery.html \
  --glob "!pkgdown-site/search.json"
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian|spatial-gaussian|phylo-gaussian|profile-targets|check-drm|nongaussian-structured-boundary|package-skeleton', reporter = 'summary')"
git diff --check
```

Targeted tests passed after the implementation and figure/doc repairs. The
broader focused structural set also passed locally, ending with `DONE` after
animal/relmat, spatial, phylo, profile-target, `check_drm`,
non-Gaussian-boundary, and package-skeleton tests.

`pkgdown::check_pkgdown()` reported no problems.

The generated-site warning scan had only the deliberate simulation section
title "Warnings and failures stay visible"; no accidental deprecated ggplot
warnings, pseudo-replicate wording, or stale planned-only animal/`relmat()`
claims remained in the checked pages.

## Tests Of The Tests

The animal/`relmat()` tests cover both covariance and precision inputs:
`A`, `Ainv`, `K`, and `Q`. They also check a malformed-input path, extractor
surface names, direct profile targets, `check_drm()` rows, and the status split
between the fitted known-matrix intercept route and still-planned slope or
pedigree routes.

The figure checks are tests of the communication layer: rendered PNGs were
opened directly, generated HTML was scanned for warning/deprecation output, and
the simulation figures now use explicit fixture replicate-error rows rather
than fake clouds reconstructed from aggregate summaries.

## Consistency Audit

Rose used these status scans:

```sh
rg -n "animal\\(|relmat\\(|sd_animal|sd_spatial|sd_relmat|sd_phylo|known-matrix|known matrix|first slice|planned" \
  README.md ROADMAP.md NEWS.md \
  docs/design/01-formula-grammar.md \
  docs/design/02-family-registry.md \
  docs/design/03-likelihoods.md \
  docs/design/34-validation-debt-register.md \
  docs/design/41-phase-18-simulation-programme.md \
  docs/design/44-structured-slope-parity-gate.md \
  docs/design/45-cross-dpar-correlation-gate.md \
  docs/design/46-pre-simulation-readiness-matrix.md \
  docs/design/53-structural-dependence-article-split.md \
  vignettes/formula-grammar.Rmd \
  vignettes/model-map.Rmd \
  vignettes/phylogenetic-spatial.Rmd \
  man/animal.Rd man/relmat.Rd
```

The current docs consistently say that `animal(A/Ainv)` and `relmat(K/Q)` fit a
known-matrix Gaussian `mu` intercept first slice, while pedigree construction,
slopes, `sigma`, bivariate covariance, direct-SD parity, and `corpair()` parity
remain planned. No new public `sd_animal*()`, `sd_spatial*()`, or
`sd_relmat*()` family-specific names were added in this slice.

## GitHub Issue Maintenance

Ada inspected the overlapping open issues:

- #147, "Implement animal() and relmat() known-relatedness structured effects"
- #58, "Phase 17: visualization layer for fitted models and simulation outputs"
- #255, "Phase 18: preserve replicate-level simulation artifacts for uncertainty displays"
- #265, "Design public bootstrap intervals for hard fits"

Issue #147 should stay open. This branch closes only the known-matrix Gaussian
`mu` intercept subtask; the larger animal/`relmat()` parity ladder still needs
pedigree construction, slopes, `sigma`, bivariate covariance, `corpairs()`,
profile/bootstrap intervals, examples, and recovery simulations. Issues #58
and #255 also stay open because the current figure repairs are a gate and
contract repair, not the final public plotting API or comprehensive Phase 18
artifact policy.

Issue comments added:

- #147: <https://github.com/itchyshin/drmTMB/issues/147#issuecomment-4502036396>
- #58: <https://github.com/itchyshin/drmTMB/issues/58#issuecomment-4502039264>
- #255: <https://github.com/itchyshin/drmTMB/issues/255#issuecomment-4502042474>

## What Did Not Go Smoothly

- An early broad formatter call touched unrelated files; Ada reverted that
  unrelated drift and kept the final diff scoped to the animal/`relmat()`,
  structural-doc, and figure-gate files.
- A first article render in a new R process used the installed package and
  failed to find local `predict_parameters()`. Grace corrected the render path
  to load the source tree first.
- One intermediate figure patch inherited the wrong data layer and failed with
  missing `bias_error`/`error` aesthetics. Fisher/Rose caught the data-grain
  mismatch and the recipe now uses explicit `inherit.aes = FALSE` layers where
  needed.

## Team Learning

- Ada: keep moving toward the slice target, but close each local capability
  with code, docs, tests, figures, issue state, and a report before opening the
  next lane.
- Florence: rendered PNGs are the truth; source recipes and contact sheets are
  navigation aids only.
- Fisher: visual data grain is part of the statistical claim. Replicate errors,
  fitted-row predictions, aggregate RMSE, binomial MCSE, Wald intervals, and
  unavailable intervals must not share one vague "uncertainty" label.
- Pat and Darwin: worked examples should show model outputs visually after the
  figure grammar stabilizes, especially for animal, phylo, spatial, and
  `relmat()` routes.
- Grace: pkgdown article renders and warning scans belong in the same loop as
  tests when user-facing examples change.
- Rose: repeated small visual slips signal a process problem, not a Florence
  problem alone.

These were role perspectives, not spawned agents.

## Known Limitations

- `animal(pedigree = ...)` remains planned; this slice requires a precomputed
  additive relationship or inverse-relatedness matrix.
- Animal and `relmat()` slopes remain planned.
- Animal and `relmat()` `sigma` relatedness models remain planned.
- Bivariate animal/`relmat()` covariance blocks and `corpairs()` rows remain
  planned.
- Direct-SD naming parity is unresolved. The current branch does not add
  `sd_animal*()`, `sd_spatial*()`, or `sd_relmat*()` names.
- The current figure gallery is much cleaner, but diagnostic/status figures
  still need a future design pass before they become publication templates.

## Next Actions

1. Prepare a small PR for the animal/`relmat()` first slice plus current figure
   gate, then let GitHub Actions verify the installed-package path.
2. Start the next parity lane only after the PR is green: likely spatial
   "toward phylo parity" or animal/`relmat()` q=2 location-location planning,
   keeping the public direct-SD naming question unresolved until designed.
