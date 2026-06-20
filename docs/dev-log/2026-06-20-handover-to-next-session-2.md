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

## 8. Continuation update (2026-06-20 ~11:15 MDT)

**Owner directives handled this stretch:** (1) PUSH both branches — done; both are
now on origin (drmTMB `shannon/overnight-audit-gaps-20260619`, DRM.jl
`shannon/overnight-audit-verify-20260619`; first pushes — the earlier "PR #636" was
never actually pushed). drmTMB pushes are now ongoing (owner authorized). (2) The
matrix rho12 bridge cell decision: owner agreed with Fisher (covered overclaims) →
resolved to **`planned -> partial`** (Rose+Fisher reconfirmed). (3) New goal: work
till 2pm, flip planned/partial cells, communicate + bridge R↔Julia.

**Commits added this stretch (all pushed):**
- `098d2ad0` — rho12 bridge cell `planned -> partial`; 3 binomial finish-board
  visual cells `planned -> covered` (existing figure).
- `516e7ac9` — **Confidence Eye** coverage figures (maintainer-requested grammar):
  shared helper `_coverage-eye-helper.R`; rho12 + non-Gaussian + binomial(refresh)
  eye figures, Florence-approved; promoted rho12 + non-Gaussian matrix **visual**
  cells `-> covered` and the rho12 lead-novelty finish-board visual.
- `a5c07b7d` — Route A bridge finding + R↔Julia coordination in the bridge-parity doc.
- `99b603aa` — handover refresh.
- `08eb4a19` — **Random slopes point cell `partial -> covered`** (owner chose "new
  recovery sims for harder caps"): a 500-rep native Gaussian correlated random-slope
  recovery (`bf(y ~ x + (1 + x | id), sigma ~ 1)`, n_group {40,80}, 0 errors, pdHess
  1.000). Curie+Fisher both promote, scoped to POINT recovery: fixed effects
  near-unbiased; RE SDs consistent with the expected ML small-sample downward bias
  (sd_slope -6.7%@40 → -1.1%@80). rho not validated; RE-SD intervals not claimed;
  Wald cell stays partial (n=40 b1 0.922). Artifact:
  `docs/dev-log/simulation-artifacts/2026-06-20-gaussian-random-slope-recovery/`.

**Recovery-sim pattern for harder caps (reusable):** self-contained `run.R` with an
`n_rep` arg, an n_group/n ladder to show CONSISTENCY (RE-variance bias shrinks with
groups — read it as estimator behavior, not failure), extract RE SDs from
`fit$sdpars$<dpar>`, smoke (3) → pilot (50) → 500, then Curie+Fisher verify. Scope
"covered" to POINT recovery and disclose the small-n RE-SD bias; keep wald/interval
cells separate.

**Confidence Eye grammar (now the coverage-figure standard here):** use
`docs/dev-log/figure-audits/_coverage-eye-helper.R` (vertical lens, quadratic-loglik
profile, hollow circle=intercept / triangle=slope, `show.legend=FALSE` on the
polygon, set `ylim` wide enough to not clip the widest eye). Per design 39, coverage
plots use eyes only "for a specific reason"; the maintainer's request is that reason.

**Route A finding (important):** a fresh repro of Gaussian phylo-mean
(`y ~ x + phylo(1|sp), sigma ~ 1`) vs DRM.jl `f46035d` gave **clean parity ≤1.6e-9**
across 3 seeds on a balanced 60-species DGP — the garbage-logLik symptom did NOT
reproduce. The Route A skip is **data-shape-specific**, not a blanket failure. If the
DRM.jl team confirms a fix (or the triggering shape is found), the Route A skip can
become an asserted ≤1e-6 parity test. Recorded in
`docs/dev-log/2026-06-20-bridge-parity-verification.md` (Update section).

**Two decisions now waiting on the owner:**
1. **GitHub coordination posting** — a public comment to drmTMB#499 (bridge status)
   and a DRM.jl-side note (Route A question) were drafted but **auto-denied** (the
   "communicate" directive didn't specifically authorize external posting). The
   content is in the bridge-parity doc. Owner can post it, or grant a `gh issue
   comment` permission, or say "post the coordination comments".
2. The matrix rho12 bridge cell is now `partial` (resolved) — no longer open.

**Direction chosen by owner (this stretch): run NEW recovery sims for harder caps.**
Random slopes point is now done (`08eb4a19`). Next harder-cap recovery candidates
(same proven pattern: smoke→pilot→500→Curie+Fisher→scoped promote):
- **Independent-slopes-only** confirmation (`(1|id) + (0+x|id)` or `||`) — completes
  the design-168 "independent second" milestone explicitly.
- **Random-slope RE-SD interval calibration** — would address the Random slopes
  `wald`/`profile` cells (currently partial/planned) the point promotion left alone.
- **Non-Gaussian random effects** recovery (existing DGPs: `sim_dgp_nbinom2_mu_random_effect.R`,
  `sim_dgp_bounded_response_mu_random_intercept.R`).
- A **Confidence Eye recovery figure** for the random-slope artifact → Random slopes
  visual cell.

Lower-risk banked-evidence flips still available:
- ADEMP matrix **visual** (comparator figure of banked glm-parity data) — but ADEMP
  is an aggregate row, likely an honest partial-hold, not a clean covered.
- Binomial/rho12/non-Gaussian **docs** cells via a figure-gallery vignette
  surfacing the eye figures (Pat/Darwin gate, pkgdown render) — heavier.

Genuinely blocked/owner-gated (unchanged): high-2 q4 logdet, q8, rho12 random
effects, structured/q4 recovery, missing-data, DRM.jl #9/#8, Route A (pending
DRM.jl), engine_control, release/CRAN.

## 9. Continuation update (2026-06-20 ~12:07 MDT) — harder-cap recovery stretch

Commits since §8 (all pushed): `99379d32` handover; `08eb4a19` Random slopes point
→ covered; `2be5fd2f` relmat structured recovery (banked, **cell HELD partial**);
`82cb5ea2` binomial point reconciled → covered.

**KEY LESSON — aggregate rows can't be flipped by one sub-type.** The relmat
recovery was clean (fixed effects unbiased; sd_relmat -3.0%@40 → -1.0%@80; Wald
coverage 0.936-0.960 every cell) but Curie+Fisher HELD the "Structural dependencies"
point cell: it is a single aggregate over six sub-types (animal/phylo/relmat/spatial/
kernel/SPDE), and there is **no granular relmat row** for a scoped `covered` to live
in. Same shape as ADEMP / Visuals-and-articles / Master matrix. To flip an aggregate
row you need a SET of sub-type sims (cover most), OR the owner adds per-sub-type rows
to the matrix/registry so each sub-type is individually promotable (a structural
decision — surface it to the owner).

**Under-promotion check paid off:** binomial `point` was partial while `wald`/
`profile` were covered — reconciled to covered on the already-verified glm-parity
(1.9e-11) + 12-cell bias (<=0.009) evidence. Worth scanning for other
"intervals-covered-but-point-partial" inconsistencies.

**Recovery-sim helpers banked (reuse):** random-slope (`(1+x|id)`), relmat
(`relmat(1|id, Q=solve(K))`, AR(1) K) — both with the smoke→pilot(50)→500→Curie+Fisher
pattern, RE SDs from `fit$sdpars$mu`, n-ladder to show consistency.

**Single-capability flippable cells are now largely exhausted.** Remaining work:
- **Structured sub-type set** (animal next — pedigree, very like relmat; then phylo)
  toward eventually flipping Structural dependencies; OR propose per-sub-type rows.
- **Random-slope / non-Gaussian RE-SD interval calibration** (the wald/profile cells
  the point promotions left at partial) — harder (profile/bootstrap on RE SDs).
- **Figure-gallery vignette** surfacing the eye figures → docs cells (Pat/Darwin).
- Owner decisions still parked: post the R↔Julia coordination comments (auto-denied);
  whether to add per-sub-type structured rows.

## 10. Coevolution (Hadfield 2014) + kernel directions (2026-06-20 ~12:35 MDT)

Owner opened two strategic threads. Commits: `99f57a80` (design 178 + phylo-SD
diagnostic), `19b03ee6` (design 178 corrected). Branch pushed.

**Coevolution = "A Tale of Two Phylogenies" (Hadfield et al. 2014, Am Nat).** Full
design + paper mapping in `docs/design/178-coevolution-tale-of-two-phylogenies.md`.
Key verified facts (owner-corrected, both confirmed in code):
- The model is fully expressible in EXISTING grammar -- no new primitives. Main
  effects = `phylo(1|host)` / `phylo(1|parasite)`; coevolution = two-tree
  `phylo_interaction(1|host:parasite, tree1, tree2)`; the evolutionary-interaction
  terms (eq. 4 `I(x)A`, `A(x)I`) = `phylo_interaction()` with a STAR tree for the
  other partner.
- BUT the additive multi-component fit is BLOCKED at the engine: the assembly
  extracts a SINGLE structured term per dpar (`extract_gaussian_mu_phylo_term`,
  `R/drmTMB.R:7534-7549`, aborts on >1 phylo term; sibling guard `:2634`). Verified
  by fitting `phylo(host)+phylo(parasite)+phylo_interaction(...)` -> it errors
  "Only one phylogenetic structured effect is implemented in mu". The single-term
  slices DO work.
- So the next step is an ENGINE EXTENSION (Gauss): collect all structured terms,
  build + SUM their precisions per dpar (R assembly + very likely `src/drmTMB.cpp`).
  Then identifiability validation at adequate N -- which is the maintainer's "we
  just need larger N, be honest" point. The phylo-SD diagnostic
  (`2026-06-20-phylo-sd-recovery/`) QUANTIFIES that N requirement (rel bias
  -32%@60 species -> -4.8%@240; consistent estimator, not a defect).
- Staged plan in design 178: Stage 1 engine multi-block; Stage 2 adequate-N
  recovery (species ladder, report the N contract); Stage 3 star-tree evolutionary
  interactions; Stage 4 ICC accessor (align DRM.jl#188) + Bernoulli + spatial (eq.7-8).
- This is careful engine surgery -- do it with fresh context + Gauss, not at the
  tail of a long session. The paper PDF is at /Users/z3437171/Downloads/674445.pdf.

**Kernel.** Jason (landscape_scout) is mapping the gllvm/DRM.jl#270 kernel
(NNGP/Matern) abstraction as the scalable replacement for fixed relmat; fold his
synthesis into design 178 (the A matrices generalize to estimated kernels). Scout
was in flight at handoff.
