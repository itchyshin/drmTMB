# Issue #575 basin-selection slice — final summary

## Design chosen

Restructured `fit_q4_reml` (src/reml_q4.jl) so that, when the caller does not
supply `phi0` directly (the normal `drm(method=:REML)` path), the REML LBFGS
is no longer started from a single ML-warm-start `phi0`. Instead:

1. Build **K = 5** structurally different `Λ0` candidates for the ML
   warm-start step (`fit_q4_sparse_tmb`): the caller's own default
   (`0.3I(4)`), two isotropic scale variants (`0.1I(4)`, `1.0I(4)`,
   `2.0I(4)` — i.e. 4 isotropic scales including the default), plus one
   **structured (non-diagonal)** candidate, since the mechanism note's
   known-better basin has real off-diagonal `Λ` structure that no isotropic
   scale can reach.
2. **Cheap pre-screen**: derive each candidate's own ML-warm-start `phi0`,
   then run a SHORT LBFGS pass (150 iterations, `g_tol = 2e-3`; widened from
   an initial 30/`5e-3` in cycle 1 that separated nothing) and rank
   candidates by the objective at the pre-screen's endpoint.
3. **Full solve from the best 1–2** pre-screened candidates only (continuing
   from each candidate's own pre-screen endpoint, not re-starting from
   scratch), capping the runtime multiplier well under `K×`.
4. **Snapshot/restore `u_cache`/`beta_cache`** around every candidate
   evaluation (pre-screen and full solve alike) — the known
   cache-corruption trap from the earlier plateau slice — with an inline
   comment naming it.
5. **Accept-by-contract selection**: among the best 1–2 fully-solved
   candidates, prefer one satisfying `g_residual < g_tol`; among those
   (or, failing that, among all), prefer the better objective value. A
   better objective that fails the g_tol contract was meant to be rejected.

The rest of `fit_q4_reml` (the `#484` stall-restart and `#497` widened
rescue blocks, the final `phi_hat`/`reml_loglik`/`converged`/`g_residual`
computation) was left untouched from the pre-slice baseline.

## Pre-screen budget

Cycle 1: 30 iterations, `g_tol = max(g_tol*5, 1e-2)`. Cycle 2 (final):
150 iterations, `g_tol = max(g_tol*2, 2e-3)`.

## Per-candidate objectives

Not captured numerically per-candidate in a standalone diagnostic this
slice (time-boxed under the coordinator's 2-regression-cycle cap) — only
the end-to-end `drm()` route was measured directly:

| Run | `loglik(fit)` | `is_converged(fit)` |
|---|---|---|
| Pre-slice baseline (no basin selection, PLATEAU report) | -219.630231 | true |
| Cycle 1 (K=5 candidates, pre-screen 30/5e-3) | -219.630158 | true |
| Cycle 2 (K=5 candidates, pre-screen 150/2e-3, structured Λ0 added) | not independently re-measured via `drm()` after the widen (superseded by the regression found in the direct `test_q4_reml_warm_restart.jl` engine-level check, below) | — |

Cycle 1's `drm()`-route number (-219.630158) is materially IDENTICAL to the
pre-slice baseline (-219.630231; delta 0.00007, within the run-to-run
BLAS/SuiteSparse floating-point noise already documented for this iterative
pipeline) — the basin selection did not find a better basin on that run.

## Final converged objective + g_residual

**No implementation shipped.** The cycle-2 full no-regression gate found a
genuine regression on `test_q4_reml_warm_restart.jl`'s ENGINE-LEVEL check
(bypassing the `is_converged` flag):

```
q4 phylo REML: engine-level g_residual < g_tol, not just the flag (#484): Test Failed
  Expression: rr.g_residual < g_tol
   Evaluated: 0.0026196283797741415 < 0.001
```

i.e. the basin-selected winner's own `Optim.g_residual` (0.0026) exceeds
`g_tol` (0.001) at the engine level, even though the higher-level
`is_converged(fit)` flag (which also allows Optim's f-criterion route to
convergence, not only a strict g_tol check) still read `true`. Per the
coordinator's design point 4 ("a better objective that fails the contract
is rejected") and the hard boundary ("never more than 2 regression cycles
without concluding"), `src/reml_q4.jl` was **reverted entirely** back to
the state at commit `6cb66b07` (verified `git diff` empty / `git status`
clean against `HEAD` after the revert) rather than attempting a third
fix-and-verify cycle.

## All test summaries, verbatim

**Cycle 1 — target test only, K=5 candidates, pre-screen 30/5e-3:**
```
Test Summary:                               | Broken  Total   Time
issue #575: q4 REML reaches its own optimum |      1      1  40.2s
```
Direct diagnostic (`drm()` public route):
```
wall_time_fixed = 39.35273003578186 s
loglik(fit) = -219.6301582324982
is_converged(fit) = true
```

**Cycle 2 — full no-regression gate, pre-screen widened to 150/2e-3, structured Λ0 added:**
```
Test Summary:                               | Broken  Total   Time
issue #575: q4 REML reaches its own optimum |      1      1  42.2s
Test Summary:                                                            | Pass  Total   Time
q4 phylo REML: public drm() converges through public kwargs alone (#484) |    3      3  13.7s
q4 phylo REML: engine-level g_residual < g_tol, not just the flag (#484): Test Failed at test/test_q4_reml_warm_restart.jl:100
  Expression: rr.g_residual < g_tol
   Evaluated: 0.0026196283797741415 < 0.001
Test Summary:                                                            | Pass  Fail  Total   Time
q4 phylo REML: engine-level g_residual < g_tol, not just the flag (#484) |    2     1      3  16.5s
```
(`test_reml_q4_allaxes.jl` and `test_parity_biv_q4_phylo_reml.jl` did not
run this cycle — the `LoadError` from the `#484` engine-level failure
halted the chained `include()` sequence before reaching them.)

## Timing line

Fixed-code (basin-selection, cycle 1) `drm()` wall time on the fixture:
**39.35 s**. No independently-measured baseline (pre-slice) wall time was
re-captured in THIS slice (the plateau slice's earlier runs measured whole
test files, not an isolated `drm()` call, so they are not directly
comparable); report only, no speed claim — this number is provided for the
record, not as a before/after comparison.

## Verdict: PLATEAU

No src fix shipped this slice either. `src/reml_q4.jl` is reverted to
`6cb66b07`'s content (test-only state, `@test_broken` unchanged). No new
implementation commit was made — there is nothing to commit beyond the
progress/summary scratchpad files, which are outside the repo. The branch
`fix/575-q4-optimum` is unchanged at `f33dfb69` (the tip already present
before this slice started, including an unrelated docs-only citation
commit made concurrently by another lane).

## Root cause (unchanged from the plateau report, reconfirmed)

Basin-dependence of a non-convex REML variance-component surface. This
slice's decisive new finding: even a K=5, pre-screened, contract-gated
basin search — cheap enough to bound runtime well under `K×` — either (a)
does not separate candidates enough within an affordable pre-screen budget
to find the better basin (cycle 1), or (b) when the pre-screen budget is
widened enough to start separating candidates, the WINNING candidate's own
full solve can still land at a point whose engine-level `g_residual`
exceeds `g_tol` while `Optim.converged`'s own (looser, f-criterion-
inclusive) bookkeeping still calls it converged (cycle 2) — i.e. the
accept-by-contract gate as implemented was not strict enough, because it
trusted `Optim.g_residual(res_c)` measured immediately after each
candidate's full solve, but did not re-verify that same number the way
`test_q4_reml_warm_restart.jl`'s OWN engine-level check does at the
returned `phi_hat` (post the #484/#497 rescue blocks, which run identically
regardless of which candidate basin selection picked).

## One-sentence hypothesis for what a proper fix needs

The accept-by-contract check inside basin selection needs to be the
IDENTICAL final check `test_q4_reml_warm_restart.jl` performs (post-#484/
#497-rescue `g_residual`, not each candidate's raw post-full-solve
`Optim.g_residual`), and/or the pre-screen needs a genuinely larger budget
or a smarter candidate-ranking criterion than plain objective-at-endpoint,
before this design can be trusted to ship without an engine-level
regression.

## Files

- Progress log (per-cycle checkpoints): `scratchpad/p12a-basin-progress.md`
- Reverted-attempt backup (not shipped):
  `scratchpad/reml_q4.jl.basin-selection-attempt-backup`
- Prior plateau report (root cause, warm-start finding):
  `scratchpad/p12a-summary.md`
