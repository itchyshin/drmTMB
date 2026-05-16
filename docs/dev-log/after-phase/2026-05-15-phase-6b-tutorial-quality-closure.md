# After Phase: Phase 6b Tutorial Quality Closure

Date: 2026-05-15

## Goal

Close the local Phase 6b tutorial-quality pass with the learning path, major
interpretation tables, roadmap status, pkgdown render, pkgdown check, and
stale-claim scans aligned.

## Implemented Scope

Phase 6b improves reader-facing documentation only. It does not change formula
grammar, likelihood parameterization, TMB code, tests, or exported functions.

The implemented documentation boundary is:

- Getting Started and the model map now point from scientific questions to the
  right tutorial, guide, or post-fit workflow.
- The model workflow guide now uses a symbolic equation and a report-scale
  table for `mu`, `sigma`, `rho12`, `corpairs()`, and `profile_targets()`.
- The Gaussian location-scale tutorial now separates fixed slopes, random-slope
  SDs, residual-scale random-slope SDs, and random-effect scale slopes.
- The bivariate coscale tutorial now separates `mu1`, `mu2`, `sigma1`,
  `sigma2`, and `rho12` slopes.
- The meta-analysis tutorial now separates known sampling variance, fitted
  extra heterogeneity SD, heterogeneity variance, and total observation
  variance.
- The structured-dependence tutorial now gives a six-row q=4 phylogenetic
  interpretation table and keeps all four mean-scale pairs visible.
- The scale guide now explains Family A versus Family B, current
  `sd_phylo()` naming, future `sd(..., level = ...)` wording, `corpairs()`, and
  invalid mixed formulations.

## Mathematical Contract

The tutorials now share one interpretation contract:

```text
fixed mu slope          -> expected response
fixed sigma slope       -> residual SD ratio or variance ratio
mean random-slope SD    -> variation in group-level reaction norms
sigma random-slope SD   -> variation in residual-scale reaction norms
sd(group) slope         -> direct model for group-level mean-effect SD
rho12 slope             -> residual response-response coupling
corpairs row            -> named correlation layer, not automatically rho12
```

For q=4 location-scale covariance, the tutorial names all six rows and keeps
`mu1`-`sigma2` and `mu2`-`sigma1` visible alongside the same-trait pairs.

## Checks Run

- `air format` on the edited roadmap and tutorial files: passed.
- `git diff --check`: passed.
- `pkgdown::build_site()`: passed.
- `pkgdown::check_pkgdown()`: passed with no problems found.
- Rendered-source scans confirmed the new learning-path, scale, bivariate,
  meta-analysis, and q=4 tutorial text.
- Stale-claim scans found no claim that phylogenetic or spatial slopes are
  implemented, no claim that derived q=4 profile intervals are ready, and no
  new `rho ~`, `meta_gaussian()`, or `tau ~` user-facing syntax. Remaining
  hits are intentional guardrails.

## What Remains Outside Phase 6b

- GitHub Actions and public pkgdown deployment remain PR-side gates.
- Real-data tutorial expansion remains future work.
- Profile intervals for derived q=4 correlations remain future work.
- Structured random slopes move to Phase 6c; they are not implemented by this
  tutorial pass.
- Visualization and marginal-effect helper APIs remain a later phase.

## Team Learning

- Ada: close tutorial phases with rendered-site evidence, not just source
  edits.
- Boole: syntax tables are clearest when they name the parameter layer before
  the formula.
- Gauss and Noether: no math contract changed; the value is that equations,
  output columns, and interpretation now match more closely.
- Darwin and Pat: biological examples need explicit "what this coefficient
  means" tables for slope and variance-component work.
- Grace: the local gate is green; GitHub Actions should be the next
  reproducibility check.
- Rose: future tutorial edits should keep planned structured slopes and derived
  profile intervals visibly planned.

## Next Actions

1. Open the Phase 6b tutorial-quality PR.
2. Watch GitHub Actions and fix any platform-specific documentation issue.
3. After merge, start Phase 6c with the random-slope math contract and ordinary
   one-slope baseline.
