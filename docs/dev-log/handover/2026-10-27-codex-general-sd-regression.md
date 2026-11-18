# Codex handoff: general predictor-dependent random-effect SD regression

## Critical Context

The programme remains open. The user authorized implementation, deferred interval-coverage validation, and asked for Julia parity. Keep the separate DRM.jl parity and audit lanes coordinated; do not send the previously discussed email. Preserve all shared and foreign edits in this candidate worktree.

## What Accomplished

A narrow native R/TMB lognormal slice admits coefficient-specific SD formulas for an ordinary, unlabelled correlated two-coefficient location block. It has a synthetic correlated recovery test, target-name and predicted-scale checks, constant-SD likelihood equivalence, and user/developer documentation. Focused test passed: 40 expectations, zero failures/warnings/skips. Reviewer follow-up found no remaining concrete issues in this slice. No interval coverage claim is made.

The target vignette and formula grammar vignette rendered. `pkgdown::check_pkgdown()` passed with existing Pandoc MathML warnings. A full `pkgdown::build_site()` exceeded its 3-minute estimate and was interrupted after 6m46s during unrelated rendering; it is incomplete and must not be reported as passing.

Evidence receipt: `docs/dev-log/general-sd-regression/evidence/native-lognormal-correlated-q2-sd-20261027/`. Checkpoint: `LOOP/lanes/general-sd-regression/checkpoint.md`. The broader evidence reconciler passed with 19,678 candidate rows, 161 linked, 19,517 unlinked, and 181 evidence records; its 11 tests passed. These counts are candidate ledger bookkeeping, not completed capability coverage.

## Current Working State

- Worktree: `.worktrees/general-sd-regression`
- Branch: `codex/general-sd-regression`
- HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- The checkout has extensive mixed dirty state. Exact status/path inventory is in `2026-10-27-general-sd-worktree-paths.tsv`.
- No broad staging, commit, push, reset, cleanup, or rebase was performed.
- The Codex efficiency gate requires a fresh task before more project work. Resume in a new task attached to this working tree.

## Key Decisions

- Keep interval coverage deferred; continue implementation with focused numerical/recovery checks and label uncertainty evidence accurately.
- The next implementation slice should be chosen from rows with existing base-fit support after fresh preflight and current lane reconciliation. Do not assume Gamma q2 is already supported.
- Julia direct probit phylogenetic evidence exists in its candidate lane, but the R bridge still rejects non-logit structured Binomial routes. End-to-end capability remains incomplete.
- Keep the shared lane board as the cross-lane pointer. This native SD lane is documented in `docs/dev-log/active-lane-split.md`; the canonical AGENTS pointer goes through `docs/dev-log/coordination-board.md`.

## Files and Ownership

See the exhaustive current dirty-path manifest: `2026-10-27-general-sd-worktree-paths.tsv`. Treat all listed state as carried over or protected until its ownership is reconciled. The lognormal slice's implementation and evidence files are described above; do not stage unrelated paths.

## Landing State

Not landed. The candidate HEAD is local and the working tree contains mixed shared changes. The normal handoff gate reported that the next agent must read `origin`; do not represent local state as remotely available. No commit or push was made.

CARRIED-OVER: branch `codex/general-sd-regression` and all 1,117 dirty paths listed in the manifest; resume in this worktree because the implementation state is uncommitted.

FINDINGS-OF-RECORD: none

## Next Steps

1. Open a fresh Codex task with this exact working tree and read this handoff, the path manifest, `AGENTS.md`, the SD goal/checkpoint, and the current lane board.
2. Run lane preflight for the candidate repository and the selected files before editing. Reconcile active R/TMB, Julia parity, and audit lanes; preserve their changes.
3. Select one bounded next capability row with existing base-fit support. Add a focused test before implementation, then update its evidence receipt and docs.
4. Do not claim programme completion until the remaining family/effect/backend ledger and final checks are reconciled.

## Blockers and Gotchas

- Broad shared dirty state and many local branch refs make path-level inspection essential.
- `lane_preflight.sh` is a coordination signal, not permission to overwrite another lane.
- The attempted full pkgdown build did not finish.
- Coverage and calibrated uncertainty remain deferred by user decision.

## How to Resume

Resume in `.worktrees/general-sd-regression` on `codex/general-sd-regression`. Start with `git status --short`, inspect the exact selected-file diffs, then run the required lane preflight. Do not switch to the clean primary checkout because the candidate work is uncommitted.

| Mission Control field | Value |
|---|---|
| Status | In progress; handoff required due efficiency gate |
| Completed slice | Native lognormal ordinary correlated q2 SD regression |
| Next bounded action | Fresh preflight, then choose next existing-base-fit capability row |
| Blocked by | Shared worktree ownership reconciliation for touched files |
| Evidence | `docs/dev-log/general-sd-regression/evidence/native-lognormal-correlated-q2-sd-20261027/` |
| Resume command | `cd .worktrees/general-sd-regression && git status --short` |

Copy-paste resume prompt: “Continue the general predictor-dependent random-effect SD regression goal from `docs/dev-log/handover/2026-10-27-codex-general-sd-regression.md`. Preserve all dirty state. Start with fresh lane preflight and reconcile current R/TMB, Julia parity, and audit lanes, then select one bounded next capability row with existing base-fit support. Interval coverage remains deferred.”
