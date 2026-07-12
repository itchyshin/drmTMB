# Handover → Claude — Arc 2a landed (a `mu` random intercept for every family)

**Date:** 2026-07-12 · **Author:** Claude · **Target:** Claude (next session) ·
**Branch shipped:** `feature/arc2a-mu-random-intercept` → merged to `main` at
`0ba88fd8` (pushed) · **This handover branch:** `handover/2026-07-12-arc2a-claude`.

You are the next Claude picking up drmTMB. Arc 2a is **done and merged**. This doc
is the durable record — read it plus the after-task report; do not re-derive.

---

## Mission-control

| Item | State |
|---|---|
| Repo / branch | drmTMB · `main` @ `0ba88fd8` (Arc 2a merged, pushed) |
| CI (R-CMD-check) | Running on `main` for the Arc 2a merge; local `--as-cran` was **0/0** (11593 tests). Confirm green. |
| CI (pkgdown) | Was **red** (5 topics missing); **fixed** in this merge (`_pkgdown.yml`). pkgdown re-runs after R-CMD-check (workflow_run) — confirm it flips green. |
| Version | `0.6.0.9000` (dev) · last CRAN `0.5.0` |
| Next by leverage | 1) tweedie fix-`p` API (carried over) · 2) Arc 4a validate intervals · 3) Arc 1a Gaussian REML parity · 4) Arc 2b slopes / 2c sigma-RE · 5) DG3 multi-seed campaign (Totoro) |

## Critical context / goals

- **Mission:** drmTMB = univariate/bivariate distributional regression (sister of
  gllvmTMB). The ratified 0.6.0-class roadmap is five arcs + a post-0.6.0 bivariate
  flagship (Arc 6). Source: `docs/dev-log/2026-07-12-0.6.0-candidate-arcs-plan.md`.
- **This session** executed **Arc 2a** end-to-end via the ultra-plan
  `docs/dev-log/2026-07-12-arc2a-random-intercept-all-families-ultra-plan.md`.

## What was accomplished

- An ordinary `mu` random intercept `(1 | group)` now works for the **five**
  families that previously rejected all random effects: **binomial,
  cumulative_logit, skew_normal, tweedie, zero_one_beta**. Every fitted univariate
  family now supports at least a mean random intercept.
- Per-family DG2 recovery sentinels pass (convergence 0, `pdHess`, SD within 0.30
  of truth, BLUP correlation 0.84–0.97, `profile_targets()` profile-ready,
  `check_drm()` replication `ok`). `--as-cran` 0/0/1-note.
- Ledger cells `mc-0059/0225/0463/0538/0567` → `implemented` / `verified` /
  `point_fit_recovery`; surface regenerated.
- **pkgdown blocker fixed**: added the five #747/#748 topics (`fitted_distribution`,
  `exceedance`, `centile_chart`, `worm_plot`, `qq_plot`) to `_pkgdown.yml`.
- Estimator-axis decision recorded (REML Gaussian-only; AGHQ the non-Gaussian
  lever) + Arc 6 (bivariate) recorded — in the candidate-arcs plan and the brain.

Full detail: **`docs/dev-log/after-task/2026-07-12-arc2a-mu-random-intercept.md`**.

## Key decisions & rationale

- **Intercept-only, ML-Laplace.** Scope is `(1 | g)` on `mu`; slopes (2b),
  `sigma`/shape/inflation REs (2c), and labelled blocks stay rejected. Evidence bar
  = DG2 (`point_fit_recovery`) + an honest small-cluster downward-bias caveat in
  NEWS; DG3 coverage deferred (pairs with Arc 1/REML). Grounded in NotebookLM
  search (`scratchpad/reml-aghq-synthesis.md`, `scratchpad/arc2a-notebooklm-synthesis.md`)
  + Qin/Mizuno/Morrison/Nakagawa marginal-R² Table 1.
- **cumulative_logit** identifiability: the ordered cutpoints ARE the intercepts
  (fixed intercept already dropped), so a zero-mean RE is identified — no aliasing.
  phylo + ordinary RE is rejected for now (guard added).
- **mu-RE + response masking** is a working combination (verified); the old
  missing-response "gate" tests were updated to assert acceptance.

## Gotchas / failed approaches (READ — saves hours)

The mu-RE path is only *partly* shared. A naive builder + C++ edit compiles but
**diverges with a NaN objective from a good start** — the signature of a
declared-but-unused random parameter. There are **four hidden per-family
allow-lists** that must ALL be extended:
1. `make_tmb_data` — three family blocks hardcoded `n_mu_re_terms = 0L` + dummy
   mu-RE arrays (the actual NaN root cause). `R/drmTMB.R` ~17627/17743/17801.
2. `check_drm` replication/design whitelist (`R/check.R:1233,1274`).
3. `split_tmb_random_effects` BLUP whitelist (`R/drmTMB.R:~18895`).
4. `split_tmb_sdpars` whitelist (`R/drmTMB.R:~18536`).
When adding a capability to a family, audit every allow-list, not just the builder
and the likelihood branch.

## Files created / modified (Arc 2a merge `966174c0..0ba88fd8`)

- Code: `R/drmTMB.R`, `R/check.R`, `src/drmTMB.cpp`
- Tests: `tests/testthat/test-arc2a-mu-random-intercept.R` (new) +
  `test-{tweedie-location-scale,skew-normal-location-scale,binomial-response,cumulative-logit,zero-one-beta,missing-response-boundary,missing-response-continuous}.R`
- Docs: `NEWS.md`, `docs/design/03-likelihoods.md`, `docs/design/04-random-effects.md`,
  `_pkgdown.yml`, `docs/dev-log/after-task/2026-07-12-arc2a-mu-random-intercept.md`
- Ledger: `docs/dev-log/dashboard/capability-ledger/{cells,evidence,transitions}.tsv`,
  regenerated `capability-census/*` + `capability-surface.{md,html}`,
  `tools/capability_ledger.py` (status-count guard 283/343/42 → 288/339/41)
- This handover: this doc + the `AGENTS.md` snapshot bullet.

## Next immediate steps (for you, next Claude)

1. **Confirm CI green on `main`**: `gh run list --branch main --limit 3` — the Arc 2a
   R-CMD-check and the follow-on pkgdown should both pass. If pkgdown is still red,
   read `gh run view <id> --log-failed`.
2. **tweedie fix-`p` escape hatch (carried over, NOT done).** The plan scoped a
   user-facing way to hold the Tweedie power `p` fixed (glmmTMB-style `map`); only
   the DG2 test fixes `p` internally. Small usability slice — pure R/TMB, needs a
   compile. Good first task.
3. Then by leverage: **Arc 4a** (validate existing intervals), **Arc 1a** (Gaussian
   REML structured parity), **Arc 2b** (one random slope per family) / **2c**
   (`sigma`-RE), and the **DG3** multi-seed recovery campaign on Totoro (deferred;
   needs MFA).

## Blockers / open questions

- None blocking. The DG3 coverage campaign needs Totoro MFA (external, human).
- The capability-surface **artifact** (mission-control, `claude.ai/code/artifact/a1bf21a1-...`)
  still shows the five families with "no RE" — it reflects pre-Arc-2a `main`. Refresh
  it to show `mu ✓ int` for the five when convenient (owner keeps updating this one).

## How to resume

**Rehydrate recipe (Claude):** read the `AGENTS.md` snapshot (top of file) + this doc
+ the after-task report + the candidate-arcs plan; spawn **Rose** (systems_auditor)
before any completion claim. Claude plans/refactors/writes prose and runs
logic/`--as-cran` checks locally (this Mac has the live R/TMB toolchain, so you CAN
compile — `devtools::load_all()` recompiles `src/`).

**One-command resume** (paste in your authenticated terminal, from the repo root):

```
claude "Rehydrate from docs/dev-log/handover/2026-07-12-arc2a-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps (confirm CI green, then the tweedie fix-p escape hatch)."
```

Autonomous, clean context:

```
claude -p "Rehydrate from docs/dev-log/handover/2026-07-12-arc2a-claude-handover.md + the AGENTS.md snapshot, then execute the Next Immediate Steps." --max-budget-usd 5
```
