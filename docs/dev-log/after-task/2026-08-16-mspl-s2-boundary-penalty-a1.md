# After-task: MSPL boundary S2 slice 1 (A1 penalty route)

**Date:** 2026-08-16  
**Lane:** `claude/mspl-boundary-s0-s1` · worktree `.worktrees/mspl-s0s1`  
**Reader:** Shinichi / next Cursor agent on this lane

## Purpose

Ship the smallest Design-256 S2 increment: the derived moving-anchor RE-SD soft-penalty
on the univariate Gaussian A1 iid `(1 | group)` cell, as a `penalty` vocabulary extension
(MAP-labeled; intervals withheld).

## What landed

- `drm_boundary_penalty()` + admission/apply wiring in `R/penalty.R`
- C++ hook in the Gaussian leaf: `nll += -c_g * Q_κ(a − mean(η^σ))` with
  `c_g = 2√(q_v/g)`
- `confint` / `profile` hard-abort for this penalty class
- Focused tests including closed-form `I_g`, equivariance-weight loud fails, A1 MAP
  fit, off-cell rejects, and a 5-rep S0-A scale-equivariance smoke

## What did not land

- S3 campaign / D-139 compute
- Public NEWS / all-family expansion / `estimator = "mspl"` overload
- Merge to `main` (0.7 quiesce still binds shipped-file merges)

## Evidence

`NOT_CRAN=true` · `test-boundary-penalty.R` → FAIL 0 / PASS 137; phylo MAP + REML×penalty
guards still green.
