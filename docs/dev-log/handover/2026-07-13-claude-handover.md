# Handover → Claude — Arc 2b/2c landed; Arc 4a (profile-interval) ratified as next

**Date:** 2026-07-13 · **From:** Claude · **To:** Claude (next session) ·
**Repo:** drmTMB · `main @ 43c1a321` (Arc 2b/2c + DG3 evidence merged) ·
**This handover branch:** `docs/arc4a-plan-and-handover`.

## Critical Context

- **Arc 2b/2c are DONE and MERGED** (PR #775). Every fitted univariate family now has a `mu`
  random **intercept + independent slope**; **lognormal + Gamma** also have a `sigma` random
  **intercept**. All at `point_fit_recovery` (ML-Laplace) — **NOT** supported/inference_ready.
- **The RE-SD downward bias is expected, not a bug.** Two independent studies this session
  proved it: drmTMB-Laplace matches `lme4`-Laplace to ~3 dp; the bias is finite-sample and
  vanishes as clusters M and per-cluster n grow. **AGHQ** fixes the integral (per-n) half;
  **REML** fixes the df (per-M) half (Gaussian only).
- **The next arc is ratified: Arc 4a — the profile-CI DG3 rerun** (see the plan doc). It is the
  only near-term lever that promotes a cell's tier, and it is *diagnostic* (isolates interval
  vs point bias → tells us whether REML or AGHQ binds next). **Do not over-claim it:** profile
  fixes the ∞-width artifact but NOT the M=8 coverage gap; binomial may honestly not promote.

## What Was Accomplished

- **Arc 2b** — one independent `mu` slope `(0 + x | id)` for binomial, cumulative_logit,
  skew_normal, tweedie, zero_one_beta. R-only (one predicate flip per validator; parser/data/
  start/map/C++ were already column-generic). 60-seed bias sweep + DG2 sentinels.
- **Arc 2c** — `sigma` random intercept `(1 | id)` for lognormal + Gamma. Full `re_sigma`
  plumbing (make_tmb_data, start, map, `random_names`) + C++ block. 60-seed sweep + sentinels.
- **Verification:** 560+8 assertions green · `--as-cran` 0/0/1-benign · D-43 adversarial review
  **2 DONE / 1 NOT-DONE**, all NOT-DONE findings fixed (ledger regen, stale message, generators).
- **Ledger/census/surface regenerated** (guard 288/339/41 → 295/333/40); artifact `a1bf21a1`
  refreshed.
- **Evidence studies (both merged):** Laplace-vs-AGHQ + bias-vs-sample-size
  (`.../2026-07-12-laplace-vs-aghq/`); DG3 RE-SD interval coverage on **Totoro**, 7,200 fits
  (`.../2026-07-12-dg3-re-sd-coverage/`, PR #777).
- **Next-arc design workflow** (`wf_d42c1616-6a3`, 5 agents) → ratified Arc 4a plan
  (`docs/dev-log/2026-07-13-arc4a-profile-interval-plan.md`).

## Current Working State

- **Working:** everything above, on `main`. Full detail:
  `docs/dev-log/after-task/2026-07-12-arc2b-2c-slopes-sigma-re.md`.
- **In progress / next:** Arc 4a per the plan doc (S1 harness patch → S2 Totoro campaign → S4
  review → S5 promotion).
- **Totoro is set up:** drmTMB `0.6.0.9000` installed from `main @ 38cfa4e6` into `~/Rlib`;
  DG3 harness + results in `~/drmTMB_work/`. **Reachable from this environment (no MFA);
  DRAC is NOT (TCP timeout).** Reload from source on Totoro (`pkgload::load_all`) — the default
  library build was stale 0.1.4.

## Key Decisions & Rationale

- **Evidence bar = point_fit_recovery via SD-magnitude + ≥50-seed bias sweep** (Fisher's raise
  from a single-seed smoke test). No coverage claim; DG3 is separate.
- **2c is ML-only, lognormal+Gamma only, not combinable with a mu-RE** (first gate); student/
  skew_normal held (sigma↔nu / sigma↔skew identifiability); REML rows stay rejected (SR159).
- **Next arc chosen by workflow synthesis:** profile-CI DG3 rerun over REML / AGHQ / 2c-ext,
  because it advances a tier this session AND diagnoses which of REML/AGHQ binds next.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| Arc 2b/2c code+evidence — `main` | y | y | #775 merged | **LANDED** |
| DG3 coverage evidence — `main` | y | y | #777 merged | **LANDED** |
| Arc 4a plan + this handover — `docs/arc4a-plan-and-handover` | pending | pending | to open | **CARRIED-OVER** → committed + PR'd at end of this session; do not auto-merge |
| Totoro drmTMB build + DG3 results — `~/drmTMB_work` (Totoro) | n/a | n/a | n/a | **LANDED remotely** (results already in-repo via #777) |

## Next Immediate Steps

1. **Arc 4a S1:** patch `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/generate.R`
   to add `confint(fit, parm=<sd_parm>, method="profile")` per replicate alongside the Wald read
   + the denominator columns. Smoke-reproduce the isolated case (gaussian_slope M=8 seed
   20260976: Wald upper=Inf, profile upper≈0.327).
2. **Arc 4a S2:** run the profile campaign on Totoro (3 specs × M∈{8,16,32,64} × 600). Report
   profile_coverage, profile_finite_rate, MCSE; find the certified M-floor.
3. **S4 review → S5 promote** only cells clearing the bar; honest claim_boundary. Binomial may
   NOT promote (point-bias, not interval) — a valid recorded negative.
4. **Spin-off bug (tiny slice):** `has_sigma_random_effects()` reportedly omits lognormal/Gamma
   (Arc 2c omission) — verify + fix + test.

## Blockers / Open Questions

- None blocking. DRAC unreachable from the agent environment (use Totoro). Arc 4a's realistic
  yield may be ONE promotion (lognormal `mc-0382` at M≥16), binomial `mc-0061` a documented
  non-promotion — that is an acceptable outcome, not a failure.

## Gotchas & Failed Approaches

- **The Arc-2c NaN trap:** enabling a family RE needs the family validator PLUS make_tmb_data
  un-zero-fill + start/map/`random_names` threading — any miss → NaN objective from a good start.
  Always mirror gaussian/nbinom2 end-to-end and smoke-fit for `convergence==0 && pdHess`.
- **Totoro's installed drmTMB is stale (0.1.4).** Always `pkgload::load_all` from a fresh clone,
  or reinstall into `~/Rlib`, before any campaign.
- **Wald(log-SD) intervals are literally `[x, Inf)` at small M** — the reason Arc 4a switches to
  profile. But profile does NOT fix the point-bias-driven coverage gap; do not conflate the two.

## How to Resume

**Rehydrate (Claude):** read the `AGENTS.md` snapshot pointer + this doc + the Arc 4a plan
(`docs/dev-log/2026-07-13-arc4a-profile-interval-plan.md`) + the after-task report
(`docs/dev-log/after-task/2026-07-12-arc2b-2c-slopes-sigma-re.md`) + the two evidence READMEs.
Claude CAN compile locally (this Mac has the live R/TMB toolchain) and CAN reach Totoro (no MFA).
Spawn a fresh adversarial NOT-DONE lens (Rose/Fisher) before any promotion claim (D-43).

**One-command resume** (paste in your authenticated terminal, repo root):

```
claude "Rehydrate from docs/dev-log/handover/2026-07-13-claude-handover.md + the AGENTS.md snapshot, then execute Arc 4a per docs/dev-log/2026-07-13-arc4a-profile-interval-plan.md (S1 harness patch, then the Totoro profile campaign)."
```

Autonomous, clean context:

```
claude -p "Rehydrate from docs/dev-log/handover/2026-07-13-claude-handover.md + the AGENTS.md snapshot, then execute Arc 4a S1-S2 per the ratified plan." --max-budget-usd 6
```
