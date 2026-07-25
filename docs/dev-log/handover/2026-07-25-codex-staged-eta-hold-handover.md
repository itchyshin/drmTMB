# Session Handoff: staged-eta bootstrap hold

Meta: 2026-07-25 · from Codex · to Codex · status: decision-review continuation, not compute

## Critical Context

The staged Bernoulli × ordinary-NB2 `associate_pairs()` route estimates a
two-stage frozen-margin association link, eta. It has a narrow fixed-effect
point-estimation/diagnostic claim only. Its stage-2 curvature is conditional
on fitted margins and therefore cannot be called an eta SE or used for Wald or
profile intervals.

The 24-cell full-refit-bootstrap campaign is stopped. Do not resume it,
aggregate its partial outputs, or expose an interval API. A future uncertainty
project needs a new product-level decision and a cost-calibrated plan first.

## Goals and Direction

The package's immediate objective is an honest bivariate association surface,
not maximal feature breadth. The direct fixed-effect `biv_lognormal()` rho12
inference campaign is complete and separate. For staged eta, first decide
whether a public uncertainty interface is needed at all. If it is, compare a
valid two-stage variance method with a narrowly targeted bootstrap feasibility
pilot before authorizing coverage work.

## What Was Accomplished

- Implemented developer-only full-refit bootstrap infrastructure, an
  independent Bernoulli × NB2 DGP oracle, a guarded runner, retained ledgers,
  and focused tests (20 staged-bootstrap and 69 existing Bernoulli × NB2
  expectations pass in the final local check).
- Ran a tiny schema smoke only; it is not recovery or calibration evidence.
- Launched then stopped the over-scaled full campaign. At stop, 284 Totoro and
  513 Fir outer-result CSV shards existed. They are preserved as provenance
  only and must not be aggregated or interpreted.
- Recorded the stop in the design handoff, simulation contract, ultra-plan,
  check log, and after-task report.

## Current Working State

- Working: staged eta point estimates for the reviewed fixed-effect literal
  Bernoulli × ordinary-NB2 route, including the numeric `association = ~ x`
  extension.
- On hold: developer-only bootstrap helper, runner, DRAC worker, aggregator,
  and their tests. They are unmerged and confer no public capability.
- Stopped: Totoro runners and dispatchers; Fir recovery job; recurring monitor.
- Not working / unsupported: staged-eta SEs, Wald intervals, profiles,
  `confint()`, recovery, availability, and coverage claims.

## Key Decisions and Rationale

The original grid is 24 cells × 200 outer datasets × 399 full refits, or about
1.9 million bootstrap refits. That cost is disproportionate to an uncommitted
developer-only feature. Do not attempt to salvage the partial outputs: an
incomplete all-attempt denominator cannot support an inference claim.

The direct `biv_lognormal()` rho12 route remains complete; it is an exact joint
likelihood and must not be generalized to staged eta.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/staged-eta-bootstrap-hold` (current local tip) | yes | no | none | CARRIED-OVER |

This is a deliberately local hold branch so that the next Codex session can
inspect the implementation and decide its disposition. Do not merge or push it
as package capability. Resume locally with `git switch codex/staged-eta-bootstrap-hold`.

## Files Created / Modified

- `R/associate-pairs.R`
- `R/associate-pairs-bootstrap.R`
- `tests/testthat/test-associate-pairs-staged-bootstrap.R`
- `inst/sim/run/sim_run_staged_eta_bernoulli_nbinom2_bootstrap.R`
- `tools/slurm/staged-eta-full-refit-bootstrap-fir.sbatch`
- `tools/summarize-staged-eta-full-refit-bootstrap.R`
- `docs/design/239-bernoulli-nbinom2-association-regression.md`
- `docs/design/240-arc6-staged-eta-uncertainty-followup.md`
- `docs/dev-log/2026-07-24-staged-eta-full-refit-bootstrap-ultra-plan.md`
- `docs/dev-log/simulation-designs/2026-07-24-staged-eta-full-refit-bootstrap/README.md`
- `docs/dev-log/smoke/2026-07-24-staged-eta-full-refit-bootstrap-smoke.md`
- `docs/dev-log/after-task/2026-07-24-staged-eta-bootstrap-infrastructure.md`
- `docs/dev-log/after-task/2026-07-25-staged-eta-bootstrap-campaign-stop.md`
- `docs/dev-log/check-log.md`
- `AGENTS.md`
- this handover

## Next Immediate Steps

1. Read `AGENTS.md`, this handover, the campaign-stop report, and design 240.
2. Confirm the hold boundary remains correct; do not run compute.
3. Decide whether to retain the developer-only infrastructure on the hold
   branch or remove it entirely. Retention requires a concrete future research
   question; removal is appropriate if staged eta remains point-only.
4. If uncertainty is reopened, make an ultra-plan for the product decision and
   mathematical route before changing code or requesting compute.

## Blockers / Open Questions

- Does staged eta have a user-facing inference use case strong enough to merit
  any uncertainty interface?
- If yes, is a stacked-score/Godambe approach feasible and preferable to a
  costly full-refit bootstrap?
- Should the local developer infrastructure be retained as a research scaffold
  or discarded to keep the branch estate small?

## Gotchas and Failed Approaches

- Conditional stage-2 curvature is not an eta SE; neither a Wald interval nor
  a profile of that conditional objective repairs missing margin uncertainty.
- The full campaign was too large before runtime was measured. Do not infer a
  finish time from worker count alone.
- Partial shards must not be combined into apparent coverage evidence.
- Use `R_PROFILE_USER=/dev/null Rscript --no-init-file` for local R commands.

## Mission Control

| Lane | State | Claim boundary | Next by leverage |
| --- | --- | --- | --- |
| Direct `biv_lognormal()` rho12 | complete | exact direct fixed-effect rho12 only | leave closed; do not reopen |
| Staged Bernoulli × NB2 eta | held | point estimate / diagnostic only | decide whether any public uncertainty is needed |
| Bootstrap infrastructure | local, unmerged | no evidence or API | retain-or-remove decision; no compute |

## How to Resume

From the repository root, start a fresh Codex session and paste:

```text
Rehydrate from docs/dev-log/handover/2026-07-25-codex-staged-eta-hold-handover.md
and the AGENTS.md staged-eta HOLD snapshot. Do not run compute or merge the
hold branch. First make the retain-versus-remove and product-need decision for
staged-eta uncertainty.
```

Codex should run live R/TMB checks only if the decision requires them. Claude
may review the product question, mathematics, and prose, but must not claim a
staged-eta interval or run this repository concurrently with Codex.
