# Next arcs — a 1–2 day Codex campaign (ultra-plan)

> **Execution update, 2026-07-13.** The approved Codex ultra-plan superseded the original
> sequential outline below. A0 is repaired and tested. The original centered-effect Arc 4a
> campaign was invalid for population-SD coverage; its promotion evidence is withdrawn and
> replaced by the iid-un­centered 14,400-fit campaign in
> `simulation-artifacts/2026-07-12-dg3-re-sd-coverage/README-profile-iid-v2.md`. Fresh D-43 review
> supports `mc-0382` and `mc-0061` at `inference_ready_with_caveats` over discrete tested domains,
> never `interval_feasible`. Task B used TMB 1.9.21 adaptive marginal Gauss-Kronrod, not AGHQ, and
> returned a negative/inconclusive gate; see
> `simulation-artifacts/2026-07-13-marginal-gk-probe/README.md`. Task C (Arc 1a) is now
> implemented and campaign-verified on its dedicated branch. Final
> package/site verification, Rose review, branch landing, and the external Claude mirror remain
> pending.

Status at authorship: **PLAN for Codex.** Sequences the concrete, de-risked next work after Arc 2b/2c +
the Arc 4a profile-coverage evidence. Grounded in the 5-agent design workflow (`wf_d42c1616-6a3`),
the Arc 4a S4 review disposition (`2026-07-13-arc4a-profile-interval-plan.md`), and today's
Laplace-vs-AGHQ + DG3 coverage findings. **Routed to Codex because every task needs the live
R/TMB toolchain** — real fits, `pkgload::load_all` / `R CMD INSTALL` compiles, `R CMD check`,
and Totoro campaigns. Claude planned; Codex executes; Claude reviews the diff.

## Live-environment facts Codex must know

- **Totoro** (`snakagaw@totoro.biology.ualberta.ca`) is reachable, **no MFA**, 384 cores —
  cap at ≤ 90, `OPENBLAS_NUM_THREADS=1`. drmTMB `0.6.0.9000` is installed in `~/Rlib` from
  `main`; **reinstall from a fresh `main` clone** before campaigns (`~/drmTMB_work/`). **DRAC is
  NOT reachable from the agent env** (TCP timeout). Harnesses already there:
  `~/drmTMB_work/generate.R` (Wald DG3), `/tmp/generate-profile.R` (profile DG3).
- The installed *default* library can be stale — always `pkgload::load_all()` from source.

## Task A — Arc 4a completion (~half day). FULLY specified by the S4 review.

**A0 — fix the shipped bug FIRST (blocks A2).** `has_sigma_random_effects()`
(`R/methods.R:5294-5298`) gates on gaussian/biv_gaussian/nbinom2 and **omits lognormal/Gamma**,
so `predict(fit, dpar="sigma")` (`R/methods.R:2726-2732`) silently drops the σ-BLUP for the
Arc-2c sigma-RE, and the emmeans block (`R/emmeans-preflight.R:243`) doesn't fire. Add
lognormal + Gamma; add a test that `predict(dpar="sigma")` includes the σ-BLUP for a fitted
`sigma ~ (1|id)` model. Compile + test. [live]

**A1 — re-scope the promotion to the CORRECT tier.** The Arc-4a coverage evidence is
`inference_ready_with_caveats`-grade, **NOT** `interval_feasible` (that tier means "interval
computes, no coverage"; two independent reviewers + precedent mc-0276/mc-0153 agree). Decide:
promote `mc-0382` (lognormal, M≥16) and `mc-0061` (binomial, M≥32) to
`inference_ready_with_caveats`, or leave `point_fit_recovery` if the sub-nominal coverage
(0.917 / 0.943) is judged below that tier's bar. Run the **Noether/math lens** (not yet run) +
re-confirm Fisher/Rose (D-43, ≥2 NOT-DONE withholds).

**A2 — execute the ledger edit (schema-correct).** `coverage_status` does NOT exist in
`cells.tsv`; the caveat lives in `claim_boundary`. Rewrite `next_gate` / `claim_boundary` /
`primary_evidence_id` on `cells.tsv:62,383`; add `ev-mc-*-arc4a` rows to `evidence.tsv`
(path → the Arc-4a artifact) + `verified→verified` `transitions.tsv` rows. Claim_boundary must
lead with the worst-in-range number (lognormal **0.917**), say "Monte-Carlo-coverage-backed
unlike interval_feasible's other cells", name the single fixture, and name the residual lever
(REML Gaussian / AGHQ non-Gaussian). `tools/capability_ledger.py --write` + `--check`; refresh
the `a1bf21a1` artifact. After-task report.

## Task B — de-risk the hard lever: AGHQ Slice 0 (~2-4h, isolated). Do this before any drmTMB edit.

The demonstrated payoff (Laplace RE-SD −23% at n=2 vs AGHQ +2%) makes AGHQ the marquee lever,
but the TMB `integrate=` machinery is undocumented. **Slice 0 is a standalone probe, no drmTMB
changes:** a tiny binomial random-intercept TMB template, fit once via ordinary `random=`
Laplace and once via `integrate=list(u=list(method="marginal_gk"))`, checked against
`lme4::glmer(nAGQ=25)` on the exact n=2 cell from `scratchpad/laplace_vs_aghq.R`. If it
reproduces AGHQ's ≈unbiased SD, the mechanism is proven and Slice 1 (wire `integrate=` into
`drm_fit_spec` for binomial `model_type==18`, intercept-only) is greenlit; if not, AGHQ stays
deferred and REML (Task C) is the whole of day 2. [live]

## Task C — REML Arc 1a (implemented and evidence-backed on 2026-07-13)

Gaussian/biv-Gaussian REML→ML parity (roadmap Arc 1a/1b) is the finite-M/df-bias remedy — the
Gaussian half of today's DG3 coverage gap. Established C1 recipe
(`docs/dev-log/after-task/2026-07-08-c1-reml-scale-structured-unlock.md`): gate relaxation +
focused reference test + Totoro recovery (N≈300-400) + Totoro coverage (N≈300) + Noether review.
**Do one self-contained slice**, recommended **Slice 2 — univariate mean-side
`spatial()/animal()/relmat()` REML admission** (relax `R/drmTMB.R:2072-2077`; deterministic
exact-restricted-likelihood reference test mirroring `test-reml-phylo-location`). [live]

Execution used the stricter approved Arc 1a ultra-plan: independent dense
restricted-likelihood oracles, representation-parity and rejection guards,
11,200 recovery fits, 14,000 coverage fits with 21,000 target profiles, and
fresh Noether/Fisher/Pat D-43 review. The three provider cells reach no higher
than `inference_ready_with_caveats`; see
`simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/README.md`.

## Sequencing & estimate

- **Day 1:** Task A0+A1+A2 (Arc 4a completion, fully specified) → then Task B Slice 0 (AGHQ probe).
- **Day 2:** fork on B's result — AGHQ Slice 1 (binomial `integrate=`) if the probe passed, and/or
  Task C REML Slice 2 (always safe, R-only). Each closes with DG2/DG3 evidence + Noether + a fresh
  D-43 NOT-DONE review before any ledger/tier claim, and an after-task report.
- **Discipline every task:** symbolic/interface first → per-family DG2/DG3 evidence (reuse the
  Totoro harnesses) → honest-scope docs → adversarial NOT-DONE review (≥2 NOT-DONE withholds) →
  ledger `--write`/`--check` → refresh the `a1bf21a1` artifact (Shinichi values the live surface).

## Full scopings

Design workflow `wf_d42c1616-6a3` (journal in the session subagents dir) — the four levers
(profile-interval, AGHQ, REML, 2c-student/beta) with per-lever feasibility/effort/risk/decomp.
