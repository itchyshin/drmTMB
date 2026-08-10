# After Task: 0.7 issue-sweep handover

## 1. Goal

Create a lossless Codex-to-Codex handover that makes a repository-grounded
issue sweep the next action before any drmTMB 0.7 candidate freeze.

## 2. Implemented

Added a standalone handover with the current commit, CI receipts, artifact
identity boundary, 29-issue Arc Card, approval gates, and exact resume prompt.
Refreshed the AGENTS snapshot and active-lane board without altering foreign
lane ownership.

## 3a. Decisions and Rejected Alternatives

The next release action is an issue sweep before candidate freezing. Repeating
the 0.6 tarball preflight now was rejected because #950 changed installed bytes
and the useful artifact will be the later, owner-authorized exact 0.7 candidate.
Compute was rejected for this triage arc because no evidence question requiring
new simulation has yet been identified.

## Mathematical Contract

Not applicable. This is release-scope documentation only.

## 4. Files Touched

- `docs/dev-log/handover/2026-08-08-codex-handover.md`
- `docs/dev-log/after-task/2026-08-08-07-issue-sweep-handover.md`
- `AGENTS.md`
- `docs/dev-log/active-lane-split.md`

## 5. Checks Run

- Refreshed `origin/main` and verified `c996613db`.
- Verified DESCRIPTION `0.6.0`.
- Read the live open issue inventory: 29 issues.
- Read the live open PR inventory: #858 and #937.
- Verified post-merge R-CMD-check `31278747498` and pkgdown `31280621236` are green.
- Compared the prior exact freeze with current main and confirmed
  `vignettes/drmTMB.Rmd` changed after the freeze.
- Ran the handoff gate; it reported pre-existing foreign unpushed branches,
  which are explicitly declared and not owned by this lane.

## 6. Tests of the Tests

The exact-artifact boundary was checked with a commit-to-commit file diff, not
inferred from green CI or documentation-only intent.

## 7a. Issue Ledger

No issue was changed in this handover slice. The next arc will read and classify
all 29 before making evidence-backed maintenance changes.

## 8. Consistency Audit

The handover distinguishes the historically proven predecessor tarball from
the unrefrozen current main and preserves all existing release approval gates.

## 9. What Did Not Go Smoothly

The primary checkout and many unrelated local branches are dirty or unpushed.
A clean worktree from current `origin/main` isolated the handover safely.

## 10. Known Residuals

This handover does not itself classify the 29 issues or advance a CRAN rung.
The handoff gate also reports numerous pre-existing foreign unpushed branches;
they remain explicitly outside this lane.

## 11. Team Learning

Issue triage is cheapest before candidate freeze: a genuine installed-byte
blocker found afterward invalidates every exact-artifact check.

## 12. Cross-Product Coverage

No DRM.jl, gllvmTMB, or other package surface changed. GVA/EVA and Julia-engine
issues remain future drmTMB work and are not silently transferred to a twin.
This slice does NOT cover REML, AGHQ, penalties, estimator engines, missing-data
models, aggregation, capability promotion, simulations, or twin-package code.

## Next Actions

Run the Arc Card in a fresh task, produce the tracked issue-sweep ledger, and
ask the owner about the 0.7 candidate only after the finite blocker set is known.
