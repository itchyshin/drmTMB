# CRAN example corrections for the 0.7.0 resubmission

PLATFORM: codex | ON BRANCH: codex/cran-examples-resubmission-20260905 | LANE: CRAN example repair | OTHER LANES: 23 live at preflight

## 1. Goal

Address Konstanze Lauseker's 5 September CRAN review of drmTMB 0.7.0: make the named examples executable, remove unjustified `\\dontrun{}` use, confirm that `meta_vcov_bivariate()` is exported in the submitted source, and produce a checked resubmission candidate without uploading it to CRAN.

## 2. Implemented

- Made the full-profile `confint()` and `corpairs(..., conf.int = TRUE)` calls ordinary executable examples.
- Put only the 99-refit bootstrap example in `\\donttest{}` and fixed its seed.
- Removed every `\\dontrun{}` from package R source and generated manuals.
- Replaced the slow pair-prediction interval example with an ordinary `n = 30` point-prediction example that runs in about 3 seconds locally.
- Added `tests/testthat/test-cran-examples.R` to protect the reviewer-named pages, the package-wide no-`\\dontrun{}` rule, and both static and loaded-namespace export status for `meta_vcov_bivariate()`.
- Regenerated the affected Rd files and added the concise resubmission account to `cran-comments.md`.
- Built and checked exact candidate commit `0154a8318612965f60c457451d3caa890b5954eb`.

## 3a. Decisions and Rejected Alternatives

- Based the repair on `fb8e6c1a5e297941de1f7b05cf516ace0d35dbe9`, the source recorded for the actual 24 August submission. Starting from the older `6170fbe` evidence candidate was rejected once the submitted-source record was found.
- Kept `meta_vcov_bivariate()` exported. The submitted source already has `@export`, a `NAMESPACE` export, and its own help page/example; the two pages named by CRAN do not contain helper examples in this source. Removing the export would shrink a documented public surface and would not explain the generated-manual discrepancy seen by CRAN.
- Used `\\donttest{}` only for the 99-refit bootstrap. Keeping the short pair-association examples in `\\donttest{}` was rejected after timing showed they can run normally in under 5 seconds.
- Replaced, rather than merely wrapped, the pair-prediction interval example because its first executable form took 8.5--9.6 seconds and caused an example-timing NOTE.
- Did not open a PR against current `main`: `main` is hundreds of commits beyond the submitted candidate, so such a PR would not be a minimal resubmission repair. The exact hotfix branch was pushed instead.
- Did not upload to CRAN. Submission is irreversible external state and remains Shinichi's explicit final gate.

## 4. Files Touched

- `R/associate-pairs.R`
- `R/methods.R`
- `R/profile.R`
- `cran-comments.md`
- `man/confint.drmTMB.Rd`
- `man/confint.drm_pair_association.Rd`
- `man/corpairs.Rd`
- `man/predict.drm_pair_association.Rd`
- `tests/testthat/test-cran-examples.R`
- `docs/dev-log/after-task/2026-09-05-cran-examples-resubmission.md`

## 5. Checks Run

- Lane preflight: found 23 active lanes and two unrelated untracked files in the protected primary checkout; all edits were made in an isolated leased worktree.
- `devtools::document()`: passed; only the four intended generated Rd files changed.
- Focused CRAN-example regression test: 5 expectations passed.
- Direct execution of all four affected manual example blocks with `run_donttest = TRUE`: passed.
- Local elapsed times: full-profile `confint()` 0.162 s; bootstrap `R = 99` about 3.0 s; `corpairs()` profile 0.735 s; pair-association `confint()` 1.777 s; final pair prediction 2.947 s.
- Clean exact-source build: candidate tarball `/private/tmp/drmtmb-cran-resubmission.8Jb4ie/candidate-0154a8318/drmTMB_0.7.0.tar.gz`, SHA-256 `78f0e9ecebd706556ac84cad425176125bd6021d4c58cb01d65302a715a0dfb9`, 5,546,519 bytes, 949 entries; forbidden-path scan clear.
- `R CMD check --as-cran --run-donttest --no-manual` on that exact tarball: exit 0, 0 ERRORs, 0 WARNINGs, 1 expected first-submission NOTE; examples, tests, and vignettes passed.
- `pkgdown::check_pkgdown()`: passed with no problems.
- Targeted pkgdown reference build for the seven affected/adjacent pages: passed after using the same-commit `_pkgdown.yml` excluded from the source tarball.
- PDF manual build: passed, 98 pages; rendered pages for all affected/adjacent references were visually inspected and were legible without clipped or commented-out example code.
- CRAN release-gate checker self-test: all negative controls passed. The exact-candidate ledger passes at `tarball-clean`.
- Fresh three-OS GitHub Actions run `33970962071` was dispatched for exact candidate SHA `0154a8318`; it was still in progress when this report was first written.

## 6. Tests of the Tests

The new regression test was run red before the fixes: it reported both reviewer-named commented example blocks and four `\\dontrun{}` occurrences. After the changes it passed all five expectations. The first exact candidate check also produced a timing NOTE for the newly executable pair-prediction interval example; simplifying that example removed the NOTE on a rebuilt exact candidate. These two failures show that both the source guard and CRAN check can detect the targeted defect class.

## 7a. Issue Ledger

- CRAN review: fixed in exact candidate `0154a8318`; the response is recorded in `cran-comments.md`.
- Slow pair-prediction example: found during exact checking and fixed before freezing the final candidate.
- GitHub issue: none created or changed; the governing external record is the CRAN reviewer email.
- CRAN resubmission: deliberately open pending platform/external evidence and Shinichi's upload decision.

## 8. Consistency Audit

- Searched all R source and generated manuals, not only the two pages named by CRAN: no `\\dontrun{}` remains.
- Inspected all examples in `confint.drmTMB.Rd`, `corpairs.Rd`, `confint.drm_pair_association.Rd`, and `predict.drm_pair_association.Rd`; the reviewer-named commented calls are now executable and no commented-out code remains in the named example blocks.
- Verified `meta_vcov_bivariate` three ways: its R source has `@export`, `NAMESPACE` exports it, and the loaded namespace reports it as exported. Its own help page contains the example; the two unrelated formula pages do not.
- Regenerated documentation, built the reader-facing reference pages, and visually inspected the PDF manual so source, Rd, HTML, and PDF agree.
- Compared the initial base with the recorded 24 August submitted source before continuing; all initially touched source/manual files were byte-identical, then the repair was rebased onto the actual submitted source.
- Confirmed that the closeout file is outside the installed-package inventory; it is a governance record after the immutable candidate commit, not a candidate-byte mutation.

Memory receipt: the CRAN release-gate memory shaped the exact-source, exact-artifact, rung, and `--run-donttest` checks. The canonical `route.py drmTMB` call returned no manifest for this checkout, so the work used the repository's own instructions plus the hub's `WHAT-WORKS` and project records.

Golden Set: not run because this was not a known cross-repo regression class; the directly relevant CRAN gate self-test and a deliberately red new regression test were run instead.

## 9. What Did Not Go Smoothly

- The first working base was the 18 August candidate named in an older release pointer. Repository evidence later identified a different 24 August submitted source, requiring a clean rebase before freezing the repair.
- CRAN's report that the helper was unexported did not reproduce from the recorded submitted Git source: that source already exports it and lacks the reported examples on the two named pages. The repair therefore adds an executable namespace guard rather than inventing an unsupported historical explanation.
- A full development `devtools::test()` entered the package's large, slow research suite and was interrupted after more than 90 seconds rather than spending an unestimated campaign-sized run locally. The exact tarball's standard test suite later passed inside `R CMD check` in 51 seconds.
- The first exact check could not reach CRAN from the sandbox; the same command was rerun with network access and passed.
- The first executable pair-prediction example exceeded CRAN's 5-second guidance and generated a timing NOTE. It was redesigned as a smaller point-prediction example and rechecked.
- The targeted pkgdown build initially lacked the build-excluded `_pkgdown.yml`, then hit sandbox network/cache restrictions; using the same-commit config and permitted network access resolved both without changing package source.

## 10. Known Residuals

- The fresh three-OS workflow is not yet final in this first report revision.
- No exact-candidate win-builder result or other new external check has been collected for this source.
- No independent Grace/Rose/Pat submission panel has signed this candidate.
- The candidate has not been uploaded to CRAN and is not claimed `platform-clean` or `submission-ready`; the highest proven rung is `tarball-clean`.
- The hotfix is intentionally not merged into current `main`, whose much newer development contents are outside this resubmission lane.
- The exact tarball currently lives under `/private/tmp`; its hash, size, source commit, inventory, and check log are recorded, but a durable release bundle still needs to be placed at the final submission location before upload.

## 11. Team Learning

- For a CRAN resubmission, identify the source that was actually uploaded before editing; the nearest frozen-candidate pointer may be historical.
- Turning a reviewer complaint into a package-wide executable guard is stronger than editing only the named Rd files: loaded-namespace export status and all `\\dontrun{}` occurrences are now checked together.
- Making an example executable can expose a second defect class -- timing -- so the final check must include `--run-donttest` and the example timing table, not merely successful evaluation.
- Generated-manual claims can disagree with the recorded Git source. Preserve the discrepancy honestly, fix the reproducible contract, and avoid asserting an unproven cause.

No durable brain-vault update was written because the user did not authorize a memory update; the reusable facts are preserved in this repository report.

## 12. Cross-Product Coverage

- Covers: the exact 0.7.0 submitted-source line; R source, generated Rd, loaded namespace exports, ordinary examples, `\\donttest{}` examples, targeted pkgdown pages, PDF manual rendering, exact tarball inventory, and local CRAN-style checking.
- Covers: the four association/profile example surfaces named or implicated by the CRAN message and the package-wide absence of `\\dontrun{}` in R/man.
- This repair does NOT cover: current `main` development features, likelihood or estimator behavior, inference/coverage claims, sanitizer/valgrind results, win-builder, CRAN's own incoming checks, or CRAN acceptance.
- This repair does NOT cover: submission authorization. A green local artifact and a green three-OS workflow, once final, do not themselves upload the package.
