# Issue #575 basin-selection — progress log

## Cycle 1

**What ran:** `test/test_575_q4_optimum.jl` (still `@test_broken` at this
point, unmodified assertion) against the basin-selection implementation
(K=4 Λ0 candidates: caller/default 0.3I, 0.1I, 1.0I, 2.0I; pre-screen 30
iters @ g_tol=5e-3; full solve from best 2 candidates; accept-by-contract
selection).

```
Test Summary:                               | Broken  Total   Time
issue #575: q4 REML reaches its own optimum |      1      1  40.2s
```

Still `Broken` (assertion still false) — no `Unbroken` error, so the floor
(`-219.6206`) was not reached.

**Direct diagnostic** (`drm()` public route, same fixture):
```
wall_time_fixed = 39.35273003578186 s
loglik(fit) = -219.6301582324982
is_converged(fit) = true
```

**Objective:** -219.630158 — essentially IDENTICAL to the pre-basin-selection
baseline (-219.630231, delta 0.00007, within run-to-run BLAS/SuiteSparse
noise already documented in p12a-summary.md). No material improvement.

**Verdict: basin selection did not find a better basin on this run.**

**Diagnosis:** the pre-screen (30 iterations, g_tol=5e-3) most likely ranks
the status-quo Λ0=0.3I candidate as best (or ties with it) before any
candidate's LBFGS trajectory has moved far enough to reveal a genuinely
different, better basin — 30 iterations is a small fraction of what the
looped-polish experiments in the plateau report needed (NelderMead+LBFGS
needed 5000+500 iterations per round to shave the gap at all). The
`is_converged=true` / `converged` contract IS satisfied here (good — no
#484-style regression expected from this candidate), but the winning
candidate is essentially the same basin as before.

**Next action (cycle 2, bounded):** widen the pre-screen budget
substantially (still capped, e.g. 150-200 iterations instead of 30) so
candidates have a real chance to separate, and/or bias the candidate set
more aggressively per the design's item (c) — a direct φ0 perturbation in
the fruitful direction (larger cross-axis structure, not just a uniform
diagonal Λ0 scale) rather than only isotropic Λ0 scale variants, since the
mechanism note showed the better basin's Λ has non-trivial off-diagonal
structure that an isotropic-scale ML warm start is unlikely to discover on
its own regardless of scale.

## Cycle 2 (final — hard boundary reached, concluding)

**What changed from cycle 1:** widened pre-screen from 30 iters/g_tol=5e-3 to
150 iters/g_tol=2e-3; added a 5th candidate, a structured (non-diagonal)
Λ0 alongside the isotropic {default, 0.1I, 1.0I, 2.0I} scales, since the
mechanism note's better basin has real off-diagonal Λ structure that an
isotropic-scale ML warm start cannot discover regardless of scale.

**What ran:** full no-regression gate — `test_575_q4_optimum.jl`,
`test_q4_reml_warm_restart.jl`, `test_reml_q4_allaxes.jl`,
`test_parity_biv_q4_phylo_reml.jl` — chained in one `include()` sequence
(a `LoadError` from an early failure halts later `include`s in the chain,
so allaxes/parity did not get a chance to run this cycle).

```
Test Summary:                               | Broken  Total   Time
issue #575: q4 REML reaches its own optimum |      1      1  42.2s
Test Summary:                                                            | Pass  Total   Time
q4 phylo REML: public drm() converges through public kwargs alone (#484) |    3      3  13.7s
q4 phylo REML: engine-level g_residual < g_tol, not just the flag (#484): Test Failed
  Expression: rr.g_residual < g_tol
   Evaluated: 0.0026196283797741415 < 0.001
Test Summary:                                                            | Pass  Fail  Total   Time
q4 phylo REML: engine-level g_residual < g_tol, not just the flag (#484) |    2     1      3  16.5s
```

**Verdict: REGRESSION.** #575's own test still `Broken` (no material
improvement — the widened pre-screen still did not separate candidates
enough to reach the floor). The public-route `is_converged` assertion
passed, but the ENGINE-LEVEL `g_residual < g_tol` assertion — a stricter,
direct check bypassing the `is_converged` flag — now fails
(`g_residual = 0.0026 > g_tol = 0.001`). This is a genuine regression: the
basin-selection's accept-by-contract logic uses `Optim.g_residual(res_c)`
on each FULL-solve candidate and should reject a candidate whose final
g_residual exceeds `g_tol`, but the WINNING candidate it selected still
ends up with `g_residual = 0.0026` at the engine level despite passing the
higher-level `is_converged` flag — meaning `Optim.converged(res)`'s own
internal bookkeeping (which also allows an f-criterion-based convergence
claim, not only a strict g_tol check) accepted a point the engine-level
test's own tighter numeric check does not.

**Hard boundary reached (2 regression cycles).** Per the coordinator's cap,
concluding now: `src/reml_q4.jl` reverted entirely back to the state at
commit `6cb66b07` (no diff). No implementation commit is made this slice.
