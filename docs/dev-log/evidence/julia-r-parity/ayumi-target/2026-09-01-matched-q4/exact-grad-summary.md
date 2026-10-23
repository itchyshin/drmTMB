# #575 — exact gradient of the q=4 REML objective: FIXED

Branch `feat/575-exact-reml-gradient` (pushed). Worktree
`scratchpad/wt-exact-grad`.

| commit | gate |
|---|---|
| `11e13860` | G1 derivation note |
| `7a05a7ca` | G2 RED test |
| `12f758ec` | G2 GREEN implementation |
| `f5f8a600` | G3 certification + wiring + polish |
| `35201b00` | G4 target test flipped + no-regression |

## Alignment table

`docs/src/developer-notes/reml-q4-exact-gradient.md` (in the branch). §2.2 is
the 9-row term-by-term table; §1.1 the identity it rests on; §3 the degeneracy
found during implementation.

## G1 — the derivation

The implemented REML objective (`reml_ll_and_mode`, `src/reml_q4.jl`) collapses
to a single Laplace form over the AUGMENTED state `z = (u, β)`:

```
L_REML(φ) = −J(ẑ;φ) − ½ logdet 𝓗 + ½ logdet P ,   𝓗 = [[A,B],[B',D]]
A = H_uu,  B = H_uβ,  D = H_ββ,  logdet 𝓗 = logdet A + logdet S
```

because `H_uβ` and `H_ββ` are built from the same per-leaf 4×4 `leaf_hess` as
`H_uu`: the leaf's whole contribution is `R_iᵀ Hb R_i` for the lift
`R_i = [E_i | F_i]`. This is structurally identical to the ML objective in
`fit_q4_sparse_tmb.jl`, so its exact O(p) implicit-function gradient transfers
term-by-term with the leaf selected-inverse block replaced by

```
Ω_i = Vsel[leaf block] + G_i S⁻¹ G_iᵀ ,   G_i = C[leaf block,:] − F_i
```

`𝓗` is never formed or factorised: everything comes from the existing CHOLMOD
factor of `A`, its Takahashi selected inverse, and the small dense `S`.
Complexity O(p·n_β²).

## G2 — exact gradient (test-first)

`test/test_575_exact_reml_gradient.jl`. Exact vs a step-scanned central
difference (steps 1e-3 … 1e-5, most stable Richardson pair) on
`biv-q4-phylo-reml`, at three φ points, with `‖∇_z J(ẑ)‖ < 1e-8` asserted:

```
┌ Info: exact-vs-FD REML gradient
│   point = "ML-scale start"
│   max_abs_err = 2.8230790594108157e-8
└   rel = 2.413456623609924e-9
┌ Info: exact-vs-FD REML gradient
│   point = "DRM.jl optimum"
│   max_abs_err = 6.13858829878744e-8
└   rel = 6.13858829878744e-8
┌ Info: exact-vs-FD REML gradient
│   point = "TMB fitted point"
│   max_abs_err = 3.175936257471951e-8
└   rel = 3.175936257471951e-8
Test Summary:                                                         | Pass  Total   Time
issue #575: exact q4 REML gradient matches a tight central difference |   12     12  48.2s
```

New public-in-module entry points in `src/reml_q4.jl`:
`reml_nll_exact`, `reml_nll_and_exact_grad`, plus `_reml_joint_newton`
(joint (u,β) Newton on the bordered solve, `‖∇_z J‖ → ~5e-13`).

### Defect found by the RED test and fixed

`prior_precision(Q, Λ⁻¹)` calls `sparse(Λinv)`, which **drops zeros**. At an
exactly diagonal Λ — including `fit_q4_reml`'s own default warm start
`Λ0 = 0.3I(4)` — the cross-axis entries of `H_uu` at non-leaf nodes are
STRUCTURALLY absent, so the Takahashi selected inverse cannot supply entries the
logdet-H trace needs. Two lc gradient components came out wrong by **0.037** and
**13.70**; with a 1e-6 off-diagonal added, every component agreed to **6.7e-8**.
`_reml_prior_precision` stores all 16 entries of the 4×4 axis block (numerically
identical matrix, larger pattern).

**`marginal_and_exact_grad` (`fit_q4_sparse_tmb.jl:374–384`) builds its `Gst`
from the same construction and shares this degeneracy on the ML path.** Left
alone (out of scope for #575) and recorded in the note §3. The ML fit also
starts at `Λ0 = 0.3I`, so its first exact gradient is taken at the degenerate
point — worth a follow-up.

## G3 — certification + wiring

`fit_q4_reml`'s `fg!` now returns `reml_nll_and_exact_grad`'s value and gradient
at a joint-Newton-certified mode, replacing the central FD (`h_inner = 5e-4`,
mode alternation re-run per perturbation). Also:

- inner-convergence flag (#526) is now `‖∇_z J‖ < 1e-6` at the returned point,
  measured directly, instead of the alternation's relative-β proxy;
- the final evaluation goes through the same exact path, so objective, mode and
  `g_residual` describe one point;
- exact-gradient polish at 10× tighter `g_tol`, adopted only if converged, no
  worse in objective and strictly better in `g_residual`, with `u_cache` /
  `beta_cache` restored on rejection (the cache-corruption trap documented in
  `p12a-summary.md`).

### Final numbers (drm() engine inputs, defaults g_tol=1e-3, iterations=300)

| route | reml_loglik | converged | g_residual |
|---|---|---|---|
| cold start (public route) | **−219.614005** | true | 9.47e-5 |
| warm start at φ_TMB | **−219.614006** | true | 8.93e-5 |
| baseline (FD gradient, pre-slice) | −219.630231 | true | 7.54e-4 |
| drmTMB reference (`expected.toml`) | −219.613986 | — | — |
| `floor_ll` in the target test | −219.6206 | — | — |

Both routes land on the SAME point, 2e-5 from drmTMB's optimum. **The reported
basin-dependence was an artefact of the FD/mode noise, not a feature of the
surface**: the earlier "better basin at −219.6034" was a value read off an
under-converged inner mode, and the "suboptimal basin at −219.6302" was where a
noise-floor gradient certified.

Speed: the exact path costs one mode solve per evaluation instead of `2·nph + 1`
(nph = 11). The whole `fit_q4_reml` call runs in ~0.5 s once compiled (the 25 s
first-call figure in the raw logs is JIT).

## G4 — no-regression + target

`test/test_575_q4_optimum.jl` brought over from `fix/575-q4-optimum`;
`@test_broken` flipped to `@test`; **passes**.

```
Test Summary:                               | Pass  Total   Time
issue #575: q4 REML reaches its own optimum |    1      1  31.9s
Test Summary:                                                            | Pass  Total  Time
q4 phylo REML: public drm() converges through public kwargs alone (#484) |    3      3  0.6s
Test Summary:                                                            | Pass  Total  Time
q4 phylo REML: engine-level g_residual < g_tol, not just the flag (#484) |    3      3  0.7s
Test Summary:                                                         | Pass  Total   Time
issue #575: exact q4 REML gradient matches a tight central difference |   12     12  17.5s
Test Summary:                                | Pass  Total   Time
biv_q4_phylo_reml same-target fixture (#433) |   33     33  31.8s
Test Summary:                                              | Pass  Total  Time
REML q4: restricted correction reaches all four axes (#18) |    9      9  5.7s
```

Wider sweep over every other test touching the q4 / REML surface, all green:

```
niterations — iterative fitters report a real count                        20/20
q2 REML (test_reml_q2_structured.jl, 6 testsets)                           34/34
bivariate Student-t                                                        17/17
bivariate lognormal                                                        46/46
Bivariate q=4 relmat / animal / spatial / validation / gradient / #509     35/35
Bivariate q=4 phylo front end (4 testsets)                                 47/47
Missing data — listwise deletion path (#49)                                30/30
```

`fit_q4_reml` has exactly one caller in `src/` (`gaussian_bivariate.jl`), so the
affected surface is the q4 REML route, which the above covers.

### Behaviour note (flagged, not covered by any test)

`_reml_border_blocks` passes `prob.obs1/obs2` to `leaf_hess`; the inline build it
replaced did not. Identical for fully-observed data; for missing responses it
makes the Schur complement consistent with `H_uu`, which has always honoured the
masks. **No test covers q4 REML with missing responses**, so this is an
unverified consistency change, not a verified fix.

## Verdict: FIXED
