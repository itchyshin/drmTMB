# After Task: Slice 39 Phase 5 Synthesis

## Goal

Make the roadmap, landing page, model map, limitations, and local pkgdown site
tell one coherent Phase 5 story before the final merge gate.

## Implemented

The roadmap now has a Phase 5 closure-boundary table. It separates:

- univariate phylogenetic pieces that are fitted;
- bivariate phylogenetic pieces that are fitted;
- the first coordinate-spatial piece that is fitted;
- inference and output support that is available now;
- q=4 predictor-dependent correlations, mesh/SPDE, spatial q=4, and
  visualization helpers that remain planned.

The README now says the current practical path includes fitted phylogenetic
`corpairs()`, constant q=4 phylogenetic location-scale covariance, and the first
coordinate-spatial `check_drm()` row. The local pkgdown site was rebuilt so the
rendered roadmap shows Phase 18 and the Phase 5 closure boundary.

## Mathematical Contract

No likelihood changed. The synthesis only updates status language around the
models already implemented in earlier slices:

```r
phylo(1 | species, tree = tree)
phylo(1 | p | species, tree = tree)
corpair(species, level = "phylogenetic", block = "p",
        from = "mu1", to = "mu2") ~ w
sd_phylo(species) ~ z
sd_phylo1(species) ~ z
sd_phylo2(species) ~ z
spatial(1 | site, coords = coords)
```

## Files Changed

- `README.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

The local `pkgdown-site/` output was rebuilt but remains ignored by git.

## Checks Run

- `PATH=/opt/homebrew/bin:$PATH air format README.md ROADMAP.md docs/design/09-phylogenetic-and-spatial-speed.md docs/dev-log/known-limitations.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-14-slice-37-spatial-tutorial-diagnostic-polish.md docs/dev-log/after-task/2026-05-14-slice-38-mesh-spde-design-gate.md`
- `rg -n 'Phase 5 closure boundary|spatial_mu_diagnostics|Phase 18|Visualization, Marginal Effects|fitted phylogenetic `corpairs\(\)`|check_drm\(\) spatial diagnostic' README.md ROADMAP.md docs/design/09-phylogenetic-and-spatial-speed.md docs/dev-log/known-limitations.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `rg -n 'Phase 5 closure boundary|Phase 18: Visualization|spatial_mu_diagnostics|Mesh/SPDE Implementation Gate|coordinate-spatial `mu` diagnostics|spatial diagnostic row' pkgdown-site/ROADMAP.html pkgdown-site/index.html pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/articles/model-map.html pkgdown-site/reference/check_drm.html --glob '!pkgdown-site/search.json'`
- `rg -n 'spatial fields remain planned|coords = coords\).*not implemented|spatial likelihood is not implemented|will currently reject spatial\(1 \| site, coords|Phase 18.*planned only|public site.*Phase 18.*done' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes pkgdown-site --glob '!pkgdown-site/search.json'`

All passed. The stale-wording scan returned no contradictions.

## Tests Of The Tests

This is a status-synthesis slice. The useful verification was the rendered-site
scan: local `pkgdown-site/ROADMAP.html` contains Phase 18 and the Phase 5
closure boundary, and the structured-dependence article renders the spatial
diagnostic row.

## Consistency Audit

README, ROADMAP, known limitations, model map, structured-dependence article,
and `check_drm()` reference agree on the current boundary: phylogenetic q=4 and
q=2 phylogenetic `corpair()` are fitted; coordinate-spatial univariate `mu` is
fitted; mesh/SPDE and spatial bivariate extensions remain planned.

## What Did Not Go Smoothly

The public website is still necessarily stale until the PR is merged and the
pkgdown workflow deploys from the main branch. The local site has the right
Phase 18 content.

## Team Learning

- Ada: close a phase by naming implemented and planned pieces in one table.
- Boole: keep fitted formula examples and extractor names in the same row.
- Gauss: avoid status prose that sounds like a likelihood change.
- Noether: every roadmap claim needs a matching R syntax and output surface.
- Darwin: comparative trait examples need staged answers, not one premature
  everything-model.
- Fisher: output support and interval support should be its own row, because
  fitted point estimates are not automatically reliable intervals.
- Pat: the landing page should say what the user can run now.
- Grace: local pkgdown proves rendering, but public deployment waits for merge.
- Rose: stale public website reports should be handled by merge/deploy, not by
  pretending feature-branch docs are already live.

## Known Limitations

Phase 18 exists locally and in source, but it will not appear on the public
site until the branch is merged and the pkgdown deployment workflow succeeds.

## Next Actions

Run the final package gates, commit and push Slices 36-39/40, wait for GitHub
Actions, merge the PR, pull the updated main branch, and verify the public
roadmap.
