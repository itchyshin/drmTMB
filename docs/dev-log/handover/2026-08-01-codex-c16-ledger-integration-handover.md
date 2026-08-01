# Session Handoff: C16 source-bound ledger integration

Meta: 2026-08-01 · from Codex · to Codex · Lane C only

## Critical Context

PR #876 is merged at `402aca4c`, making `mc-0583` canonical. PR #877 carries
the nine separately authorized C16 transitions: `mc-0584`--`mc-0587` and
`mc-0593`--`mc-0597`. Do not merge #877 until its release CI is green and
Shinichi explicitly authorizes that merge.

The approved C16 result is strictly point-fit recovery. It is not a profile,
interval, coverage, calibration, or inference-ready claim. Do not change the
paired q2-plus boundary rows `mc-0696`--`mc-0704`.

## What Was Accomplished

- Source-bound receipts for all nine named q1 structured zero-one-beta leaves
  were added to the C16 branch: each names its source SHA, independent oracle,
  retained four-attempt fixture, and Noether/Fisher/Rose GO review.
- The ledger, append-only evidence and transition records, generator guards,
  unit test, and generated reader surface now agree on the proposed canonical
  model-surface census: 327 implemented / 340 rejected-by-design / 20 not
  implemented.
- Local checks passed: `python3 -m unittest tools.tests.test_capability_ledger`
  (46 tests), `python3 tools/capability_ledger.py --check`, and the closeout
  compiler for the C16 integration receipt.

## Current Working State

- Working: branch `codex/lane-c-c16-mc0584-oracle` at `321b87ff0` (before this
  handoff document) is pushed and PR #877 is open.
- In progress: GitHub's `ubuntu-latest (release)` check for PR #877 was still
  running at the last readback; `os-matrix` had passed.
- Blocked: canonical integration and Mission Control verification require green
  CI plus explicit authorization to merge #877.

## Key Decisions & Rationale

- C14's older 328/330/19 headline is superseded by the non-lossy C14 split:
  the verified model surface has 687 rows and 340 boundary rows. Never edit the
  source taxonomy merely to recreate the old headline.
- The nine C16 promotions are individually source-bound. Do not replace their
  evidence with the older C14 equivalence records or broaden their formula
  grammar.
- Lane B's #858 and all foreign unpushed branches are outside this handover.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| `codex/lane-c-c16-mc0584-oracle` C16 evidence + ledger integration | yes | yes | [#877](https://github.com/itchyshin/drmTMB/pull/877) open | CARRIED-OVER: awaiting release CI and merge authorization |
| `origin/main` C16 `mc-0583` transition | yes | yes | #876 merged | LANDED |

`/Users/z3437171/shinichi-brain/tools/handoff_gate.sh` reports unpushed commits
on unrelated foreign branches. They are not C16 work; do not rebase, push,
clean, or stage them.

## Files Created / Modified

The complete source-bound inventory is the file list on PR #877. Its material
paths are:

- `docs/dev-log/dashboard/capability-ledger/c16-source-bound-evidence-manifest.tsv`
- `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-mc-0584-*`
- `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-mc-0585-*`
- `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-mc-0586-*`
- `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-mc-0587-*`
- `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-mc-0593-*`
- `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-mc-0594-*`
- `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-mc-0595-*`
- `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-mc-0596-*`
- `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-mc-0597-*`
- `docs/dev-log/dashboard/capability-ledger/{cells,evidence,transitions}.tsv`
- `tools/capability_ledger.py`, `tools/tests/test_capability_ledger.py`
- generated capability census/surface files and
  `docs/dev-log/after-task/2026-08-01-lane-c-c16-nine-leaf-ledger-integration.md`

## Next Immediate Steps

1. Run `lane_preflight.sh` and inspect PR #877; preserve every foreign lane.
2. When both CI checks are green, obtain/confirm explicit authorization to merge
   PR #877; do not treat its opening as authority to merge.
3. Merge #877 only after that authorization, then `git fetch origin main`.
4. Run `python3 tools/capability_ledger.py --check` against `origin/main`; it
   must report the 327/340/20 model-surface state.
5. Start/restart Mission Control only through its documented launcher, then
   verify `/p/drmTMB/runtime.json` names canonical `main` and the same counts.

## Blockers / Open Questions

- Required external gate: the release CI check for PR #877.
- Required user authority: merge PR #877 after it is green.
- The remaining 20 rows are not automatically authorized for promotion; each
  retains its own architecture/evidence gate.

## Gotchas & Failed Approaches

- The C16 ledger test initially retained the one-cell `mc-0583` constants; it
  correctly failed until the named nine-leaf authorization was encoded.
- Do not claim the old 330-boundary count: C14's q1/q2-plus split makes 340 the
  verified boundary count.
- Do not use a dirty working-tree Mission Control overlay as a canonical count.

## Mission-Control Summary

| Repo | Branch / canonical ref | CI | Shipped / carried state | Next action |
|---|---|---|---|---|
| drmTMB | PR #877 → `main` | `os-matrix` pass; release running | nine C16 q1 point-fit transitions | merge only after green CI + authority, then verify runtime source/count |

## How to Resume

Start Codex in a fresh drmTMB checkout and paste:

```text
Rehydrate from docs/dev-log/handover/2026-08-01-codex-c16-ledger-integration-handover.md and AGENTS.md. Work only on PR #877's Lane C ledger integration: inspect CI, merge only after explicit authorization, then verify origin/main and Mission Control runtime alignment. Preserve Lane A/B and all foreign branches.
```

Codex should run the live R/Python toolchain for ledger generation and runtime
readback. Use `NOT_CRAN=true` only if a focused R test requires it; no recovery
or coverage campaign is part of this handoff.
