# Session Handoff: Arc 4a closeout and capability-artifact mirror

Meta: 2026-07-13 · from Codex to Claude · branch
`feature/arc4a-profile-coverage` · PR #779

You are Claude Code, picking up a verified drmTMB Arc 4a closeout. The local R/TMB,
campaign, ledger, site, and review work is complete. Your bounded next job is to
mirror the tracked capability HTML into Claude artifact `a1bf21a1`, verify that
the mirror matches the canonical file, and leave merge to Shinichi.

## Critical Context

1. The canonical capability surface is
   `docs/dev-log/dashboard/capability-surface.html`, SHA-256
   `225272ea0abdc5eb89893c5f7462b59fcaae3ee1880b7af45d2cad02aa5d1f47`, from
   implementation commit `2806f00b7b64204ef98e65f0c9eb6515257bbeeb`. The
   external Claude artifact `a1bf21a1` is **pending**, not refreshed.
2. `mc-0382` and `mc-0061` are only
   `inference_ready_with_caveats` over their exact discrete ledger domains.
   They are not `interval_feasible`, `supported`, nominal, or general `M >= ...`
   claims. Lognormal/Gamma `mu` and `sigma` random-effect routes are separate and
   cannot be combined.
3. The isolated TMB 1.9.21 adaptive marginal Gauss-Kronrod probe is
   negative/inconclusive. Do not wire it into the package or call it AGHQ. Task C,
   package AGHQ integration, broader bias/recovery work, and merge are deferred.

## Goals and Mission

drmTMB remains the primary R/TMB package. This arc repaired sigma-scale
prediction, replaced invalid centered-effect coverage evidence with an iid
uncentered campaign, made the capability surface live-ledger-derived, and tested
whether TMB's marginal integration mechanism reproduced a high-accuracy direct
oracle on one frozen binomial random-intercept fixture.

The remaining mission is publication synchronization only: mirror the exact
tracked HTML to Claude's external artifact without changing its claims.

## What Was Accomplished

- Repaired `has_sigma_random_effects()` for lognormal and Gamma and added fitted
  link/response/newdata, `sigma()`, print, and emmeans-preflight regressions.
- Demonstrated 10 expected test-of-test failures on clean pre-fix `HEAD`; the
  repaired focused file passes 52 assertions.
- Withdrew centered-v1 promotion evidence and ran 14,400 iid-uncentered Totoro
  profiles across 12 cells using 64 workers and `OPENBLAS_NUM_THREADS=1`, with
  14,400 finite profiles and zero failures.
- Fresh Noether/Fisher/Pat D-43 review unanimously admitted only:
  - `mc-0382`: lognormal sigma random intercept, true SD 0.4, `n_each=12`,
    `M={16,32,64}`;
  - `mc-0061`: independent binomial mu slope, true SD 0.6, 12 observations per
    group, 12 trials per observation, `M={32,64}`.
- Repaired the capability generator, appended schema-correct evidence and
  transitions, regenerated 30 outputs, and linked primary evidence directly to
  `README-profile-iid-v2.md` rather than the mixed v1/v2 directory.
- Built the standalone TMB marginal-GK probe. Its normalized GK/direct gap is
  about `1.068e-9`, versus a propagated direct numerical-error estimate of about
  `2.984e-10`; all fitted SD optima are boundary-singular. No package wiring was
  added.
- Repaired current-facing documentation drift across README, ROADMAP, family
  registry, readiness/evidence maps, known limitations, and five pkgdown
  articles. Rose caught and removed unsupported combined lognormal/Gamma
  `mu`+`sigma` examples.
- Rose's final repaired-tree audit returned DONE.

## Current Working State

- Working: implementation commit `2806f00b7b64204ef98e65f0c9eb6515257bbeeb`
  is pushed on `origin/feature/arc4a-profile-coverage`; PR #779 is open.
- In progress: external Claude artifact `a1bf21a1` still needs the canonical
  tracked HTML imported and visually/read-back verified.
- Not working / blocked: TMB marginal-GK did not meet the direct-oracle gate on
  the frozen fixture and is intentionally not integrated.

## Key Decisions and Rationale

- Population-SD coverage uses iid uncentered simulated effects. Mean-centering
  changes the estimand and invalidated v1 as promotion evidence.
- Caveated promotion is cell- and domain-specific. Measured coverage is mildly
  anti-conservative rather than certified nominal.
- Binomial's promoted claim is coverage-backed, not evidence that profiling
  improves the interval.
- Numerical integration error is propagated onto the negative-log-likelihood
  and normalized-objective scale and called an estimate, not a guaranteed bound.
- The external artifact is a mirror; the tracked ledger-derived HTML is source
  truth.

## Landing State

The required handoff gate was run after implementation commit/push. It exited 1
because this long-lived checkout contains 31 pre-existing user-owned untracked
paths and 355 commits on unrelated legacy local branches. The active Arc 4a
branch itself had no unpushed commit: local and origin both resolved to
`2806f00b7b64204ef98e65f0c9eb6515257bbeeb`. Those unrelated states are declared
below and were not altered.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `drmTMB` `feature/arc4a-profile-coverage` implementation `2806f00b` | yes | yes | #779 open | LANDED |
| This handoff plus refreshed `AGENTS.md` pointer | yes, in containing commit | yes, in containing commit | #779 open | LANDED |
| Pre-existing untracked after-task draft, five shard logs, and `scratchpad/` files | no | no | none | CARRIED-OVER — protected user state, outside Arc 4a; resume with `git status --short` and do not stage or delete |
| Unrelated legacy local branches reported by `handoff_gate.sh` | mixed | no on 355 commits | unrelated | CARRIED-OVER — pre-existing repository estate, outside Arc 4a; inspect only with `git log --oneline --branches --not --remotes` if Shinichi opens a separate cleanup task |

## Verification Evidence

- Focused Arc 2c file: 52 assertions passed.
- Corrected campaign: 14,400/14,400 finite; zero fit, convergence, Hessian,
  profile, or finite-bound failures.
- Capability generator: 13 tests passed; 30/30 generated outputs current.
- Runtime oracle: 18 verified routes; G0=G1=G2=0.
- Full `devtools::test()`: zero failures, 62 known warnings, 24 unavailable-Julia
  skips.
- Genuine `--as-cran`: 0 errors, 0 warnings, one expected development/new-
  submission NOTE.
- Full pkgdown build/check plus post-Rose article rebuild/check: no problems.
- Rendered read-back verified the separate/cannot-combine boundary across
  formula, distribution-family, source, implementation, and model-map pages.
- After-task validator and `git diff --check`: passed.
- Rose: DONE.

Full evidence and exact counts are in
`docs/dev-log/after-task/2026-07-13-arc4a-closeout-and-marginal-gk-probe.md`.

## Files Created / Modified

Implementation commit `2806f00b` contains every path below:

- `AGENTS.md`
- `NEWS.md`
- `R/methods.R`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/195-binomial-docs-polish.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/design/79-supported-nongaussian-evidence-goal.md`
- `docs/dev-log/2026-07-13-arc4a-profile-interval-plan.md`
- `docs/dev-log/2026-07-13-next-arcs-codex-campaign-plan.md`
- `docs/dev-log/after-task/2026-07-13-arc4a-closeout-and-marginal-gk-probe.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/capability-census/_master.tsv`
- `docs/dev-log/dashboard/capability-census/_widget_data.json`
- `docs/dev-log/dashboard/capability-census/binomial.tsv`
- `docs/dev-log/dashboard/capability-census/cumulative_logit.tsv`
- `docs/dev-log/dashboard/capability-census/lognormal.tsv`
- `docs/dev-log/dashboard/capability-census/skew_normal.tsv`
- `docs/dev-log/dashboard/capability-census/tweedie.tsv`
- `docs/dev-log/dashboard/capability-census/zero_one_beta.tsv`
- `docs/dev-log/dashboard/capability-ledger/cells.tsv`
- `docs/dev-log/dashboard/capability-ledger/evidence.tsv`
- `docs/dev-log/dashboard/capability-ledger/transitions.tsv`
- `docs/dev-log/dashboard/capability-surface.html`
- `docs/dev-log/dashboard/capability-surface.md`
- `docs/dev-log/dashboard/estimator-surface-conformance.tsv`
- `docs/dev-log/handover/2026-07-13-codex-handover.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/README-profile-iid-v2.md`
- `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/README-profile.md`
- `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/generate-profile.R`
- `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/profile-coverage-iid-v2-campaign.log`
- `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/profile-coverage-results-iid-v2-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/profile-coverage-results-iid-v2-raw.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/profile-coverage-results-iid-v2-summary.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-13-marginal-gk-probe/README.md`
- `docs/dev-log/simulation-artifacts/2026-07-13-marginal-gk-probe/best-fits.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-13-marginal-gk-probe/binomial_ri.cpp`
- `docs/dev-log/simulation-artifacts/2026-07-13-marginal-gk-probe/fit-results.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-13-marginal-gk-probe/fixture.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-13-marginal-gk-probe/manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-13-marginal-gk-probe/objective-grid.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-13-marginal-gk-probe/run-probe.R`
- `docs/dev-log/team-improvements.md`
- `tests/testthat/test-arc2c-sigma-random-intercept.R`
- `tools/capability_ledger.py`
- `tools/tests/test_capability_ledger.py`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/implementation-map.Rmd`
- `vignettes/includes/capability-ledger-family-map.md`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`

This handoff commit additionally contains:

- `docs/dev-log/handover/2026-07-13-arc4a-claude-handover.md`
- `AGENTS.md` (snapshot pointer refresh)

## Mission Control

| Repo | Branch / PR | Verification | What shipped | Next by leverage |
| --- | --- | --- | --- | --- |
| drmTMB | `feature/arc4a-profile-coverage`; PR #779 open into `main` | full test, `--as-cran`, pkgdown, ledger/runtime, D-43, Noether, Rose all green | A0 prediction repair; iid-v2 14,400-fit evidence; two exact caveated promotions; live capability surface; negative marginal-GK probe | Mirror canonical HTML to Claude artifact `a1bf21a1`; verify hash/content; leave merge to Shinichi |

## Next Immediate Steps

1. Check out `feature/arc4a-profile-coverage` and read `AGENTS.md`, this handoff,
   the after-task report, and the campaign plan.
2. Open the tracked
   `docs/dev-log/dashboard/capability-surface.html`; verify SHA-256
   `225272ea0abdc5eb89893c5f7462b59fcaae3ee1880b7af45d2cad02aa5d1f47`.
3. Import that exact HTML into Claude artifact
   `a1bf21a1-8c5a-495e-b0ee-1b91608a5ca2`. Do not edit claims in the external
   mirror. Read back the two promoted cells, aggregate counts, and separate
   lognormal/Gamma routes.
4. Report the external mirror refreshed only after that read-back succeeds.
5. Do not merge PR #779 without separate Shinichi approval. Do not start Task C
   or package marginal-integration wiring from this handoff.

## Blockers / Open Questions

- Claude artifact editing requires Claude's authenticated artifact surface; it
  cannot be completed from this Codex session.
- The marginal-GK mechanism needs a new, identified fixture and a newly approved
  plan before any package-integration work.

## Gotchas and Failed Approaches

- Never reuse the centered-v1 profile results for promotion. Centering simulated
  random effects changes the finite-sample SD estimand.
- Do not point evidence at the mixed v1/v2 directory. Use
  `README-profile-iid-v2.md` or the exact iid-v2 summary/raw artifact.
- Do not show lognormal/Gamma `mu` and `sigma` random effects in the same fitted
  formula; tests explicitly reject that combination.
- Do not call TMB's tested method AGHQ. It is adaptive marginal
  Gauss-Kronrod integration.
- `stats::integrate()` reports a numerical error estimate, not a guaranteed
  bound; propagate it to objective scale before comparing normalized objectives.
- The checkout contains protected untracked user work and many unrelated legacy
  branches. Never use `git add -A`, delete the untracked files, or clean branches
  as part of this handoff.

## How to Resume

From the drmTMB repository root, Shinichi can start a fresh authenticated Claude
session with:

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-13-arc4a-claude-handover.md + the AGENTS.md snapshot, then mirror the canonical capability-surface HTML into artifact a1bf21a1 and verify the exact hash/content. Do not merge or start deferred work."
```

To regenerate the canonical surface before comparing, use:

```sh
python3 tools/capability_ledger.py --write && python3 tools/capability_ledger.py --check
```
