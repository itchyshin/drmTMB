# After Task: Slice 13B Phylo And Species Reader Path

## Goal

Show applied users how to read the fitted bivariate phylogenetic mean layer
beside ordinary species covariance without confusing either layer with
residual `rho12`.

## Implemented

`vignettes/model-map.Rmd` and `vignettes/phylogenetic-spatial.Rmd` now include
an example syntax pattern with both an ordinary labelled species block and
matching `phylo()` terms:

```r
mu1 = trait1 ~ predictors + (1 | species_residual | species) +
  phylo(1 | species, tree = tree)
mu2 = trait2 ~ predictors + (1 | species_residual | species) +
  phylo(1 | species, tree = tree)
```

The text directs readers to `rho12()`, `corpairs(..., level =
"phylogenetic")`, and `corpairs(..., level = "group")` as three separate
correlation layers. It also tells them that `check_drm()` records a note when
the ordinary and phylogenetic blocks both use `species`.

## Mathematical Contract

The example is a staged trait-mean model only. It does not add phylogenetic
`sigma` terms, spatial covariance, structured effects in `rho12`, or the full
q=4 location-scale endpoint.

## Files Changed

- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `pkgdown-site/articles/model-map.html`
- `pkgdown-site/articles/phylogenetic-spatial.html`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-13b-phylo-species-reader-path.md`

## Checks Run

- `Rscript -e 'pkgdown::build_article("model-map"); pkgdown::build_article("phylogenetic-spatial")'`: passed and wrote both article HTML files under `pkgdown-site/articles/`.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'spatial.*implemented|spatial.*now fits|spatial likelihood is implemented|full q=4.*implemented|q=4.*now fits' NEWS.md README.md ROADMAP.md docs vignettes man R tests`: found only planned-boundary wording, historical notes, and explicit "not implemented" text.
- `rg -n 'future .*non-phylogenetic species|Non-phylogenetic species covariance.*future|Add bivariate Gaussian `mu1` and `mu2` ordinary species|Add bivariate Gaussian phylogenetic `mu1`' docs/design/29-mammal-location-coscale-route.md ROADMAP.md docs/design vignettes`: no matches.
- `Rscript -e 'devtools::test()'`: passed with 2,772 expectations.

## Tests Of The Tests

The reader path is backed by the focused diagnostic and simulation tests from
Slices 11B and 12B. The article build confirms the examples render into the
local pkgdown site.

## Consistency Audit

The user-facing status remains phylo-only: bivariate `mu1`/`mu2` phylogenetic
mean covariance is fitted, ordinary group species covariance is a separate
fitted layer, and spatial covariance remains planned.

## What Did Not Go Smoothly

The previous hidden q=4 scaffolds already used Slice 11--13 names, so this
batch uses Slice 11B--13B filenames to avoid confusing the dev-log trail.

## Team Learning

Pat and Darwin should see the staged interpretation before the q=4 endpoint:
mean-mean phylogenetic association, ordinary species association, and residual
coupling are different biological questions.

## Known Limitations

The examples are syntax and interpretation guidance. They are not a worked
mammal data analysis, and they do not estimate spatial or phylogenetic scale
effects.

## Next Actions

Give the user the local pkgdown article links for review, then decide whether
the next phylo-only slice should be another recovery scenario or a commit/PR
cleanup.
