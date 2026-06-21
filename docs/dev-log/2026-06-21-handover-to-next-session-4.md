# Handover to the next Claude session (session 4 → 5)

**Date:** 2026-06-21 · **From:** Ada (autonomous, owner-directed, ultracode on) ·
**Mode:** push-LIVE, evidence-first, one defended slice at a time.

Read this top-to-bottom before touching anything. It is self-contained; the prior
handover (`2026-06-20-handover-to-next-session-3.md`) covers the Stage A/B Julia
bridge lineage and is still accurate for that part.

---

## 0. Who you are and how to operate

- You are **Ada**: decompose, route to the team (Gauss/Curie/Rose/Fisher/Noether/
  Florence…), enforce after-task + claim-boundary discipline. The owner is
  **Shinichi Nakagawa** (itchyshin@gmail.com).
- **Mission:** finish drmTMB (R) + its DRM.jl (Julia) twin + the R↔Julia bridge,
  one *defended evidence slice* at a time. Correctness over cost (ultracode on).
- **Owner's standing directives (still in force):**
  - **"We cannot hand over to Codex — keep pushing HERE."** Do the work in this
    Claude session; do not punt landable slices to Codex. (Codex still owns the
    heaviest live R/TMB toolchain runs if ever needed, but the owner wants Claude
    to finish what it can finish locally.)
  - **"Close the issues, open the issues."** Actively manage GitHub issues — close
    what is verifiably done (with evidence), keep-open with notes otherwise.
  - **Ultracode:** prefer Workflow orchestration for substantive multi-front work;
    but author single coherent deliverables (handover, one focused merge) solo.
- **Every promotion is verified** before it ships: Rose (claim-boundary) + Fisher
  (inference) at minimum, Curie/Noether/Florence as fits. Cite ASSERTED tolerances,
  not measured-as-guarantee. **Parity ≠ coverage.** Keep the three lanes separate.

---

## 1. Workspaces, branches, environment (HAZARDS)

**Work in the 540b worktrees, NOT the owner's main checkout.**

- drmTMB: `/Users/z3437171/.codex/worktrees/540b/drmTMB`
  branch `shannon/overnight-audit-gaps-20260619`, HEAD **`ea3db393`**, clean.
- DRM.jl: `/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main`
  branch `shannon/overnight-audit-verify-20260619`, HEAD **`0865c42`**, clean.
- **cwd hazard:** the Bash tool resets cwd to
  `/Users/z3437171/Dropbox/Github Local/drmTMB` (the owner's MAIN checkout, which
  has unrelated uncommitted changes) between calls. ALWAYS `cd` into the 540b
  worktree at the start of every Bash command, and use absolute paths.
- `main` exists in both repos but **lags** — most live work is on the `shannon/*`
  branches, which are the integration branches. Closing an issue as "done" when
  the capability is on the shannon branch is the team's norm; say so in the comment.
- Pushes are **LIVE and owner-authorized** (push to the shannon branches freely).

**Environment (verified working this session):**
- Julia 1.10.0 at `/Users/z3437171/.juliaup/bin`. Run DRM.jl tests with:
  `cd /Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main && JULIA_HOME=/Users/z3437171/.juliaup/bin /Users/z3437171/.juliaup/bin/julia --project=. -e 'include("test/<file>.jl")'`
- **Aqua gap:** `test/runtests.jl` line 31 `include("test_aqua.jl")` ABORTS the
  full suite locally — `Aqua` is not in the local test env. So you CANNOT use the
  full `runtests.jl` as a gate locally; run the **specific** test files via
  `include()` instead. Some files need `using Test, DRM, Random, LinearAlgebra,
  Statistics, SparseArrays` preloaded (they assume `runtests.jl` did it).
- R 4.5.2 at `/usr/local/bin/Rscript` works locally, incl. `pkgload::load_all(".")`
  on drmTMB (TMB compiles fine). `timeout` is NOT available (macOS) — don't use it.
- The R↔Julia bridge harness round-trip is ~3 min (JuliaCall first-use compile);
  set `options(drmTMB.DRM.jl.path = "/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main")`
  and `Sys.setenv(JULIA_HOME = "/Users/z3437171/.juliaup/bin")`, callr-isolated.

---

## 2. The doctrine to preserve (do not violate)

- **Three lanes, separately gated:** native R/TMB · direct DRM.jl · Julia-via-R
  bridge. Never let one lane's evidence stand in for another. Bridge parity (engine
  == engine) is NOT interval coverage.
- **Claims discipline:** `claim_status` in the capability registry means: `covered`
  = point + logLik + coefficient + Wald-endpoint parity (engine vs engine), NOT
  coverage. Do not promote a cell without banked per-cell parity evidence + Rose +
  Fisher sign-off. No release/CRAN claims. No `engine_control` user surface.
- **Capability registry is single-source:** the R function
  `drm_julia_capability_comparison()` in `R/julia-bridge.R` is the source of truth.
  Regenerate BOTH TSVs from it: `Rscript tools/write-julia-capability-comparison.R`.
  Gate test `tests/testthat/test-julia-gate-vs-engine.R` asserts artifact==registry;
  validator `tools/validate-mission-control.py` reads the dashboard TSV.
- **Warm-start lives only in the direct DRM.jl lane**, opt-in, default cold. Never
  let warm-start leak into the native TMB lane or the bridge.
- **Reuse of gllvmTMB/Julia code** requires `inst/COPYRIGHTS` provenance + tests.

---

## 3. What landed this session (session 4)

**Capability shipped (DRM.jl, pushed):**
1. **Warm-start parametric bootstrap — fixed-effect Gaussian location-scale**
   (design 179 Stage B). Opt-in `warmstart=true` on `bootstrap_result`/`_ci`/
   `_summary` (default false = cold, unchanged). `_fit_fixed_gaussian` gained a
   `start` kwarg; `_gaussian_warm_refit` (src/inference.jl) reuses θ̂ as the LBFGS
   start, cold fallback on non-finite/non-converged. Parity gate
   `test/test_bootstrap_warmstart.jl` 58/58 (asserted 1e-7 on SE/CI). Commit
   `eff22d9`. Reviewed by Fisher + Rose.
2. **VA/ELBO marginal through `drm(..., method = :VA)`** for Poisson/Binomial/NB2/
   Gamma/Beta with a single `(1|g)` (#136 front-end). Routes `(1|g)` to
   `_fit_<fam>_ranef_va`; every other model errors via `_va_reject` (no silent
   Laplace downgrade). Re-integrated from the 133-commit-stale `shannon/va-frontend`
   (`e83b0b3`) by resolving 5 dispatch conflicts; the body routing merged correctly,
   only the signature/missing-response wrapper needed manual merge (forwards
   `method` through the observed-rows recursion). `test/test_va_frontend.jl` 55/55,
   zero regressions. Commit `b32488d` (+ check-log `0865c42`).

**Cleanup / consistency (drmTMB, pushed):**
3. **Capability-TSV drift reconciled** — the dashboard was 2 rows + 1 promotion
   ahead of the R registry + shipped extdata. Owner approved promoting the registry
   to the banked evidence: added `nonphylo_biv_rho12_predictor` (covered, Route B
   parity) and `phylo_coef_profile_bridge` (partial, Stage A/B), promoted
   `base_gaussian_location_scale` → covered (Route C parity); regenerated both TSVs
   from the registry. Gate test 113/113, validator green. Commit `ea3db393`.

**Issues closed (5)** — verified by local tests, evidence comments posted:
- DRM.jl **#188** (coevolution accessors + CIs), **#165** (exact implicit-logdet
  gradient), **#167** (non-Gaussian relmat/animal/spatial structured means), **#11**
  (REML q4 wiring), **#294** (binomial-bridge coordination — alignment complete).

**Issues kept open with notes:**
- DRM.jl **#291** — REML *speed/AI-REML* track; its acceptance gates (design note,
  hsquared scout, benchmark harness, correctness+inference gates) are genuinely
  unmet. The triage initially over-claimed it as done — it is NOT. Note posted.
- DRM.jl **#136** — VA front-end landed (above); the general VA marginal scaffold
  still has **3 `@test_broken`** in `test/test_variational.jl`. Kept open for that.
- DRM.jl **#164** — deferred with a **full turnkey landing plan banked in the issue
  comment** (see §5.1).

**Honest negative result (recorded, not shipped):**
- **Warm-start for the single `(1|g)` Gaussian random intercept** was attempted
  (added `start` to `_fit_ranef_gaussian`, extended `_gaussian_warm_refit`). The
  parity gate FAILED on the variance-component (`:resd`, log σ_b) row: β rows matched
  to 1e-10 but σ_b SE/CI diverged > 1e-6. Root cause: the population-level
  (RE-at-zero) `simulate` draws σ_b = 0 in every replicate, so the variance MLE sits
  on the boundary where warm/cold LBFGS terminate at different near-`-∞` points.
  **Reverted**; recorded in design 179 ("Attempted and reverted" bullet). Same
  conclusion as the LocScale q2 cell: RE warm-start needs an RE-conditional
  `simulate` first. **Do not re-attempt without fixing simulate.**

---

## 4. Issue tracker landscape (after this session)

Verified true status against code/check-logs this session (be skeptical of any
"done" claim — re-run the specific test before closing; one triage agent cited a
commit `d24406b` that was not even in-branch).

- **Already done / closed:** #188, #165, #167, #11, #294 (DRM.jl).
- **Landable here next (highest value):** #164 (see §5.1).
- **Genuinely deep / deferred:** #293 (q4 ML −Inf ladder — needs live-Julia
  instrumentation), #202 (non-Gaussian σ-phylo new kernels), #166 (beta-binomial
  phylo kernel), #13 (wire natgrad EM), #49 (FIML), #496 (GVA engine, design-only),
  #136 scaffold remainder.
- **Speed/quality tracks (open by design):** #291 (REML/AI-REML speed), #270
  (kernel/NNGP), #269 (Pagel's λ), #227 (scout backlog).
- **Epics / roadmap / coordination:** #186, #280, #147, #4, #5, #3, #33, #60, #61,
  #491 (the local-R work queue — read it), the roadmap issues.

---

## 5. Highest-value next work, ranked, with recipes

### 5.1 #164 — crossed (non-phylo) nonconstant-sigma (sigma~x) — THE next slice
Owner-gated "defer to a focused effort" — it is now THAT focused effort's turn.
**High value, but genuinely careful (likelihood code).** Full plan is banked in the
DRM.jl #164 comment; summary:
- The complete impl exists on branch `shannon/issue-164-nonconst-sigma` (`f9edc0c`,
  2026-06-11): 599 ins / 220 del across 11 files, FD gates ≤1e-6 on the branch
  (NB2 crossed 1.3e-8, Gamma crossed 3.6e-7, Beta crossed 3.3e-7). It is **487
  commits stale** vs HEAD → **REPLAY, do not merge** (a cherry-pick will conflict
  hard, like the VA front-end did — and this is core `sparse_laplace_glmm.jl`).
- Recipe: remove the constant-sigma guards at `src/sparse_laplace_glmm.jl:2735/
  2756/2779` → thread `Xsigma` through `_phylo_mean_laplace_nuisance_fg` /
  `_fit_crossed_mean_laplace_nuisance`; rename `theta_sigma0 → beta_sigma0` → add
  per-obs dispersion helpers (`_nb2_size_vec`, `_gamma_shape_vec`,
  `_beta_precision_vec`, `_sigma_start` scalar/vector dispatch) → update theta layout
  `[beta_mu; scalar_sigma; logsigma] → [beta_mu; beta_sigma(psigma); logsigma]` →
  port the test extensions (`test_nonconst_sigma_re.jl` +132, the FD gates in
  `test_nongaussian_phylo_grad_gate.jl` +230; flip `@test_throws` → affirmative).
- Verify: the specific test files (NOT full runtests — Aqua gap) + **constant-sigma
  byte-identity** (the constant-σ path must be unchanged) + FD gates ≤1e-6. Back out
  if it gets messy; this is likelihood code — do not ship a rushed result.

### 5.2 Warm-start for EXPENSIVE refit cells (the marquee speed win) — BLOCKED on simulate
The fixed-effect cell is the only clean warm cell. Investigation (this session)
found: `_fit_ranef_gaussian` (1|g) and `_fit_structured_gaussian` (dense phylo) have
clean single-LBFGS entries that *could* take a `start` kwarg, BUT the bootstrap is
degenerate because `simulate(fit)` draws population-level (RE at zero) → variance
component pinned at the boundary → warm/cold parity breaks (proven this session for
(1|g)). **Prerequisite:** an RE-conditional `simulate` (draw the group effects, not
just residuals). Then the (1|g) → dense-phylo → (eventually) bridge passthrough
become tractable. Sparse-EM (`_fit_structured_gaussian_em`) has no warm semantics —
leave it. Design 179 has the full map.

### 5.3 Bridge Stage A/B remainder (design 179)
- Multi-coefficient batching (the SD/coef multi-row join — flagged collision risk).
- Boundary-robust **sigma** coefficient profiles (DRM.jl `parm=:sigma` runs to the
  log-σ→−∞ boundary; a DRM.jl-side fix). Currently mu-coef only.

### 5.4 #136 VA scaffold remainder
The front-end ships; the general VA marginal scaffold has 3 `@test_broken` in
`test/test_variational.jl`. Resolving those (or formally scoping them out) closes #136.

---

## 6. Constraints & live blockers (READ — these will bite you)

- **GitHub issue writes are gated by an auto-permission classifier.** This session it
  DENIED `gh issue close` until the owner explicitly named the issues, then allowed
  the named ones. Pattern: get the owner's explicit per-issue (or blanket) approval
  BEFORE batch-closing; if denied, STOP and surface it (do not work around it).
  Closing on a sub-agent's say-so is exactly what the classifier (rightly) blocks —
  re-verify with a local test yourself first.
- **Owner-parked:** the drmTMB#499 / DRM.jl#294-era coordination comments were
  historically parked; #294 is now closed, but treat any *new* outward GitHub post as
  needing a nod.
- **No release / CRAN / coverage / power claims.** No `engine_control`. REML +
  location-only stay in DRM.jl `src/experimental/` off the bridge surface.
- **Reverting Codex/human work** is not allowed unless explicitly asked.

---

## 7. Verification cookbook (commands that work locally)

```bash
# DRM.jl single test file (Aqua gap means NO full runtests locally):
cd /Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main && \
JULIA_HOME=/Users/z3437171/.juliaup/bin /Users/z3437171/.juliaup/bin/julia --project=. \
  -e 'using Test, DRM, Random, LinearAlgebra, Statistics, SparseArrays; include("test/<file>.jl")'

# Regenerate the capability TSVs from the R registry (single source of truth):
cd /Users/z3437171/.codex/worktrees/540b/drmTMB && Rscript tools/write-julia-capability-comparison.R

# drmTMB gate test + mission-control validator:
cd /Users/z3437171/.codex/worktrees/540b/drmTMB && \
  Rscript -e 'pkgload::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R")' && \
  python3 tools/validate-mission-control.py
```

Commit-message footer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
After-task notes go in `docs/dev-log/after-task/`; check-log entries in both repos'
`docs/dev-log/check-log.md`.

---

## 8. Key design docs

- `docs/design/179-julia-inprocess-profile-bootstrap.md` — warm-start + bridge Stage
  A/B; the authoritative state for §5.2/§5.3.
- `docs/design/168-r-julia-finish-capability-matrix.md` — the capability matrix.
- `docs/design/157-capability-completion-worklist.md` + `46-pre-simulation-readiness-
  matrix.md` — the dependency-ordered remaining-capability map (start here for scope).
- DRM.jl #164 comment — the turnkey crossed-sigma plan.

---

## 9. One-line status

Both repos clean and pushed (DRM.jl `0865c42`, drmTMB `ea3db393`). Five issues
closed, two real capabilities shipped (VA front-end, fixed-effect warm-start
bootstrap), one consistency drift fixed, one dead-end (warm (1|g)) documented. The
single highest-value next slice is **#164 crossed nonconstant-sigma** (turnkey plan
banked); the marquee warm-start expansion is blocked on an RE-conditional `simulate`.
