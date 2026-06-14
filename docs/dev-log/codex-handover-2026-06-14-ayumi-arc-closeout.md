# Codex handover — 2026-06-14 — Ayumi σ-phylo arc close-out

Claude session handing the baton to Codex in **drmTMB**. Rehydrate evidence-first:
`git log --oneline origin/main`, the linked issues/PRs, and this doc. Live ledger =
GitHub Issues. **No CRAN** (user-confirmed, repeatedly). Speak as the team (AGENTS.md).

## Rehydration anchors
- **drmTMB** `main` tip: `27cbdd50` (#543). Merged today: #541, #542, #543.
- **DRM.jl** `main` has the engine fix: #289 (REML all-axes) + #290 (docstring).
- Package topology (don't confuse): drmTMB(R) ↔ **DRM.jl**(Julia engine) · gllvmTMB(R) ↔ **GLLVM.jl**(Julia engine).

## What shipped this session (all merged + verified)
1. **DRM.jl #289** — REML scale-axis fix. `reml_q4.jl` restricted correction was
   **mean-only** (β_μ); now profiles **all four** among-axis axes (β_μ **and** β_σ),
   so the two scale axes are corrected (previously wrong-signed under REML). Gate:
   `test/test_reml_q4_allaxes.jl` asserts `diag(Σ_a)_REML ≥ diag(Σ_a)_ML` on every
   axis (σ1 moved 0.27→0.40). CI `test (1.10)` green.
2. **DRM.jl #290** — dropped the stale `src/DRM.jl` "REML not yet wired" module note.
3. **drmTMB #542** — R bridge: `reml_supported` now admits `biv_gaussian`; `confint()`
   biv parm labels fixed (from `structured_sd_scales` names); article clarifications
   (decouple `derived_interval_unavailable` from `pdHess=FALSE`; profile is
   *recommended* not the `confint` default; identified-vs-collapsed-axis table; a
   REML-all-axes note).
4. **drmTMB #543** — fixed a **pre-existing** biv-confint CI red. `main` had been red on
   **all three OSes since #541**: `test-julia-biv-confint.R:151/164/166` failed because
   the fake-result fixture fed **log-scale** bounds while the reader takes DRM.jl's
   **SD-scale** bounds directly, and the synthetic fixture had no `bp$formula` so the
   label fell back to `"group"`. Fixture → SD-scale; label ← `structured_sd_scales`
   names. Verified locally `failed=0` via `devtools::load_all` + `test_file`.
5. **Ayumi reply POSTED** → `Ayumi-495/LS_ecogeographical-rules#2` (issue comment).
   Source text: `DRM.jl/report/finish-audit/ayumi-reply-FINAL.md`. It answers her 3
   points (interaction crash / wall-time / missing-response) + the native-REML
   follow-up, and points to the julia-engine article (rebuilds via CI ~30 min).
6. **Tracker hygiene** — status comments on DRM.jl#11, DRM.jl#186, drmTMB#499; new
   issue **drmTMB#544** (bridge-gate-drift audit + CI guard); scoped gllvmTMB#488.

## Top open threads for Codex (drmTMB-focused, in priority order)
1. **drmTMB#544 — bridge-gate-drift audit + a gate-vs-engine CI guard.** THE actionable
   one. The arc kept finding the R wrapper rejecting cases the DRM.jl engine already
   handled (REML gate, missing-response gate, family gate). Enumerate every
   `cli_abort`/reject in `R/julia-bridge.R`, check each vs DRM.jl's *current*
   capability, relax stale ones, and add a CI test asserting each deliberately-gated
   cell still errors (so the next capability can't silently lag). The sister has the
   identical class: **gllvmTMB#488** (verified real — `julia-bridge.R:169` blanket
   NA-reject though its TMB engine ships `is_y_observed`; `:188` gaussian-only
   covariate gate). Do the audit + guard on **both** bridges; cross-link.
2. **drmTMB#499 / #342 — NEWS reconciliation + a fresh `devtools::check()` on current
   main.** The 06-08 "capability freeze + as-cran OK" is stale (5 PRs merged after;
   #543 fixed a pre-existing red). This is **hygiene/NEWS only — NOT a CRAN submission.**
3. **Honest-scope wording (don't overclaim).** `miss_control(response="include")` on
   `engine="julia"` is a masked **observed-data** likelihood (keep-the-tree), **not**
   FIML/imputation of missing responses, which is still unimplemented. Small-p profile
   CI **width** calibration is irreducibly uncertain (the boundary call is the robust
   part). Tighten the missing-data article's blanket "FIML" sentence; mirror in
   gllvmTMB (shared Design-59 prose). See DRM.jl#49.
4. **drmTMB#531** — `corpair()` predictor-dependent **latent-RE** correlation needs a
   TMB C++ template change; the arc did residual `rho12` + the four among-axis SD CIs,
   NOT this. Untouched.
5. **drmTMB#5** — native-TMB **q8** endpoint stays `hold_diagnostic`; the arc only
   advanced the Julia-route q4 SD-CI story.
6. **drmTMB#3** — skew-normal: reopened twice after a stray auto-close; confirm it's
   intentionally open for the recovery-grid/comparator depth.

## Cross-package decisions PENDING the user (do NOT action without his yes)
- **DRM.jl#280** — per-column **mixed-family** dispatch (companion GLLVM.jl#98). User
  leans: genuinely useful for the lab's multi-trait ecological tables; bounded first
  slice (`families::Vector`).
- **DRM.jl#270** — adopt **GLLVM.jl#62's tested SPDE/Matérn-GMRF core** (sdmTMB-style)
  via a shared MIT package, + NNGP (net-new). Clarified for the user: SPDE already
  exists in **GLLVM.jl**, DRM.jl has **none**; #270 = *share, don't rebuild*. Spatial
  is low-urgency for the lab right now.

## Discipline (carry over from CLAUDE.md / AGENTS.md)
- **Local checks over CI**; Linux-only for routine; **no CRAN**.
- **License boundary:** drmTMB is **GPL(≥3)**; DRM.jl / GLLVM.jl are **MIT**. NEVER
  vendor drmTMB GPL source into the Julia engines. The #270 shared-SPDE package is
  MIT↔MIT (GLLVM.jl→DRM.jl) — license-clean.
- Definition of Done = impl + tests + docstrings + worked example + check-log +
  after-task + Rose (license/honesty) audit.

## Housekeeping
Merged scratch git worktrees from this session (safe to `git worktree remove` + prune):
`/tmp/drmtmb-reml-followup` (#542), `/tmp/drmtmb-fix-fixtures` (#543),
`/tmp/drmtmb-handover` (this), and DRM.jl-side `/tmp/drm-reml-followup` (#289),
`/tmp/drm-docstring` (#290). The earlier `/tmp/drmTMB-biv-confint` predates this session.
An orphaned Gmail draft to Ayumi was created then abandoned (we posted to GitHub instead) —
trash it manually; the Gmail tool had no delete.
