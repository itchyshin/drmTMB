# After Task: Slice 37 Spatial Tutorial Diagnostic Polish

## Goal

Make the coordinate-spatial tutorial example read like a fitted workflow, not a
roadmap note.

## Implemented

The structured-dependence article now shows the first fitted spatial path in a
single applied sequence:

```r
spatial(1 | site, coords = coords)
fit_spatial$sdpars$mu
ranef(fit_spatial, "spatial_mu")
profile_targets(fit_spatial, ready_only = TRUE)
check_drm(fit_spatial)
```

The text explains that `spatial_mu_diagnostics` reports site replication,
coordinate range, fitted spatial SD, and the spatial-SD-to-residual-scale
ratio. It also says why the diagnostic is not named as a phylogenetic
replication check.

## Mathematical Contract

No model changed. The article still describes one coordinate-structured
Gaussian `mu` random intercept with one fitted spatial SD and a fixed
coordinate covariance. The new text only changes the reader path through the
fitted output.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/model-map.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

- `PATH=/opt/homebrew/bin:$PATH air format vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-14-slice-36-spatial-check-drm-diagnostics.md`
- `Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE); pkgdown::build_article("model-map", new_process = FALSE, quiet = TRUE)'`
- `rg -n 'spatial_mu_diagnostics|coordinate site field|minimum number of observations per site|check_drm\(\)' vignettes/phylogenetic-spatial.Rmd pkgdown-site/articles/phylogenetic-spatial.html vignettes/model-map.Rmd pkgdown-site/articles/model-map.html`

All passed.

## Tests Of The Tests

This slice is documentation-only. The runnable article was rebuilt through
pkgdown, which executes the spatial example and rendered the
`spatial_mu_diagnostics` row.

## Consistency Audit

The spatial article, rendered local pkgdown page, and model map now agree that
the fitted spatial path is a univariate coordinate-spatial `mu` random
intercept. Mesh/SPDE, spatial q=4, and spatial `corpair()` remain planned.

## What Did Not Go Smoothly

No code issues. The key risk was overexplaining the diagnostic; Pat kept the
new prose tied to the immediate fitted output.

## Team Learning

- Ada: place diagnostics directly after fitted summaries so readers know when
  to trust the output.
- Boole: keep singular `corpair()` and plural `corpairs()` out of the spatial
  section unless a spatial correlation model is actually fitted.
- Darwin: the example should support a real “nearby sites share unmeasured
  habitat” question without promising a full spatial ecology engine yet.
- Fisher: diagnostics should steer users toward replication and scale
  dominance, not pretend to certify identifiability.
- Pat: a short “what a note means” paragraph is more useful than a long caveat.
- Grace: render the article after prose changes because examples are live.
- Rose: tutorial wording should mirror row names exactly to prevent stale
  output prose.

## Known Limitations

No visualization helper, spatial map, mesh, spatial q=4, or spatial
`corpair()` implementation was added here.

## Next Actions

Record the mesh/SPDE contract explicitly, including why a mesh is not required
for the first `coords` path and when citation guidance becomes mandatory.
