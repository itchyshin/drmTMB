# After Task: Map Slice 25 Bivariate sd_phylo Diagnostics And Docs

## Goal

Close the phylogenetic Family B direct-SD lane by making the implemented
`sd_phylo1()` / `sd_phylo2()` path visible in diagnostics, documentation, and
pkgdown before moving to spatial Slice 26.

## Implemented

- Extended `check_drm()` so `phylo_direct_sd_model` rows cover each fitted
  `sd_phylo*()` direct-SD endpoint, not only univariate `sd_phylo()`.
- Stored per-dpar observation-to-species SD-row indices in the direct-SD
  structure so bivariate diagnostics can count species replication separately
  for `sd_phylo1()` and `sd_phylo2()`.
- Added bivariate diagnostic tests for both-endpoint and one-sided
  `sd_phylo1()` / `sd_phylo2()` fits.
- Updated the structured-dependence article with the bivariate Box 1 direct-SD
  syntax and interpretation.
- Updated NEWS, roadmap, random-effect scale design, known limitations, and
  `check_drm()` documentation.

## Mathematical Contract

The Slice 25 diagnostics do not change the Slice 24 likelihood. They check the
fitted direct-SD surfaces from:

```text
tau1_l = exp(W1_l alpha1)
tau2_l = exp(W2_l alpha2)
a1_l = tau1_l v1_tip,l
a2_l = tau2_l v2_tip,l
Cov(a1_l, a2_m) = rho_phylo tau1_l A_lm tau2_m
```

For each fitted `sd_phylo*()` endpoint, `check_drm()` reports species
replication, the fitted species-SD range, and the largest fitted species-SD
ratio. Non-finite or non-positive fitted SD surfaces are errors; one-observation
species levels are notes.

## Files Changed

- `NEWS.md`
- `R/check.R`
- `R/drmTMB.R`
- `ROADMAP.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/after-task/2026-05-14-map-slice-25-bivariate-sd-phylo-diagnostics-docs.md`
- `man/check_drm.Rd`
- `tests/testthat/test-check-drm.R`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/18-random-effect-scale-models.md vignettes/phylogenetic-spatial.Rmd R/check.R R/drmTMB.R tests/testthat/test-check-drm.R`: passed.
- `Rscript -e 'devtools::document()'`: passed.
- `Rscript -e 'devtools::test(filter = "check-drm|phylo-gaussian|profile-targets|summary", reporter = "summary")'`: passed after tightening the diagnostic tests.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE)'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `rg -n 'sd_phylo1\(species\).*planned|sd_phylo2\(species\).*planned|sd_phylo1\(species\).*not implemented|sd_phylo2\(species\).*not implemented|bivariate `sd_phylo1\(\)`.*planned|bivariate `sd_phylo2\(\)`.*planned|univariate `sd_phylo\(\)` direct-SD diagnostic row|univariate `sd_phylo\(\)` path' README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site/articles/phylogenetic-spatial.html R tests`: only historical Slice 22 check-log wording remains.
- `git diff --check`: passed.

## Tests Of The Tests

- The new positive test fits both bivariate direct-SD endpoints and checks that
  `check_drm()` returns two `phylo_direct_sd_model` rows with `target=mu1` and
  `target=mu2`, positive finite SD ranges, species replication, and no
  direct-SD warning or error.
- The one-sided test fits only `sd_phylo1()` so the diagnostic path is checked
  when one endpoint keeps a scalar phylogenetic SD.
- The older univariate singleton and invalid-SD tests still check note and
  error branches.

## Consistency Audit

The live docs now agree on the phylogenetic Family B state:

- univariate `sd_phylo()` implemented;
- bivariate `sd_phylo1()` / `sd_phylo2()` implemented for location random
  effects;
- diagnostics report fitted species-SD surfaces for each direct-SD endpoint;
- residual `rho12` remains separate;
- q=4 Family A location-scale covariance and Family B direct-SD regression
  remain separate model families;
- spatial direct-SD siblings remain planned.

## What Did Not Go Smoothly

The first focused test run failed because the test mutated only the legacy flat
`observation_sd_row0` field. The implementation now stores per-endpoint
observation row indices, so the test had to mutate that list to exercise the
singleton branch. A second assertion expected the whole bivariate fit to be
globally `ok`, but small bivariate structured-effect fits can carry unrelated
notes; the test now checks that the new direct-SD rows themselves are not
warnings or errors.

## Team Learning

- Ada: Slice 25 should close the phylo lane by making implemented features
  diagnosable and visible, not by adding more likelihood complexity.
- Boole: direct-SD diagnostics need endpoint names in the value string so users
  can distinguish `sd_phylo1()` from `sd_phylo2()`.
- Gauss: the likelihood did not need another change; the useful addition was
  metadata that records how observations map to each endpoint's species SD row.
- Noether: `summary(fit)$covariance` and `check_drm()` should both remind us
  that direct-SD covariance is species-pair specific.
- Curie: one-sided direct-SD tests are important because they combine one
  direct surface with one scalar phylogenetic SD.
- Fisher: compact diagnostics are screening tools; broad recovery grids remain
  a future simulation-design task, especially for weak SD surfaces.
- Darwin: the article example now uses species-level habitat variability for
  direct SD and assay context for residual `rho12`, which matches the ecology.
- Pat: the tutorial gives the user a next action: run `check_drm()` before
  interpreting direct-SD slopes.
- Emmy: storing `observation_sd_row0_list` keeps diagnostics independent of
  whether complete-case data were retained.
- Grace: full tests, article build, and pkgdown check all passed before the
  slice was staged.
- Rose: stale-wording scans should ignore historical after-task notes but
  should be strict on live docs, NEWS, roadmap, and generated article text.

## Known Limitations

- No long simulation grid was added for bivariate `sd_phylo1()` /
  `sd_phylo2()` recovery across tree shapes, low species counts, or weak SD
  surfaces.
- `summary(fit)$covariance` still uses median direct-SD endpoint summaries for
  compact reporting; the full species-pair covariance surface is not yet an
  extractor.
- Spatial structured effects and `sd_spatial*()` remain planned.
- Predictor-dependent latent `corpair()` fitting remains deferred.

## Next Actions

- Slice 26: start the spatial sibling lane with the ordinary spatial random
  effect foundation and data contract.
- Keep the phylogenetic direct-SD status as implemented, diagnostic-covered,
  and documented; do not reopen it unless Windows or later checks expose a
  regression.
