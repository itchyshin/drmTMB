# Structural-Dependence Article Split

Date: 2026-05-20

Status: first navigation slice started.

The current `phylogenetic-spatial.Rmd` article is an umbrella article. It now
has to teach fitted and planned animal syntax, fitted phylogenetic slices,
partial spatial support, future combined phylogenetic-plus-spatial models,
`relmat()` fitted-first-slice and design boundaries, residual `rho12`,
`corpairs()`, direct phylogenetic SD surfaces, and profile-interval targets.
That is too much for one reader route.

Slice 2026-05-21 adds `vignettes/structural-dependence.Rmd` as the first small
index page. Follow-up slices add `vignettes/animal-models.Rmd` for `pedigree`,
`A`, and `Ainv` animal-model support, `vignettes/phylogenetic-models.Rmd` for
tree-based `phylo()` support, and `vignettes/relmat-known-matrices.Rmd` for
lower-level known-matrix relatedness. These slices do not split the technical
article yet; they give applied readers a route table, focused structural-layer
landing pages, and links to the existing `phylogenetic-spatial.Rmd` tutorial
for detailed examples.

Future pkgdown work should continue splitting structural dependence into
focused articles, in this order:

1. Animal models: fitted dense-pedigree and known-matrix `animal()` Gaussian
   `mu` intercepts, the first matching q=2 bivariate location covariance,
   ordinary-repeatability fallbacks, planned sparse large-pedigree precision
   construction, planned structured slopes, and future additive genetic
   covariance examples.
2. Phylogenetic models: fitted `phylo()` support, bivariate q=2 and q=4
   blocks, `sd_phylo*()` surfaces, phylogenetic `corpair()`, `corpairs()`,
   diagnostics, and intervals.
3. Spatial models: fitted coordinate-spatial `mu` intercept, one-slope, and q=2
   bivariate location-covariance paths, plus the planned mesh/SPDE, q=4,
   `sigma`, and spatial `corpair()` extensions.
4. Phylo + spatial models: planned additive structured layers with explicit
   identifiability checks before any simultaneous fit is advertised.
5. `relmat()` and known matrices: fitted lower-level Gaussian `mu` intercepts
   and matching q=2 bivariate location covariance from user-supplied latent
   relatedness covariance `K` or precision `Q`, with slope, scale, q=4, and
   `corpair()` parity kept separate from `meta_V(V = V)` known sampling
   covariance.

The split should keep fitted and planned status visible at the top of each
article. It should not promote a planned route into a tutorial until the
likelihood, diagnostics, extractors, profile or bootstrap interval story,
simulation recovery tests, and examples all exist.

This design note also fixes the route order used in the reader-facing article:
animal, phylo, spatial, phylo + spatial, then `relmat()`.
