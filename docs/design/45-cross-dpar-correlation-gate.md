# Cross-Dpar Random-Effect Correlation Gate

This note records the Slice 240 boundary for covariance among distributional
parameters before Phase 18 grows into a broad simulation programme. The reader
is an applied ecology or evolution user who wants to know which correlations
can be fitted now, and a package contributor who needs to keep unsupported
correlation surfaces out of simulation grids.

## Purpose

`drmTMB` now has several real correlation layers. They should stay separate:

- residual response-response correlation, `rho12`;
- ordinary group-level random-effect correlations;
- structured random-effect correlations, such as phylogenetic or spatial
  correlations;
- known sampling covariance `V` in `meta_V(V = V)`, which is input data rather
  than an estimated model parameter.

The Phase 18 rule is simple: simulate fitted surfaces, list planned surfaces in
the failure ledger, and do not treat a parsed formula or design note as
implemented evidence.

## Current Status

| Layer | Fitted now | Not in Phase 18 Wave A |
| --- | --- | --- |
| Residual `rho12` | Bivariate Gaussian fixed-effect residual correlation, including predictor-dependent `rho12 = ~ x` and row-specific profile targets through `newdata`. | Random effects in `rho12`; covariance between `rho12` random effects and `mu`, `sigma`, `zi`, `hu`, `zoi`, `coi`, or `nu`. |
| Ordinary Gaussian `mu` | Univariate Gaussian random intercepts, independent slopes, correlated q=2 blocks, q > 2 location blocks such as `(1 + x1 + x2 | id)`, and matching slope-only bivariate `mu1`/`mu2` blocks such as `(0 + x | p | id)`. q=3 has recovery-smoke coverage; larger q is advanced. | Predictor-modelled slope correlations and broader bivariate random slopes. |
| Gaussian `sigma` | Random intercepts and independent numeric slopes in the residual-scale formula, plus multiple matched univariate `mu`/`sigma` random-intercept covariance blocks. | Correlated residual-scale slope blocks, labelled scale-slope covariance, and slope-level `mu`/`sigma` covariance. |
| Bivariate Gaussian covariance blocks | Matching labelled `mu1`/`mu2`, `sigma1`/`sigma2`, same-response `mu`/`sigma`, all-four `mu1`/`mu2`/`sigma1`/`sigma2` random-intercept blocks, and matching slope-only `mu1`/`mu2` blocks. | Intercept-plus-slope bivariate location blocks, residual-scale slope blocks, q=6 or q=8 location-scale slope endpoints, mixed-distribution bivariate likelihoods, and q=4 direct correlation profiles. |
| Phylogenetic effects | Univariate `mu` and `sigma` intercepts with optional matching `mu`/`sigma` correlation, bivariate `mu1`/`mu2` intercept correlation, all-four q=4 phylogenetic intercept block, `sd*()` direct-SD routes with `level = "phylogenetic"`, and q=2 predictor-dependent `corpair(..., level = "phylogenetic", from = "mu1", to = "mu2")`, including the q=2 direct-SD plus `corpair()` combination. Known-matrix animal and `relmat()` Gaussian `mu` and `sigma` intercepts, constant bivariate q=2 location covariance, and constant all-four q=4 location-scale covariance are fitted sibling slices. | Phylogenetic slopes beyond the first `mu` slope, residual-scale structured slopes, q=4 predictor-dependent phylogenetic correlations, and non-Gaussian phylogenetic random effects. Animal/`relmat()` residual-scale structured slopes, predictor-dependent `corpair()` regressions, and spatial/animal/`relmat()` direct-SD levels remain outside Wave A. |
| Coordinate spatial effects | Univariate Gaussian `mu` and `sigma` intercepts with optional matching `mu`/`sigma` correlation, one independent `mu` slope through `spatial(1 + x | site, coords = coords)`, constant bivariate `mu1`/`mu2` q=2 covariance, and constant q=4 location-scale covariance through matching `spatial(1 | p | site, coords = coords)` terms. | Spatial slope correlations, residual-scale structured slopes, spatial direct-SD models, spatial `corpair()` regressions, and non-Gaussian spatial effects. |
| Non-Gaussian `mu` | Poisson `mu` random intercepts and independent numeric slopes for non-zero-inflated Poisson models. | Correlated non-Gaussian slope blocks, labelled non-Gaussian covariance, zero-inflated or hurdle count-side random effects, and structured non-Gaussian random effects. |
| Non-Gaussian `sigma`, `zi`, `hu`, `zoi`, `coi`, and `nu` | Fixed-effect scale, shape, zero-inflation, and hurdle formulas where the family likelihood is implemented. Student-t `nu` is fixed-effect shape; `zoi` and `coi` are planned bounded-response parameters. | Random effects and covariance blocks in non-Gaussian scale, inflation, hurdle, one-inflation, and shape parameters. Fixed-effect zero-one-inflated bounded likelihoods must come before `zoi`/`coi` random effects. |
| Known sampling covariance | `meta_V(V = V)` for vector or matrix known sampling covariance. `V` is not estimated and is not an interval target. | Treating known `V` as a random-effect covariance, reusing `V` for relatedness matrices, or combining dense known `V` with unsupported bivariate/random-effect covariance surfaces. |

## Correlation Rules

For Phase 18 Wave A, fitted random-effect correlations are constant block
hyperparameters. A fitted block may estimate one or more constant correlations,
but the correlation itself is not yet a formula with predictors unless it is
one of the already implemented special lanes:

```r
rho12 = ~ x
corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ w
corpair(species, level = "phylogenetic", block = "p",
        from = "mu1", to = "mu2") ~ ecology
```

The first line is a residual-correlation formula. The second and third lines
are intercept-level latent random-effect correlation formulas for q=2
location-location blocks. They do not imply predictor-modelled slope
correlations, q=4 correlation regressions, or random effects in `rho12`.

Slope-related correlations stay deliberately narrower. Ordinary Gaussian `mu`
can fit q > 2 constant location blocks. Gaussian `sigma` can fit independent
slopes. Coordinate spatial can fit one independent `mu` slope. The parser can
read one-slope `phylo()`, `animal()`, and `relmat()` markers, but parser support
does not create a fitted slope correlation model. Phylogenetic, animal,
`relmat()`, bivariate, non-Gaussian, and cross-parameter slope correlations need
their own implementation, diagnostics, interval targets, and recovery tests
before they enter broad simulations.

## Simulation Consequence

The comprehensive simulation should start with fitted surfaces:

- Gaussian location-scale fixed effects;
- ordinary Gaussian `mu` q=3 random slopes;
- Gaussian `sigma` independent slopes;
- univariate and bivariate Gaussian random-intercept covariance blocks;
- coordinate spatial Gaussian `mu` one-slope models;
- Gaussian `meta_V(V = V)`;
- Poisson `mu` random-effect pilots where zero inflation is absent.

It should not simulate non-Gaussian cross-parameter covariance, shape random
effects, `zoi`/`coi` random effects, random effects in `rho12`, animal-model
slopes, or mixed-distribution bivariate models as if they are implemented.
Those belong in `docs/design/34-validation-debt-register.md` until focused
gates close.

## User-Facing Message

When a requested model crosses this boundary, the error or documentation should
say which layer is missing and what smaller model to try. Examples:

```r
bf(y ~ x + (1 + x | id), sigma ~ z)
bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id))
bf(y ~ x, sigma ~ z + (0 + w | id))
```

These are fitted Gaussian surfaces. By contrast, models such as
`zi ~ x + (1 | id)`, `nu ~ x + (1 | id)`,
`rho12 ~ x + (1 | id)`, or matched slope labels across `mu` and `sigma` are
future work until the likelihood, extractor, interval, diagnostic, and
simulation evidence exists.
