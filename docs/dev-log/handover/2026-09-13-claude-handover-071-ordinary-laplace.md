# Session handover: Claude — 0.7.1 ordinary-Laplace CI repair

**From:** Codex  
**To:** Claude  
**Date:** 2026-09-13  
**Working directory:** `/Users/z3437171/local-scratch/lanes/drmTMB-071-ordinary-laplace-bridge`  
**Branch / PR:** `codex/071-ordinary-laplace-bridge` / draft [PR #1304](https://github.com/itchyshin/drmTMB/pull/1304)

## Critical context

You are Claude, taking over only a narrow CI-repair slice of the source-pinned 0.7.1 ordinary-random-intercept R–Julia parity arc. The implementation and evidence are already retained on this branch. Do **not** rerun the campaign and do **not** alter source pins, manifests, target labels, frozen fixtures/DGPs, the two-hour profile cap, denominators, or the bounded coverage interpretation.

The issue is CI staging/reconciliation, not an evidence failure: current-source C17 compatibility passed in the CI log, including `C14 receipt equivalence: OK (3 eligible, 7 source-different retained receipts; C17 current-source compatibility PASS)`.

The DRM.jl branding work is separately complete and publicly deployed. It is not part of this handover and must not be reopened here.

## Goals / mission

Finish the draft PR's test and generated-artifact repair so the retained 0.7.1 parity result is reviewable. Keep the claimed scope exactly: four frozen ordinary-RI/coupled-NB2 scenarios with classified same-target evidence, not general interval calibration or release readiness.

## What was accomplished

- Added the scalar `marginal = :Laplace` parity route and bridge/evidence plumbing represented by this branch.
- Retained source-pinned campaign receipts and source-subset reconciliation evidence.
- Recertified the model-15 compatibility receipt in `81e080176`.
- Opened draft PR #1304; do not merge or release it.
- Wrote an earlier Cursor handover at `docs/dev-log/handover/2026-09-13-cursor-handover-071-ordinary-laplace.md`; this Claude handover supersedes it for the active CI repair.

## Current working state

The branch was clean at handover and its latest commit was `8744b91d7` (`docs: hand off ordinary Laplace CI repair to Cursor`). The latest CI run is [34734561536](https://github.com/itchyshin/drmTMB/actions/runs/34734561536). It has passing OS-matrix work but failures in the blind-spot source-tree test and release shards 1–4.

The main reproducible failures are:

- `tests/testthat/test-071-four-fixture-summary.R`: expected staged receipt / source-proof / manifest / fixture / attempt / worker / FIR-array / reconciliation / coverage-summary inputs are absent or resolved against the wrong current-tree location.
- `tests/testthat/test-julia-gate-vs-engine.R:176`: the Julia capability-comparison artifact does not match the registry.

The correct repair target is the staging contract and generated artifact wiring. Never fabricate evidence bytes or substitute current checkout files for retained source-pinned proof inputs.

## Key decisions and rationale

- `:LA` remains GHQ-32; `:Laplace` is distinct and must never be relabelled as `:LA`.
- Retained historical receipts may be source-different by design; C17 checks their current-source compatibility without rewriting provenance.
- Missing/non-finite profile outcomes remain classified failures in the original denominator.
- CI must be repaired in a way that preserves the retained Nibi source-subset proof contract and its positive, tamper, and missing-required-file tests.
- Claude may plan, refactor, write prose, and run pure-logic/CI checks. If diagnosis truly needs live R/TMB or Julia fits, hand that bounded command back to Codex rather than widening this lane.

## Files created / modified

The authoritative complete list is `git diff --name-only origin/main...HEAD`. The changed paths are:

```text
.gitignore
DESCRIPTION
R/drmTMB.R
R/julia-bridge.R
R/profile.R
README.md
docs/design/01-formula-grammar.md
docs/design/04-random-effects.md
docs/design/143-phase-18-structured-workflow-registry.md
docs/design/capability-status.md
docs/design/parity-matrix.md
docs/design/parity-scoreboard.md
docs/dev-log/after-task/2026-09-09-071-ordinary-laplace-native-coupled-nb2.md
docs/dev-log/after-task/2026-09-12-071-ordinary-laplace-closeout.md
docs/dev-log/after-task/2026-09-12-071-source-subset-proof-reconciliation.md
docs/dev-log/check-log.d/2026-09-09-071-*.md
docs/dev-log/check-log.d/2026-09-11-071-*.md
docs/dev-log/check-log.d/2026-09-12-071-*.md
docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv
docs/dev-log/dashboard/julia-capabilities.tsv
docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/*
docs/dev-log/handover/2026-09-13-cursor-handover-071-ordinary-laplace.md
docs/dev-log/implementation-recovery/2026-09-12-ordinary-laplace-merge-c17c2-c14-final-source-compatibility/*
docs/dev-log/known-limitations.md
inst/extdata/julia-capabilities.tsv
src/drmTMB.cpp
tests/testthat/test-071-four-fixture-summary.R
tests/testthat/test-julia-bridge-coef-labels.R
tests/testthat/test-julia-bridge.R
tests/testthat/test-nbinom2-location-scale.R
tools/write-parity-matrix.R
tools/write-parity-scoreboard.R
vignettes/formula-grammar.Rmd
```

This handover adds `docs/dev-log/handover/2026-09-13-claude-handover-071-ordinary-laplace.md`.

## Landing state

| Repository | Branch / state | CI / what shipped | Next action |
| --- | --- | --- | --- |
| drmTMB | `codex/071-ordinary-laplace-bridge`, draft PR #1304 | Retained parity implementation/evidence; CI repair owed | Repair only staging/registry expectations, then push and keep draft |
| DRM.jl | `main`, merge `cdcbcfea28010a7b44e0d75571f13311ec55b171` | Branding merged and Documenter deploy passed | Protected/done; no action in this lane |
| drmTMB sibling lanes | Protected | Handoff gate reports 769 unpushed commits on unrelated branches | Do not inspect, stage, push, or reconcile them |

The repository has multiple concurrent lanes. Do **not** update the single `AGENTS.md` live-snapshot pointer: doing so could orphan a sibling lane.

## OWED next immediate steps

1. Run lane preflight and rehydrate from the files below before editing:

   ```sh
   /Users/z3437171/shinichi-brain/tools/lane_preflight.sh /Users/z3437171/Dropbox/Github\ Local/drmTMB
   git status --short
   gh run view 34734561536 --repo itchyshin/drmTMB --log-failed
   ```

2. Classify every handover item as `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`. Read `AGENTS.md`, this handover, `docs/dev-log/after-task/2026-09-12-071-ordinary-laplace-closeout.md`, and `docs/dev-log/after-task/2026-09-12-071-source-subset-proof-reconciliation.md`.

3. Reproduce the summary test narrowly, repair the source staging / generated registry wiring, and add or preserve tests for positive, tampered, and missing-required-source-file cases. Begin with:

   ```sh
   Rscript -e "testthat::test_file('tests/testthat/test-071-four-fixture-summary.R')"
   ```

4. Regenerate only the capability outputs justified by their source inputs; then run the smallest affected tests. Commit explicit paths, push the existing branch, and re-check PR #1304. Keep it draft until all required checks are green.

## Blockers / open questions

- The handoff gate is globally red only because it finds 769 unpushed commits on unrelated protected branches. This branch itself was clean and already pushed; do not resolve that unrelated global condition.
- If a CI failure demands a new campaign, manifest target, fixture, pin, or denominator, stop and return the decision to Shinichi. That would exceed this repair authority.

## Gotchas / failed approaches

- Do not replace source-pinned receipt files with current checkout bytes merely to satisfy tests.
- Do not delete source-different retained receipts: their source difference is intentional and C17 compatibility is the admission route.
- Do not run campaign artifacts in GitHub Actions.
- Never stage `.unlazy`, generated local build output, foreign worktree files, or other-lane changes.
- Do not merge PR #1304 or make a release.

## How to resume

Use the branch directory above. Claude should handle the refactor/logic/CI side; Codex remains the live R/TMB/Julia execution route if one becomes genuinely necessary. The safe first verification is the one-file test command in the OWED list; avoid a full campaign or broad test suite until the staged-source failure is understood.

Read AGENTS.md and docs/dev-log/handover/2026-09-13-claude-handover-071-ordinary-laplace.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
