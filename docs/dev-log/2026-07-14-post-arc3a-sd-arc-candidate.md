# Post-Arc-3a candidate: the `sd()` arc

**Status:** BANKED PROPOSAL ONLY. This note records a possible main-lane arc for
comparison after Arc 3a closes. It is not an approved GOAL, implementation
plan, capability claim, or reason to widen the active Arc 3a campaign. Starting
this work requires a fresh GOAL, symbolic/API plan, and Shinichi's approval.

## Purpose

Extend the canonical direct random-effect-SD submodel

```r
sd(group, level = ...) ~ predictors
```

family by family across drmTMB's fitted distributions. Each family needs an
explicit scale contract; the proposal must not imply that Beta precision,
Gamma coefficient of variation, lognormal log-SD, count overdispersion, and
Student-t scale share one likelihood mapping. This is a Phase 4 capability-
completion candidate, not an Arc 4a interval/coverage extension.

The existing design anchor is ROADMAP Slice 389 and
`docs/design/66-implementation-map-slices-356-405.md:133-145`. They require a
family-specific structured-scale contract before random effects move outside
`mu`, and they explicitly prohibit treating structured-`mu` evidence as
evidence for structured `sigma` or direct-SD models.

## First bounded slice: Beta phylogenetic location-scale-scale

The first candidate gate is Beta because its three predictors have distinct
interpretations:

```r
fit <- drmTMB(
  bf(
    Male_plumage_prop ~
      1 + Dale_mating_system_z +
      phylo(1 | spp_id, tree = tree),
    sigma ~
      1 + Dale_mating_system_z,
    sd(spp_id, level = "phylogenetic") ~
      1 + Dale_mating_system_z
  ),
  family = beta(),
  data = data
)
```

The location formula predicts the Beta mean `mu`. The first scale formula
predicts Beta precision through drmTMB's current
`phi = 1 / sigma^2` parameterization. The direct-SD formula predicts the
phylogenetic random-effect SD. These are three different estimands and must
remain separate in equations, syntax, TMB data/parameters, extractors,
simulation truths, and user interpretation.

## Current evidence boundary

A deterministic simulated-data probe with 32 species and 384 observations
reached two independent expected-rejection gates: Beta first rejected the
canonical direct-SD distributional parameter and then rejected `phylo()` in
`mu`. The fixed `mu + sigma` Beta control converged. This establishes only the
current admission boundary. It is not likelihood, recovery, interval,
coverage, or support evidence for the proposed slice.

## Required starting artifacts if selected

Before implementation, write the symbolic equation -> R syntax -> DGP -> TMB
parameter -> extractor -> truth alignment and a family/provider admission
matrix. The first matrix must distinguish Beta from beta-binomial, Gamma,
lognormal, count, and Student-t scale contracts rather than inferring a common
engine from a common `sd()` spelling. Tests must preserve malformed neighbours
and the existing fixed `mu + sigma` control.

Run toy simulations locally, then use Totoro or DRAC for retained-denominator
recovery. Never use GitHub Actions for simulation, recovery, power, or coverage
campaigns.

## Post-Arc-3a decision

**Decision at Arc 3a closeout: bank and split; do not execute next.** The Beta
example currently combines two independently absent capabilities--Beta
`phylo()` in `mu` and a non-Gaussian direct random-effect-SD submodel--inside a
three-estimand location-scale-scale fit. That is too much parser, likelihood,
identifiability, and comparator risk for one first slice.

The recommended next main-lane slice is Arc 1b-S1, the existing bivariate-
Gaussian fixed-covariance spatial q2 location cell under REML, because it has
an ML comparator and an independent dense restricted-likelihood oracle. The
full plan is `docs/dev-log/2026-07-14-next-arc1b-spatial-q2-reml-ultra-plan.md`.

When this `sd()` candidate returns, split it into three approved GOALs:

1. admit and recover Beta phylogenetic `mu` without a direct-SD formula;
2. prove canonical `sd(group, level = ...)` parsing and extractor compatibility
   on an existing Gaussian structured route; and
3. only then combine them in the Beta phylogenetic location-scale-scale model.

Each later family still needs its own scale mapping and evidence. The shared
`sd()` spelling is not a blanket likelihood contract.
