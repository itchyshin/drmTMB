# Session Handoff: Q-Series 104/104 arc — M2 done (98/104), start M3 (q8)

Meta: 2026-07-05 · from Claude (Shannon) to Claude · context very high

You are Claude, picking up the **drmTMB Q-Series 104/104 completion arc** after M2
(q6 two-slope location admission). Read `AGENTS.md` first, then **the ultra-plan**
`docs/dev-log/2026-07-05-qseries-104-completion-ultra-plan.md`, then this file, then
the M2 after-task `docs/dev-log/after-task/2026-07-05-m2-q6-location-admission.md`
and the M1 verdict `docs/dev-log/after-task/2026-07-05-m1-highq-covariance-recovery-verdict.md`.

## Goal / mission (durable)

Complete the Q-Series structured-RE matrix to **104/104** as real,
recovery-gated capability. drmTMB is the finish-first R/TMB package. **Locked
decisions (Shinichi):** 104-bar = fit + recovery + STAN match (intervals =
per-row Fisher-gated follow-on, Phase 5); **q6 before q8** (done); Gaussian-8
first (→102/104) then the 2 non-Gaussian rows (→104); DRAC arrays + Totoro
authorized. Codex is out; the **Claude team drives the live R/TMB work** (Mac
R 4.6 env working).

## What M2 accomplished (this session) — 94 → 98/104

- **Admitted the four structured q6 two-slope location rows** (`(1 + x + z | p | id)`
  in mu1/mu2 for phylo/spatial/animal/relmat; 6 SDs + 15 correlations) at
  `point_fit`/`extractor_ready` on honest recovery evidence.
- **Parser/assembly admission, no C++** (`R/parse-formula.R` + `R/drmTMB.R`): a
  label-gated multi-slope branch routing the two-slope location block through the
  existing q-generic covariance machinery. Univariate + all-four multi-slope stay
  rejected. New test `tests/testthat/test-structured-re-q6-location.R` (55 asserts).
- **Recovery** (`docs/dev-log/simulation-artifacts/2026-07-05-m2-q6-recovery/`,
  streamed): **pdHess=TRUE + clean recovery at adequate n for all four providers**
  (phylo full curve rmse→0.058; spatial n=256 rmse 0.19; animal/relmat n=256
  rmse 0.072/0.055; no cap-saturation). q6 (15 corr) is well-identified, unlike q8.
- **4-lens gate:** Curie (recovery) · Noether (symbolic↔R↔TMB CONSISTENT) · Fisher
  (inference HONEST, +2 wording tightenings) · Rose (SIGN_OFF_WITH_CHANGES —
  caught a 4th generator I'd missed; fixed).
- **Status accounting** (all consistent, four gates green): support-cells → point_fit,
  regenerated ledger + release-status + release-check sidecars, claim-guard phrases,
  readiness-reset, closure-triage (high_q_planned→high_q_gate_required), high-q audit,
  mission-control validator (new `STRUCTURED_RE_Q6_RUNTIME_CELLS` allowlist), and the
  conversion-contracts test (22271 asserts).

## Current working state

- Branch `drmtmb/fix-family-conventions`; **draft PR #730** still open (unchanged).
- Uncommitted M2 changes in the working tree (R:2, dashboards:5, release-audits:6,
  tools:2, + new test + sim artifacts + after-task/check-log/design-218/NEWS/.gitignore).
  **Not yet committed** — the maintainer commits (global rule: commit only when asked).
- **Mission Control truth: 98/104 / 8/104 / 0/104 / 6/104** (was 94/8/0/10).

## Critical context — M3 (q8) is NOT a repeat of M2

**The parser already builds q8** (all-four one-slope `(1 + x | p | id)` on
mu1/mu2/sigma1/sigma2 → 8 SDs + 28 corr; M1 fit it). So M3 needs **no engine
change** — recovery-gating + a claims gate. **The catch:** M1 proved q8
**recovers but `pdHess=FALSE` persists even at 1024 groups** (genuine weak-ID of
the 28-corr Hessian; not iteration-capped; partial-Cholesky doesn't fix it).

⇒ **M3 is a judgment call the maintainer should own:**
- **(A) Admit-at-recovery-with-caveat** — arc-consistent (M1 doctrine: recover +
  no cap-saturation + profile/bootstrap inference *is* the bar). Reaches 102/104
  with an explicit `pdHess=FALSE`/stability caveat; the 28 correlations route
  through **parallel profile (primary) + bootstrap (fallback); ELR excluded**.
  **Recommended.** Fisher owns the stability honesty; Rose owns the accounting and
  the tension with the existing `q8_stability_blocked` closure bucket (5 rows).
- **(B) Resolve `pdHess=TRUE` first** via reduced-rank factor-analytic (glmmTMB
  `rr()` / Meyer-WOMBAT) — a real C++/parser/methods arc, weeks not days, blocks
  the headline. Defer this to its own arc.

## Next immediate steps

1. Rehydrate: `git status`; read AGENTS.md + ultra-plan + M2 after-task + M1 verdict.
2. Confirm q8 parses/builds for all four providers (it should — reuse the M1 q8
   sim pattern; `…/2026-07-05-m1-highq-recovery/00-helpers.R` has the q8 DGP).
3. Run a q8 recovery-vs-n ladder per provider (STREAMING, fast-first, per-fit flush;
   SEQUENTIAL — do NOT share one TSV across concurrent R jobs, they lose rows).
   Document rmse-vs-n + the persistent `pdHess=FALSE`. Reuse the M2 helper pattern
   (`…/2026-07-05-m2-q6-recovery/`) generalized to q8 (8 endpoints, 28 corr).
4. 4-lens gate. Then, IF admitting (option A), the accounting move mirrors M2 but is
   heavier (28 corr, stability caveat). **Regenerate BOTH generators** and run **all
   four gates + the conversion-contracts test** (see the M2 lesson below).

## Gotchas & doctrine (carried from M1/M2)

- **Data-size rule:** correct non-convergence on a small fixture is
  data-insufficiency, not engine failure. Size gates to the model.
- **Streaming-sim discipline:** stream+flush per fit, cheapest fit first, heartbeat
  to a `.log`, time one fit before scaling. **Never share one results TSV across
  concurrent R jobs** (R `cat(append=TRUE)` isn't concurrency-safe — rows are lost).
- **Never let a sim's truth touch the global RNG** when it's a default arg (it
  silently defeats multi-seed replication — M2 bug).
- **Status accounting has TWO generators.** A q-series status move must regenerate
  `qseries_v1_release_ledger.py` (--write --write-status) **AND**
  `qseries_v1_release_check.py` (--write-report --write-candidates), then run **all
  four** gates (mission-control, ledger --check --check-status, claim-guard,
  release-check --check-report --check-candidates) **AND**
  `test-structured-re-conversion-contracts.R` (it pins the generated counts +
  candidate list). Partial regeneration passes three gates and looks complete —
  it isn't. (The repo is under Dropbox; ignore transient gate FAILs in tight loops
  — re-check individually.)
- Run R with `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript --no-init-file`.
- Do NOT rewrite the covariance engine (M1: it's q-generic). Do NOT use ELR for
  correlation CIs. Keep Julia optional. Spawn Rose before any status/dashboard claim.
- q8 admission (option A) is recovery-only: no intervals, coverage, STAN, REML,
  AI-REML, bridge, or supported. The `q8_stability_blocked` closure bucket (5 rows)
  and its relationship to admitting q8 rows is a Rose/maintainer decision.

## Mission Control

| Area | State | Meaning |
| --- | --- | --- |
| Repo / branch | `drmTMB` @ `drmtmb/fix-family-conventions` | draft PR #730 open; M2 uncommitted |
| Arc plan | `docs/dev-log/2026-07-05-qseries-104-completion-ultra-plan.md` | phases/team/models/compute |
| M1 (engine) | DONE — engine q-generic, no build | q4 clean; q8 recover+profile |
| M2 (q6) | **DONE** — 4 rows admitted, 98/104 | parser + recovery + 4-lens gate |
| M3 (next) | q8 admitted (4 providers, recovery) | parser already builds it; pdHess=FALSE caveat; option A vs B decision |
| Practical surface | **98/104** (94.2%) | +4 q6 rows |
| Compute | DRAC arrays + Totoro authorized | recovery at Santi-scale n |

## How to resume

From the repo root in an authenticated terminal:
```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-05-claude-m2-to-m3-handover.md + the AGENTS.md snapshot + the ultra-plan, then start M3 (q8 admission)."
```
Then set the M3 goal (paste as `/goal`):
```
Reach M3 of the drmTMB 104/104 arc: admit the four q8 all-four one-slope rows (phylo/spatial/animal/relmat) on honest fit + recovery evidence at Santi-scale, taking the Gaussian surface to 102/104. The parser already builds q8 — this is recovery-gating + claim-honesty, not engine work. pdHess=FALSE persists for q8 (genuine weak-ID, not failure): document it explicitly, route the 28 derived correlations through parallel profile/bootstrap (ELR excluded), and admit with a stability caveat. Defer the reduced-rank factor-analytic estimator (the pdHess=TRUE fix) to its own arc. Gate with Curie/Noether/Fisher/Rose — Fisher owns the pdHess/stability honesty, Rose owns the 102/104 accounting and the q8_stability_blocked question. Do not inflate coverage/support/STAN wording.
```

Spawn Rose before any status/dashboard claim; Curie owns the recovery sims (streaming, sequential!).
