# Structured REML Status

## Purpose

This note records the SR051-SR060 native REML boundary for structured random
effects. It keeps exact-Gaussian mean-side phylogenetic REML separate from ML
support, q2/q4 support, direct DRM.jl evidence, R-to-Julia bridge support, and
HSquared/AI-REML wording.

## Current Native REML Support

Native `REML = TRUE` supports the exact-Gaussian univariate mean-side
phylogenetic location model:

```r
bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
```

The focused REML test compares the fitted values to a hand-computed restricted
likelihood reference and checks that the REML phylogenetic SD is not more
downward-biased than the ML estimate in the fixture.

## Current Native REML Rejections

Native REML currently rejects:

- scale-side phylogenetic structured effects;
- matched univariate phylogenetic `mu`/`sigma` location-scale effects;
- q2 and q4 phylogenetic structured effects;
- coordinate `spatial()` structured effects;
- `animal()` structured effects;
- `relmat()` structured effects.

A direct smoke on 2026-06-22 showed that `spatial()`, `animal()`, and
`relmat()` REML all reject with the current message:

```text
`REML` currently supports only phylogenetic (`phylo()`) mean-side structured effects.
Spatial, animal, and relatedness structured effects under REML are not validated yet.
```

## Vocabulary Boundary

Native REML here means exact Gaussian restricted likelihood inside drmTMB's
native TMB engine. It is not HSquared AI-REML. Direct DRM.jl q4 REML evidence
is direct Julia evidence only until an R-to-Julia bridge row proves parity for
that exact cell.

This note does not promote native q4 REML, non-Gaussian REML, R bridge support,
public optimizer controls, or calibrated interval coverage.
