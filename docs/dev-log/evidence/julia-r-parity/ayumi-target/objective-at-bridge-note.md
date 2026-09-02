# Design note — an R-side surface for DRM.jl's `reml_objective_at` (#575 follow-up)

**Not implemented this slice.** `R/julia-bridge.R` is 5,985 lines of
structured payload/translate/call machinery (`drm_julia_bridge_payload`,
`drm_julia_translate_control`, `drm_julia_call_bridge`, …); wiring a new
diagnostic entry point through it correctly — including a live-Julia-gated
`testthat` case — is not a "small and clean" addition within this slice's
budget. This note records the intended R surface so the next slice can build
it without re-deriving the design.

## What DRM.jl now exposes (landed this slice)

`DRM.reml_objective_at(prob, Q_cond, phi; beta0, u0, n_newton)` — added to
DRM.jl (`src/reml_q4.jl`, exported, ENGINE tier) on branch
`feat/575-objective-at`. Evaluates the q=4 REML objective at a **supplied**
`phi = (beta_rho, lc)`, reprofiling `beta_mu1/mu2/s1/s2` by the same
conditional-Newton alternation `fit_q4_reml` runs internally, and returns the
normalised (TMB/lme4/glmmTMB-comparable) `reml_loglik`. It is the primitive
behind #575's mode-finder-vs-objective-translation diagnosis: "is DRM.jl's
own objective, evaluated AT another engine's fitted point, better or worse
than what DRM.jl's own solver returned?"

## Intended R surface

A thin wrapper, NOT a new payload/translate/call triple — this diagnostic
does not fit a model, it evaluates one already-parameterised point, so it
should reuse the bridge's EXISTING problem construction rather than
duplicating it:

```r
drm_julia_reml_objective_at <- function(fit, beta, Lambda, rho12 = NULL) {
  # `fit` = a drmTMB fit already produced via the biv-q4-phylo REML bridge
  #   route (engine = "julia", method = "REML") -- reuses its cached
  #   Julia-side `prob`/`Q_cond` handles rather than re-marshalling data.
  # `beta` = named list/vector of TMB-scale fixed effects
  #   (beta_mu1, beta_mu2, beta_sigma1, beta_sigma2[, beta_rho12]).
  # `Lambda` = 4x4 phylo covariance matrix, axis order (mu1, mu2, sigma1,
  #   sigma2) -- e.g. straight from `fit$obj$report()$phylo_q4_covariance`,
  #   which #575's diagnosis confirmed is ALREADY on DRM.jl's own axis basis
  #   (no further reparameterisation needed beyond DRM.jl's own
  #   `Λ_to_lc`/`pack_phi`, which the bridge call performs Julia-side).
  # Returns a list: reml_loglik (normalised), raw_reml_ll, converged.
}
```

Bridge-side, this maps to one `JuliaCall::julia_call` invocation of
`DRM.reml_objective_at` against the fit's already-built `prob`/`Q_cond`
(the base biv-q4-phylo REML route already constructs and can cache these —
see `drm_julia_call_bridge` / the `biv_q4_phylo_reml` cell's
`drm_julia_biv_phylo_dpars`/`drm_julia_biv_phylo_dimension` helpers for the
existing problem-shape logic to reuse), plus the same `pack_phi`/`Λ_to_lc`
marshalling #575's diagnosis did by hand in Julia. No new TMB-control
surface, no new family/dpar dispatch — the intended scope is genuinely
narrow.

## Why this is the right shape (not a bigger bridge feature)

- **Read-only diagnostic, not a fitting route.** It must not gain its own
  `optimizer`/`control` surface, `family` dispatch, or missing-data handling
  — it evaluates one point against an EXISTING fitted problem.
- **Reuses, does not duplicate, problem construction.** The base
  `biv_q4_phylo_reml` bridge route already builds the Julia-side
  `prob`/`Q_cond`; a second independent construction path would be the kind
  of "two correct implementations of one thing" this codebase's lane
  discipline warns against.
- **Test gating.** The live-Julia `testthat` case belongs behind the same
  `skip_if_not_installed`/live-Julia guard the rest of the bridge suite
  uses (see `tests/testthat/test-xfam-bridge.R` for the pattern) — it should
  assert the same two numbers #575's diagnosis and DRM.jl's
  `test/test_reml_objective_at.jl` already pin: `obj(θ̂_julia) ≈ -219.630231`
  and `obj(θ̂_TMB) ≈ -219.620508` (DRM.jl-side tolerance 2e-4, documented
  there as the inner-alternation noise floor — not tighter than that on the
  R side either).

## Pointers

- DRM.jl impl: `src/reml_q4.jl` (`reml_objective_at`), branch
  `feat/575-objective-at`.
- DRM.jl test: `test/test_reml_objective_at.jl`.
- #575's original mechanism receipt (the numbers this note's test case
  should reproduce from R):
  `docs/dev-log/evidence/2026-09-01-matched-q4/575-mechanism.md` (this repo).
- Bridge machinery to reuse, not duplicate: `R/julia-bridge.R`
  (`drm_julia_bridge_payload`, `drm_julia_call_bridge`,
  `drm_julia_biv_phylo_dpars`, `drm_julia_biv_phylo_dimension`).

## Not this slice

R code, a new `testthat` file, any change to `R/julia-bridge.R`, promoting
this to a public/documented bridge entry point, or an `r_bridge_status`
change.
