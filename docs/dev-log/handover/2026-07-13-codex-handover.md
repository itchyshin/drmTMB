# Handover → Codex — Arc 2b/2c landed; run the Arc 4a-completion + next-arc campaign

> **Superseded as an execution starting point (2026-07-13).** This remains the historical inbound
> handover. The current branch repaired the sigma prediction bug, replaced the invalid
> centered-effect Arc 4a evidence with an iid-un­centered 14,400-fit campaign, conditionally
> promoted the two cells to `inference_ready_with_caveats` after fresh D-43 review, refreshed the
> tracked capability surface, and obtained a negative/inconclusive marginal-Gauss-Kronrod probe.
> Use `../2026-07-13-next-arcs-codex-campaign-plan.md` and the forthcoming Codex after-task report
> for current truth. Task C remains deferred; final verification and Rose sign-off are still open.

**Date:** 2026-07-13 · **From:** Claude · **To:** Codex (new session) · **Repo:** drmTMB ·
`main @ 43c1a321` (Arc 2b/2c + DG3 evidence merged). This doc stands alone — you did not see
the Claude chat. Your role: **the live R/TMB toolchain** (real fits, compiles, `R CMD check`,
Totoro campaigns). Everything below is grounded in `AGENTS.md` + the linked docs.

## Critical Context (read or you will go wrong)

- **Arc 2b/2c are DONE + MERGED** (PR #775). Every fitted univariate family has a `mu` random
  intercept **+ independent slope**; **lognormal + Gamma** also a `sigma` random intercept. All
  `point_fit_recovery` (ML-Laplace) — NOT supported/inference_ready.
- **Arc 4a (profile-interval coverage) is HALF done.** S1 (harness) + S2 (Totoro campaign, 7,200
  fits) are committed on branch `feature/arc4a-profile-coverage`: the **profile interval
  completely fixes the Wald ∞-width defect** (finite_rate 1.000). But the **ledger promotion was
  WITHHELD by a D-43 review (2 NOT-DONE)** — the target tier was wrong AND a shipped bug was
  found. **Do not simply "finish the promotion" — it must be re-scoped.** See Task A.
- **The full 1–2 day campaign is specified in
  [`docs/dev-log/2026-07-13-next-arcs-codex-campaign-plan.md`](../2026-07-13-next-arcs-codex-campaign-plan.md)** —
  that is your work list (Task A: Arc 4a completion · Task B: AGHQ de-risk probe · Task C: REML
  Arc 1a slice). This handover is the wrapper; the campaign plan is the detail.

## What Was Accomplished (this Claude session)

Arc 2b (mu slope ×5 families), Arc 2c (sigma intercept for lognormal/Gamma), both merged with
DG2 evidence + honest caveats + regenerated ledger (295/333/40) + refreshed artifact `a1bf21a1`.
Two evidence studies (merged): Laplace-vs-AGHQ (`.../2026-07-12-laplace-vs-aghq/`) and DG3 RE-SD
coverage on Totoro (`.../2026-07-12-dg3-re-sd-coverage/`, PR #777). Arc 4a S1+S2 (profile
harness + Totoro campaign) committed. A 5-agent design workflow ranked the next levers; a D-43
review withheld the Arc 4a promotion and re-scoped it. Full detail:
`docs/dev-log/after-task/2026-07-12-arc2b-2c-slopes-sigma-re.md`.

## Current Working State

- **Working (on `main`):** Arc 2a/2b/2c; the two evidence studies. Local Mac + Totoro both
  compile drmTMB.
- **In progress (branch `feature/arc4a-profile-coverage`):** Arc 4a S1+S2 evidence + the S4
  disposition. **This is your starting branch.**
- **Blocked/withheld:** the Arc 4a ledger promotion (re-scope per Task A).

## Key Decisions & Rationale

- Evidence bar = `point_fit_recovery` via SD-magnitude + ≥50-seed bias sweep; coverage is DG3.
- The Arc-4a coverage evidence is `inference_ready_with_caveats`-grade, **NOT** `interval_feasible`
  (that tier = "interval computes, no coverage"). Re-target accordingly (Task A1).
- REML fixes the finite-M/df bias (Gaussian only); AGHQ fixes the per-cluster-n integral bias
  (non-Gaussian). Today's DG3/profile finding shows the residual coverage gap is *point-bias*,
  which neither the interval method nor a promotion can fix — hence Tasks B/C.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| Arc 2b/2c + DG3 evidence — `main @ 43c1a321` | y | y | #775, #777 merged | **LANDED** |
| Arc 4a S1+S2 + S4 disposition — `feature/arc4a-profile-coverage @ 476e3632` | y | pending | to open | **CARRIED-OVER** → pushed + PR'd (not merged) at end of this session; this is your branch |
| Campaign plan + this handover — same branch | pending | pending | same PR | **CARRIED-OVER** |
| Totoro: drmTMB build + DG3/profile results — `~/drmTMB_work` | n/a | n/a | n/a | **LANDED remotely** (in-repo via the artifacts) |

## Live-environment setup (Codex — you run this)

- Compile drmTMB from source: `R -e 'pkgload::load_all(".")'` (or `R CMD INSTALL --preclean .`);
  `src/drmTMB.cpp` (~4.4k lines) takes a few min. `--as-cran`:
  `rcmdcheck::rcmdcheck(args="--as-cran")` (baseline is 0/0/1-benign new-submission note).
- **Totoro** `snakagaw@totoro.biology.ualberta.ca` — reachable, **no MFA**, 384 cores. Rule:
  **≤ 90 cores**, `OPENBLAS_NUM_THREADS=1`, `.libPaths("~/Rlib")`. Reinstall drmTMB from a fresh
  `main` clone into `~/Rlib` before campaigns (the default lib can be stale). Harnesses:
  `~/drmTMB_work/generate.R`, `/tmp/generate-profile.R`. **DRAC is NOT reachable** (TCP timeout).
- Team: `.codex/agents/*.toml` (Rose mandatory before any completion/promotion claim; Fisher for
  inference, Noether for math-consistency — the D-43 gate is ≥2 NOT-DONE withholds).

## Next Immediate Steps (ordered — from the campaign plan)

1. **Task A0 (bug, do first):** `has_sigma_random_effects()` (`R/methods.R:5294-5298`) omits
   lognormal/Gamma → `predict(dpar="sigma")` silently drops the σ-BLUP for the Arc-2c capability.
   Add the two families + a test. Compile + test.
2. **Task A1/A2 (Arc 4a promotion, re-scoped):** promote `mc-0382`/`mc-0061` to
   `inference_ready_with_caveats` (NOT interval_feasible) with corrected claim_boundaries (lead
   with lognormal's worst-in-range **0.917**; binomial M≥32 is coverage- not profile-driven);
   schema-correct ledger edit (`coverage_status` doesn't exist — caveat in `claim_boundary`; add
   `evidence.tsv`/`transitions.tsv` rows); Noether lens + D-43; `--write`/`--check`; refresh
   `a1bf21a1`. Full spec in the campaign plan.
3. **Task B (AGHQ de-risk):** the isolated `integrate=` probe vs `lme4::glmer(nAGQ=25)` (no
   drmTMB changes) — greenlights AGHQ Slice 1 only if it reproduces AGHQ's ≈unbiased SD.
4. **Task C (REML Arc 1a):** one bounded slice (mean-side structured REML admission), C1 recipe.

## Blockers / Open Questions

- None hard. DRAC unreachable → use Totoro. The Arc 4a promotion's correct tier
  (`inference_ready_with_caveats` vs stay `point_fit_recovery`) is a judgment for Task A1's
  review to settle — the sub-nominal coverage (0.917/0.943) is the crux.

## Gotchas & Failed Approaches

- **Do NOT promote Arc 4a to `interval_feasible`** — two reviewers + precedent say it's the wrong
  (too-low) tier; it would mislabel a real coverage campaign as "no coverage checked."
- **Wald(log-SD) RE-SD intervals are `[x, Inf)` at small M** — profile fixes this, but does NOT
  fix the point-bias-driven coverage gap. Don't conflate the two.
- **Totoro's default-library drmTMB can be stale (was 0.1.4).** Always reinstall from `main`.
- The Arc-2c NaN trap: enabling a family RE needs the validator + make_tmb_data + start/map/
  `random_names` all extended — smoke-fit for `convergence==0 && pdHess`.

## How to Resume (Codex)

Read `AGENTS.md` (native) → this doc → the campaign plan
(`docs/dev-log/2026-07-13-next-arcs-codex-campaign-plan.md`) → the Arc 4a S4 disposition
(`docs/dev-log/2026-07-13-arc4a-profile-interval-plan.md`) → the after-task report. Check out
`feature/arc4a-profile-coverage`. Spawn Rose (and Fisher/Noether) before any promotion claim.

**Model-tier routing (don't default everything to Sol — `MODEL-ROUTING.md`):** **Luna** =
scouting / mechanical / the `has_sigma_random_effects` one-liner + test scaffolding (low
effort). **Terra** = the real implementation (A0 fix, the re-scoped ledger promotion A1/A2,
the AGHQ Slice-0 probe, the REML slice). **Sol** = the D-43 NOT-DONE review + Noether
math-consistency check + orchestration only (high effort). Set `reasoning_effort` per task.

**One-command resume** (paste in your authenticated Codex terminal, repo root):

```
codex "First open the drmTMB capability surface — https://claude.ai/code/artifact/a1bf21a1-8c5a-495e-b0ee-1b91608a5ca2 — the live implemented-capability × evidence-tier map; keep it current as tiers change. Then rehydrate: AGENTS.md + docs/dev-log/handover/2026-07-13-codex-handover.md + docs/dev-log/2026-07-13-next-arcs-codex-campaign-plan.md; check out feature/arc4a-profile-coverage. Run it as an ultra-plan campaign with deliberate Codex model-tier routing — Luna for scouting/mechanical, Terra for implementation, Sol only for the D-43/Noether adversarial reviews + orchestration; reasoning_effort high only where correctness is expensive. Execute in order: Task A0 (fix has_sigma_random_effects for lognormal/Gamma + test predict(dpar='sigma')), then A1/A2 (promote mc-0382/mc-0061 to inference_ready_with_caveats — NOT interval_feasible — with corrected claim_boundaries + schema-correct evidence/transitions rows + Noether lens + D-43, then capability_ledger.py --write/--check and refresh the a1bf21a1 surface), then Task B (AGHQ integrate= probe vs glmer(nAGQ=25)). Live toolchain: pkgload::load_all to compile; Totoro for campaigns (no MFA, <=90 cores, OPENBLAS_NUM_THREADS=1); DRAC unreachable. Rose signs off before any completion claim."
```
