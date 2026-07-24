# Handover — Arc 6 direct `rho12` evidence landed; staged-eta bootstrap is next → Codex

**From:** Codex  
**To:** Codex  
**Date:** 2026-07-24  
**Landing at handover:** `main` = `d0ac907f` (`docs: namespace Arc 6 vignette calls`); GitHub Actions R-CMD-check run [30126489352](https://github.com/itchyshin/drmTMB/actions/runs/30126489352) passed.

## Critical context

The requested direct-association evidence package is complete and landed. It
supports scientifically qualified reporting of a *constant*, direct
`biv_lognormal()` log-residual correlation `rho12`, under the exact tested
fixed-effect design. The current staged `associate_pairs()` Bernoulli x NB2
association `eta` remains a different, frozen-margin estimand and has **no**
standard error, Wald interval, profile, or confidence-interval claim.

The next lane is therefore a new, plan-first staged-eta full-refit-bootstrap
lane. Do not treat it as a continuation or generalisation of the direct
lognormal evidence.

## What landed

The direct interval implementation and evidence were landed on `main` through
these commits:

- `be762770` — guarded atanh-link Wald, direct-likelihood profile, and joint
  parametric-bootstrap interval support for direct lognormal `rho12`.
- `1e5bd429` — immutable retained-attempts coverage ladder and tests.
- `73f85c7a` — campaign result, open-data tutorial, design/limitations/docs,
  independent review record, and staged-eta follow-up design.
- `54c9c7e2` — installed-package test-path repair.
- `d0ac907f` — namespace-qualified executable vignette calls; this repaired
  the final installed-vignette CI boundary.

Totoro ran the exact `1e5bd429` source at 90 outer workers with
`OPENBLAS_NUM_THREADS=1`: 300 outer attempts in each of the nine cells
(`n = 100, 300, 1000` by true `rho12 = 0, 0.5, 0.85`) and 199 full joint
simulation/refit bootstrap attempts per outer fit. That is 2,700 outer fits
and 537,300 bootstrap refits. The compact result, manifest, hashes, and
failure accounting are tracked at
`docs/dev-log/simulation-artifacts/2026-07-24-biv-lognormal-rho12-totoro-coverage/`;
the 117 MB all-attempt ledgers deliberately remain local and on Totoro.

Profile likelihood passed its predeclared gate at every `n >= 300` cell. It is
the primary interval only for this tested direct likelihood/domain. Wald and
the joint bootstrap were calibrated comparators, not substitutes for profile
diagnostics. The all-attempt record includes one outer false convergence at
`n = 1000`, `rho12 = 0.85`; two endpoint-profile re-optimisation failures in
the same cell; and 278/537,300 non-converged bootstrap refits (0.052%). None
were discarded.

`vignettes/bivariate-nongaussian.Rmd` now contains the audited open-data
Palmer Penguins example (333 complete positive pairs): biological question,
log-residual rather than raw-scale interpretation, marginal patterns, all
three interval routes, and diagnostics. Its 43/99 successful real-data
bootstrap draws are printed as a diagnostic, not concealed as a reliable
interval. The raw scatter is descriptive: raw-scale correlation is neither
direct `rho12` nor staged `eta`.

## Why direct profile, Wald, and bootstrap differ from staged eta

For direct `biv_lognormal()`, `rho12` is a parameter of the exact joint
likelihood. A profile re-optimizes that likelihood, which is why profile is
the package's preferred reporting route here. Link-scale Wald is a fast local
curvature approximation and the joint parametric bootstrap is a robustness and
failure diagnostic; all three were tested together.

For staged `associate_pairs()`, the association stage conditions on independently
estimated margins. Its stage-2 Hessian describes conditional curvature,
`I(alpha alpha | fitted margins)`, and omits margin uncertainty and cross-stage
covariance. A conditional Wald SE and a profile of that conditional objective
would therefore misstate uncertainty. The valid near-term route is a
**full-refit parametric bootstrap**: simulate paired outcomes, refit both
margins from scratch, then refit `eta` in every replicate. A later
stacked-score Godambe/sandwich estimator could earn an SE/Wald route only after
derivation and coverage validation; a true profile would require a genuine
joint likelihood and therefore a different estimator architecture.

## Current state and boundaries

| State | Scope |
| --- | --- |
| Working and landed | Exact direct fixed-effect `biv_lognormal()` constant `rho12`: guarded Wald, direct profile, joint bootstrap, calibrated n-ladder, and penguin tutorial. |
| Plan only | Fixed-effect literal-Bernoulli x ordinary-NB2 staged `eta` full-refit bootstrap. |
| Explicitly deferred | `biv_student()` intervals; all current staged `eta` SE/CI/profile claims; generic cross-family pairs; random effects, missingness, weights, offsets, REML, and association-predictor expansion beyond the reviewed Bernoulli x NB2 slope. |

The next lane's immutable proposal is
`docs/design/240-arc6-staged-eta-uncertainty-followup.md`: fixed covariates;
refit both margins and association in every bootstrap replicate; 399 attempted
replicates with at least 380 resolved associations for interval availability;
plain percentile intervals on link coefficients; transformed summaries only at
predeclared `x = -1, 0, 1`. Its first feasibility/recovery grid is 24 cells:
`n = 120, 240, 480`, two Bernoulli prevalences, two NB2 dispersions, and two
association settings. This is DRAC-scale after a non-empty smoke and a fresh
compute approval; never GitHub Actions.

## Landing state

The handoff gate was run before this document was written:

```text
XX drmtmb-arc6-ci-path-fix codex/arc6-ci-path-fix 3 UNPUSHED on other branch(es)
   + a3d58b2e docs: plan Arc 6 execution through integration
   + de87ffe2 docs: plan Arc 6.6 Bernoulli NB2 association
   + c018908a docs: close pkgdown reader-surface audit
   ^ branch codex/arc6-6-bernoulli-nb2-plan has 2 unpushed
```

Those commits are foreign planning/docs lanes, not unlanded direct-evidence
work. Do not stage, amend, push, merge, or otherwise attribute them from the
staged-eta lane.

| Artifact / branch | State |
| --- | --- |
| `main` at `d0ac907f` | LANDED: direct association evidence and CI repair are committed, pushed, and CI-green. |
| `handover/2026-07-24-codex-staged-eta` | This handover-only branch; commit, push, and review PR are the remaining mechanical closure steps. |
| `codex/arc6-6-bernoulli-nb2-plan` | CARRIED-OVER, foreign/unpushed planning branch; do not touch. |
| `c018908a` pkgdown audit | CARRIED-OVER, foreign/unpushed documentation lane; do not touch. |
| `claude/handover-freshness-0718` | Separate AGHQ/non-Gaussian REML lane; do not touch from Arc 6. |

## Next immediate steps

1. Start a fresh Codex task from current `main`, read `AGENTS.md`, this
   handover, the direct after-task report, the direct results README, and
   `docs/design/240-arc6-staged-eta-uncertainty-followup.md`.
2. The user invoked `$ultra-plan`. Switch the next task to Plan mode and run
   only orientation and the bounded Phase 0–2 research/reconciliation work:
   brain/context receipt, branch/worktree sweep, model-contract/oracle audit,
   and grounded data/literature audit. Do **not** implement staged inference,
   run a smoke, or request compute before presenting the plan and receiving
   fresh approval.
3. Make the plan explicitly distinguish direct `rho12` from frozen-margin
   `eta`; require symbolic alignment, an independent oracle, retained-all-
   attempts policy, an n-ladder, Fisher/Noether/Rose review, and an M2 D-80
   lane receipt.
4. Once implementation is approved, request compute approval before a
   non-empty local smoke. After inspection, use DRAC for the replicated grid;
   preserve every failed margin, association, and bootstrap replicate.

## Rehydration recipe

Codex owns live R/TMB fits, tests, rendering, and any approved Totoro/DRAC
execution. Planning-side research/review may be delegated, but Rose is
mandatory before a public claim. Read native `AGENTS.md` first and use the
launchable reviewers in `.codex/agents/` as bounded reviewers rather than
continuous background work.

Use the stable R invocation because the user R profile can select an
incompatible library:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::load_all(quiet = TRUE)'
```

Paste this into the fresh Codex task:

```text
Rehydrate from docs/dev-log/handover/2026-07-24-codex-staged-eta-handover.md
and the newest AGENTS.md snapshot. Read docs/design/240-arc6-staged-eta-
uncertainty-followup.md, docs/dev-log/after-task/2026-07-24-arc6-direct-
lognormal-rho12-coverage.md, and the direct result README. Then enter Plan
mode and execute only Ultra Plan Phases 0–2 for the staged Bernoulli x NB2
full-refit-bootstrap lane. Do not implement, run a smoke, or request compute
until Shinichi approves the plan.
```

Automatic creation of a fresh Codex task is unavailable in this context; the
pasteable prompt above is the complete resume entry point.
