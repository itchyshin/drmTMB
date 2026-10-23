# After task: emmeans preflight contract tests

## 1. Goal

Refresh draft PR #1602 against current `main`, verify its focused contract tests and skip census, and prepare it for exact-head CI review. This is a test-only change.

## 2. Implemented

Merged current `main` at `2fb93b768977330fc9939d86375c37329a539277` into an isolated local worktree. The merge completed without conflicts. The test file is unchanged. The census preserves main's updated `test-mi-weights-1459.R` count and the PR's twelve emmeans skip call sites. Local merge candidate: `a4332c191f20928cb8a0ec9e139d3ea48eb1abca`; it has not been pushed.

## 3a. Decisions and Rejected Alternatives

- Kept this PR test-only; no implementation or public API change was needed.
- Synchronized by merge so both histories remain visible and no force-push is required.
- Assumption: the existing draft can be updated after its exact-head CI passes. If the author intended the draft to remain review-only, leave it unmerged and ask before changing that state.
- Golden Set: not run. This test-only source sync did not modify an identified known-mistake class.

## 4. Files Touched

- `inst/extdata/env-skip-census.tsv` (updated through current-main merge; 914 skip call sites in the combined candidate).
- `docs/dev-log/check-log.d/2026-10-22-emmeans-preflight-contract-tests.md` (updated local evidence and current-source boundary).
- `docs/dev-log/after-task/2026-10-22-emmeans-preflight-contract-tests.md` (this report).

The PR's added test, `tests/testthat/test-emmeans-preflight-contract.R`, remains unchanged; its SHA-256 is `61140ceecad21422083f94d68158af872da86ff3e9ae47b056aa07113c49e134`.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "emmeans-preflight-contract", reporter = "summary")'`: passed with no failures on the synchronized local candidate. The runner reported zero live Julia-engine tests.
- `Rscript tools/write-env-skip-census.R --check`: passed; 914 skip call sites.
- `check-after-task.R`: report structure passed. The full `closeout.py check` remains blocked because the shared Shinichi-brain acceptance check reports nine unmet ledgers outside this PR (`leaf-book`, brain-campaign, and brain-visuals gates); no foreign ledger was changed.
- `git diff --check`: passed after this report update.
- Exact-head workflow run #3520 for the earlier PR head was incomplete: one release shard was cancelled. No CI result exists yet for this local merge candidate.
- Full `devtools::test()`, `R CMD check`, pkgdown, documentation generation, and live Julia parity were not run.

## 6. Tests of the Tests

The test-only PR covers supported and refusal paths for response transforms, distributional-parameter validation, unsupported model classes, retained and recovered model frames, row alignment, link metadata, and real Gaussian fits. An independent read-only review found the assertions coherent with current helper behavior. No before/after bug-fix comparison applies because package implementation is unchanged.

## 7a. Issue Ledger

Searched open drmTMB issues for `emmeans preflight`; no matching issue was identified in the PR record. No issue or PR comment has been posted, and no issue state has changed. PR #1602 remains open and draft pending exact-head checks and review.

## 8. Consistency Audit

Compared the PR paths with current main and merged without conflict. The synchronized census check confirms that the PR's new skip sites and main's later skip-count change are both represented. The test file targets the unchanged `R/emmeans-preflight.R` contract. No family inventory, formula grammar, likelihood, vignette, pkgdown page, or generated Rd file changed.

## 9. What Did Not Go Smoothly

The PR was 30 commits behind current main, and its earlier exact-head run had a cancelled shard. The source sync is local only, so that earlier run cannot certify this candidate. The shared lane-lease registry was busy during the claim attempt; work remained in the dedicated PR worktree and used non-overlapping files from the other active PR lanes.

## 10. Known Residuals

The focused tests do not establish full package health, live Julia bridge behavior, CRAN-lane behavior, or interval calibration. Two real-fit test groups intentionally skip on CRAN and when `emmeans` is unavailable. Exact-head CI has not run on the synchronized candidate; it is not ready to merge.

## 11. Team Learning

For test-only PRs, update generated skip inventories from the synchronized source instead of carrying a stale count forward. A clean merge tree and focused test pass still require fresh exact-head CI.

## 12. Cross-Product Coverage

This slice covers only the R package's `emmeans` preflight tests and skip census. It does NOT cover Julia engine execution, full package checks, CMR routes, statistical interval calibration, pkgdown deployment, or public release readiness.

## Memory Receipt

Memory receipt: project guidance came from `AGENTS.md` and `docs/design/10-after-task-protocol.md`. The lane preflight reported concurrent PR lanes; this work stayed in its own worktree. The independent reviewer loaded the routed `r-package-engineer` and `validation-harness` instructions. No new durable project decision was made.

Golden Set: not run because this test-only source sync did not modify an identified known-mistake class.
