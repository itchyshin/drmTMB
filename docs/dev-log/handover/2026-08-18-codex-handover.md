# Session Handoff: drmTMB 0.7.0 Ligges wait

> **Final disposition 2026-08-19:** this is the historical predecessor-byte
> handoff, not the live release state. Its OWED Windows collection is DONE;
> `5153ae7e…` and `6b45164b…` are RETRACTED as final candidates but retained as
> predecessor evidence; #1033 and `_julia_skip2_artifacts/` remain PROTECTED.
> The final immutable candidate is source
> `6170fbeeea65f22444d7b0934f4e808c40744d22`, SHA-256
> `1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`,
> 4,368,396 bytes. Its exact-byte local and three-arm win-builder evidence and
> exact-source 3-OS/sanitizer evidence plus unanimous Gate 7 review prove
> `submission-ready`; this is readiness evidence, not submission authority.
> The closeout is recorded in the current ledger. See
> [`../coordination-board.md`](../coordination-board.md). The prohibitions on
> `submit_cran()`, 19 August submission, #1033, and
> `_julia_skip2_artifacts/` remain in force.

Meta: 2026-08-18 · from Claude · to Codex · branch
`cursor/070-ligges-codex-handover`

You are Codex, picking up the **CRAN Ligges wait/file lane only**. The durable
mission is to preserve exact-byte Windows evidence for drmTMB 0.7.0 without
turning preparation into submission authority.

## Critical Context

Shinichi decided that **19 August is not a submit day**. Do not call
`submit_cran()`, do not touch [#1033](https://github.com/itchyshin/drmTMB/pull/1033),
do not freeze a candidate, and do not claim `platform-clean`.

[#1072](https://github.com/itchyshin/drmTMB/pull/1072) is merged as
`6152aaef12b7f6cf439f15d9606440d1f6bbeb53`. Ligges R-oldrelease
[`T2LOH4zOG6WT`](https://win-builder.r-project.org/T2LOH4zOG6WT) is filed for
the exact julia-skip-2 tarball:
`5153ae7ea7dc2e4ec518dfd6549b4245566b598f97422592d0c3210246023787`,
10,098,642 bytes. It finished with 11,379 tests passed, 0 failed, and
`Status: 1 NOTE`; the JuliaCall hang is gone. The repaired-byte R-release 4.6.1
result was still absent from Gmail at the last verified search.

## Goals / Mission

1. Wait for and file the R-release Ligges result for the **same**
   `5153ae7e…` bytes.
2. Keep every claim tied to a receipt, downloaded log, exact hash, and the
   Windows arm that produced it.
3. Leave the frozen-versus-live choice to Shinichi: ship julia-skip-2, or
   re-freeze current `main` after Wave 3 #1069 and Julia hard-abort #1071.

## What Was Accomplished

- Re-read #1072 state and merge SHA from GitHub.
- Re-read the upload receipt and R-oldrelease filing from `origin/main`.
- Confirmed the receipt pins `5153ae7e…` and 10,098,642 bytes, not the hung
  julia-skip-1 `8764b2fe…` tarball.
- Confirmed R-oldrelease R 4.5.3: install 208 seconds, check 947 seconds,
  1 NOTE.
- Searched Gmail for repaired-byte R-release mail; no matching mail was
  returned.
- Started/reused Mission Control at <http://127.0.0.1:8823/p/drmTMB/> and
  refreshed its status source.
- At 2026-08-18T12:50Z, the `R-CMD-check` run on merge tip `6152aaef…` was
  still in progress. `os-matrix` was green, but it is only the selector job,
  not the package check.

## Historical Working State

- **Working:** R-oldrelease evidence is committed on `main`.
- **Resolved:** all three Ligges arms for exact `5153ae7e…` were filed as
  predecessor evidence; post-#1072 CI was verified.
- **Resolved:** Shinichi selected current `main`; the final candidate identity
  is recorded in the disposition banner above.
- **Still withheld:** `submit_cran()` and any CRAN submission.

The ledger described below is historical. The current ledger is
`docs/dev-log/release-audits/2026-08-19-070-cran-release-ledger-1d6445db.json`.
The predecessor ledger was
`docs/dev-log/release-audits/2026-08-15-070-cran-release-ledger-2.json` at
`tarball-clean` for obsolete source `302ac2579…` / SHA `0d150ef3…`. Rewrite it
only after Shinichi chooses bytes and both Windows arms for those bytes exist.
`platform_matrix` remains required before `platform-clean`.

## Key Decisions & Rationale

- FTP `226` proves transfer only; it is not a Ligges check result.
- R-oldrelease cannot stand in for R-release. File each arm independently.
- Current `main` includes #1069 and #1071, but the owner has not selected a
  re-freeze. Do not manufacture that decision.
- Do not rebuild admitted non-Gaussian random-intercept or independent-slope
  routes. Gamma correlated slopes remain rejected. Lognormal `mc-0720` is on
  `main` at `point_fit_recovery`.
- C14 whole-file-pins `R/drmTMB.R` through `C17_C14_SOURCE_FILES`; the next
  edit will intentionally re-red CI until a new dated C17/C14 receipt is
  generated and repointed. Never hand-edit the stored blob.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-18-codex-handover.md` — this handover.
- `AGENTS.md` — refreshed multi-lane snapshot pointer.
- `docs/dev-log/coordination-board.md` — current Codex Ligges lane pointer.
- `docs/dev-log/after-task/2026-08-18-codex-ligges-handover.md` — compact
  verification and limitations record.
- `~/shinichi-brain/Shinichi/Dashboards/mission-control/live/status/drmTMB.json`
  — #1072 merged / oldrelease filed / R-release waiting state.

Never stage `_julia_skip2_artifacts/`; it is foreign untracked evidence.

## Landing State

The required landing gate was run before finalising this handover and failed
closed because this handover branch was not yet committed/pushed, because
`_julia_skip2_artifacts/` is foreign untracked state, and because it reports
448 historical/foreign unpushed commits across other branches. Those other
branches are not this lane.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `6152aaef…` | yes | yes | #1072 merged | LANDED |
| `cursor/070-ligges-codex-handover` | yes | yes | small docs PR open | LANDED for review; do not auto-merge |
| `_julia_skip2_artifacts/` | no | no | none | PROTECTED foreign untracked; never stage |
| #1033 | n/a | n/a | open | PROTECTED; do not touch |
| `claude/handover-freshness-0718` | historical dirty checkout | no action | none | PROTECTED |

## Mission Control

| Repo | Branch / main | CI | What shipped | Plan by leverage |
|---|---|---|---|---|
| drmTMB | `origin/main` `6152aaef…`; handover branch `cursor/070-ligges-codex-handover` | Post-merge `R-CMD-check` was running; `os-matrix` alone green | #1072 filed R-oldrelease 1 NOTE for exact `5153ae7e…` | 1. Wait/file same-byte R-release. 2. Owner chooses ship/re-freeze. 3. Rewrite ledger/comments only after both Windows arms. 4. Platform matrix → Gate 7 → explicit submit GO |

Other lanes remain separate: #1033 is protected; `mc-0576` is parked; MSPL S2
is parked; the interval-truth lane remains governed by the coordination board.

## Next Immediate Steps

1. Run lane preflight and classify this dated handover against live state as
   `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`.
2. Refresh the post-#1072 `R-CMD-check`; distinguish the real
   `check-r-package` result from `os-matrix`.
3. Search Gmail for repaired-byte R-release 4.6.1 mail. If present, read the
   message and downloaded evidence; verify it belongs to `5153ae7e…`.
4. File R-release evidence under
   `docs/dev-log/release/0.7.0-cran-gate/candidate-julia-skip-2/` on a scoped
   docs branch. Do not infer Status and do not email Ligges.
5. Stop and await Shinichi's frozen-versus-live byte choice.

## Blockers / Open Questions

- R-release result for exact `5153ae7e…` is not yet evidenced.
- Shinichi has not chosen julia-skip-2 versus re-freeze-current-main.
- Submission authorization is explicitly absent.

## Gotchas & Failed Approaches

- The previous `8764b2fe…` R-release run hung inside
  `JuliaCall::julia_setup()`; do not attach it to repaired bytes.
- `os-matrix SUCCESS` is not package-check success.
- A green oldrelease result does not imply release is green.
- The landing gate scans every local branch and reports large foreign
  historical state. Do not clean or absorb it into this lane.

## Codex Rehydration and Live Toolchain

From the repository root, read `AGENTS.md`, this file, the coordination board,
the morning scoreboard, and the three julia-skip-2 receipts. Codex reads
`AGENTS.md` natively. Team agents are mirrored in `.codex/agents/*.toml`;
launch `.codex/agents/systems-auditor.toml` (Rose) for the mandatory fresh
audit before any release-rung claim.

Use the live environment:

```sh
export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
```

Codex owns the live toolchain in this lane: Gmail/Ligges wait and filing,
`R CMD check`, and exact-byte receipt verification. Do not run a simulation
campaign, do not touch #1033, and do not call `submit_cran()`.

## How to Resume

Start Codex in:

```text
/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/design257-1060-rebase
```

Then paste this one command/prompt:

```text
Rehydrate from docs/dev-log/handover/2026-08-18-codex-handover.md + the AGENTS.md snapshot, classify every item OWED/DONE/RETRACTED/PROTECTED, launch the mandatory Rose audit from .codex/agents/systems-auditor.toml, export R_PROFILE_USER=/dev/null and NOT_CRAN=true, then continue only the OWED Ligges wait/file Next Immediate Steps for exact 5153ae7e bytes; do not submit_cran and do not touch #1033.
```
