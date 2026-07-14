# Native REML Phylo Asymmetry Gap

> **Historical derivation-gap note; implementation status superseded
> 2026-07-14.** Current native TMB REML admits the tested q1 mean, q1 sigma,
> matched univariate q2, bivariate mean-side q2, and block-diagonal/dense q4
> phylogenetic rows at row-specific interval, point-fit, or recovery tiers.
> The discussion below records the earlier rejection state and is not the live
> capability authority. See `docs/design/211-structured-reml-status.md` and
> `docs/dev-log/dashboard/structured-re-native-reml-scope-status.tsv`.

## Purpose

This note records the former native TMB REML boundary for the Ayumi
phylogenetic balance arc and the derivation questions that preceded the later
row-specific implementation.

## Historical Boundary

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

Native TMB REML rejected scale-side and matched location-scale phylogenetic
requests when this note was written:
> ### ⚠️ SUPERSEDED (2026-07-14)
>
> **Pure scale-side and matched univariate phylo are now ADMITTED** under REML, as are ordinary `sigma`
> random effects, bivariate mean-side q2, and block-diagonal/dense q4 phylogenetic cells at point-fit
> or recovery tiers. Arc 1a also admits narrowly bounded pure-`mu` univariate
> `spatial()`/`animal()`/`relmat()` intercept and independent one-slope routes. It does not admit
> those providers on `sigma`, in matched `mu+sigma` blocks, or in bivariate models. The
> phylogenetic rows do not inherit interval reliability or coverage from the q1 mean row.
>
> Authority: `docs/dev-log/dashboard/estimator-surface-conformance.tsv` (machine-checked by
> `tests/testthat/test-estimator-surface-conformance.R`) and
> `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`. Prose is derived; the TSVs are truth.


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

That former bivariate restriction is also superseded: tested bivariate
mean-side q2 and block-diagonal/dense q4 phylogenetic REML cells now have
point-fit or recovery evidence. They remain below inference-ready.

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

Implementation is no longer deferred for the tested rows, but inference
promotion remains deferred. The honest current wording is:

- native ML is balanced for univariate Gaussian `phylo()` location and scale
  intercept layouts;
- native REML has exact-Gaussian, row-specific q1/q2/q4 phylogenetic point,
  recovery, and limited interval evidence plus the bounded Arc 1a spatial,
  animal, and relmat mean-side shapes; this does not create provider-wide
  interval or coverage parity;
- q2/q4 bivariate phylogenetic native REML remains below inference-ready;
- Julia/DRM.jl REML rows, where available, remain experimental bridge evidence
  until direct DRM.jl, native R, and R-via-Julia parity agree row by row.
