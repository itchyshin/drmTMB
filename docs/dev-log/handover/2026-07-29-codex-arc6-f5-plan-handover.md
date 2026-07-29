# Session Handoff: Arc 6 F4R closeout to Association F5 planning

Meta: 2026-07-29 · from Codex · to Codex · fresh-task boundary

## Critical Context

You are Codex, picking up a **plan-only** Association F5 lane. F4R has a
private high-information alpha interval-feasibility PASS, but it is not public
association inference. Do not write F5 code, alter articles, promote the
capability ledger, launch compute, or expose `vcov()`/`confint()` until Shinichi
has explicitly approved an eligibility contract after this plan is reviewed.

The completed F4R closeout is PR #864. Its local documentation and after-task
receipt are clean; GitHub's Ubuntu release check was still queued when this
handover was written. Recheck it first and merge **only if all required checks
pass**. The user has authorized that merge. Do not touch unrelated PRs or worktrees.

## What Was Accomplished

- Inspected every retained F4R receipt through the existing Rorqual
  ControlMaster: 16 completed shards, 16 `RUN-COMPLETE.txt`, 16
  `all-attempts.tsv`, 16,000 retained attempts, and consistent source/engine/
  fixture provenance.
- Recorded the bounded private PASS in
  `docs/dev-log/2026-07-29-arc6-f4r-completion-review.md` and a validator-clean
  after-task receipt.
- Confirmed that the public bivariate articles correctly remain beta-labelled:
  F4R does not yet justify changing them.
- Created the plan-only F5 design at
  `docs/dev-log/2026-07-29-arc6-association-f5-plan.md`.

## Current Working State

- **Working:** F4R alpha interval feasibility is supported only for the frozen
  high-information, fixed-effect complete-pair Bernoulli x ordinary-NB2
  intercept grid (`n = 480` or `960`).
- **In progress:** PR #864 is mergeable, with its OS matrix green and its Ubuntu
  release check still queued/running at handover time.
- **Blocked:** F5 public implementation awaits an explicit owner decision on
  whether a defensible, fail-closed eligibility predicate exists.

## Key Decisions and Rationale

- Treat `eta_delta_unavailable` as ancillary to the alpha target; explicit
  alpha availability fields, not terminal status, decide the F4R screen.
- Do not infer an arbitrary-data sample-size threshold from the two F4R values.
- If no bounded public eligibility predicate can be defended, return a private
  diagnostic/development outcome or a further validation design rather than
  silently widening the public claim.
- Keep Association Lane A separate from Lane B `sd()`/Arc D work. The active
  lane split remains in `AGENTS.md`; only the Lane A pointer is updated here.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| F4R closeout `codex/arc6-f4r-closeout-main` at `131b8de9b` | yes | yes | #864 open | **CARRIED-OVER** — await the Ubuntu release check, then merge if green. Resume: `gh pr checks 864 --repo itchyshin/drmTMB --watch`. |
| This handover `handover/2026-07-29-codex-arc6-f5-plan` | pending | pending | pending | **CARRIED-OVER** — commit and push this plan-only documentation; do not merge automatically. |
| Foreign AGHQ/REML root lane `claude/handover-freshness-0718` | yes | status not audited here | foreign | **PROTECTED** — dirty root checkout; do not clean or stage it. |
| Foreign WIP branches reported by `handoff_gate.sh` | mixed | mixed | mixed/none | **PROTECTED** — `claude/arc-a-external-comparator-evidence`, `codex/arc-d-design1-overflow-guard`, `codex/arc6-6-bernoulli-nb2-plan`, `codex/lane-b-q1-preflight-admission`, `codex/lane-c-implementation-recovery`, `codex/lane-c-provider-cohort-20260729`, `codex/sd-bootstrap-r999-diagnosis`, and `codex/staged-eta-godambe-se`; each belongs to its existing owner. |

## Next Immediate Steps

1. Rehydrate from `AGENTS.md`, this handover, the F4R completion review, and
   the F5 plan.
2. Run `tools/lane_preflight.sh` and check PR #864. If every required check is
   green, merge #864; otherwise report the exact external CI state and wait.
3. Inspect the staged-association object and existing S3 method conventions.
4. Answer the plan's single owner question: public alpha interface with a
   fail-closed predicate, or private diagnostic/further validation design.
5. Do not enter implementation unless Shinichi explicitly approves that choice.

## Blockers / Open Questions

- The external Ubuntu release check for #864 had not completed at capture time.
- F4R is insufficient by itself to claim a general sample-size rule. The next
  task must decide whether any public predicate can be both honest and useful.
- F5 has no execution approval yet.

## Gotchas and Failed Approaches

- Do not translate F4R's alpha result into eta intervals or generic staged
  association inference.
- Do not borrow direct `biv_lognormal()` `rho12` evidence for staged eta.
- Do not replace unavailable results with a fallback approximation.
- Do not remove the `beta` labels from `bivariate-nongaussian` or `cross-family`
  until a separately validated public result exists.
- Do not merge PR #862 or other foreign work under this handover; #862 needs a
  fresh, specific merge authorization after its own status is read.

## How to Resume

From a fresh Codex task in the drmTMB project, paste:

```text
Rehydrate from docs/dev-log/handover/2026-07-29-codex-arc6-f5-plan-handover.md,
docs/dev-log/2026-07-29-arc6-f4r-completion-review.md, and
docs/dev-log/2026-07-29-arc6-association-f5-plan.md. First run lane preflight
and inspect/merge PR #864 only if all CI checks pass. Then complete Phase 0–2
of the F5 plan. Do not implement F5, launch compute, change public articles, or
make a public association claim without explicit owner approval.
```

Use the live R toolchain with `R_PROFILE_USER=/dev/null Rscript --no-init-file`
for focused checks. Treat the repository as technical truth and retain the
Association/Lane B split.

## Mission Control

| Lane | State | Next leverage step |
| --- | --- | --- |
| Association F4R closeout | External CI pending | Merge PR #864 only after every check passes. |
| Association F5 | Plan-only | Decide whether a public alpha eligibility predicate is defensible. |
| Staged eta / general sandwich | Separate carried lane | Do not alter from F5. |
| Lane B `sd()` / Arc D | Separate lane | Do not alter from Association work. |
