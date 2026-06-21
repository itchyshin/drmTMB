# Handover to the next Claude session (session 6 → 7)

Date: 2026-06-21 · From: Ada (autonomous, owner-directed; took over session 5→6) ·
Mode: push-LIVE, evidence-first, one defended slice at a time.
Read top-to-bottom before touching anything. Self-contained; the prior chain
(`docs/dev-log/2026-06-21-handover-to-next-session-{4,5}.md`) holds the deeper lineage.

## 0. Who you are / how to operate

- You are **Ada**: decompose, route to the team (Gauss/Curie/Rose/Fisher/Noether/…),
  enforce after-task + claim-boundary discipline. Owner: **Shinichi Nakagawa**.
  Correctness over cost. Finish HERE; don't punt landable slices to Codex.
- **Every promotion/landing is Rose (claim-boundary) + Fisher (inference) verified
  before it ships; re-verify locally yourself — do NOT trust sub-agent verdicts.**
  Both reviewers caught real issues THIS session (a test that could silently absorb a
  regression; recovery bands that included zero) — the gate works, use it.
- Three lanes (native R/TMB · direct DRM.jl · Julia-via-R bridge) gated separately.
- Tooling note: `Glob` and `TodoWrite` are NOT available here — use `find` via Bash,
  and the `Task*` MCP tools (load via ToolSearch `select:TaskCreate,TaskUpdate,TaskList`)
  for progress tracking.

## 1. Workspaces, branches, environment (HAZARDS)

- **drmTMB**: `/Users/z3437171/.codex/worktrees/540b/drmTMB` — branch
  `shannon/overnight-audit-gaps-20260619`, HEAD `549c633d`, clean, pushed.
- **DRM.jl**: `/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main` — branch
  `shannon/overnight-audit-verify-20260619`, HEAD `4e4d157`, clean, pushed.
- cwd resets to the owner's MAIN checkout between Bash calls → use absolute paths /
  `git -C` every time. `shannon/*` are the live branches; main lags.
- Env: Julia 1.10.0 at `/Users/z3437171/.juliaup/bin`; R 4.5.2. `timeout` NOT on macOS.
- **Aqua gap**: DRM.jl `test/runtests.jl` aborts locally → run specific files:
  `cd <DRM.jl> && JULIA_HOME=/Users/z3437171/.juliaup/bin /Users/z3437171/.juliaup/bin/julia --project=. -e 'using Test, DRM, Random, LinearAlgebra, Statistics, SparseArrays; include("test/<file>.jl")'`.
  Most DRM.jl test files are self-contained (own `using`) and run fine standalone.
- **Bridge test skip-guard env vars differ**: `DRM_JL_PHYLO_PATH` (tmb-parity + missing
  + inference) vs `DRM_JL_PATH` (q4 phylo). q4 tests also carry `skip_on_cran()` → add
  `NOT_CRAN=true`. Set BOTH path vars + `JULIA_HOME` to be safe. Bridge round-trip ≈ 3 min
  (JuliaCall first-use compile, callr-isolated).

## 2. Doctrine (don't violate)

- `covered` = point + logLik + coefficient + Wald-endpoint parity, engine-vs-engine —
  NOT interval coverage. No release/CRAN/coverage/power claims. No `engine_control`
  surface. Don't revert Codex/human work.
- **Bridge capability cells are about the BRIDGE (drmTMB↔DRM.jl), NOT the direct DRM.jl
  engine.** A DRM.jl-engine capability landing (e.g. this session's relmat `sigma~x`) is
  banked via the DRM.jl `check-log.d` + `after-task/`, NOT the drmTMB capability registry.
- Recovery sims are point-estimate evidence; label pilot vs calibration honestly. For a
  σ-axis recovery claim, the band MUST exclude zero (else a dead σ-axis passes — Fisher).

## 3. What landed this session (session 6) — 3 slices, all Rose+Fisher verified, pushed

1. **§4 phylo_coef μ multi-coef profile batching** (drmTMB `8544c4fb` + DRM.jl `f0920cd`).
   One `confint(parm = c("mu:(Intercept)","mu:x"), method = "profile")` profiles the whole
   mu block in ONE bridge round-trip and returns every coef row (joined by coef NAME, not
   dpar). Took **5 edits not 3**: the `call_inference` option-merge (silently dropped
   `profile_param` when `profile_coef` was NULL) and the target-count validator (rejected 2
   coef targets) were the non-obvious ones — both caught by the test failing, not by
   reading. Batched endpoints match native tmbprofile ≤ 2.43e-5; stays a **STRONGER
   PARTIAL** (`claim_status` still `partial`; sigma + warm-start prereqs remain). Artifact:
   `docs/dev-log/simulation-artifacts/2026-06-21-phylo-coef-profile-multi-batch/`. After-task:
   `docs/dev-log/after-task/2026-06-21-phylo-coef-profile-multi-batch.md`. Bridge matrix
   still **3/11 covered**. Fisher caught that the `good_fit` conflation could silently
   exclude a batch-join regression on a well-fit cell → assertions now gate on
   fit-agreement only; test grid widened to 4 seeds {42,7,13,101}.
2. **relmat/animal/spatial covariate dispersion `sigma ~ x`** (DRM.jl `4e4d157`). The last
   non-Gaussian `sigma ~ x` route (phylo + crossed landed earlier in #164). Extracted a
   Q-generic `_fit_general_mean_laplace_hetero` core from `_fit_phylo_mean_laplace_hetero`
   (phylo hetero now a thin tree→Q wrapper — **BYTE-IDENTICAL**, the #164 phylo+crossed gates
   all stay green), branched `_fit_{nb2,gamma,beta}_relmat_laplace` (constant→nuisance,
   covariate→hetero with the relmat-derived Q), dropped the 3 `sigma~1` guards. NB2/Gamma/Beta
   recovery 7/7 each with **σ-slope bands EXCLUDING zero** (recovered −0.28/−0.19/−0.30 —
   Fisher's fix; a constant-σ fit fails them), FD ≤ 1e-6 (margin 4.9e-8), 1-col-Xσ reduction
   EXACT (0.0/0.0). Direct DRM.jl lane (NOT a bridge cell). After-task: DRM.jl
   `docs/dev-log/after-task/2026-06-21-relmat-animal-spatial-covariate-sigma.md`.
3. **bridge gate wording fix** (drmTMB `549c633d`). Slice 2 made the DRM.jl ENGINE fit
   general-cov `sigma~x`, so the bridge strings saying "DRM.jl … requires `sigma~1`" became
   a layer misattribution (Rose). Reworded 3 `R/julia-bridge.R` strings to put the gate at
   the BRIDGE layer (engine fits `sigma~x`; bridge not yet widened); kept "requires
   `sigma~1`" in the guard so the gate `message_pattern` still matches; regenerated the gate
   + capability TSVs. No behaviour change.

## 4. THE next slice — pick from §5 by owner priority (no single forced do-now)

The session-5→6 handover nominated §4 as do-now; this session cleared §4 + the cheap relmat
follow-on it named + the wording cleanup. There is no single forced next slice. Cheapest
honest candidates:

- **Single non-phylo `(1 | g)` non-Gaussian RE with `sigma ~ x`** — confirm whether the
  single-RE GHQ/Laplace path already supports a covariate dispersion or it is a genuine gap
  (carried over from the crossed + relmat after-tasks). CHEAP scoping first: read the
  single-RE fitters (`_fit_<fam>_ranef_*` / the GHQ path) and grep for a `sigma ~ 1` guard;
  do likelihood work ONLY if a gap is confirmed. This is the last "is `sigma~x` covered on
  every non-Gaussian RE route?" question.
- **3-way `aux_from_hetero` DRY refactor** — the σ-axis hetero aux is now duplicated across
  the phylo, crossed, and relmat fitters (it is Q-independent). Factor
  `_<fam>_laplace_hetero_setup(y, Xμ, Xσ)` (mirroring the existing `_<fam>_laplace_setup`),
  used by all three call sites. Pure refactor; gate on the #164 phylo + crossed + relmat
  tests staying byte-identical. Low risk, removes drift hazard.

## 5. Other remaining work

- **biv_q4** next_action — full (≥200-rep) recovery calibration; profile/bootstrap
  among-axis SD CIs through the bridge; bridge==direct faithfulness.
- **phylo_coef `covered`** blocked on two DRM.jl-lane prereqs (design 179): (a)
  boundary-robust `parm=:sigma` profiling (diverges toward log-σ→−∞, ~10 disagreement); (b)
  warm-start THROUGH the bridge (needs an RE-conditional `simulate` first).
- **SE/vcov gate for the relmat hetero path** — `se` forwards but is not separately gated;
  the Hessian near the σ-boundary is ungated. Do NOT make any interval/coverage claim on
  the hetero path until this is gated.
- **Bridge widening to Beta + `sigma~x` general-cov** — the DRM.jl engine now supports it,
  but the bridge gate (`R/julia-bridge.R` ~L3096 family gate, ~L3137 `sigma~1` guard) does
  not route it. A real FEATURE (needs a bridge test), NOT a wording fix. Beta general-cov is
  not bridge-routed at all yet.
- **#136 VA scaffold** — 3 `@test_broken` in `test/test_variational.jl`.
- **Team hygiene (Rose)**: overview surfaces (model-map narrative, get-started bullets,
  bridge `claim_boundary` strings) lag the per-family de-staling by a slice. A grep gate for
  "constant `sigma`" / "require `sigma ~ 1`" / "sigma predictors stay gated" across
  `docs/src` + `R/julia-bridge.R` would stop the drift.

## 6. Constraints (READ — will bite)

- GitHub issue-CLOSE needs an EXPLICIT per-issue owner "yes" in the prompt. A multi-select
  answer does NOT register and the auto-permission classifier blocks it. If denied, STOP and
  surface — do not work around it.
- No release/CRAN/coverage/power claims. No `engine_control`. Don't revert Codex/human work.
- **Editing a DRM.jl registry** (the drmTMB Julia gate OR capability registry, both in
  `R/julia-bridge.R`) → regenerate BOTH artifacts: `tools/write-julia-gate-registry.R` (gate)
  AND `tools/write-julia-capability-comparison.R` (capability), else
  `test-julia-gate-vs-engine.R` fails on the artifact-vs-registry compare. The gate test ALSO
  checks each guard's `cli_abort` message against its `message_pattern` regex — if you reword
  a guard, keep the pattern matching (or update the pattern). (This bit me this session.)
- **σ convention** (non-Gaussian hetero): dispersion = `exp(-2·ησ)` (size/shape/precision),
  so `coef(:sigma) = -0.5 · log-dispersion`. Recovery tests assert
  `coef(:sigma)[2] ≈ -0.5·βσ_slope` with a band that EXCLUDES zero.

## 7. Verification cookbook

```
# DRM.jl single/multi test file (Aqua gap → no full runtests):
cd /Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main && \
  JULIA_HOME=/Users/z3437171/.juliaup/bin /Users/z3437171/.juliaup/bin/julia --project=. \
  -e 'using Test, DRM, Random, LinearAlgebra, Statistics, SparseArrays; include("test/<file>.jl")'

# drmTMB capability/gate consistency (regenerate BOTH registries first):
cd /Users/z3437171/.codex/worktrees/540b/drmTMB && \
  Rscript tools/write-julia-gate-registry.R && \
  Rscript tools/write-julia-capability-comparison.R && \
  Rscript -e 'pkgload::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R")' && \
  python3 tools/validate-mission-control.py

# drmTMB live bridge test (set the RIGHT guard env; q4/inference need NOT_CRAN=true):
cd /Users/z3437171/.codex/worktrees/540b/drmTMB && NOT_CRAN=true \
  DRM_JL_PATH=/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main \
  DRM_JL_PHYLO_PATH=/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main \
  JULIA_HOME=/Users/z3437171/.juliaup/bin \
  Rscript -e 'pkgload::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-julia-<file>.R")'
```

Commit footer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`. After-task notes →
each repo's `docs/dev-log/after-task/`; check-log rows → drmTMB `docs/dev-log/check-log.md`
(prose `##` entries) and DRM.jl `docs/dev-log/check-log.d/` (one file per slice, one table
row — the DRM.jl `check-log.md` table is frozen). Durable memory snapshot lives in
`~/.claude/memory/memory_summary.md` (drmTMB section).

## 8. One-line status

Three slices landed + pushed (§4 multi-coef batching; relmat/animal/spatial `sigma~x`;
bridge wording fix). Bridge matrix 3/11 covered. No single forced next slice — pick from §5
(the single-RE `sigma~x` gap-check or the 3-way `aux_from_hetero` DRY refactor are cheapest).
Nothing pending owner approval.
