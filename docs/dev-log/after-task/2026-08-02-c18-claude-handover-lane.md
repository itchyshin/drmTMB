# After Task: Create the C18 Claude Handover Lane

## 1. Goal

Create a durable, multi-lane-safe handover that starts C18 planning in a fresh
Claude session without reopening C17 or colliding with active mesh/SPDE PR
#893.

## 2. Implemented

Created a docs-only handover branch and current active-lane board. The handover
selects the ten collapsed structured zero-one-beta `zoi`/`coi` rows as the
highest-yield coherent programme, requires representation splitting before any
q1 promotion, and limits the receiving Claude session to read-only Ultra Plan
Phases 0–2 until the overlap gate clears and Shinichi approves the plan.

No drmTMB model capability changed.

## 3a. Decisions and Rejected Alternatives

This docs-only lane creates no mathematical contract. It requires Claude to
write symbolic structured-`zoi` and structured-`coi` equations before proposing
code. The existing aggregate ledger rows must not be interpreted as equations
or as q2+ support.

Rejected alternatives were immediate C18 source mutation while #893 owns shared
files, direct promotion of collapsed rows from q1 evidence, and an assumed
`330 + 10` census ceiling before representation splitting.

## 4. Files Touched

- `AGENTS.md`
- `docs/dev-log/active-lane-split.md`
- `docs/dev-log/handover/2026-08-02-claude-handover.md`
- `docs/dev-log/after-task/2026-08-02-c18-claude-handover-lane.md`

## 5. Checks Run

- Canonical model-surface count from
  `docs/dev-log/dashboard/capability-ledger/cells.tsv`: 17
  `not_implemented`, including the ten named structured atom rows.
- Canonical lane preflight: foreign lanes #893, #891, #869, and #858 detected.
- `gh pr view 891`: docs-only mesh handover, both required checks green.
- `gh pr view 893`: genuine shared-source overlap; `os-matrix` green and
  `ubuntu-latest (release)` failed at inspection time.
- `git diff --check`: pass before final staging; rerun after this report.
- File existence/read-back for the snapshot, lane board, and handover: pass.

Package tests, documentation generation, pkgdown, and package check were not
run because this branch changes no R, TMB, roxygen, generated ledger, package
documentation, or runtime behaviour.

## 6. Tests of the Tests

N/A. No test code or test expectation changed. The receiving plan must design
independent likelihood/oracle tests and malformed-neighbour tests before C18
implementation.

## 8. Consistency Audit

The active-lane board carries forward mesh/SPDE, Lane B E0, and the
missing-data cross brief rather than replacing them with a single C18 pointer.
The handover and `AGENTS.md` point to the same Claude document and branch. The
claim is deliberately planning-only: no `implemented`, recovery, profile,
interval, coverage, inference-ready, supported, q2+, REML, AGHQ, or
missing-response status changed.

Prose review found and preserved the key reader actions: read the current lane
board, classify dated items, rerun preflight, plan read-only, and stop before
overlapping mutations.

## Design-Doc Updates

None. C18 architecture and ledger representation are unresolved design work for
the Ultra Plan; changing formula or likelihood design documents in this
handover would pre-decide that work and overlap PR #893.

## pkgdown and Documentation Updates

Only internal developer coordination documents changed. No README, vignette,
Rd, pkgdown navigation, or generated site artifact changed.

## 7a. Issue Ledger

Inspected overlapping open PRs #893, #891, #858, and #869. No issue or PR was
commented on, opened, closed, merged, or modified because this task only creates
the handover lane and must not claim foreign work.

## 9. What Did Not Go Smoothly

The first requested target was a fresh Codex task. Shinichi then redirected the
handover to Claude before the branch was committed. The uncommitted handover was
rewritten for Claude and the branch renamed; no obsolete Codex handover was
landed.

The handoff gate also reported a large historical estate of mixed local/remote
branches. Those are foreign and remain explicitly carried over rather than
being cleaned or force-pushed.

## 11. Team Learning

The remaining count alone is not a safe implementation target. Each of the ten
structured atom rows collapses q1 through q12, so representation design is the
first capability task. Splitting the ledger can change the denominator; a
simple `330 + 10` ceiling would be misleading.

## 10. Known Residuals

- PR #893 blocks overlapping C18 source mutation while open, unless Shinichi
  gives fresh overlap authorization.
- The preferred structured carrier architecture is not yet decided.
- The post-split canonical census is unknown until the generator design is
  approved.
- This task cannot launch or authenticate a fresh Claude session; Shinichi must
  start Claude and paste the resume prompt.

## Next Actions

1. Commit and push the four explicit handover paths.
2. Open a docs-only PR; do not auto-merge.
3. Start a fresh Claude session and paste the exact prompt in the handover.
4. Claude performs only the `OWED` read-only Ultra Plan steps until approval and
   the #893 overlap gate clear.

## 12. Cross-Product Coverage

This lane covers only coordination, rehydration, and planning provenance. It
does NOT cover formula admission, TMB routing, structured precision fields,
extractors, prediction, simulation recovery, profiles, intervals, coverage,
REML, AGHQ, missingness, q2+, Lane A/B, mesh/SPDE, or any model-surface
promotion.
