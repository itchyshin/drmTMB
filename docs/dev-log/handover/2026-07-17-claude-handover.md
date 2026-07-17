# Session Handoff: Beta phylogenetic q1 direct-SD successor — post-merge planning transfer

Meta: 2026-07-17 · from Codex · target Claude · PR #787 merged

## Critical Context

PR [#787](https://github.com/itchyshin/drmTMB/pull/787) is merged into `main` at `a9b2633c3f314db3a1ae88103a871403772053f1`. It is a separately versioned successor to the stopped Beta direct-SD campaign, not a repair or rerun. The stopped campaign remains immutable at `1c9bfd5f`; its 399 successful shared-arm fits are descriptive only, never a successor denominator.

The merged claim is narrow: finite-precision conditional-Beta, univariate ML q1, direct latent phylogenetic-SD **point-fit recovery** for the exact tested `g=1024,m=4` arms. It is not an interval, coverage, `inference_ready`, `supported`, or universal species-count claim.

Keep the scale axes separate: `phi_i = sigma_i^-2` is Beta family precision, while `tau_s` is the latent phylogenetic location-effect SD targeted by `sd(spp_id, level = "phylogenetic")`. Do not add family-`sigma` phylogeny or random/hierarchical RHS terms in `sd()`.

## Goals / Mission

`drmTMB` remains the authoritative R/TMB implementation. The completed Beta lane establishes only the direct-latent-SD recovery evidence above. The next task is not pre-authorized implementation: Claude should prepare a successor **ultra-plan only**, then stop for Shinichi's explicit approval before edits, tests, or compute.

The current candidate question is whether the exact Beta q1 direct-SD domain should next receive a profile-interval and calibrated-coverage design. This is a proposed direction, not a ratified capability expansion. Do not rescue the retained `g=256,m=2` stress-quality HOLD by changing denominators, seeds, gates, or model surface.

## What Was Accomplished

- Merged PR #787 after both GitHub R-CMD-check jobs succeeded.
- Added a machine-strict conditional-Beta generator that redraws only a non-interior response and records redraw telemetry; it never clips, epsilon-shifts, deletes responses, retries attempts, or replaces seeds.
- Completed an authenticated Totoro campaign: 12 cells × 400 retained attempts = 4,800 attempts, at 32 workers with BLAS pinned.
- Both independent promotion arms (`distinct_g1024_m04` and `shared_g1024_m04`) passed, yielding `PASS_EXACT_TWO_G1024_M4`; all final responses were strictly interior and no cap exhausted.
- Retained `shared_g256_m02` as a transparent quality HOLD (`pdHess=0.9975`) without pooling or altering the frozen promotion rule.
- Synchronized formula, likelihood, capability ledger/census/surface, limitations, roadmap, runner tests, and the after-task report.

## Current Working State

- **Working:** `main` is at `a9b2633c`; #787 is merged and its two R-CMD-check jobs succeeded.
- **Working:** the merged route is recorded as `point_fit_recovery` only.
- **Not started:** no post-#787 successor plan, implementation, test, or compute is authorized.
- **Held:** `shared_g256_m02` is a stress-quality HOLD, not a new denominator or repair task.
- **Preserved:** stopped branch `codex/beta-phylo-q1-sd-regression` at `1c9bfd5f` is immutable.

## Key Decisions and Rationale

- The finite-precision DGP is new and prospective: it conditions Beta response generation on a machine-representable strict interior response while preserving seeds and recording response-level redraws.
- The two `g=1024,m=4` arms have separate 400-attempt denominators. Lower-information cells and stopped-campaign results must never be pooled into the promotion decision.
- Direct-SD grammar is exactly `sd(spp_id, level = "phylogenetic") ~ x_tau`; hierarchical/random RHS `sd()` effects are a future separate lane requiring its own nesting, identifiability, symbolic, and recovery contract.
- The durable two-part Beta location-scale-scale decision—constant-SD prerequisite, then direct phylogenetic-SD regression—is complete. No durable decision has selected a post-lane expansion, so plan before implementing.

## Landing State

The standard gate was run as `~/shinichi-brain/tools/handoff_gate.sh .`. It reported 358 pre-existing local-only commits on unrelated historical branches and exited non-zero. They are not this task's artifacts, are not work to resume, and must not be cleaned up or staged in this lane.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| `main` `a9b2633c` | yes | yes | #787 merged | LANDED |
| `codex/beta-phylo-q1-sd-interior-dgp` `515aba5e` | yes | yes | #787 merged | LANDED through merge commit |
| `codex/beta-phylo-q1-sd-regression` `1c9bfd5f` | yes | historical | HOLD, no successor PR | CARRIED-OVER — immutable stopped campaign; do not resume or modify |
| `codex/handover-2026-07-17-claude` | yes | yes | #788 open | CARRIED-OVER — handoff-only PR awaiting human merge; resume with `git fetch origin && git switch codex/handover-2026-07-17-claude` if correction is needed |

## Files Created / Modified

The merged #787 diff from `0bdfda14` to `a9b2633c` changed:

```text
R/drmTMB.R
R/methods.R
ROADMAP.md
docs/design/01-formula-grammar.md
docs/design/03-likelihoods.md
docs/dev-log/2026-07-16-beta-phylo-q1-interior-dgp-symbolic-alignment.md
docs/dev-log/2026-07-16-beta-phylo-q1-pr2-symbolic-alignment.md
docs/dev-log/after-task/2026-07-17-beta-phylo-q1-interior-dgp-successor.md
docs/dev-log/check-log.md
docs/dev-log/dashboard/capability-census/_master.tsv
docs/dev-log/dashboard/capability-census/_widget_data.json
docs/dev-log/dashboard/capability-census/beta.tsv
docs/dev-log/dashboard/capability-ledger/cells.tsv
docs/dev-log/dashboard/capability-ledger/evidence.tsv
docs/dev-log/dashboard/capability-ledger/transitions.tsv
docs/dev-log/dashboard/capability-surface.html
docs/dev-log/dashboard/capability-surface.md
docs/dev-log/known-limitations.md
docs/dev-log/simulation-artifacts/2026-07-17-beta-phylo-q1-interior-dgp-certification/README.md
docs/dev-log/simulation-designs/2026-07-16-beta-phylo-q1-interior-dgp/design.tsv
docs/dev-log/simulation-designs/2026-07-16-beta-phylo-q1-interior-dgp/seed-audit.tsv
docs/dev-log/simulation-designs/2026-07-16-beta-phylo-q1-pr2-sd-regression/design.tsv
docs/dev-log/simulation-designs/2026-07-16-beta-phylo-q1-pr2-sd-regression/prior-design-manifest.tsv
docs/dev-log/simulation-designs/2026-07-16-beta-phylo-q1-pr2-sd-regression/seed-audit.tsv
src/drmTMB.cpp
tests/testthat/test-beta-location-scale.R
tests/testthat/test-beta-phylo-direct-sd.R
tests/testthat/test-beta-phylo-q1-sd-interior-recovery-runner.R
tests/testthat/test-beta-phylo-q1-sd-regression-runner.R
tools/run-beta-phylo-q1-sd-interior-recovery.R
tools/run-beta-phylo-q1-sd-regression-recovery.R
tools/tests/test_capability_ledger.py
```

This handoff branch additionally changes `AGENTS.md` and `docs/dev-log/handover/2026-07-17-claude-handover.md`.

## Plans / Roadmap

1. Rehydrate and confirm the post-#787 snapshot remains accurate.
2. Use `/ask-brain`, the Beta after-task report, symbolic alignment, capability ledger, and stopped-campaign evidence to formulate a narrow post-merge ultra-plan.
3. The likely candidate is direct-SD profile intervals plus a prospective coverage contract for the exact proven domain, but present alternatives and freeze scope before claiming it is selected.
4. Shinichi approves or redirects the plan. Only then may the owning platform implement or run compute.

## Next Immediate Steps

1. Read `AGENTS.md` from the top, this handover, and `docs/dev-log/after-task/2026-07-17-beta-phylo-q1-interior-dgp-successor.md`.
2. Confirm live GitHub state for #787 and `origin/main`; do not infer it from this document alone.
3. Invoke `/ask-brain` before deciding the next arc, especially `[[DECISIONS]]` D-57 and D-58.
4. Run an ultra-plan **only**. Include symbolic/inference review, provenance, fresh seed/denominator policy, profile-method boundary policy, and an exact coverage gate. Exclude family-sigma phylogeny, hierarchical/random RHS `sd()`, q>1, labels/slopes, REML, missing routes, and broad family expansion unless Shinichi revises scope.
5. Stop for Shinichi's explicit approval before implementation, tests, compute, commits beyond the planning packet, or a PR.

## Blockers / Open Questions

- The post-#787 arc is not yet approved: decide whether inferential calibration for the exact direct-SD route is the next arc or a separately scoped Beta step.
- The generic handoff gate is noisy because of 358 unrelated historical local-only commits. This handoff declares that state; do not delete or consolidate those branches here.

## Gotchas and Failed Approaches

- `rbeta()` can return a finite non-interior representable endpoint. Never clip or replace it after the fact.
- The strict generator permits a response-level redraw only. Whole-attempt retry, seed replacement, denominator change, response deletion, `pmin`/`pmax`, or epsilon shift violates the frozen contract.
- The first one-fit artifact had an inherited unquoted SHA command and was quarantined; retain path quoting in any future provenance harness.
- Do not treat `shared_g256_m02` as an implementation failure. It is retained diagnostic evidence, deliberately outside the promotion arms.
- Recovery/coverage campaigns run on Totoro or DRAC, never GitHub Actions or GitHub artifacts.

## Mission Control

| Repo | Main / branch | CI and landed evidence | Next action by leverage |
|---|---|---|---|
| drmTMB | `main` `a9b2633c`; handoff branch pending | #787 merged; 2 GitHub R-CMD-check jobs green; authenticated 4,800-attempt Totoro certificate | Claude drafts a bounded next-arc ultra-plan, then waits for approval |

## How to Resume

Run this from an authenticated terminal in the drmTMB repository:

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-17-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps. Do planning only and stop for explicit approval before implementation or compute."
```

Claude should use `AGENTS.md`, run `/ask-brain`, and use the launchable `.claude/agents/` review lenses before making a public claim. Claude is the right owner for planning, prose, and review synthesis; route live TMB compilation, full package checks, and Totoro/DRAC campaigns to the platform with the live toolchain after a plan is approved.
