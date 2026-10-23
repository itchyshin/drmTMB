## 1. Goal

Repair the stale C17/C14 receipt in the isolated CMR PR candidate and align the reader-vignette map with the current CJS page.

## 2. Implemented

Merged current drmTMB main into the CMR repair lane without conflicts. Re-ran the 12-fit C17/C14 compatibility check, updated the three matching receipt rows, and added the CJS page to the specialist branch in the reader map. The source fingerprint stayed unchanged.

## 3a. Decisions and Rejected Alternatives

Kept the receipt narrow to its three existing model-15 compatibility routes. Did not describe it as CMR recovery or interval calibration. Kept CJS in the specialist branch because its hidden-state likelihood and first-capture conditioning differ from ordinary response-family formulas.

Assumptions made without asking: the CJS tutorial belongs in the specialist branch; if Shinichi prefers a different navigation grouping, only the placement label and rationale need revision.

## 4. Files Touched

- `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`
- `docs/dev-log/implementation-recovery/2026-10-22-cmr-pr1612-merged-main-recert-v1/`
- `docs/design/226-reader-learning-path.md`
- `docs/dev-log/check-log.d/2026-10-22-cmr-pr1612-local-repair.md`
- `docs/dev-log/after-task/2026-10-22-cmr-pr1612-local-repair.md`

The local merge commit is `cdf87f2851f327d55f2d230d20820fc2ed267174`; the evidence and reader-map updates are in `117f9fcce2270528297e9c0f35f3682c433aee52`. After local verification, that commit was pushed to the existing `codex/cmr-page-integration` branch for PR #1612. No PR merge or deployment action occurred.

## 5. Checks Run

- `C17_COMPAT_RUN_ID=2026-10-22-cmr-pr1612-merged-main-recert-v1 R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-lane-c-c17c1-c14-model15-compatibility.R`: passed 12/12 fits, four per route, in 1 minute 39 seconds. Mean tau relative errors were 0.0990, 0.1661, and 0.0613.
- `python3 tools/capability_ledger.py --check`: passed, 31 generated outputs.
- `python3 -m unittest tools.tests.test_capability_ledger`: passed 81/81 after the reader-map correction.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-reader-vignette-contracts.R", reporter = "summary")'`: passed 35 expectations.
- `git diff --check`: passed.
- `python3 tools/memory_regression.py --selftest`: all Golden Set detectors passed their self-tests.

The full R package suite was not rerun. After local verification, the candidate was pushed to PR #1612; exact-head GitHub checks are pending.

## 6. Tests of the Tests

The Python ledger test initially failed because the design title said 38 vignettes while the manifest and test counted 39. Adding the CJS page and correcting the count made all 81 checks pass. This failure demonstrates that the test detects this reader-map drift.

## 7a. Issue Ledger

- Fixed locally: C17/C14 receipt was stale for the CMR candidate's `src/drmTMB.cpp` blob.
- Fixed locally: CJS tutorial was absent from the reader-map table and the documented total was one short.
- Still open: drmTMB PR #1612 now points to `117f9fcce2270528297e9c0f35f3682c433aee52`; exact-head CI has not yet returned results.
- Deferred: interval availability/recovery qualification and all repeated-sample coverage or calibration work.

## 8. Consistency Audit

Checked the manifest count, reader-map table, three receipt rows, current model-15 fingerprint, runner source hashes, generated capability outputs, and the reader-vignette contract test. All agree on this local candidate. The compatibility check covers only the existing sigma-intercept, zoi-intercept, and sigma-slope model-15 routes.

## 9. What Did Not Go Smoothly

The first bounded run was pinned to the pre-merge candidate and could not certify the merged source. I preserved its receipt outside the repository and repeated the check after pinning the merge commit. The first ledger test exposed the separate reader-map count drift, which is now fixed.

## 10. Known Residuals

No full package test was run. No route-wide CMR recovery or interval availability campaign was run. Repeated-sample interval coverage and calibration remain deferred to Phase B. The remote PR remains open and the article is not confirmed deployed. The broader open-PR scans found no safe quick closeouts: 57 drmTMB PRs and 37 DRModels.jl PRs were assessed, with their nearest candidates held by stale bases or failed/cancelled checks. The closeout compiler's structural check passed, but its acceptance-ledger gate is blocked by nine unrelated unmet gates in the global brain campaign; those gates are outside this worktree and were left untouched.

## 11. Team Learning

For source-bound compatibility evidence, merge the intended base first, then run once against that pinned source and point only the matching ledger rows at the resulting receipt. Preserve the authenticated model fingerprint when only surrounding source changed. Memory receipt: loaded the routed drmTMB and DRM.jl manifests; the exact-source and compute-routing rules shaped this repair. Golden Set: `memory_regression.py --selftest` passed; no transcript was submitted for a Golden Set verdict.

## 12. Cross-Product Coverage

Covers: drmTMB's three existing C17/C14 model-15 routes, generated capability-ledger checks, and the R reader-vignette count contract.

Does NOT cover: Julia implementation or parity, the R-to-Julia bridge, any CMR recovery result, interval availability across supported CMR routes, repeated-sample interval coverage/calibration, the full R package suite, or public documentation deployment.
