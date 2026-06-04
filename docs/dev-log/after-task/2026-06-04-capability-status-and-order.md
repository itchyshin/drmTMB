# After Task: Capability Status Classification and Ordered Working Plan

## Goal

The project owner needed an unambiguous statement of which capabilities are
actually fitted versus only measured by a simulation lane versus not yet
implemented, plus a single ordered list of what to work on, furnished for a
local-R (Codex) session that can compile TMB.

## Why It Mattered

The recent run of recovery/coverage simulation lanes risked being read as new
model capabilities. They are not: a recovery lane quantifies accuracy for a
model that already fits. The headline goal (the individual-difference covariance
endpoint) and several other surfaces are still not-yet-fitted.

## Implemented

- `docs/design/157-capability-completion-worklist.md`: added
  - "Capability Status: Three Distinct Categories" — Implemented (fitted),
    Simulation-evidence (lanes; wired but not yet run at formal scale), and
    Not-yet-fitted (the gap) — with a classification table that states plainly
    that q4/q6 exist only for bivariate Gaussian location, q8 is design-only, and
    there is no non-Gaussian random-slope correlation or q4/q6/q8 block.
  - "Recommended Working Order" — a single flat sequence: Phase A implements the
    TMB capabilities in dependency order (q2 scale-slope -> same-response
    location-scale slope -> q8; skew-normal in parallel; structured slopes;
    correlated non-Gaussian slopes/labelled covariance; rho12 random effects;
    large-data; mixed-response deferred), Phase B runs the recovery/coverage
    evidence, Phase C is comparator + release, then the power simulation.
- `docs/design/46-pre-simulation-readiness-matrix.md`: pointer to the
  classification, stressing lane = evidence, not capability.
- Handoff issue #491 updated to embed the ordered plan.

## Scope

Documentation only. No fitted status changed; no R code or tests touched.

## Next

Codex runs Phase A/B/C from doc 157 locally; this note and #491 are the entry
points.
