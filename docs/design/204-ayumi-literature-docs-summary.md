# Ayumi Literature And Docs Summary

> **Current-status correction (2026-07-14).** This preparation note predates
> the native structured-REML admissions summarized in
> `docs/design/211-structured-reml-status.md`. Read every REML statement below
> through that row-specific authority; point-fit or recovery admission does not
> imply interval, coverage, `supported`, or HSquared AI-REML promotion.

## Purpose

This note banks A081-A090 for the Ayumi phylogenetic balance arc. It connects
the project-local evidence to the public location-scale modelling motivation
without turning tutorial or literature context into an unsupported drmTMB claim.

## External Motivation Check

The public tutorial at
<https://ayumi-495.github.io/Eco_location-scale_model/> motivates
location-scale modelling as a way to model both the expected response and the
scale or variability of that response. Its `brms` example writes a Gaussian
location-scale formula with `y ~ 1 + x` for location and `sigma = ~ 1 + x` for
scale, then interprets `summary()` through posterior intervals and diagnostics.

That tutorial is a useful reader map for Ayumi's question: if a model studies
both trait means and trait variability, it is natural to ask whether
phylogenetic structure should be available in both `mu` and `sigma`. The answer
in drmTMB is route-specific. Native ML has balanced univariate Gaussian fit
targets for `mu`, `sigma`, and matched `mu+sigma` intercepts. Native REML is
exact-Gaussian and now includes q1 mean-side inference evidence, sigma-only and
matched univariate q2 point-fit evidence, bivariate mean-side q2 point-fit
evidence, and block-diagonal or dense q4 recovery evidence. The scale-side,
q2, and q4 rows have no blanket interval, coverage, or support promotion.

## Package Contrast

`brms` is the flexible Bayesian route for location-scale models with priors,
MCMC diagnostics, and posterior intervals. That is the right comparison when
scale-side phylogenetic components are weakly identified and a prior is part of
the scientific analysis.

`glmmTMB` is a useful formula-grammar comparison for distributional regression,
but it is not a drop-in answer to q4 phylogenetic location-scale inference in
this project. drmTMB's relevant boundary is narrower and more explicit:
formula parsing, point fits, direct targets, diagnostics, and interval coverage
are separate gates.

## Reference Anchors Checked

The local MAP/penalty notes use the right anchors:

- Simpson, Rue, Martins, Riebler, and Sorbye (2017), "Penalising Model
  Component Complexity", supports PC-prior vocabulary.
- Chung, Rabe-Hesketh, Dorie, Gelman, and Liu (2013), "A nondegenerate
  penalized likelihood estimator for variance parameters", supports the idea
  that a penalty can move variance-component estimates away from degenerate
  boundaries.
- de Villemereuil and Nakagawa (2014), plus the 2025 location-scale modelling
  literature, support the phylogenetic mixed-model and PLSM framing used in
  docs 170-173.

Those references support the vocabulary. They do not prove that drmTMB has
calibrated q4 intervals, balanced native REML, or 10,440-tip sigma-phylo
intervals.

## Data-Design Note

The current Ayumi data shape remains the practical constraint: approximately
one observation per tip gives a per-tip scale random effect almost no
within-species information. That makes scale-side phylogenetic fields weakly
identified. The clean near-term recommendation is Model A+: phylogenetic
location effects for the two traits, fixed-effect `sigma1` and `sigma2`, and a
residual `rho12`. A scale-side phylogenetic question can be studied as a
sensitivity route only when diagnostics, prior sensitivity, or additional
within-tip replication support it.

## Applied-User Stub

For a future vignette or Ayumi reply, use this structure:

1. Start with Model A+ as the run-now model.
2. Show the matched native ML `mu+sigma` phylo cell as fit-target support, not
   interval support.
3. Show q4 native ML as diagnostic status only.
4. Show direct DRM.jl q4 profile/bootstrap as experimental design input, with
   known bootstrap scale-axis undercoverage.
5. State that native q4 REML is recovery-grade only: interval, coverage,
   `supported`, and R-via-Julia bridge promotion are not available today.

## Dashboard Panel Plan

A local dashboard panel should show five columns for each Ayumi row:

- route: native TMB, R-via-Julia, or direct DRM.jl;
- estimator: ML, REML, MAP, or unsupported;
- fit status: converged, diagnostic, nonconverged, or rejected;
- inference status: Wald, profile, bootstrap, coverage, or unavailable;
- next gate: what evidence is needed before an applied user should rely on the
  row.

The panel should read from the existing validator-owned TSVs rather than a new
free-form JSON payload.

## Decision

A081-A090 synchronize the reader story. They do not add a new public vignette,
pkgdown page, or Ayumi issue reply. The local docs now have enough wording to
prepare a reply later without confusing native ML balance, native REML
asymmetry, direct Julia interval machinery, and calibrated inference.
