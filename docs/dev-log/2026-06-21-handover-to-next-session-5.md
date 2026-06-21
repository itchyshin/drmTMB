# Handover to the next Claude session (session 5 → 6)

**Date:** 2026-06-21 · **From:** Ada (autonomous, owner-directed, ultracode on) ·
**Mode:** push-LIVE, evidence-first, one defended slice at a time.

Read top-to-bottom before touching anything. The prior handover
(`2026-06-21-handover-to-next-session-4.md`) covers the pre-session-5 lineage and
is still accurate for that part.

---

## 0. Who you are / how to operate

- You are **Ada**: decompose, route to the team (Gauss/Curie/Rose/Fisher/Noether/
  Florence…), enforce after-task + claim-boundary discipline. Owner: **Shinichi
  Nakagawa**. Correctness over cost (ultracode on). Finish HERE; don't punt landable
  slices to Codex.
- **Every promotion is Rose (claim-boundary) + Fisher (inference) verified** before
  it ships; re-verify with a local test yourself (don't trust sub-agent verdicts).
  **Parity ≠ coverage.** Three lanes (native R/TMB · direct DRM.jl · Julia-via-R
  bridge) gated separately.

---

## 1. Workspaces, branches, environment (HAZARDS)

- drmTMB: `/Users/z3437171/.codex/worktrees/540b/drmTMB`
  branch `shannon/overnight-audit-gaps-20260619`, HEAD **`cffa7002`**, clean, pushed.
- DRM.jl: `/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main`
  branch `shannon/overnight-audit-verify-20260619`, HEAD **`eef36da`**, clean, pushed.
- **cwd hazard:** the Bash tool resets cwd to the owner's MAIN checkout between
  calls. Always `cd` into the 540b worktree + absolute paths.
- Env: Julia 1.10.0 at `/Users/z3437171/.juliaup/bin`; R 4.5.2. `timeout` NOT
  available on macOS.
- **Aqua gap:** `test/runtests.jl` aborts locally (Aqua not in the test env). Run
  DRM.jl tests via specific files: `cd <DRM.jl> && JULIA_HOME=/Users/z3437171/.juliaup/bin
  /Users/z3437171/.juliaup/bin/julia --project=. -e 'using Test, DRM, Random,
  LinearAlgebra, Statistics, SparseArrays; include("test/<file>.jl")'`.
- **Bridge (Julia-via-R) live runs work locally** and are the slow path (~3 min /
  round-trip, JuliaCall first-use compile, callr-isolated). The test skip guards
  read **`DRM_JL_PHYLO_PATH`** (the tmb-parity + missing tests) and **`DRM_JL_PATH`**
  (the q4 phylo tests) — set the right one + `JULIA_HOME`. The q4 tests also carry
  `skip_on_cran()`, so add **`NOT_CRAN=true`** when running them via plain Rscript.

---

## 2. What landed this session (session 5)

Four slices, all Rose+Fisher verified, committed + pushed:

1. **#164 crossed (non-phylo) `sigma ~ x`** (NB2/Gamma/Beta crossed sparse-Laplace),
   DRM.jl `eef36da`. Built a new `_crossed_mean_laplace_hetero_fg` +
   `_fit_crossed_mean_laplace_hetero` that MIRROR the in-tree phylo `_hetero`
   architecture (reuse `Val(:*_hetero)` kernels) — deliberately NOT a replay of the
   487-commit-stale `f9edc0c` (which mutates the scalar `:*_fixed` kernels and would
   collide). FD ≤1e-6 (NB2/Gamma) / ≤1e-4 (Beta); 1-col-Xσ reduction invariant
   (1e-12/1e-10); recovery σ-slope bands exclude zero; constant-σ regression 46/46.
   **#164 issue CLOSE is still pending owner approval** (classifier-gated — see §4).
2. **gaussian_response_mask → covered** (bridge), drmTMB `863da255`. The mask already
   worked; it was `partial` only because the engine-vs-engine parity test was never
   written. Added a masked-data Route-C parity block to `test-julia-tmb-parity.R`
   (|dlogLik| 4.3e-10, max|dcoef| 1.4e-6, max|dWald| 1.4e-6, nobs 112/112), promoted
   the registry, reconciled the design-168/status.json Missing-values cell.
3. **plain_binomial_nonphylo** kept gated (owner decision), drmTMB `0bc1e6f8`.
   #569 (native binomial) HAS landed (PR #585, verified via gh); refreshed the stale
   "wait for #569" registry note — the bridge stays intentionally gated by design
   (no Julia speed edge for non-phylo GLMs, cf. base_nonphylo_count). No promotion.
4. **biv_q4_phylo_reml → defended partial**, drmTMB `cffa7002`. `covered`
   (engine-vs-engine) is STRUCTURALLY IMPOSSIBLE: native TMB rejects q4 phylo REML.
   Banked a live bridge q4 REML round-trip test (faithful forwarding + Wald-
   unavailable) + a direct-DRM.jl recovery pilot. **Owner's key reframe:** the
   DRM.jl #18 "REML ≥ ML" inequality is brittle (it fails when ML overshoots a
   weakly-identified scale axis); "closer to truth" is the right diagnostic. The
   40-rep pilot (`docs/dev-log/simulation-artifacts/2026-06-21-q4-reml-recovery-pilot/`)
   shows REML less biased / closer to truth on all 4 among-axis SDs (REML MAE 0.127
   vs ML 0.133). Cell stays partial.

Mission-control bridge matrix: **3/11 covered** (base_gaussian, nonphylo_biv_rho12,
gaussian_response_mask).

---

## 3. THE next slice — phylo_coef_profile_bridge μ multi-coef batching (do-now)

Owner-chosen next slice; **scoped this session, zero rediscovery needed.** It is an
L-effort, multi-repo, DELICATE bridge-inference change — do NOT rush the join logic.
It lands a STRONGER PARTIAL (not covered — see the blocked prereqs at the end).

**Current state:** the bridge coefficient-profile path returns ONE mu coef per call.
DRM.jl `src/bridge.jl` profile branch (~L74–104) takes a single
`opts[:profile_param]` + `opts[:profile_coef]` and returns one flattened row. The R
router (`R/julia-bridge.R` ~L1797–1837) passes only `targets$...[[1L]]` (the first
coef) and routes multi-vs-row off `result$multi`. The MULTI-row infra already
EXISTS but is **bivariate-only**: `_bridge_inference_flatten_multi_profile`
(bridge.jl:558) and `drm_julia_inference_confint_multi` (julia-bridge.R:2091), whose
join is by **dpar** ("mu1"→"sd_mu1").

**The gap = 3 coordinated changes + a multi-seed test:**
1. **DRM.jl `src/bridge.jl`** (profile branch): add a multi-coef path. When the R
   side requests the whole mu block (e.g. a new `opts[:profile_all_coefs]=true`, or
   `profile_coef` absent while `profile_param` is set), call
   `profile_result(fit; parm = :mu)` once and return ALL coef rows via the existing
   `_bridge_inference_flatten_multi_profile`. Keep the single-row path for back-compat.
2. **drmTMB `R/julia-bridge.R`** router (~L1797–1837): when `drm_julia_profile_targets`
   yields MULTIPLE `fixef:mu:<cn>` targets, make ONE bridge call for the block
   (signal "all coefs"), get `result$multi == TRUE`, route to `confint_multi`.
3. **drmTMB `confint_multi`** (~L2091): the current join is dpar-based and is WRONG
   for multi-coef (all mu coefs share `dpar = "mu"`). Add a **coef-NAME** join
   (match `target$term` to `result$coef`). Transform per mu coef is identity
   (`linear_predictor`, link scale) — NOT the exp/SD-scale the bivariate SD rows use.
4. **Test** (`tests/testthat/test-julia-inference.R`, extend `drm_julia_coef_profile_parity`
   / the Stage A test ~L349): request ALL mu coefs in ONE bridge call (assert a
   single round-trip returns both (Intercept)+x rows), across multiple seeds and
   n_tip ∈ {40,80}; assert engine='julia' profile endpoints match native
   `confint(method='profile')` to ≤1e-4 on every mu coef. Bank under
   `docs/dev-log/simulation-artifacts/` and cite in the `phylo_coef_profile_bridge`
   claim_boundary (upgrades "one fixture" → multi-seed parity). Stays PARTIAL.

Verify constant byte-identity of the existing single-coef path (don't regress Stage
A). Touches BOTH repos → two commits (DRM.jl bridge + drmTMB R/test). Rose+Fisher.

---

## 4. Pending / blocked

- **#164 issue CLOSE (DRM.jl #164):** owner-approved verbally, but the auto-permission
  classifier DENIED `gh issue close` (it needs an explicit per-issue "yes" in the
  prompt, which a multi-select answer didn't register as). The evidence comment is
  drafted at `/tmp/drm164-close.md`. Re-attempt only after the owner explicitly names
  the issue to close; if denied again, STOP and surface it (do NOT work around it).
- **phylo_coef `covered` is blocked** on two DRM.jl-lane prereqs (design 179): (a)
  boundary-robust `parm=:sigma` profiling (DRM.jl `parm=:sigma` diverges toward the
  log-σ→−∞ boundary, ~10 disagreement vs native); (b) warm-start THROUGH the bridge
  (the bridge bootstraps a Gaussian PHYLO fit whose fitter doesn't accept a packed
  start; needs an RE-conditional `simulate` first — same lesson as the reverted
  (1|g) warm cell).

## 5. Other remaining work (ranked-ish)

- **relmat/animal/spatial `sigma ~ x`** — CHEAP follow-on to #164 (out of #164's
  phylo/crossed title scope). The phylo hetero fg is Q-generic, so wire a
  `_general_cov_setup` Q through a hetero general-cov fitter, remove the relmat
  guards (`sparse_laplace_glmm.jl` ~1158/1254/1335), and flip the relmat throw-tests
  (`test_relmat_counts_{nb2,beta}.jl`). Likelihood code — gate on byte-identity + FD.
- **single non-phylo `(1|g)` non-Gaussian RE with `sigma ~ x`** — confirm whether it's
  already covered or a separate gap (the single-RE GHQ/Laplace path).
- **biv_q4 next_action** — a full (≥200-rep) recovery calibration; profile/bootstrap
  among-axis SD-interval CIs through the bridge; bridge==direct numeric faithfulness.
- **#136 VA scaffold** — 3 `@test_broken` remain in `test/test_variational.jl`.

## 6. Constraints (READ)

- GitHub issue writes are classifier-gated → explicit per-issue owner approval; if
  denied, STOP and surface. No release / CRAN / coverage / power claims. No
  `engine_control`. Don't revert Codex/human work. Recovery sims are point-estimate
  evidence (the project banks them) but label PILOT vs calibration honestly.

## 7. Verification cookbook

```bash
# DRM.jl single test file (Aqua gap → no full runtests locally):
cd /Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main && \
JULIA_HOME=/Users/z3437171/.juliaup/bin /Users/z3437171/.juliaup/bin/julia --project=. \
  -e 'using Test, DRM, Random, LinearAlgebra, Statistics, SparseArrays; include("test/<file>.jl")'

# drmTMB capability gate + validator (regenerate TSVs from the R registry first):
cd /Users/z3437171/.codex/worktrees/540b/drmTMB && Rscript tools/write-julia-capability-comparison.R && \
  Rscript -e 'pkgload::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R")' && \
  python3 tools/validate-mission-control.py

# drmTMB live bridge test (set the RIGHT skip-guard env; q4 tests need NOT_CRAN=true):
cd /Users/z3437171/.codex/worktrees/540b/drmTMB && NOT_CRAN=true \
  DRM_JL_PATH=/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main \
  DRM_JL_PHYLO_PATH=/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main \
  JULIA_HOME=/Users/z3437171/.juliaup/bin \
  Rscript -e 'pkgload::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-julia-<file>.R")'
```

Commit footer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`. After-task
notes in `docs/dev-log/after-task/`; check-log rows in both repos' `docs/dev-log/check-log.md`.

## 8. One-line status

Four slices landed + pushed (#164 crossed σ, gaussian_response_mask→covered,
binomial kept-gated, biv_q4 defended-partial). Bridge matrix 3/11 covered. Next:
phylo_coef μ multi-coef batching (scoped in §3). Pending owner nod: #164 close.
