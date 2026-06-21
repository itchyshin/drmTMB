# After-task: Julia Stage B — warm-start parametric bootstrap (direct DRM.jl lane)

**Date:** 2026-06-20 · **Author:** Ada (autonomous, owner-directed "let's finish B here") · **Gate:** warm-vs-cold parity (DRM.jl test suite) + Fisher + Rose review
**Branches:** drmTMB `shannon/overnight-audit-gaps-20260619`; DRM.jl `shannon/overnight-audit-verify-20260619`

## Task goal

Owner-directed (design 179 Stage B, "let's finish B here; we don't need a fresh
session"): land a warm-started parametric bootstrap "maximized in Julia" — reuse the
fitted optimum as the optimiser start for every replicate refit so the bootstrap (the
repeated-re-optimisation workload native TMB cannot make cheap) runs faster, with a
parity gate proving warm == cold.

## Scope decision (honest)

Deep read of the bootstrap paths showed the FULL warm-start (every cell) is genuinely
a focused effort: the paths with an existing warm hook (`_fit_locscale`) have a
degenerate bootstrap under the population-level (RE-at-zero) `simulate`, and the
clean-bootstrap paths (Gaussian phylo / RE) lack a packed-start fitter entrypoint. The
cell where warm-start lands SAFELY now is the **fixed-effect Gaussian location-scale**
model: interior MLE, clean `simulate`, and a compact fitter (`_fit_fixed_gaussian`)
with an obvious optimiser start. Landed that cell; documented the rest as deferred.

## Files changed

- DRM.jl `src/gaussian_core.jl`: `_fit_fixed_gaussian` gains an optional `start` kwarg
  (the fitted optimum); when `nothing` the OLS + log-sd cold start is used.
- DRM.jl `src/inference.jl`: `_gaussian_warm_refit` builds a warm refit closure
  (reuses θ̂ as the LBFGS start; per-replicate cold-start fallback on a non-finite /
  non-converged warm solve; rejects non-fixed-effect fits with a clear `ArgumentError`).
  `warmstart::Bool=false` threaded through the `DrmFit{<:Gaussian}` overloads of
  `bootstrap_result` / `bootstrap_summary` / `bootstrap_ci`; the bivariate q4 path
  rejects `warmstart=true`.
- DRM.jl `test/test_bootstrap_warmstart.jl` (new) + `test/runtests.jl` (registered).
- drmTMB `docs/design/179-...md` (Stage B warm-start increment LANDED),
  `docs/dev-log/dashboard/julia-capabilities.tsv` (bridge-row wording: warm-start not
  reachable through the bridge; direct-lane landing noted), check-logs (both repos),
  the Stage A after-task follow-ups, this report.

## Checks run and exact outcomes

- Parity gate (`test_bootstrap_warmstart.jl`, Julia 1.10.0): **58/58**. On identical
  seeds, warm and cold summaries match — asserted **1e-7** on the replicate-derived
  SE/CI; `estimate` (original-fit coefficient, refit-independent) exactly equal; the
  warm path is confirmed to actually run (`attempted == used`, `failed == 0`, not a
  silent all-cold fallback). RE fit rejected with `ArgumentError`.
- Regression: `test_bootstrap` **46/46**, `test_bootstrap_nongaussian` **45/45**,
  `test_bootstrap_sigma_a` **36/36**, `test_gaussian_core` **4/4** — all green.
- Single interactive benchmark (NOT asserted in the test): B=600 on a fixed-effect
  fixture → **1.37x** faster, SE/CI agreement **~1.2e-11**.

## What changed for users

A DRM.jl opt-in: `bootstrap_ci(fit; warmstart = true)` (and `_result` / `_summary`)
on a fixed-effect Gaussian location-scale fit runs a faster bootstrap that returns the
same intervals as the default cold path. No R-user-facing change; the R-Julia bridge is
unchanged.

## Risks / boundary

Engine PARITY (warm == cold to optimiser tolerance) + a single-run speed observation —
NOT interval coverage, NOT release/CRAN, NOT a bridge change. The cold-start fallback
guards non-finite / non-converged warm stalls; it does NOT detect convergence to a
different stationary point, so parity rests on the empirical gate plus the interior-MLE
conditions of this cell (the location-scale NLL is not proven globally unimodal). Lanes
(native R/TMB · direct DRM.jl · Julia-via-R) kept separate.

## Review

- Fisher (inference): sound — the parity gate isolates the optimiser start as the only
  degree of freedom (identical seeds → identical replicate data); flagged the
  "provably coincide" / "never the result" overstatement (softened) and the
  byte-identical-estimate framing (corrected to "refit-independent consistency check").
- Rose (claim-boundary): verified R bridge unchanged, no warm-start leak into other
  surfaces; required banking the speed/agreement figures as a single interactive run
  (done), reconciling the stale "deferred" sibling lines (done: TSV, Stage A note,
  handover), and fixing the contradictory test comments (done).

## Follow-ups

- Extend warm-start to EXPENSIVE refit cells (Gaussian phylo / RE) — thread a packed
  start into those fitters — so the R-Julia bridge can pass `warmstart` through.
- LocScale q2 warm path needs an RE-conditional `simulate` first (current
  population-level draw makes its parametric bootstrap degenerate at the boundary).
- A full `devtools::check()` (only targeted DRM.jl suites run here; this slice is
  Julia-side, no R package code changed).
