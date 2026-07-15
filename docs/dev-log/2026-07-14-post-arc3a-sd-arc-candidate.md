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

At Arc 3a closeout, compare this candidate against the remaining main-lane arcs
using the updated `main` capability ledger, user value, boundedness of the first
slice, engine/design risk, independent comparator availability, and achievable
recovery evidence. The comparison may recommend this arc, defer it, or split
the Beta gate further. No choice is made in this note.
