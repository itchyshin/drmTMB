# Handover to the next Claude session (#2) — drmTMB + DRM.jl finish-plan

You are **Ada**, continuing an autonomous, push-held run to finish drmTMB (R), its
DRM.jl (Julia) twin, and the R-Julia bridge — one defended evidence slice at a
time. Read this whole file, then the prior handover
`docs/dev-log/2026-06-20-handover-to-next-session.md` (it still holds for identity,
team, the deep plan-doc map, and boundaries). Repo state is authoritative — rerun
`git status`/`git diff` before editing.

## 0. Posture (unchanged)

- Orchestrate as **Ada**; spawn **Rose** (claim-boundary guardrail) + **Fisher**
  (inference) to verify EVERY promotion, plus the other lenses as needed.
- **Ultracode on**: prefer Workflow orchestration; correctness over cost.
- **Pushes HELD.** Commit locally on the branches below; do not push/PR/merge
  without the owner. Active `/goal`: turn the finish plan into action, reduce
  partial/planned cells with NEW measuring evidence (never status-flips), keep the
  mission-control widget honest. Do NOT mark the Big-4 goal "complete."

## 1. Workspaces and branches (PUSHES HELD)

- **drmTMB (R)**: `/Users/z3437171/.codex/worktrees/540b/drmTMB`, branch
  **`shannon/overnight-audit-gaps-20260619`**, now at the latest session-2 commit
  (`git log --oneline -8`; binomial-visual promotion `3f47503c` + this handover
  update on top).
- **DRM.jl (Julia)**: `/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main`,
  branch `shannon/overnight-audit-verify-20260619` (`f46035d`) — untouched this
  session.
- **cwd HAZARD**: every Bash/subagent shell resets to the STALE primary checkout
  `/Users/z3437171/Dropbox/Github Local/drmTMB` (159+ behind). Ignore it. ALWAYS
  pin absolute `540b` paths; tell spawned agents to do the same.
- **Bridge harness**: the R-Julia bridge runs ONLY via the callr-isolated test
  harness with
  `DRM_JL_PHYLO_PATH=/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main`
  and `JULIA_HOME=/Users/z3437171/.juliaup/bin`. An in-process `engine="julia"`
  call after `load_all()` fails. Each Julia round-trip is ~3 min (startup +
  compile); background it.

## 2. What this session committed (on `shannon/overnight-audit-gaps-20260619`)

Four defended slices, each Rose+Fisher-verified, validator green, pushes held:

1. `e303dd55` — **Non-Gaussian FE point cell -> covered.** 500-rep native R/TMB
   recovery, 6 one-response families (poisson/nbinom2/Gamma/lognormal/beta/student)
   x n in {300,600} = 12,000 fits, 0 errors, max |bias| 0.0052, pdHess >= 0.996.
   Promoted `point` only; **wald held** (student n=300 mu:x = 0.926 < 0.93),
   **simulation held** (guardrail). Artifact:
   `docs/dev-log/simulation-artifacts/2026-06-20-nongaussian-fe-recovery-calibration/`.
2. `ba3bf21f` — **Route C bridge cell -> covered.** Wald CI-endpoint parity
   (engine="julia" == engine="tmb") for Gaussian location-scale, asserted <= 1e-4
   (measured ~5.6e-6). Promoted `base_gaussian_location_scale` in
   `julia-capabilities.tsv`.
3. `357810d1` — **Route B parity test** (committed first as evidence).
4. `4a1ecd95` — **Non-phylo bivariate rho12 bridge cell -> covered.** New
   capability row `nonphylo_biv_rho12_predictor`; rho12 ~ x coefficient parity
   (incl. both rho12 coefficients, matched by name) + Wald-endpoint parity,
   asserted <= 1e-4 (measured ~1.3e-6).
5. `3f47503c` — **Binomial visual cell -> covered** (Florence gate, not
   Rose+Fisher: it visualises already-verified data). A coverage figure
   (`docs/dev-log/figure-audits/2026-06-20-binomial-coverage/`) of the banked
   Wald + profile coverage; Florence v2->v3 approve. Matrix "Bernoulli/binomial
   response family" visual `planned -> covered`.

Method note learned this session: **commit the re-runnable test BEFORE the status
promotion** (Fisher holds a promotion whose numbers live only in narrative). Bank
deltas in the after-task + check-log.

## 3. Mission control

- Source: `docs/dev-log/dashboard/status.json` (+ `julia-capabilities.tsv` now has
  **10** rows, `julia-gates.tsv` 15). Validate after ANY dashboard edit:
  `python3 tools/validate-mission-control.py` (must print `mission_control_ok`).
- Slice metrics unchanged at **25/68** (promoting a matrix/TSV *cell* does not move
  slice metrics or row counts, so the validator stays green — but keep status.json
  and design 168 in sync, and keep `evidence_url` a GitHub issue URL in the TSVs).
- Serve: `tools/start-mission-control.sh --background` at `http://127.0.0.1:8765/`.

## 4. Resume point

**No half-done slice — the tree is clean at `4a1ecd95`.** Pick the next item from
the queue below; produce evidence -> Rose+Fisher verify -> scoped promote ->
validate -> commit -> check-log + after-task + widget activity.

## 5. Evidence-path queue (leverage order; all push-held, scoped)

- **OPEN DECISION (owner/team):** move the matrix "Bivariate residual correlation
  rho12" **bridge** cell (`design 168` line 39 + status.json) `planned -> covered`?
  Rose says yes (it is a single-capability row whose bridge column is directly
  answered by the new rho12 ~ x bridge parity); Fisher says no (design-168
  "covered" is a stricter registry-level standard; Route C precedent moved only the
  TSV cell). Held this session on the split. A clean owner call would settle it.
- ~~(b) Binomial coverage visual~~ — **DONE this session** (`3f47503c`). A natural
  follow-on: surface that figure in a binomial pkgdown article/gallery, which would
  also support the binomial `docs` cell (currently partial).
- **Other `visual` planned cells**: the same low-risk pattern (figure of
  already-verified evidence -> Florence gate -> promote the visual cell) applies to
  other rows whose data is banked (e.g. non-Gaussian recovery, rho12 recovery).
- **(c) high-2 atomic::logdet re-land** — OWNER-GATED (needs supervised q4
  convergence adjudication). Do not touch autonomously.
- **(e) genuinely blocked / owner-gated:** q8 method, rho12 random effects,
  structured/q4 recovery, missing-data design gates, DRM.jl #9 Documenter pin + #8
  logdet ridge (maintainer-owned).
- Route A (Gaussian phylo-mean) bridge: tracked DRM.jl garbage-logLik bug; blocks
  its parity. Not promotable until fixed.

## 6. Boundaries (Rose enforces — non-negotiable)

No bridge-row promotion without per-cell parity; no q4/q8 or plain non-phylo
binomial bridge parity; no release/CRAN claim; no recovery/coverage/power claim
without a measuring sim; no selectable Julia `engine_control`; REML/AI-REML
Gaussian-only; missing-data vs complete-case separate; keep **native R/TMB ↔
direct DRM.jl ↔ Julia-via-R** evidence in separate lanes (a green DRM.jl suite does
NOT promote a bridge or native cell). Bridge parity (engine agreement) is NOT
interval coverage. Cite the **asserted** test tolerance as the guarantee, not the
measured value.

## 7. Owner decisions still standing

The owner reserved: (1) whether to push the two branches — currently **held**;
(2) the matrix rho12 bridge-cell call (§5). Ask before acting on either.

Hand off the same way (this note + a recovery checkpoint) when your context fills.
Good luck.
