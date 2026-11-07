# Session handoff: DRM parity and cleanup

To Claude Code, from Codex, 2026-11-07. Revalidate all dated state below before acting. Read the repository's `AGENTS.md`, its canonical personal contract and the coordination board. This handoff is for the DRM core; CJSModels is a separate effort.

## Mission and plan

Shinichi wants drmTMB and DRModels.jl finished as reliable R and Julia distributional-regression packages. Reconcile supported routes and R–Julia parity against source-pinned evidence, fix verified defects, complete tests and user documentation, and preserve exact scope and limitations. Start with the cleanup and receipt PR below, then review the remaining parity crosswalk and prioritize concrete gaps. Do not claim broad parity from focused fixtures. CMR/CJS was separated into its own package lane; CMR coverage calibration was deferred and must not be treated as a DRM-core prerequisite.

| Repository | Current work | Evidence and next direction |
| --- | --- | --- |
| drmTMB | Receipt branch `fix/phylo-bridge-receipt-20261107`, PR #1682 draft | One phylogenetic bridge fixture passed; exact-head CI passed; complete review and seek separate merge authorization. |
| DRModels.jl | Parity PR #1252 merged as `976c1ac3710c6f14cf4574dc17fdf56523d502d8` | Native shards and docs passed; R parity tests were skipped. Continue route-specific evidence. |
| Both | Priors PRs R #1681 and Julia #1258 belong to a separate lane | Preserve their work and review their own current status before overlap. |

## Critical context

The authorized cleanup goal is to organize accumulated work into owner-attributed, reviewable changes: reconcile dirty worktrees, local commits, PRs, CI and evidence; preserve all concurrent work; push only complete attributable slices; and document remaining parity. Do not discard work, merge, release, publish or deploy without separate user authorization. User approved ownership of the specific receipt refresh. Do not treat that as ownership of other priors files or branches.

The primary worktree for this handoff is `/Users/z3437171/.codex/worktrees/drm-receipt-refresh-20261107/drmTMB`. Do not stage or restore its `.claude/settings.json` or `.cursor/hooks.json`. Multiple active and historical lanes exist. The shared handover pointer was deliberately not changed because it would orphan sibling lanes; inspect `docs/dev-log/coordination-board.md` and the live lane inventory first. The earlier local consolidated evidence handoff is `/Users/z3437171/Documents/Codex/drm-cleanup-evidence-20261104/HANDOFF.md`; it is local evidence, not a substitute for remote branches.

## Accomplished and current state

R parity PR #1657 merged as `623eed27b37d53dab4af56564f1e87624929d40e`. Julia PR #1252 merged as above; Julia main Documenter run 42328456324 succeeded. R main receipt-staleness run 42308236210 failed because the existing priors bridge receipt no longer matched `R/methods.R`. Earlier main run 42298071193 had the same failure before #1657 merged.

The receipt was reproduced on Totoro using R `623eed27b37d53dab4af56564f1e87624929d40e` and Julia `f940fc4042ee2832c3343f7d334e830a96942f1b`. All eight fixture checks passed, 12 mutated receipts were rejected, and the local CI-equivalent check passed on the receipt branch. It verified 66 R files and the runner; 115 Julia entries were not verified locally, while the Totoro checker used the pinned Julia checkout. The prior receipt and README are preserved byte-for-byte with their historical checksum manifest. This supports one fixture, not interval calibration or general parity.

At this snapshot, draft PR #1682 head `1e334f1ca47e16c5aa80ba33070f36f21feb116c` has a successful R-CMD-check run 42366509228: the source-tree job, matrix setup and all four package-check shards passed. GitHub recorded no review decision. Inspect the exact run and current PR state before taking further action. Recheck the PR head, branch protection and main before review or merge. A merge requires separate authorization.

## Landing state and gate

The handoff gate flagged two modified settings files in this worktree and 1,047 unpushed commits on other local branches at inspection. It did not establish that those foreign commits are disposable or ours to push. The full local output is `/Users/z3437171/Documents/Codex/drm-cleanup-evidence-20261104/handoff-gate-20261107.txt`; rerun the gate for live state. Do not clean, reset, prune, stage or push foreign work.

| Artifact | State | Reason and resume |
| --- | --- | --- |
| R `fix/phylo-bridge-receipt-20261107` at `1e334f1ca47e16c5aa80ba33070f36f21feb116c` | CARRIED-OVER: committed, pushed, draft PR #1682 | Review and a separate merge decision remain. Run `gh run view 42366509228 -R itchyshin/drmTMB` and `gh pr view 1682 -R itchyshin/drmTMB`. |
| `.claude/settings.json`, `.cursor/hooks.json` in this checkout | PROTECTED, uncommitted | Unrelated. Inspect `git status --short`; do not stage or restore. |
| Other local unpushed branches and dirty worktrees | PROTECTED / CARRIED-OVER | Ownership is not established. Run `~/shinichi-brain/tools/lane_preflight.sh "$PWD"` and `~/shinichi-brain/tools/handoff_gate.sh "$PWD"`; do not alter them. |
| This handover | CARRIED-OVER on pushed `handover/drm-to-claude-20261107` | Read on its named branch; verify its final commit and PR state. |

FINDINGS-OF-RECORD: none. The receipt result is a source-bound CI reproduction, not a new method finding.

## Files created or modified in the receipt branch

The branch changes `docs/dev-log/check-log.md`; `docs/dev-log/after-task/2026-11-07-priors-bridge-receipt-refresh.md`; and `docs/dev-log/priors-lane-20261105/release-default-bridge-recheck/{README.md,README-before-20261107.md,SHA256SUMS,current.json,current-before-20261107.json}`. New evidence under `docs/dev-log/priors-receipt-refresh-20261107/` comprises `README.md`, `SHA256SUMS`, `checker.log`, `ci-staleness.log`, `current-candidate.json`, `historical-manifest-check.log`, `install.log.gz` and `runner.log`. This handover is `docs/dev-log/handover/2026-11-07-claude-handover.md`. Enumerate exact current branch paths with `git diff --name-only 623eed27b37d53dab4af56564f1e87624929d40e...HEAD`.

## Next immediate steps

1. Run lane preflight, inspect `git status`, current GitHub refs, the coordination board and this handoff. Classify each item `OWED`, `DONE`, `RETRACTED` or `PROTECTED`.
2. Inspect exact-head CI run 42366509228 and retain failure details or all results. Review receipt provenance and the manifest without changing its historical evidence. If checks fail, reproduce and attribute the failure before editing.
3. Once review and checks are complete, present the exact PR state to Shinichi for the separate merge decision. Check post-merge main CI if a merge is authorized and completed.
4. Return to the dated parity crosswalk and open PR/ownership inventory. The 22 unreconciled capability names need route-specific evidence, not automatic promotion. Consult the existing handoff and live source before selecting a small owner-safe slice. Keep the prior lane and separate CJS work protected.

## Gotchas and environment

The first incremental Git bundle transfer to Totoro failed with unresolved deltas before any fit; a full bundle succeeded. The direct Mac receipt checker failed because the recorded Totoro Julia path is unavailable locally; the CI wrapper intentionally reports Julia entries unverified without `DRM_JL_PATH`. Do not convert that limitation into a pass. Totoro reproduction is at `/tmp/drm-receipt-refresh-623-20261107/`, subject to temporary-file cleanup; durable evidence is committed in the branch. Use single-threaded R/Julia and the exact pinned source for comparisons. Estimate runtime before new compute and preserve failure denominators. Claude should verify its actual toolchain and credentials; do not assume any agent can compile, render or contact external services without checking.

## How to resume

From the receipt worktree or a checkout of its pushed branch, start a fresh authenticated Claude session and paste:

`Read AGENTS.md and docs/dev-log/handover/2026-11-07-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.`
