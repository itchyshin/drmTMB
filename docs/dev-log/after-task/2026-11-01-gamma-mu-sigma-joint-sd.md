# After-task report: Gamma joint mu and sigma ordinary random intercepts with separate SD formulas

Date: 2026-11-01. Base: branch codex/general-sd-regression at 175e87560.

## What changed

The Gamma builder now admits one ordinary random intercept in mu and one
ordinary random intercept in sigma in the same model, when both carry their own
SD formula:

```r
bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g),
   sd(id) ~ w, sd(g, dpar = "sigma") ~ z)
```

with `family = Gamma(link = "log")`. The grouping factors may differ (crossed)
or be the same factor.

The change is R-side only, in `R/drmTMB.R`, inside the Gamma builder. A new
flag, `gamma_joint_ordinary_sd`, is true only when both SD formulas are present,
there is no structured or phylogenetic mu term, and mu and sigma each hold
exactly one unlabelled intercept bar. When the flag is true, the shared sigma
validator is called without the mu terms, and the one-endpoint-at-a-time gate is
skipped. No C++ change was needed: the native model_type 5 block builds the mu
effects and the sigma effects independently, each with its own group-level SD
regression, so the joint likelihood already existed.

## What is covered

New file `tests/testthat/test-gamma-mu-sigma-joint-sd.R`.

- Dense Laplace oracle over the joint random-effect vector (every id level and
  every g level together), written without drmTMB internals, with exact
  per-observation score and information (digamma and trigamma) and a damped
  Newton mode search. Crossed case and same-factor case. Tolerance fixed before
  the first run: absolute log-likelihood gap below 1e-4. Both cases passed at
  that tolerance on the first run.
- Unbalanced groups, shuffled row order and shuffled factor level order, so SDs
  are matched by level label.
- Emulated bugs, each required to move the oracle by more than 1 log-likelihood
  unit (1e4 times the tolerance): swapped SD coefficients between the two
  formulas, SDs shifted by one level, and the sigma-group effect applied to mu.
- Constant SD formulas (`~ 1` on both) match the oracle with constant SDs, and
  the richer SD-regression fit is not worse in log-likelihood than the constant
  fit.
- Reported coefficients, finite vcov for both SD regressions, and per-group SD
  prediction.
- Neighbours that stay closed, with message patterns: formula-free joint
  ("combined"), mu SD formula only ("combined"), sigma SD formula only beside an
  ordinary mu effect ("combined"), mu random slope beside the sigma intercept
  ("combined"), sigma random slope beside the mu intercept ("combined"), and
  missing-response inclusion ("complete responses").

Neighbouring tests re-run after the change, all with zero failures, zero errors
and zero skips: arc2c sigma random intercept (52 passed), lognormal SD assembly
(24), Gamma sigma SD regression (23) and integration (12), Gamma SD regression
(17) and integration (23), Gamma ordinary SD beside structured (55), Gamma iid
structured (114), Gamma batch 3 (21) and batch 4 (30), Gamma location-scale
(76), NB2 and Gamma same-group oracle (10) and regression (38), Gamma phylo q2
(48), spatial q2 (47), relmat q2 (42), phylo (15). The new file has 26
passed, 0 failed.

## What is not covered

- The formula-free joint model (no SD formulas) stays refused, because an
  existing test (`test-arc2c-sigma-random-intercept.R`) pins that refusal.
  Consequently the constant-SD check could not be made against a formula-free
  fit; it is made against the oracle instead.
- Random slopes in either dpar, several bars per dpar, labelled covariance
  blocks, cross-dpar mu-sigma correlation, and structured or phylogenetic mu
  beside the sigma effect.
- Missing-response integration and missing-predictor integration.
- The Julia bridge. No Julia was started, and the bridge fence on ordinary mean
  random effects was not touched.
- Structured providers (K, A, phylo): not part of this slice, so the
  non-unit-diagonal K check does not apply.
- Simulation recovery, calibration and coverage. No calibration, parity or
  recovery claim is made; the evidence is likelihood agreement with an
  independent oracle at the fitted parameters.

## Engine

Native (TMB, model_type 5). No new engine layer.

## Stale pins

None swapped. The existing formula-free refusal pin still holds and is
repeated in the new refusal test.
