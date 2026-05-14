# After Task: Slice 19 Phylogenetic q4 Tutorial Example

## Goal

Add a reader-facing fitted phylogenetic q=4 location-scale example while keeping
predictor-dependent latent `corpair()` models and q=4 profile intervals clearly
marked as future work.

## Implemented

- Added a simulated two-trait tolerance example to
  `vignettes/phylogenetic-spatial.Rmd`.
- Fit the public all-four q=4 syntax with matching labelled
  `phylo(1 | p | species, tree = tree)` terms in `mu1`, `mu2`, `sigma1`, and
  `sigma2`.
- Included `rho12 = ~ assay_context` as the residual coscale predictor.
- Showed `corpairs(fit_phylo_q4, level = "phylogenetic")` for the six latent
  phylogenetic q=4 correlations.
- Showed `rho12(fit_phylo_q4)` as the residual-correlation layer.
- Showed q=4-specific `check_drm()` rows and `profile_targets()` rows so readers
  see the current inference boundary.
- Added planned singular `corpair(...) ~ w` syntax for future
  predictor-dependent latent phylogenetic correlations.

## Mathematical Contract

The article example fits:

```r
mu1    = heat_tolerance ~ climate + phylo(1 | p | species, tree = tree)
mu2    = desiccation_tolerance ~ climate + phylo(1 | p | species, tree = tree)
sigma1 = ~ habitat_variability + phylo(1 | p | species, tree = tree)
sigma2 = ~ habitat_variability + phylo(1 | p | species, tree = tree)
rho12  = ~ assay_context
```

The four `phylo()` terms form one constant q=4 latent phylogenetic covariance
block. `rho12` remains the residual within-observation correlation and is not
part of that latent covariance block.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-14-map-slice-19-phylogenetic-q4-tutorial-example.md`

The local rendered page was refreshed at
`pkgdown-site/articles/phylogenetic-spatial.html`.

## Checks Run

- `air format vignettes/phylogenetic-spatial.Rmd`: passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE)'`:
  passed.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `rg -n 'full bivariate phylogenetic location-scale block remain planned|full q=4 endpoint.*remain planned|future q=4 phylogenetic endpoint|not a fitted q=4 model|corpairs\\(\\.\\.\\) ~ w|corpairs\\(.*~' vignettes/phylogenetic-spatial.Rmd pkgdown-site/articles/phylogenetic-spatial.html docs/design docs/dev-log/known-limitations.md ROADMAP.md NEWS.md`:
  returned no stale current-status hits.
- `git diff --check`: passed.

## Tests Of The Tests

This slice is documentation-only, so the key check is the rendered article. The
article failed on the first render attempt because the local pkgdown subprocess
loaded a stale installed package that did not know the q=4 labelled `phylo()`
grammar. Rendering in the current package session with `new_process = FALSE`
then passed and produced live `summary()`, `corpairs()`, `rho12()`,
`check_drm()`, and `profile_targets()` output.

## Consistency Audit

Rose scanned the article source, generated HTML, roadmap, NEWS, design docs, and
known limitations for stale language saying the full q=4 phylogenetic
location-scale block was still planned. Current-facing text now says the
constant q=4 block is fitted. The article explicitly says
predictor-dependent latent `corpair()` models and q=4 profile intervals remain
planned.

## What Did Not Go Smoothly

- The first prototype simulation with a nonzero residual-correlation predictor
  and weak scale signal produced false convergence and non-finite gradients.
  The final vignette simulation uses a stable constant residual DGP while still
  fitting `rho12 = ~ assay_context`, so the article can show the residual
  coscale syntax without making the q=4 covariance example brittle.
- The compact q=4 article fit can still report an optimizer-convergence warning.
  The article therefore teaches readers to inspect the fixed gradient, Hessian,
  and q=4 diagnostic row rather than treating the example as an inference-grade
  empirical analysis.

## Team Learning

- Ada should distinguish tutorial examples from recovery tests: the tutorial
  teaches output reading, while Slice 18 carries the recovery evidence.
- Boole should keep extractor and formula names separate: `corpairs()` extracts;
  future fitted syntax should be singular `corpair() ~ w`.
- Gauss should prototype article fits before writing prose around them.
- Noether should keep the article equations, R syntax, and `corpairs()` rows in
  the same endpoint order.
- Fisher should keep the q=4 profile boundary visible until derived
  correlation profiling is implemented.
- Curie should resist tight correlation-recovery claims in a compact tutorial.
- Darwin should later replace the simulated tolerance example with a real
  biological case study only when the data have enough replication.
- Pat should check that an applied reader can tell residual `rho12` from latent
  phylogenetic correlations after reading the section.
- Emmy should keep `summary()`, `corpairs()`, `rho12()`, `check_drm()`, and
  `profile_targets()` visible together when teaching new covariance surfaces.
- Grace should remember that local pkgdown subprocesses may load stale installed
  packages; for active branch docs, render after `devtools::load_all()` in the
  current process.
- Rose should keep stale-status scans pointed at current docs and generated
  article pages.

## Known Limitations

- The example is simulated, not a real empirical dataset.
- Predictor-dependent latent `corpair()` models are not fitted yet.
- The six q=4 phylogenetic correlations remain derived targets without direct
  profile-likelihood intervals.

## Next Actions

1. Push Slice 19 after local checks are recorded.
2. If Actions are green, move to Slice 20: design `sd_phylo()` as the Family B
   Box 1 alternative.
3. Keep a future case-study note for a real replicated two-trait phylogenetic
   dataset.
