# Session Handoff: staged drmTMB 0.7.0 candidate preparation

Meta: 2026-08-09 · from Codex to two Claude tasks · two subject lanes, separate worktrees

## Critical Context

This packet serves **two separate Claude tasks**. Task 1 owns staged 0.7.0 candidate preparation in a new clean worktree from refreshed `origin/main`. Task 2 owns the existing complete/quasi-complete separation experiment only in `/Users/z3437171/local-scratch/worktrees/drmTMB-separation-s0`. Each task must classify and execute only its named lane. **Do not continue in the dirty primary checkout, edit the other task's worktree, or cross-stage between lanes.**

The leverage item is a synchronization gate: the separate complete/quasi-complete separation lane must reach a reviewed finite disposition before the final candidate SHA, DESCRIPTION version, or definitive tarball is frozen. A finite disposition means one of: (1) validated package work merges; (2) the experiment is explicitly deferred with no demonstrated package defect; or (3) a demonstrated release-relevant defect is repaired and verified.

`origin/main@ac363cadb605a2eda567de9027b873eebc4788c5` is only the orientation baseline. GitHub run `31300437472` is green at that exact SHA. DESCRIPTION remains `0.6.0`. There is no current exact 0.7 tarball and the release verdict is **NOT READY**.

## Goals / mission

Prepare one exact, honest first-CRAN candidate for drmTMB 0.7.0 without broadening its scientific claims or swallowing foreign lanes. Trust capability by exact cell/evidence tier. Keep Julia optional. Preserve the fail-closed CRAN rung ladder.

## Plans / roadmap

Authority is the staged ultra-plan:
[`docs/dev-log/2026-08-09-0.7-candidate-preparation-staged-ultra-plan.md`](../2026-08-09-0.7-candidate-preparation-staged-ultra-plan.md).

Task 1 may run candidate Stage A now: release-gate orientation, predecessor-instrument salvage, and provisional product-contract audit, then wait at Gate H. Task 2 independently owns bounded separation rehydration and the reviewed finite disposition. Stage B is held until task 2's disposition receipt and any accepted change are merged: task 1 then refreshes a clean current-main worktree, freezes source, bumps DESCRIPTION inside the release slice, lands the intended release bytes, and builds one immutable tarball from refreshed main for exact-artifact local/authorized external checks.

## What Was Accomplished

- Loaded and applied `ultra-plan`, `cran-release-gate`, `r-package-engineer`, `validation-harness`, `ask-brain`, and `handover-to-claude` instructions.
- Refreshed `origin/main` and confirmed `ac363cadb`; final-main CI run `31300437472` is green.
- Confirmed open protected lanes: #858 and #937. Historical #947 is merged and remains historical.
- Ran repository, worktree, stash, brain-semantic, deterministic-history, release-lane, and separation sweeps.
- Established that `cursor/07-cran-readiness` is 39 main commits behind with two branch-only receipt commits; `cursor/07-tarball-clean` is 37 behind with two branch-only receipt commits. Reuse their instruments, never their artifact identity or rung proof.
- Read the separation S0-A2 closeout. Its branch `codex/fixed-design-binary-separation-experiment@a28522579` is 14 behind / 3 ahead, deliberately unpushed, backed up by the brain daily process, and has no package integration or PR.
- Ran a routed Luna read-only recon. It returned NOT READY/HOLD and a valid dispatch manifest, but could not write its long report because its read-only sandbox rejected `apply_patch`; the ultra-plan contains the completed evidence-cited sweep.
- Created this clean docs-only handover worktree at `/private/tmp/drmTMB-07-candidate-handover` on `codex/handover-07-candidate-prep-0809` from `origin/main`.
- No package implementation, version bump, tarball build, external check submission, compute, D-43, tag, release, or upload was performed.

## Current Working State

- **Working:** canonical `main` and CI; capability truth; issue sweep; new docs-only handover lane.
- **In progress:** task 1 owns staged candidate preparation; task 2 owns separation finite-disposition work. Ownership is deliberately separate.
- **Blocked:** definitive candidate freeze, DESCRIPTION bump, and definitive tarball until the separation lane has a reviewed finite disposition.
- **Not working / retained STOP:** S0-A2 exact detector completion. The LP backend returned nominal success with an infeasible zero vector on the overlap negative control. All 121 objective-ray checks passed, but no valid overlap infeasibility certificate exists. Optional `brglm2` calls also used an unsupported interface. This is not yet a drmTMB defect.

## Key Decisions & Rationale

- **D-49:** one immutable tarball; predecessor results do not transfer to a new hash.
- **D-86:** first CRAN version is 0.7.0; version bump occurs inside the release slice, not before it.
- **D-93 / D-117:** measurement and warning exist; PASS remains withheld and the publish/discharge decision remains Shinichi's. Do not rerun D-117.
- **Owner 2026-08-09:** proceed with staged candidate preparation but wait for the separation disposition before freeze.
- #61 is the sole issue-derived procedural candidate blocker. #870 is a separate owner-policy decision, not a demonstrated defect.
- The paper programme, AGHQ/O3 expansion, broader REML, structured slopes, and new compute campaigns are not hidden candidate requirements.

## Files Created / Modified

This handover lane owns only:

- `docs/dev-log/2026-08-09-0.7-candidate-preparation-staged-ultra-plan.md`
- `docs/dev-log/handover/2026-08-09-claude-handover.md`
- `docs/dev-log/active-lane-split.md`
- `AGENTS.md`

Do not stage anything from the dirty primary checkout, separation worktree, old release worktrees, #858, or #937.

## Landing State

`handoff_gate.sh` was run with `bash`. It failed closed because the protected primary contains 96 uncommitted paths, its stale HEAD has two unpushed commits, and numerous historical branches are off-remote. Those states predate this handover and are declared below; they were not cleaned, staged, rebased, pushed, or merged.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `origin/main@ac363cadb` (#954 closeout) | yes | yes | #954 merged | LANDED |
| `codex/handover-07-candidate-prep-0809` | pending at document authoring | pending | none yet | HANDOVER SLICE — commit/push/open PR before chat close |
| Primary `claude/handover-freshness-0718` | mixed historical state | no for all local content | none | PROTECTED — 96 uncommitted paths; never work/stage there |
| `codex/fixed-design-binary-separation-experiment@a28522579` | yes, 3 local commits | deliberately no | none | TRANSFERRED TO CLAUDE at retained STOP; existing worktree only: `cd /Users/z3437171/local-scratch/worktrees/drmTMB-separation-s0 && git status --short --branch` |
| `cursor/07-cran-readiness@bff30dded` | yes | yes | historical | CARRIED-OVER predecessor instruments; 39 behind, evidence not transferable |
| `cursor/07-tarball-clean@f065fc905` | yes | yes | historical | CARRIED-OVER predecessor instruments; 37 behind, tarball identity not transferable |
| #858 `codex/lane-b-e0-readiness` | yes | yes | open draft | PROTECTED foreign lane |
| #937 `claude/land-gva-decision` | yes | yes | open | PROTECTED foreign lane |
| historical #947 | yes | yes | merged | PROTECTED history; do not rewrite |
| five repository stashes reported by `git stash list` | n/a | n/a | n/a | PROTECTED; do not pop/drop |

## Common rehydration — both Claude tasks

1. Read `AGENTS.md`, `docs/dev-log/active-lane-split.md`, this handover, and the staged ultra-plan. Run `python3 '/Users/z3437171/Dropbox/Github Local/Shinichi/tools/route.py' drmTMB` and `bash '/Users/z3437171/Dropbox/Github Local/Shinichi/tools/lane_preflight.sh' '/Users/z3437171/Dropbox/Github Local/drmTMB'`.
2. Classify every item here as `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`. Execute only the OWED steps for your assigned task.
3. If this handover PR is not yet merged, fetch `codex/handover-07-candidate-prep-0809` and read its exact head. Do not make implementation depend on unreviewed edits elsewhere.

## Claude task 1 — candidate-preparation lane OWED steps

1. Read `docs/dev-log/release-audits/2026-08-08-0.7-issue-sweep.md` and the full CRAN release protocol. Run `git fetch origin main` and `git log --all --oneline -20`.
2. Create the candidate execution lane from refreshed `origin/main`, not from the dirty primary and not from the separation branch. Recommended:
   `git worktree add -b claude/07-candidate-preparation-staged /private/tmp/drmTMB-07-candidate-prep origin/main`
3. If the handover docs are not merged, cherry-pick the exact handover head into this new lane so its authority and plan travel with the work.
4. Run Stage A only—Gate -1/0 orientation, authoritative CRAN-policy refresh, predecessor-instrument salvage, rights/product-contract inventory, and provisional scope freeze. Keep verdict NOT READY and DESCRIPTION `0.6.0`.
5. Wait at Gate H for task 2's reviewed disposition receipt to merge. Read that artifact; never stage task 2's worktree.
6. After Gate H, refresh current `origin/main` and verify the merged disposition and intended release state. Stage B must land the intended `0.7.0` release bytes before the definitive build. Build, hash, and check the definitive tarball only from a fresh clean worktree at the merged main SHA; any pre-merge tarball is provisional and its evidence does not transfer.
7. Return the exact candidate decision packet to Shinichi and stop before D-43, unsupported `platform-clean`, final `cran-comments.md`, tag, release publication, or upload.

## Claude task 2 — separation lane OWED steps

1. Enter only `/Users/z3437171/local-scratch/worktrees/drmTMB-separation-s0`; run `git status --short --branch`, `git log --all --oneline -20`, and read `docs/dev-log/after-task/2026-08-08-separation-s0a2-cone-experiment.md` there.
2. Preserve the three commits and current unpushed state while rehydrating. Do not touch the candidate worktree, dirty primary, #858, #937, or historical #947.
3. Repair or replace the invalid LP infeasibility check and unsupported `brglm2` interface only if needed to reach a finite evidence-backed decision. Do not claim detector PASS from current S0-A2 evidence.
4. Obtain fresh bounded Fisher and Grace reviews. Write `docs/dev-log/after-task/2026-08-09-separation-finite-disposition.md` with exactly one reviewed disposition: MERGE validated package work, DEFER with no demonstrated release defect, or DEFECT repair with tests and review.
5. Land that receipt—and any accepted package work—through this lane's own reviewed PR. Notify task 1 only with the exact merged SHA, PR, disposition, and receipt path. Do not perform candidate preparation.

## Blockers / Open Questions

- Separation disposition: unresolved and intentionally fail-closed.
- #870: explicitly defer or obtain a separate owner decision before candidate freeze.
- D-93/D-117: owner publish/discharge call remains; candidate preparation does not answer it.
- External services may introduce latency or require credentials; their absence does not authorize a higher rung.

## Gotchas & Failed Approaches

- `handoff_gate.sh` requires `bash`, not `sh`; `sh` fails on process substitution.
- The Luna recon was correctly routed but could not create its requested report under a read-only sandbox. Its short result and dispatch manifest exist under `/tmp`; do not call that a complete independent report.
- Do not copy the predecessor release ledger and change only its SHA. Re-run every identity-bearing gate.
- Do not describe solver status 0 as an overlap certificate; the returned solution violated the constraint by 1.
- Do not use finite coefficients, optimizer convergence, `pdHess`, bias reduction, or a strict-margin optimum of zero as proof that the unpenalized finite MLE exists.
- Do not rerun D-117, the 135-trace campaign, or any compute campaign.
- Never `git add -A` in this repository.

## Mission Control

| Repo | Branch / main | CI and current truth | Plan by leverage |
| --- | --- | --- | --- |
| drmTMB | `main@ac363cadb`; handover `codex/handover-07-candidate-prep-0809` | main run `31300437472` green; DESCRIPTION 0.6.0; NOT READY; no exact 0.7 tarball | 1. Stage A release orientation; 2. separation finite disposition; 3. post-disposition exact freeze/build/check; 4. owner decision packet |
| Separation lane | `codex/fixed-design-binary-separation-experiment@a28522579` | retained STOP; no package PR; deliberately unpushed | transferred to Claude in existing worktree; reviewed MERGE / DEFER / DEFECT disposition only |
| DRM.jl | separate optional twin | not a CRAN dependency for drmTMB | preserve optionality; no work in this arc |

## How to Resume

Working directory for the handover read:

```sh
cd /private/tmp/drmTMB-07-candidate-handover
git status --short --branch
```

R commands, after the execution lane exists and only when their slice is authorized:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::document()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::check()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgdown::check_pkgdown()'
```

Claude must not assume it lacks the compiler: test the live toolchain. If the live R/TMB toolchain is unavailable, checkpoint the exact command/evidence needed and hand it over turnkey; never substitute a narrower logic test for an exact-artifact gate.

Paste-ready prompt for **Claude task 1 — candidate preparation**:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-09-claude-handover.md. You own Claude task 1 only: staged drmTMB 0.7.0 candidate preparation in a new clean worktree from refreshed origin/main. Execute the common rehydration and task-1 OWED steps, keep NOT READY and DESCRIPTION 0.6.0 through Stage A, and wait at Gate H for the separate Claude task 2 disposition receipt. Do not edit the separation or dirty-primary worktrees. Stop before D-43, unsupported platform-clean, final cran-comments.md, tagging, release publication, or CRAN upload.
```

Paste-ready prompt for **Claude task 2 — separation disposition**:

```text
First read /private/tmp/drmTMB-07-candidate-handover/AGENTS.md and /private/tmp/drmTMB-07-candidate-handover/docs/dev-log/handover/2026-08-09-claude-handover.md; these authority docs are not yet present on the 14-behind separation branch. You own Claude task 2 only: the complete/quasi-complete separation experiment in /Users/z3437171/local-scratch/worktrees/drmTMB-separation-s0 on codex/fixed-design-binary-separation-experiment. Execute the common rehydration and task-2 OWED steps, preserve the existing three commits and unpushed state while orienting, and produce one fresh-reviewed MERGE, DEFER, or DEFECT disposition receipt. Do not edit the candidate-preparation or dirty-primary worktrees and do not perform candidate release work.
```
