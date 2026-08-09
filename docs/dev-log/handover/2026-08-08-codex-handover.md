# Codex Handover — define the real drmTMB 0.7 candidate by sweeping open issues

Meta: 2026-08-08 MDT · from Codex to a fresh Codex task · source
`origin/main@c996613db1527a9f30cbe27fd29af497390c7985`

## Critical Context

You are Codex, picking up drmTMB's pre-0.7 scope decision. Start with an issue
sweep, not a version bump or another validation campaign. The purpose is to
separate genuine 0.7 blockers from completed, superseded, and deliberately
post-0.7 work before freezing an exact candidate.

`origin/main` is healthy but is **not an exact 0.7 candidate**:

- DESCRIPTION remains `0.6.0`.
- PR #950 is merged at `c996613db`; post-merge R-CMD-check run
  [31278747498](https://github.com/itchyshin/drmTMB/actions/runs/31278747498)
  and pkgdown run
  [31280621236](https://github.com/itchyshin/drmTMB/actions/runs/31280621236)
  passed.
- The latest exact tarball-clean artifact is the predecessor `0.6.0` tarball
  built from `ad475cc39`, SHA-256
  `2e5234bd4bf819663e9ef95f10a1944d51c90ce64ffd5dd7a9641b69fa50c5ea`.
- PR #950 subsequently changed the installed vignette
  `vignettes/drmTMB.Rmd`. Therefore that predecessor tarball does not prove the
  bytes at current `main`; current `main` must be frozen again after the 0.7
  scope is locked.

Highest historically proven rung remains **`tarball-clean` for the exact
predecessor artifact**. Do not call current `main` tarball-clean, platform-clean,
CRAN-ready, or 0.7-ready.

Do not touch PR #858, PR #937, historical #947, the dirty primary checkout on
`claude/handover-freshness-0718`, foreign worktrees, or foreign stashes. Do not
bump DESCRIPTION, write `platform-clean`, finalize `cran-comments.md`, fire the
D-43 submission panel, or upload to CRAN in the issue-sweep arc.

## Goals / Mission

Define the smallest honest drmTMB 0.7 release surface. Preserve the package's
current capability boundaries and make the release decision from evidence,
not from the age or title of an issue. Missing future research does not block a
release when the current package rejects or documents that surface honestly.

## ARC CARD — 0.7 issue sweep and candidate-freeze decision

**Mode:** size

**Requested outcome:** Classify every currently open drmTMB issue and produce a
binary answer: what must be completed before the exact 0.7 candidate is frozen,
and what is explicitly later work?

**Mechanism authority:** Read issue threads and current-main source, tests,
documentation, ledgers, and CI evidence. Close or comment on an issue only when
current repository evidence proves it done, superseded, duplicated, or
deliberately post-0.7. Do not implement methods, expand capability claims, or
start compute inside this arc.

**Recommended arc:** A 3–5 hour capacity programme covering all 29 open issues,
with the release decision as the endpoint rather than an arbitrary number of
closures.

**Time contract:** Approximately 30 minutes to freeze criteria and inventory;
90–150 minutes to read and cross-check issues; 45–75 minutes for evidence-backed
issue maintenance; 30–45 minutes to consolidate the 0.7 candidate decision.

**Estimate confidence:** Inferred. The live issue count and topic mix are known;
thread depth and stale-claim repair needs are not yet measured.

**Arc 0 outcome:** A 29-row ledger with issue number, current claim, repository
evidence, disposition, 0.7 relevance, required action, and owner. No issue may
remain classified only by its title.

**State transition:**

1. Current state: green `main` at `c996613db`, version `0.6.0`, predecessor
   tarball-clean evidence, 29 open issues, and no locked exact 0.7 artifact.
2. Intended state: every open issue is classified; the finite 0.7 blocker set is
   explicit; each blocker is closed or has a bounded owner/action; all other
   issues are demonstrably non-blocking; the owner can make one informed
   freeze/no-freeze decision.
3. Smallest executable intervention: perform a read-only repository-grounded
   sweep before changing any issue or package file.
4. Retained evidence: one tracked sweep ledger plus links to issue comments,
   current-main files/tests/docs, and CI receipts.
5. Approval gates: Shinichi must authorize the real `0.7.0` DESCRIPTION bump;
   later, separately authorize writing `platform-clean`; and separately
   authorize CRAN upload.

**Executable rung and evidence:** The sweep itself earns a
`candidate-scope-defined` decision, not a CRAN rung. Only an exact post-sweep
tarball and its checks can earn `tarball-clean` for 0.7.

### Capacity ladder

| Rung | Budget | Separately valuable outcome |
|---|---:|---|
| Arc 0 — inventory and rules | 30 min | Complete issue inventory and classification rubric |
| Rung 1 — evidence sweep | 90–150 min | Every open issue cross-checked against current `main` |
| Rung 2 — issue hygiene | 45–75 min | Proven done/superseded items closed or corrected; future work clearly non-blocking |
| Rung 3 — freeze decision | 30–45 min | Finite 0.7 blocker list and owner-facing GO/NO-GO recommendation |

### Budget

- Orient and inventory: 30 min
- Core evidence review: 90–150 min
- Verify, repair, and issue maintenance: 45–75 min
- Consolidate and close: 30–45 min
- Total: 3–5 h

**In scope**

- All 29 issues returned by the live 2026-08-08 open-issue query.
- The release tracker #61.
- Current-behaviour candidates #570, #710, #802, #861, and #870.
- Explicit future research/performance issues #3, #4, #5, #33, #59, #60,
  #496, #499, #531, #555, #680, #682, #686, #687, #714, #740, #859,
  #914, and #932–#936.
- A tracked decision ledger at
  `docs/dev-log/release-audits/2026-08-08-0.7-issue-sweep.md`.

**Not in this arc**

- Implementing an open issue.
- Totoro or DRAC work; no unearned simulation campaign is needed for triage.
- AGHQ, REML, GVA/EVA, new families, new formula grammar, or new estimators.
- PR #858, PR #937, or historical #947.
- DESCRIPTION `0.7.0`, exact candidate freeze, platform checks, D-43,
  `cran-comments.md` finalization, or upload.

**Evidence used**

- Live GitHub issue and PR inventories on 2026-08-08.
- `origin/main@c996613db` and its green post-merge R-CMD-check/pkgdown runs.
- `docs/dev-log/handover/2026-08-08-cran-reader-boundaries-codex-handover.md`.
- `docs/dev-log/after-task/2026-08-08-pkgdown-navigation-deduplication.md`.
- `docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json`.
- `docs/dev-log/release/0.7.0-cran-gate/FREEZE-NOTES.md`.

**Risk branch**

- If an issue exposes a defect in an already advertised 0.7 surface, mark it
  `0.7 blocker` and stop candidate freezing until a separate bounded fix lands.
- If the issue requests unimplemented capability that is already rejected or
  clearly bounded in public docs, retain it as post-0.7 and do not manufacture
  a blocker.
- If evidence is ambiguous, use `owner decision`; do not close it or silently
  widen the release.
- If any repair changes installed bytes, the eventual candidate must be frozen
  only after that repair lands.

**Done when**

- All 29 issues have evidence-backed dispositions.
- Every actual 0.7 blocker has a concrete next action and owner.
- Every issue closed by the sweep has a self-contained evidence comment.
- The tracked ledger gives Shinichi a binary freeze recommendation.
- No release rung, version, capability claim, or artifact identity is advanced.

**First action:** Run the live issue inventory, freeze the classification rubric,
then inspect #61 and the five current-behaviour candidates before the obvious
post-0.7 research cluster.

### Actuals

Complete at close: elapsed time, issues reviewed, issues closed, issues retained,
0.7 blockers found, owner decisions required, and estimate calibration.

**HAND TO ULTRA PLAN:** This is a 29-issue, multi-slice programme with GitHub
state changes and a release-freeze decision. Use a compact ultra-plan, but keep
the implementation boundary exactly as written above.

## What Was Accomplished

- Restored the Function map and cheat sheet under Get started and kept What can
  I fit today? only under Model Guides through PR #950.
- Verified the deployed navigation on desktop and mobile.
- Refreshed `origin/main`, the current open issue/PR inventories, and the exact
  post-merge CI identities.
- Defined the next economical 0.7 arc as issue triage before artifact freezing.
- Created this clean handover lane without modifying the protected primary
  checkout.

## Current Working State

- **Working:** current-main R-CMD-check and pkgdown; live reader navigation;
  predecessor exact tarball receipt.
- **In progress:** only this handover PR.
- **Blocked / unproven:** exact 0.7 candidate scope, DESCRIPTION 0.7.0,
  current-main tarball identity, platform-clean, submission-ready, and upload.

## Key Decisions and Rationale

1. Sweep issues before freezing 0.7. Otherwise a late-discovered installed-byte
   blocker would invalidate the freeze and repeat every release check.
2. Do not let research ambition define release readiness. A future method is
   non-blocking when the current boundary is explicit and safe.
3. Do not rerun the 0.6 tarball preflight now. The useful next artifact is the
   authorized exact 0.7 candidate after the sweep.
4. Totoro and DRAC are available but irrelevant to this triage arc. Use them
   only if a later, separately approved blocker genuinely requires compute.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-08-codex-handover.md` — authoritative handover and Arc Card.
- `AGENTS.md` — refreshed top snapshot pointer.
- `docs/dev-log/active-lane-split.md` — refreshed current packaging/issue-sweep lane without changing foreign lane ownership.
- `docs/dev-log/after-task/2026-08-08-07-issue-sweep-handover.md` — handover-slice closeout.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| `main` `c996613db` | yes | yes | #950 merged | LANDED — current base |
| `codex/handover-07-issue-sweep-0808` | pending until close | pending until close | pending until close | CARRIED-OVER — this handover-only branch |
| PR #858 `codex/lane-b-e0-readiness` | yes | yes | open draft | PROTECTED foreign lane |
| PR #937 `claude/land-gva-decision` | yes | yes | open | PROTECTED foreign lane; explicitly post-0.7 implementation |
| dirty primary `claude/handover-freshness-0718` | mixed | mixed | none | PROTECTED; never stage, clean, or use |
| other unpushed local branches reported by `handoff_gate.sh` | mixed | mixed | mixed | PRE-EXISTING FOREIGN STATE; not owned by this handover and not a 0.7 authority |

After this branch is committed, pushed, and opened as a PR, update the pending
row in the PR description or closeout note. Do not infer ownership of the
foreign branches from their presence on disk.

## Next Immediate Steps

1. Rehydrate and classify these items `OWED`, `DONE`, `RETRACTED`, or
   `PROTECTED`; the issue sweep is `OWED` and prior reader/navigation work is
   `DONE`.
2. Run a compact ultra-plan for the Arc Card above.
3. Create the 29-row issue ledger and perform the evidence sweep.
4. Make only evidence-backed issue comments/closures; do not implement fixes in
   the sweep lane.
5. Report the finite blocker set and ask Shinichi whether to authorize the real
   `0.7.0` candidate.
6. Only after that authorization, start a fresh exact-candidate arc: bump,
   freeze, local tarball check, exact platform evidence, owner gate for
   `platform-clean`, D-43/submission preparation, and stop before upload.

## Blockers / Open Questions

The only decision the issue sweep is designed to surface is: after reviewing
the finite blocker set, does Shinichi authorize locking current intended
package bytes as the real `0.7.0` candidate? Do not ask this before the sweep.

Later gates remain separate:

1. authorize DESCRIPTION `0.7.0`;
2. authorize writing `platform-clean` after exact-artifact evidence exists;
3. authorize CRAN upload.

## Gotchas / Failed Approaches

- A green predecessor platform run cannot prove a successor tarball.
- The release ledger currently names the exact `ad475cc39` artifact; #950's
  installed-vignette change makes it stale for current main without making its
  historical evidence false.
- Do not classify an issue from its title. Read the thread and current code.
- `git log` without `--all` does not describe foreign branch activity.
- The primary checkout is dirty by design and is not a cleanup target.
- Do not rerun D-117 or the 135-trace campaign; their evidence is retained.

## Mission Control

| Repo / lane | Branch or main | CI / evidence | What shipped | Plan by leverage |
|---|---|---|---|---|
| drmTMB reader surface | `main@c996613db` | R-CMD-check 31278747498; pkgdown 31280621236 green | Reader boundary page plus corrected Function map / Model Guides navigation | DONE; do not reopen |
| drmTMB exact artifact | predecessor `ad475cc39`, SHA `2e5234bd…` | local `--as-cran` 0 E / 0 W / 1 new-submission NOTE | exact 0.6.0 tarball-clean receipt | Historical proof only after #950 installed-byte change |
| drmTMB issue sweep | `codex/handover-07-issue-sweep-0808` | handover checks only | Arc Card and clean resume lane | Sweep 29 issues; deliver 0.7 freeze decision |
| PR #858 | foreign open draft | not evaluated here | E0 readiness | PROTECTED |
| PR #937 | foreign open PR | not evaluated here | GVA decision docs | PROTECTED; not a 0.7 implementation blocker |

## How to Resume

Start a fresh Codex task in the drmTMB project. `AGENTS.md` is native; then read
this handover, the active-lane board, and the current git state. Codex owns the
live R/TMB toolchain when verification is required. Use:

```sh
cd '/Users/z3437171/Dropbox/Github Local/drmTMB'
export R_PROFILE_USER=/dev/null
unset NOT_CRAN
git fetch origin --prune
bash '/Users/z3437171/Dropbox/Github Local/Shinichi/tools/lane_preflight.sh' "$PWD"
git status --short --branch
```

Then create a fresh worktree from current `origin/main`; never use the dirty
primary checkout.

One-command resume prompt:

> Rehydrate from `docs/dev-log/handover/2026-08-08-codex-handover.md` plus the
> AGENTS.md snapshot and `docs/dev-log/active-lane-split.md`. Continue with the
> OWED Next Immediate Steps: ultra-plan and execute the 29-issue 0.7 scope
> sweep, then report the finite candidate blocker set. Preserve #858, #937,
> historical #947, all foreign lanes, and the dirty primary checkout. No
> DESCRIPTION bump, platform-clean write, D-43, compute campaign, cran-comments
> finalization, or CRAN upload.
