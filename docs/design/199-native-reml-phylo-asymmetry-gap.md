# Native REML Phylo Asymmetry Gap

## Purpose

This note records the current native TMB REML boundary for the Ayumi
phylogenetic balance arc. It explains why `REML = TRUE` is exact-Gaussian and
mean-side-only for structured phylogenetic effects today, and what would be
needed before native REML could be called balanced across `mu` and `sigma`.

## Current Boundary

Native TMB REML is implemented for the exact-Gaussian location model where the
mean fixed effects are restricted and the structured phylogenetic random field
enters the location predictor:

```r
bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
```

The focused test in `tests/testthat/test-reml-phylo-location.R` compares this
route with a hand-computed restricted-likelihood reference for

\[
y \sim N(X\beta, \sigma^2_p ZAZ^\top + \sigma^2 I),
\]

and also checks that the REML phylogenetic SD is no more downward-biased than
the ML estimate on the same fixture. This is exact Gaussian REML for the
location model only.

Native TMB REML currently rejects scale-side and matched location-scale
phylogenetic requests:

```r
bf(y ~ x, sigma ~ phylo(1 | species, tree = tree))
bf(
  y ~ x + phylo(1 | p | species, tree = tree),
  sigma ~ phylo(1 | p | species, tree = tree)
)
```

Those rejections are an implementation and validation boundary, not a
scientific claim that scale-side phylogenetic variation is impossible. Native
ML can fit univariate Gaussian mean-only, scale-only, and matched
mean-plus-scale phylogenetic intercepts. The asymmetry is specific to native
REML.

Native bivariate Gaussian REML is also restricted to fixed-effect mean models
in the current slice. `tests/testthat/test-reml-bivariate.R` rejects random or
structured bivariate mean effects under `REML = TRUE`. Therefore q2 and q4
phylogenetic bivariate native REML remain unsupported.

## Derivation Gap

The current location-only REML route marginalizes Gaussian mean fixed effects
under a covariance model that is independent of those fixed effects. A
scale-side phylogenetic random field changes the log-residual-scale predictor,
so the conditional response covariance depends nonlinearly on latent
scale-field values. That is not the same restricted likelihood as the
location-only Gaussian mixed model.

A balanced native REML design for scale-side or matched location-scale
phylogenetic effects would need to specify exactly which fixed effects are
restricted, which latent fields are integrated by the TMB Laplace
approximation, and which variance or scale parameters are optimized. It also
needs to avoid borrowing q4 Patterson-Thompson or HSquared AI-REML language for
a model that has not been derived in this codebase.

## No-Code Estimator Contract

Before implementing balanced native REML, the estimator contract should name:

- Objective: the exact restricted likelihood or approximation being optimized,
  including the determinant adjustment for restricted fixed effects.
- Parameter set: fixed effects, residual scale fixed effects, phylogenetic SDs,
  latent mean fields, latent scale fields, and any latent mean-scale
  correlations.
- Score and information: analytic or automatic-differentiation targets for the
  restricted objective, with finite-difference checks for the variance and
  correlation parameters.
- Failure modes: boundary SDs, near-perfect latent correlations, weak
  one-observation-per-tip scale fields, non-positive Hessians, profile
  endpoint timeouts, and optimizer false convergence.
- Tests: hand reference for a small mean-side model, ML-versus-REML same-target
  sanity checks where applicable, rejection tests for unsupported layouts,
  direct profile-target status checks, bootstrap accounting checks, and
  simulation recovery grids before any public balance claim.

## Decision

Native balanced REML for scale-side or matched phylogenetic structured effects
is deferred. The next acceptable promotion path is a separate estimator design
and validation lane, not a wording change in the Ayumi reply. Until that exists,
the honest public wording is:

- native ML is balanced for univariate Gaussian `phylo()` location and scale
  intercept layouts;
- native REML is exact-Gaussian mean-side-only for phylogenetic structured
  effects;
- q2/q4 bivariate phylogenetic native REML is unsupported;
- Julia/DRM.jl REML rows, where available, remain experimental bridge evidence
  until direct DRM.jl, native R, and R-via-Julia parity agree row by row.
