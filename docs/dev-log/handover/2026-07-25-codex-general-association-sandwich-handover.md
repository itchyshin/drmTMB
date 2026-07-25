# Session Handoff: staged eta reference PR and general association sandwich plan

Meta: 2026-07-25 · from Codex · to Codex · planning/coordination handoff

## Critical Context

The narrow Bernoulli × ordinary-NB2 candidate two-stage Godambe diagnostic is
on draft PR #844, not on `main`.  It remains developer-only: its conditional
stage-two curvature is not an SE, and neither the candidate sandwich nor any
other staged association has public `vcov()`, Wald, profile, `confint()`, CI,
coverage, or validation status.

Do not generalize by exposing a public method.  The next architecture arc is a
private common sandwich assembler with explicit pair adapters; shared
latent-normal structure does not validate each pair's derivatives or SE.

## What Was Accomplished

- Audited the five existing frozen-margin latent-normal association point
  classes and confirmed that only Bernoulli × ordinary-NB2 has a candidate
  sandwich implementation.
- Wrote the approved-for-review general-engine ultra-plan at
  `docs/dev-log/2026-07-25-general-latent-normal-association-sandwich-ultra-plan.md`.
- Inspected GitHub PR coordination: #844 is draft; #843 is active, open, and
  currently not mergeable. Both independently use a `docs/design/243-*` file.
- Updated the staged-eta snapshot in `AGENTS.md` to make the #843 → #844
  dependency and the fresh-lane boundary explicit.

## Current Working State

- **Working:** PR #844 is a mergeable draft holding the narrow candidate
  implementation and focused deterministic tests.
- **In progress:** PR #843 is the independent main-lane simulation correction;
  it must land before #844 is rebased and its design document renumbered.
- **Blocked:** the #844 `243` → `244` rename/rebase is intentionally blocked
  until #843 has merged. No compute or public inference work is authorized.

## Key Decisions and Rationale

- Preserve #844 as the narrow reference implementation. Do not add the general
  engine to it, and do not review it as a public SE facility.
- After #843 lands, rebase #844 on current `main`, rename
  `docs/design/243-arc6-staged-eta-godambe-se.md` to
  `docs/design/244-arc6-staged-eta-godambe-se.md`, repair links/references,
  rerun the two focused staged-association test files, then request review.
- Start the general engine only in a fresh branch/worktree after #844 has a
  resolved reference state. The plan specifies common assembly and
  pair-specific adapters; validation is later and separately approved.
- Direct `biv_lognormal()` `rho12` is a separate exact joint-likelihood route.
  Its evidence must not be used for staged eta.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/staged-eta-godambe-se` candidate implementation | yes | yes | #844 draft | CARRIED-OVER — waiting for #843 merge before rebase/rename/review. Resume: `git switch codex/staged-eta-godambe-se`. |
| This plan and handover update | pending this handover commit | pending push | #844 draft | CARRIED-OVER — commit and push this documentation before ending the session. |
| `claude/a1-simulate-marginal-re` | yes | yes | #843 open | FOREIGN ACTIVE LANE — do not modify from staged eta; wait for its merge. |
| `claude/arc-a-external-comparator-evidence` | yes | no (12 commits) | none recorded here | FOREIGN CARRIED-OVER — reported by `handoff_gate.sh`; do not touch from this lane. |
| `codex/arc6-6-bernoulli-nb2-plan` | yes | no (2 commits) | none recorded here | FOREIGN CARRIED-OVER — reported by `handoff_gate.sh`; do not modify, merge, or clean from this lane. |

## Files Created / Modified

- `AGENTS.md` — staged-eta coordination snapshot.
- `docs/dev-log/2026-07-25-general-latent-normal-association-sandwich-ultra-plan.md` — general-engine plan.
- `docs/dev-log/handover/2026-07-25-codex-general-association-sandwich-handover.md` — this handover.
- Earlier candidate PR files, already committed in #844: `R/associate-pairs-sandwich.R`,
  `tests/testthat/test-associate-pairs-staged-sandwich.R`,
  `docs/design/243-arc6-staged-eta-godambe-se.md`,
  `docs/design/240-arc6-staged-eta-uncertainty-followup.md`,
  `docs/dev-log/after-task/2026-07-25-staged-eta-godambe-se-build.md`, and
  `docs/dev-log/check-log.md`.

## Next Immediate Steps

1. Inspect PR #843 status; do not interfere with its active main-lane work.
2. When #843 has merged, rebase #844 on the resulting `origin/main` and
   perform the `243` → `244` design-record rename plus reference repair.
3. Run only the two focused staged-association test files and `git diff --check`.
4. Request narrow implementation/claim review for #844; do not merge without
   that review.
5. Once #844 has a resolved reference state, start a fresh task and rehydrate
   from the ultra-plan before creating the general-engine worktree.

## Blockers / Open Questions

- #843 has not merged, so the #844 rebase/renumber action is not yet safe.
- The general-engine plan needs explicit owner approval before implementation.
- Any full-refit comparison needs a separate post-freeze approval; no compute
  is authorized in this handoff.

## Gotchas and Failed Approaches

- Do not interpret the direct `biv_lognormal()` rho12 evidence as eta evidence.
- Do not reuse conditional stage-two curvature as a standard error.
- Do not use `setequal()`/model type alone to route repeated-family adapters;
  preserve margin side/order and unique internal labels.
- Do not expose candidate covariance through `association()`, `summary()`,
  `vcov()`, `profile()`, `confint()`, or emmeans.
- The stopped 24 × 200 × 399 bootstrap campaign and its partial shards are
  provenance only; never aggregate or resume them.

## How to Resume

From the repository root, start Codex and paste:

```text
Rehydrate from docs/dev-log/handover/2026-07-25-codex-general-association-sandwich-handover.md
and the AGENTS.md staged-eta coordination snapshot. First inspect PR #843/#844
status; do not run compute or expose public inference. Continue only the Next
Immediate Steps.
```

Read `AGENTS.md`, this handover, and
`docs/dev-log/2026-07-25-general-latent-normal-association-sandwich-ultra-plan.md`
before edits. Use the live R toolchain with:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file
```

Use `.codex/agents/` for bounded reviews; Rose remains the required claims
auditor. Codex may run focused R tests and later approved live compute, but no
Totoro/DRAC campaign or public inference work is authorized by this handover.

## Mission Control

| Lane | State | Next leverage step |
| --- | --- | --- |
| PR #843 simulation repair | Foreign active main lane | Let its owner finish and merge it. |
| PR #844 staged eta candidate | Draft; carried over | Rebase/renumber after #843, then review narrow candidate. |
| General association sandwich | Planned only | Fresh lane after #844 reference resolution and explicit approval. |
| Direct `biv_lognormal()` rho12 | Closed and separate | Do not modify or use as staged-eta evidence. |
