# Issue #575 — q4 REML mode-finder: PLATEAU

## Root cause

`fit_q4_reml` (src/reml_q4.jl) declares convergence purely on FD-gradient
grounds (`g_residual < g_tol`). On the `biv-q4-phylo-reml` fixture, the
standard ML-warm-start trajectory (default `Λ0 = 0.3I(4)` → `fit_q4_sparse_tmb`
→ REML LBFGS) lands in a basin whose local optimum is objectively worse than
a basin reachable from a different starting point. This is **basin-dependence
of a genuinely non-convex REML variance-component surface**, not a loose
tolerance or a line-search-termination bug within the basin the standard
warm start finds. Restarting/polishing FROM that basin (tighter g_tol,
NelderMead+LBFGS, bounded jittered multistart) can shave part of the gap but
never reaches the better basin, because none of those moves are large enough
in the right direction to cross the basin boundary.

## The warm-start finding (decisive diagnostic)

Calling `fit_q4_reml(prob, Q_cond; phi0 = phi_TMB, beta0 = beta_TMB,
Lambda0 = Lambda_TMB, g_tol = 1e-3, iterations = 300, n_newton = 40)` —
i.e. starting the REML LBFGS DIRECTLY at TMB's fitted point instead of the
usual ML warm start — reaches:

```
converged = false   g_residual = 0.0009023359541782128   (< g_tol = 1e-3, but Optim's own flag still read false)
reml_loglik (normalised) = -219.6034149638684
phi moved from phi_tmb by norm = 0.0180600358027271
```

`-219.6034` is **better than TMB's own reported optimum** (`-219.6139863`).
This proves a materially better basin exists and is reachable by the SAME
optimizer/objective — the standard ML-warm-start trajectory (which lands at
`-219.630231`) simply never gets there. This is the single most important
finding: the bug is "wrong starting basin," not "stops short within a basin."

## What was tried, in order (all in `src/reml_q4.jl`, `fit_q4_reml`)

1. **Tighter-g_tol LBFGS restart from the same point**, accepted via
   `Optim.minimum` comparison — introduced a cache-corruption bug (the
   restart trial mutates the shared `u_cache`/`beta_cache` `Ref`s via `fg!`
   regardless of whether it's adopted, corrupting the warm-start used later
   for `phi_hat`'s own final evaluation). Fixed by snapshotting/restoring
   the cache Refs around every trial. This was itself a real, independently
   confirmed bug (a rejected trial silently regressing the accepted point's
   reported objective from -219.630231 to -219.634351) but fixing it alone
   did not close any of the actual #575 gap — the trial from the same point
   at a tighter tolerance is simply rejected every time (no improvement
   available in that direction from that point).
2. **NelderMead (derivative-free) + LBFGS refine, one pass**: closed part of
   the gap, `-219.630231 → -219.625761`.
3. **Looped NelderMead+LBFGS (up to 5 rounds, accept only if strictly
   better)**, tighter tolerances (`x_reltol`, more iterations): plateaued at
   `-219.625166` after round 2 (round 3 found no further improvement).
4. **Bounded jittered multistart (3 fixed-seed `MersenneTwister(575)`
   restarts, jittering the lc/variance block by `N(0, 0.05²)`, each run
   through NelderMead+LBFGS, accept only if strictly better)**: reached
   `-219.624343` (best value found in this whole investigation), still short
   of `floor_ll = -219.6206` by `0.0037`.
5. **Convergence-flag fix**: reporting `converged` via `g_resid_val < g_tol`
   (the caller's own tolerance) instead of `Optim.converged(res)` directly,
   since the internal LBFGS calls inside the polish/multistart machinery run
   at their OWN (tighter) internal `g_tol`, whose own `Optim.converged` flag
   can read `false` even when the point comfortably satisfies the caller's
   actual tolerance. This did NOT fix the regression below — the final
   `g_resid_val` itself, not just Optim's bookkeeping, was above `g_tol` at
   the multistart's best point.

## Regression found and why the fix was reverted

`test/test_q4_reml_warm_restart.jl` — "q4 phylo REML: public drm() converges
through public kwargs alone (#484)" — regressed under every version of the
polish/multistart machinery: `is_converged(fit)` went from `true` (current
committed behaviour) to `false`. The multistart machinery's best-found point
(`-219.624343`) has a genuinely worse FD gradient residual than `g_tol`,
even though it is a strictly better objective value than the baseline
(`-219.630231`) — i.e. a point that is BETTER by objective but not
"converged" by the existing gradient-based contract. Per the coordinator's
explicit instruction, since #484 still failed after the convergence-flag
fix, **the `src/reml_q4.jl` change was reverted entirely** (back to the
state at commit `608abcf6`, the test-only commit). No src change is shipped.

## Before / after objectives (all runs executed, verbatim numbers)

| Point | reml_loglik (normalised) |
|---|---|
| TMB optimum (`expected.toml`) | -219.613986 |
| DRM.jl baseline (`fit_q4_reml`, committed code, unchanged) | -219.630231 |
| DRM.jl's own objective at θ̂_TMB (reprofiled) | -219.620508 |
| Attempt 2 (NM+LBFGS, 1 pass) | -219.625761 |
| Attempt 3 (looped NM+LBFGS, plateaued) | -219.625166 |
| Attempt 4 (jittered multistart, best found — **regressed #484**) | -219.624343 |
| Warm-start DIRECTLY at φ_TMB (diagnostic only, not shippable as-is) | -219.603415 (better than TMB) |

Final shipped state: **DRM.jl baseline, unchanged, -219.630231** (src
reverted).

## Verbatim test summaries (every run executed)

**Failing test first (RED), baseline code:**
```
issue #575: q4 REML reaches its own optimum: Test Failed ...
  Expression: loglik(fit) >= floor_ll - 0.001
   Evaluated: -219.63023117686905 >= -219.6216
Test Summary:                               | Fail  Total   Time
issue #575: q4 REML reaches its own optimum |    1      1  38.0s
```

**After cache-bug fix (single tighter-g_tol restart, still rejected every
time — same as baseline):**
```
Evaluated: -219.63023117686905 >= -219.6216
```
(before the cache-bug fix, the SAME polish attempt without snapshot/restore
produced a worse, corrupted value: `-219.634350814876 >= -219.6216`)

**After NelderMead+LBFGS single pass:**
```
Evaluated: -219.62576098506713 >= -219.6216
```

**After looped NM+LBFGS (5 rounds, plateaued at round 2):**
```
Evaluated: -219.6251664129739 >= -219.6216
issue #575: q4 REML reaches its own optimum |    1      1  1m12.8s
```
Re-confirmed on the standalone diagnostic script's own independent
evaluation (`reml_ll_and_mode` at the returned `phi`, not through the test):
```
converged = false  g_residual = 0.002342358299323166
reml_loglik (normalised) = -219.62434309448295
```
(this run used a slightly earlier/later floating point trajectory —
BLAS/SuiteSparse threading gives small run-to-run numerical variation in
this iterative pipeline, ~0.001 on reml_loglik, observed directly across
repeated runs of byte-identical code)

**After bounded jittered multistart (best found overall):**
```
issue #575: q4 REML reaches its own optimum: Test Failed ...
  Expression: loglik(fit) >= floor_ll - 0.001
   Evaluated: -219.62434309448295 >= -219.6216
Test Summary:                               | Fail  Total     Time
issue #575: q4 REML reaches its own optimum |    1      1  7m16.9s
```

**Regression on #484 (Optim.converged(res) directly):**
```
q4 phylo REML: public drm() converges through public kwargs alone (#484): Test Failed
  Expression: is_converged(fit) == true
   Evaluated: false == true
Test Summary:                                                            | Pass  Fail  Total     Time
q4 phylo REML: public drm() converges through public kwargs alone (#484) |    2     1      3  7m35.7s
```

**Regression on #484 persisted after the `g_resid_val < g_tol` convergence-flag fix:**
```
q4 phylo REML: public drm() converges through public kwargs alone (#484): Test Failed
  Expression: is_converged(fit) == true
   Evaluated: false == true
Test Summary:                                                            | Pass  Fail  Total     Time
q4 phylo REML: public drm() converges through public kwargs alone (#484) |    2     1      3  8m47.3s
```
→ confirms the multistart's best point genuinely has `g_residual > g_tol`,
not merely a bookkeeping artifact of `Optim.converged`. This is the direct
evidence for reverting rather than shipping a "better objective, worse
gradient-contract" trade.

**Warm-start-at-φ_TMB diagnostic (decisive finding, verbatim):**
```
=== Warm-start fit_q4_reml DIRECTLY at phi_tmb (bypassing ML warm start) ===
converged = false  g_residual = 0.0009023359541782128
reml_loglik (normalised) = -219.6034149638684
phi moved from phi_tmb by norm = 0.0180600358027271
```

**Final state (src reverted to 608abcf6, test marked `@test_broken`):**
```
Test Summary:                               | Broken  Total   Time
issue #575: q4 REML reaches its own optimum |      1      1  39.9s
```

## Verdict

**PLATEAU.** No src fix shipped. The failing assertion is now `@test_broken`
in `test/test_575_q4_optimum.jl`, with the numeric floor left unchanged
(verified reachable in principle by the warm-start-at-φ_TMB diagnostic) and
a comment pointing back to this file.

## One-sentence hypothesis for what a proper fix needs

A genuine fix needs a warm-start/basin-selection strategy for the REML
LBFGS's OWN `phi0` (e.g. trying more than one structurally different
`Lambda0`/ML-warm-start scale and keeping the best REML basin among them —
or some other global/basin-hopping strategy over the *starting point*, not
a post-hoc polish of wherever the single ML warm start happens to land) —
because the evidence here shows the standard warm start's basin is provably
suboptimal while a different, better basin is directly reachable from a
different starting point.

## Files

- Test (kept, `@test_broken`): `test/test_575_q4_optimum.jl`
- Diagnosis: `575-mechanism.md (this directory)` (pre-existing, read first)
- Diagnostic scripts: `mechanism_575.jl` (session scratch, not retained),
  `warmstart_575.jl` (this directory)
- Reverted-attempt backup (not shipped):
  session scratch (not retained; the attempts are fully described above)
