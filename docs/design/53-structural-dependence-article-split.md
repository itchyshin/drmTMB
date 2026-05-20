# Structural-Dependence Article Split

Date: 2026-05-20

Status: planned documentation architecture.

The current `phylogenetic-spatial.Rmd` article is an umbrella article. It now
has to teach fitted and planned animal syntax, fitted phylogenetic slices,
partial spatial support, future combined phylogenetic-plus-spatial models,
`relmat()` fitted-first-slice and design boundaries, residual `rho12`,
`corpairs()`, direct phylogenetic SD surfaces, and profile-interval targets.
That is too much for one reader route.

Future pkgdown work should split structural dependence into a small index plus
several focused articles, in this order:

1. Animal models: fitted known-matrix `animal()` Gaussian `mu` intercepts
   through `A` or `Ainv`, ordinary-repeatability fallbacks, planned pedigree
   construction, planned structured slopes, and future additive genetic
   covariance examples.
2. Phylogenetic models: fitted `phylo()` support, bivariate q=2 and q=4
   blocks, `sd_phylo*()` surfaces, phylogenetic `corpair()`, `corpairs()`,
   diagnostics, and intervals.
3. Spatial models: fitted coordinate-spatial `mu` intercept and one-slope
   paths, plus the planned mesh/SPDE, bivariate, `sigma`, and spatial
   `corpair()` extensions.
4. Phylo + spatial models: planned additive structured layers with explicit
   identifiability checks before any simultaneous fit is advertised.
5. `relmat()` and known matrices: fitted lower-level Gaussian `mu` intercepts
   from user-supplied latent relatedness covariance `K` or precision `Q`,
   with slope, scale, bivariate, and `corpair()` parity kept separate from
   `meta_V(V = V)` known sampling covariance.

The split should keep fitted and planned status visible at the top of each
article. It should not promote a planned route into a tutorial until the
likelihood, diagnostics, extractors, profile or bootstrap interval story,
simulation recovery tests, and examples all exist.

This design note also fixes the route order used in the reader-facing article:
animal, phylo, spatial, phylo + spatial, then `relmat()`.
