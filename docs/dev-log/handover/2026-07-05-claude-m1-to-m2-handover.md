# Session Handoff: Q-Series 104/104 arc — M1 done, start M2 (q6)

Meta: 2026-07-05 · from Claude (Shannon) to Claude · context very high

You are Claude, picking up the **drmTMB Q-Series 104/104 completion arc** after an M1
(covariance-engine) investigation session. Read `AGENTS.md` first, then **the ultra-plan**
`docs/dev-log/2026-07-05-qseries-104-completion-ultra-plan.md` (you inherit it — it has the
phases, team roster, model tiers, compute map, and locked decisions), then this file, then
the M1 after-task `docs/dev-log/after-task/2026-07-05-m1-highq-covariance-recovery-verdict.md`.

## Goal / mission (durable)

Complete the Q-Series structured-RE matrix from **94/104 to 104/104** as real,
recovery-gated, STAN-cross-validated capability. drmTMB is the finish-first R/TMB package;
DRM.jl/Julia optional/later. **Locked decisions (Shinichi):** 104-bar = fit + recovery +
STAN match (intervals = per-row Fisher-gated follow-on); **q6 before q8**; Gaussian-8 first
(→102/104) then the 2 non-Gaussian rows (→104); DRAC job arrays + Totoro authorized.

## Critical context — M1's finding RE-SHAPES the arc

**The feared Phase-1 engine build is unnecessary.** M1 proved the TMB engine ALREADY recovers
high-q structured covariance at adequate n — no log-Cholesky rewrite (P1.2 = no-op). The
documented "q8 production-transform blocker" (docs/design/220) was a **data-size misdiagnosis**:
it judged a 36-parameter covariance on **16 groups**. Evidence:
- **q4 all-four: clean at Santi-scale** (n≥512: conv=0, pdHess=TRUE, rmse ~0.05). Fails at n=64.
- **q8 all-four: recovers** (rmse 0.48→0.116 as groups 16→1024, cap-saturation gone by n=256)
  but **pdHess=FALSE persists** even at 1024 (genuine weak-ID of the 28-corr Hessian; not an
  iteration cap; partial-Cholesky doesn't fix it).

**Inference doctrine:** `pdHess=FALSE` is not failure — route q8 inference through **parallel
profile** (`confint(..., method="profile", workers=)`, the primary) + **bootstrap** (fallback);
**ELR/"estimated profile" is EXCLUDED** (under-covers for correlated targets). Pushing q8 to
pdHess=TRUE is a **separate reduced-rank factor-analytic estimation arc**, deferred.

⇒ **Phase 2/3 (q6/q8 rows) collapse to: parser admission + recovery-gating at Santi-scale n +
parallel profile/bootstrap intervals — NOT engine surgery.** The arc is materially de-risked.

## What was accomplished (this session)

- Banked the 94/104 practical checkpoint + the structured-RE naming **regression fix**
  (122-test regression, root-caused + fixed; draft PR #730, ubuntu CI green). See the earlier
  handovers/after-tasks from 2026-07-05.
- Trimmed CI to ubuntu-only for routine PRs (3-OS on tags/dispatch).
- Wrote the 104/104 **ultra-plan** (now in-repo).
- **M1 verdict** (above): engine already works; q4 clean; q8 recover+profile; no build needed.
- Recorded the Curie long-sim discipline (stream/fast-first/heartbeat) in the agent files +
  brain `LESSONS.md`; recorded the ELR-contraindication doctrine in the brain.

## Current working state

- Branch `drmtmb/fix-family-conventions`; **draft PR #730** open (94/104 + regression fix),
  ubuntu CI green. Mission Control truth unchanged: **94/104 / 8/104 / 0/104 / 10/104**.
- M1 evidence committed under `docs/dev-log/simulation-artifacts/2026-07-05-m1-highq-recovery/`.
- **Not merged:** #730. The arc plan's Phase 0 (merge #730 + branch `qseries/high-q-completion`)
  is still open — decide branch strategy early (the M1 sim/plan/agent edits are on the current
  branch; you may want to split or continue here).

## Next milestone: M2 = q6 admitted (4 providers, recovery)

q6 = two-slope location-only (`1 + x + z` in mu1 & mu2): 6 SD + 15 corr, LOWER-dimensional than
q8 → should be *more* identifiable, likely reaching pdHess=TRUE more readily than q8. Per row
(phylo/spatial/animal/relmat): parser admission (Boole) → **recovery at Santi-scale** (Curie,
reuse `…/2026-07-05-m1-highq-recovery/00-helpers.R` DGP + the STREAMING runner pattern) →
extractor check (Emmy) → 4-lens gate. Row counts at recovery + (where practical) profile.

## Next immediate steps

1. Rehydrate: `git status`; read AGENTS.md snapshot + the ultra-plan + the M1 after-task.
2. Decide branch strategy for the arc (continue on `drmtmb/fix-family-conventions` vs merge
   #730 first + branch `qseries/high-q-completion`).
3. M2: confirm q6 syntax parses (`bf(mu1=y1~x+phylo(1+x+z|p|species), mu2=..., sigma1=~., sigma2=~., rho12=~1)`),
   then run a q6 recovery-vs-n ladder (STREAMING, fast-first) per provider — does q6 reach
   pdHess=TRUE at Santi-scale (likely, being lower-dim than q8)? Gate with Curie/Noether/Fisher/Rose.
4. Only after recovery lands, admit the q6 rows (dashboard) with Rose sign-off — no inflated
   coverage/support wording.

## Gotchas & doctrine

- **Data-size rule:** a complex model needs large n; correct non-convergence on a small
  fixture is data-insufficiency, NOT engine failure. Size every recovery gate to the model.
- **Streaming-sim discipline:** stream+flush per fit, run the cheapest decisive fit first,
  heartbeat to a `.log`, time one fit before scaling (see `.claude/agents/simulation-tester.md`).
- Run R with `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 Rscript --no-init-file`.
- Do NOT rewrite the covariance engine — it works. Do NOT use ELR for correlation CIs.
- Keep Julia optional; don't touch claims/dashboard until a row's recovery is gated.

## Mission Control

| Area | State | Meaning |
| --- | --- | --- |
| Repo / branch | `drmTMB` @ `drmtmb/fix-family-conventions` | draft PR #730 (94/104 + regression fix), ubuntu CI green |
| Arc plan | `docs/dev-log/2026-07-05-qseries-104-completion-ultra-plan.md` | inherited; phases/team/models/compute |
| M1 (engine) | **DONE** — engine already recovers; no build | q4 clean at scale; q8 recover+profile; FA-arc deferred |
| M2 (next) | q6 admitted (4 providers, recovery) | parser + recovery-gate + profile; lower-dim than q8 |
| Practical surface | 94/104 (unchanged) | no row admitted by M1 |
| Compute | DRAC arrays + Totoro authorized | recovery at Santi-scale n |

## How to resume

From the repo root in an authenticated terminal:
```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-05-claude-m1-to-m2-handover.md + the AGENTS.md snapshot + the ultra-plan docs/dev-log/2026-07-05-qseries-104-completion-ultra-plan.md, then start M2 (q6 admission)."
```
Then set the M2 goal (paste as `/goal`):
```
Reach M2 of the drmTMB 104/104 arc: admit the four q6 rows (two-slope location-only, phylo/spatial/animal/relmat) on honest fit + recovery evidence at Santi-scale n. Reuse the M1 streaming-sim discipline and DGP helpers. For each provider: confirm q6 parses, run a streaming recovery-vs-n ladder (does pdHess reach TRUE at scale? q6 is lower-dim than q8), then admit the row only after a Curie/Noether/Fisher/Rose gate. pdHess=FALSE is not failure — route intervals through parallel profile/bootstrap, ELR excluded. Do NOT rewrite the covariance engine (M1 proved it works), do NOT inflate coverage/support wording, keep Julia optional. End with the four q6 rows admitted + a clean check-log/after-task, or a clean handover.
```

Spawn Rose before any status/dashboard claim; Curie owns the recovery sims (streaming!).
