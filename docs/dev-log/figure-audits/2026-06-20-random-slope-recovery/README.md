# Gaussian random-slope recovery figure (bias/consistency; Florence-approved)

**Date:** 2026-06-20 · **Author:** Ada (autonomous, pushes live) · **Gate:** Florence (APPROVE)

A recovery figure for the Gaussian correlated random-slope model
`bf(y ~ x + (1 + x | id), sigma ~ 1)`, built from the already-verified
(Curie+Fisher) 500-replicate recovery artifact
(`docs/dev-log/simulation-artifacts/2026-06-20-gaussian-random-slope-recovery/`,
no refit). It promotes the matrix "Random slopes" **visual** cell planned -> covered.

## Figure

`random-slope-recovery-bias-v1.png` (script `plot-random-slope-recovery.R`).

- Repo default recovery grammar (`docs/design/39-visualization-grammar.md`): dots +
  Monte-Carlo error bars + a zero target line -- NOT a Confidence Eye (the promoted
  claim is POINT recovery + RE-SD consistency, not coverage).
- x = the five estimands (mu intercept, mu slope, SD(intercept), SD(slope), residual
  sigma); colour = group count (n_group 40 vs 80); bars = +/- 1.96 * rmse/sqrt(n) on
  the relative-bias scale (Monte-Carlo uncertainty on the mean, not model
  uncertainty); grey band = +/- 5% reference (not a pass/fail threshold).

## What it shows (honest)

- Fixed effects near-unbiased at both group counts (mu intercept +1.0%/+0.3%, mu
  slope -0.8%/-0.1%).
- The random-effect SDs carry the expected ML small-sample downward bias that
  SHRINKS with groups: SD(intercept) -2.8% -> -1.0%, SD(slope) -6.7% -> -1.1% from
  n_group 40 to 80 -- the consistency story. The SD(slope) n_group=40 CI excludes
  zero (real bias); the n_group=80 CI includes zero (bias shrunk into noise).
- Residual sigma essentially unbiased.

## Honest scope

POINT recovery only: the random-effect correlation rho is NOT validated, RE-SD
interval calibration is NOT claimed, and the Wald cell stays partial (n_group=40
slope coverage 0.922). This figure promotes only the Visual cell.

## Florence review

APPROVE (single pass). Every plotted value and caption number cross-checked against
the source CSV; colour-blind-safe palette; nothing clipped (SD(slope) n40 whisker to
-8.89% fully visible; v1 adds a -7.5 y-break so the worst-case bias reads off the
axis). Non-blocking suggestion noted: a third group rung (e.g. 160) would make
"consistent" visually unambiguous -- left for a future harder-cap sim.

## Boundary

Bias/recovery display of already-verified random-slope POINT recovery; native TMB,
Gaussian, complete data, n_group in {40, 80}. Not an interval-calibration proof.
Wald/profile cells and the Julia bridge are separate cells.
