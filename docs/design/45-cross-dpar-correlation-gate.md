# Cross-Dpar Random-Effect Correlation Gate

> **Status supersession (2026-07-14).** This document preserves a historical
> planning state. Any statement below that residual-scale structured slopes are
> wholly planned is superseded. Current 0.6.0 fits the exact Gaussian q1
> `sigma` one-slope routes for `phylo()`, `spatial()`, `animal()`, and
> `relmat()`; phylo, A-matrix animal, and K/Q relmat are inference-ready with
> caveats, while spatial remains point-fit/extractor only. NB2 q1 structured
> `sigma` intercept-plus-one-slope routes for the same four providers are also
> fitted at recovery grade. Multiple or labelled structured sigma slopes,
> spatial sigma-slope intervals, and broader non-Gaussian structured scale
> routes remain planned.


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
| Ordinary Gaussian `mu` | Univariate Gaussian random intercepts, independent slopes, correlated q=2 blocks, q > 2 location blocks such as `(1 + x1 + x2 | id)`, matching slope-only bivariate `mu1`/`mu2` blocks such as `(0 + x | p | id)`, same-response matching slope-only `mu`/`sigma` blocks, q4/q6 bivariate location blocks with smoke artifact routing such as `(1 + x | p | id)` and `(1 + x + z | p | id)`, and the first q8 all-endpoint block with matching `(1 + x | p | id)` terms in all four bivariate endpoint formulas. q=3 has recovery-smoke coverage; larger q is advanced, while q4/q6 bivariate location and q8 have diagnostic artifact lanes only. | Predictor-modelled slope correlations, q8 coverage/power evidence, and broader all-endpoint coefficient sets. |
| Gaussian `sigma` | Random intercepts, independent numeric slopes, and unlabelled correlated intercept-slope and multi-slope blocks in the residual-scale formula; multiple matched univariate `mu`/`sigma` random-intercept covariance blocks; the matching bivariate `sigma1`/`sigma2` q2 slope-only block; one same-response matching slope-only bivariate `mu`/`sigma` block; and the scale endpoints in the first ordinary q8 block. | Labelled univariate residual-scale slope blocks, cross-formula `mu`-`sigma` slope covariance, q8 coverage/power evidence, and q8 variants outside the matching one-slope ordinary Gaussian route. |
| Bivariate Gaussian covariance blocks | Matching labelled `mu1`/`mu2`, `sigma1`/`sigma2`, same-response `mu`/`sigma`, all-four `mu1`/`mu2`/`sigma1`/`sigma2` random-intercept blocks, matching slope-only `mu1`/`mu2`, `sigma1`/`sigma2`, and same-response `mu`/`sigma` blocks, smoke-artifact-routed matching q=4/q=6 `mu1`/`mu2` location blocks, and the first q8 all-endpoint block with diagnostic smoke/recovery artifacts. | q8 coverage/power evidence, mixed-distribution bivariate likelihoods, and q > 2 direct correlation profiles. |
| Phylogenetic effects | The documented Gaussian routes are fitted. Exact non-Gaussian gates fit ordinary Poisson/NB2 q1 phylogenetic `mu` intercept-plus-one-slope, recovery-grade NB2 q1 phylogenetic `sigma`, Student-t q1 phylogenetic `nu`, and cumulative-logit q1 phylogenetic `mu`. Animal/relmat sibling gates are row-specific in the live ledger. | Multiple or labelled structured slopes, structured slope correlations, q4 predictor-dependent phylogenetic correlations, non-Gaussian phylogenetic random effects outside those exact gates, animal/`relmat()` predictor-dependent `corpair()` regressions, and generic direct-SD grammar remain outside Wave A. |
| Coordinate spatial effects | Univariate Gaussian `mu` and `sigma` intercepts with optional matching `mu`/`sigma` correlation, one independent `mu` slope and one q1 `sigma` slope through `spatial(1 + x | site, coords = coords)`, constant bivariate `mu1`/`mu2` q=2 covariance, and constant q=4 location-scale covariance through matching `spatial(1 | p | site, coords = coords)` terms. | The spatial `sigma`-slope interval gate, spatial slope correlations, multiple or labelled spatial slopes, spatial direct-SD models, spatial `corpair()` regressions, and non-Gaussian spatial effects outside the exact ordinary Poisson/NB2 q1 spatial `mu` intercept-plus-one-slope, recovery-grade NB2 q1 spatial `sigma`, Student-t spatial `mu`, Poisson spatial `zi`, fixed-`zi` Poisson spatial `mu`, and fixed-`zi` NB2 spatial `mu` gates. |
| Non-Gaussian `mu` | Poisson `mu` random intercepts and independent numeric slopes for non-zero-inflated Poisson models, plus the exact diagnostic-only fixed-`zi` Poisson and diagnostic-only fixed-`zi` NB2 `mu ~ spatial()` intercept gates. | Correlated non-Gaussian slope blocks, labelled non-Gaussian covariance, zero-inflated or hurdle count-side random effects and structured non-Gaussian random effects outside the exact named gates. |
| Non-Gaussian `sigma`, `zi`, `hu`, `zoi`, `coi`, and `nu` | Fixed-effect scale, shape, zero-inflation, and hurdle formulas where the family likelihood is implemented, plus row-specific gates including diagnostic-only Poisson `zi ~ spatial()`, diagnostic-only Student-t `nu ~ phylo()`, and diagnostic-only truncated-NB2 `hu ~ relmat()`. Student-t `nu` is otherwise fixed-effect shape; `zoi` and `coi` are planned bounded-response parameters. | Random effects and covariance blocks in non-Gaussian scale, inflation, hurdle, one-inflation, and shape parameters outside the exact named gates. Fixed-effect zero-one-inflated bounded likelihoods must come before `zoi`/`coi` random effects. |
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
slopes, and bivariate Gaussian can now fit the matching q2 `sigma1`/`sigma2`
scale-slope block plus one same-response matching q2 `mu`/`sigma` slope block.
Coordinate spatial can fit one independent `mu` slope. The parser can read
one-slope `phylo()`, `animal()`, and `relmat()` markers, but parser support does
not create a fitted slope correlation model. Phylogenetic, animal, `relmat()`,
non-Gaussian, structured q8, and broader all-endpoint slope correlations need
their own implementation, diagnostics, interval targets, and recovery tests
before they enter broad simulations. The ordinary q8 route has diagnostic
smoke/recovery artifacts, but it does not yet have coverage or power evidence.

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
`rho12 ~ x + (1 | id)`, cross-response `mu1`/`sigma2` slope labels, mismatched
same-response slope labels, q8 coefficient sets beyond one shared slope, or
predictor-dependent q8 `corpair()` regressions are future work until the
likelihood, extractor, interval, diagnostic, and simulation evidence exists.
