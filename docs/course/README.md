# Course Notes

These notes are a teaching-path ledger for `drmTMB`, not a separate source of
model status. The pkgdown articles stay authoritative for fitted syntax,
planned neighbours, diagnostics, and interpretation.

For a short course, use this sequence:

1. Start with `vignettes/drmTMB.Rmd` for distributional regression and one
   formula per distributional parameter.
2. Use `vignettes/model-map.Rmd` to choose a fitted route and to separate
   fitted, first-slice, planned, and unsupported syntax.
3. Teach `vignettes/location-scale.Rmd` and `vignettes/which-scale.Rmd` before
   random-slope examples, so readers know the difference between fixed mean
   slopes, residual `sigma`, random-effect SDs, and `sd(group)` surfaces.
4. Use `vignettes/bivariate-coscale.Rmd` for residual `rho12`, ordinary
   group-level covariance, and the boundary between `rho12`, `corpair()`, and
   `corpairs()`.
5. Use `vignettes/structural-dependence.Rmd` for `phylo()`, `spatial()`,
   `animal()`, and `relmat()` as structured random-effect layers, not residual
   `rho12` models.
6. Use `vignettes/implementation-map.Rmd` and `vignettes/source-map.Rmd` when a
   learner asks whether a neighbouring random-slope or covariance model is
   implemented.

Phase 6c random slopes are currently taught through the status map and the
location-scale worked examples. The bivariate slope-only `mu1`/`mu2` route is
fitted and issue-led, but it still needs its own worked tutorial before it
becomes a course module. Until then, teach it as a capability row and point
readers to `corpairs()` and `profile_targets()` for fitted-output inspection.
