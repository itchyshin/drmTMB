# Codex handover — Arc 6 F3 provenance smoke success

## Start here

The only completed result is a private, fixed-effect complete-pair Bernoulli x
ordinary-NB2 **staged F3 provenance smoke**. It is retained and pushed on
`codex/arc6-f3-provenance-success-receipt` at
`8c8f4a7cbe875d7ff6e3c0da929e886afdf46678`.

Read:

1. `docs/dev-log/2026-07-26-arc6-f3-provenance-success-receipt.md`
2. `docs/dev-log/smoke/2026-07-26-arc6-f3-2418d847b458/attempt-001/status.csv`
3. `docs/dev-log/after-task/2026-07-26-arc6-f3-provenance-success.md`

## Completed

The owner supplied a fresh pre-execution approval naming source
`2418d847b45891b09f719932e75985101be50116`, the runner, and the immutable
path. One clean detached worktree made the exact CLI invocation. Its source,
two F1M blobs, status, requested path, and all artifact hashes agree.

The receipt has `complete/success`; the DGP, two margin, association, rectangle,
sandwich, and delta stages are `ok`; interval is `not_attempted`. The focused
runner-contract suite passed with 57 expectations. Three fresh read-only D-43
lenses accepted only this narrow provenance claim.

## Claim boundary

Allowed statement:

> One staged full-refit Bernoulli x ordinary-NB2 F3 provenance smoke completed.

Not established: calibrated SEs, empirical-SD agreement, intervals, recovery,
coverage, public inference, capability status, API exposure, F4, F5, or any
transfer to other pair classes. `private/sandwich.rds` is retained private
evidence, not public uncertainty validation.

## Next decision

Do not run or design F4 compute without a new explicit owner decision. The
previous user instruction excludes F4 compute and public inference. If the
owner wants to continue, begin with an approval-gated F4 preregistration review
only; no simulation, remote connection, or launch follows without separate
approval.

## Landing State

| Branch or worktree | State | Why / resume command |
| --- | --- | --- |
| `codex/arc6-f3-provenance-success-receipt` | PUSHED | Current F3 receipt at `8c8f4a7c`; `git switch codex/arc6-f3-provenance-success-receipt`. |
| `claude/arc-a-external-comparator-evidence` | CARRIED-OVER, foreign | 12 unpushed commits belong to Claude's external-comparator lane; do not modify. |
| `codex/arc6-6-bernoulli-nb2-plan` | CARRIED-OVER, protected | 2 legacy unpushed commits; unrelated and never clean or reuse. |
| `codex/sd-bootstrap-r999-diagnosis` | CARRIED-OVER, foreign | 11 unpushed commits; unrelated SD-bootstrap diagnosis. |
| `codex/staged-eta-godambe-se` | CARRIED-OVER, foreign | 3 unpushed commits; separate staged-eta diagnostic lane. |
| Claude Arc D/F5 | FOREIGN, protected | Do not touch, merge, resolve, or restage. |

The handoff gate reports those 28 carried-over commits across other branches;
they do not belong to this F3 receipt branch. The F3 receipt branch is clean,
pushed, and independently recoverable from `origin`.
