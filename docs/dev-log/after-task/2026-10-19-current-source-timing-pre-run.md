# After Task: Current-Source Bernoulli Timing Pre-Run

## 1. Goal

Measure runtime and fit health for the current dirty drmTMB source snapshot on Totoro before using its timings to plan recovery work. This was a 45-fit timing-only pre-run; recovery, coverage, and calibration were outside its scope.

## 2. Implemented

Built drmTMB 0.7.1 from the current worktree snapshot at HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`, installed it into isolated temporary libraries on macOS and Totoro, then ran 45 independent synthetic Bernoulli fits on Totoro. The design used `y ~ x + (1 | id)` with `sd(id) ~ w`, 15 seeds at each log-SD slope `a = -0.5, 0, 0.5`, and 95% fitted profile intervals.

All 45 attempts completed with valid intervals, zero warnings, zero worker errors, and passing convergence, Hessian, gradient, clamp, and independent Laplace-oracle checks. Supervisor wall time was 29.052 seconds. Mean fit time was 7.664 seconds, median 7.730 seconds, 90th percentile 9.049 seconds, minimum 6.048 seconds, and maximum 9.749 seconds. The 45-row manifest used fresh seeds disjoint from the historical streams recorded by `clean-manifests.R`.

### Mathematical Contract

For group `i`, the Bernoulli random intercept has standard deviation `exp(log(0.8) + a * w_i)`, where `w_i` is the simulated group-level predictor. The worker fits the Bernoulli likelihood with a latent Gaussian random intercept and profiles the log-SD slope at level 0.95. The independent Laplace oracle checks the fitted marginal likelihood to tolerance `1e-6`. This validates this worker's runtime and numerical checks only.

## 3a. Decisions and Rejected Alternatives

- Kept this 45-fit run as a timing pre-run. Its results do not establish recovery, bias, false-positive control, or interval coverage.
- Preserved the 95% fitted profile interval contract for the timing worker. The separate Bernoulli calibration contract uses 97.5% Monte Carlo intervals.
- Refreshed the adapter source snapshot as audit v4 and reran only the no-fit replay regression. This does not qualify the adapter or authorize a calibration campaign.
- Corrected downstream records that incorrectly treated 97.5% fitted intervals as the approved target. The current design is 95% fitted profiles with 97.5% Monte Carlo confidence intervals; the completed 97.5%-profile run remains historical exploratory evidence.
- Assumption made without asking: the corrected current-source timing capsule is the relevant basis for preliminary runtime projection; shared-host contention and memory remain unmeasured.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/calibration-20261019/timing-current-source-v1/` contains the exact source capsule, package tarball, 45 attempt records, profiles, health records, worker logs, summaries, and readback manifest.
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/stage-two-current-source-audit-20261019-v4/` contains the current 17-file adapter source manifest, receipt, hash sidecars, and no-fit regression log.
- This after-task report and its entry in `docs/dev-log/check-log.md` record the result.
- The exact-draft naturalness assessment is stored beside this report as `2026-10-19-current-source-timing-pre-run.assessment.json`.
- Updated `docs/dev-log/check-log.md`, `docs/dev-log/general-sd-regression/native-calibration-design.md`, `docs/dev-log/general-sd-regression/stage-two-execution-design.md`, `.unlazy/general-sd-regression/GATES.md`, and the two older Bernoulli after-task reports to label the prior 97.5%-profile interpretation as superseded and align current execution instructions with `worker-095.R`.

The source package tarball SHA-256 is `5485f730b289a5512d40722a73281b7d8fd9df8779cc8cb77c5ee72e16b409ad` (4,475,922 bytes). The prepared source registry SHA-256 is `a7a6cf907ed2263afeab60d090c6c2eaf3ab9c398dda326227f93355b24ae8ec`. The 235-file readback manifest SHA-256 is `28f2e295ee4d55e969e8c1b8e3d636752271a1a7d3c071e1f2244dc37988b028`. The final evidence archive SHA-256 is `7d1c4b511cc7ff525c8ff26688bd4d5dbd02b1b0a4ad35344eb155e6b14d2f48` (5,024,518 bytes); its local copy matches the remote digest.

## 5. Checks Run

- `R CMD build --no-build-vignettes --no-manual --sha256` succeeded for the current candidate.
- `R CMD INSTALL` succeeded from the exact tarball into isolated macOS and Totoro libraries. The installed package loaded as version 0.7.1.
- The 45-row timing manifest passed its schema, uniqueness, and historical-seed-disjointness checks.
- Totoro source verification passed for every path in the prepared registry before launch. Rscript was `/usr/bin/Rscript`, version 4.6.1 (2026-06-24), SHA-256 `a7bfc8750477744d5cb261e54b17e136f7e98bc04f7924c600751ea386b69a0a`; `/usr/lib/R/bin/R` SHA-256 was `243435d7af7cab9018e1ae48233d0bafe2d9a987ea84a0dcfdb3dac2435abc84`.
- `run-095.py` completed 45 of 45 cases with no launch errors under 15 workers, a 120-second per-case limit, and a 240-second campaign limit.
- `summarize-timing-095.R` verified 45 of 45 valid profiles and `calibration_claim=false`.
- `Rscript tools/general-sd-regression/native-calibration/test-summarize-timing-095.R` passed, including its tamper-rejection and incomplete-attempt fixtures.
- The local file-by-file readback check matched all 235 listed files with zero mismatches.
- `Rscript -e` loading the installed package, Python byte compilation of the supervisors, and `run-095.py --help` passed.
- The no-fit `test-combine-stage-two.R` regression exited 0. It emitted `STAGE_TWO_LEGACY_REPLAY_REJECT_PASS no_fits=TRUE status=1`; the subprocess warning and status 1 are expected because this fixture must reject the historical replay before output creation.
- Stage-two source audit v4 binds all 17 current adapter `.py`, `.R`, and `.md` files, including corrected `test-combine-stage-two.R` SHA-256 `bd40ee2427d2b72a66b1d1859d9dbc791159ab97e3b0bb45e56c9e1e56c01b1b`. The manifest SHA-256 is `5baf6e34c2508bdd89187e849413a040d367c54dfc71a9d7a02199f2320dea28`; receipt SHA-256 is `a79dd280f5481745bf660e6c66fab6abee08b668a97866c29669ffacf53156b9`; regression log SHA-256 is `3b28e99d39837c1cbf931670a7c3146dcc9028c03005c5d854b471ee9572fca5`.
- The direct after-task structure check, exact-draft assessment check, prose lint, and `git diff --check` passed. The documented CLI validator printed its structure pass, then began re-verifying the 12 active acceptance ledgers and did not return during two bounded waits; I stopped it. Full acceptance-ledger re-verification is incomplete for this milestone.
- Direct structure checks for the revised Bernoulli after-task reports passed. The prose checker returned zero findings for the current timing report.

## 6. Tests of the Tests

The summary contract test checks incomplete attempts, boundary profiles, warnings, invalid intervals, and a tampered result hash. It passed on this run. The 45 fit records independently check convergence, positive-definite Hessians, gradient magnitude below `0.001`, inactive SD clamps, finite non-boundary profile endpoints, and Laplace-oracle error below `1e-6`.

## 7a. Issue Ledger

Read-only searches for “Bernoulli random effect SD calibration”, “predictor-dependent random-effect scale”, and “sd(group) random effects” found no issue specific to this timing measurement. Issue #1520 tracks planned slope-specific `sd(group)` formulas and remains relevant to the broader feature. No issue was changed because this step adds internal timing evidence and changes no public support claim.

## 8. Consistency Audit

No likelihood, public API, family support claim, formula grammar, vignette, or pkgdown navigation changed in this timing step. The active uncertainty contract remains 95% fitted profile intervals with 97.5% Monte Carlo intervals. The replay-correction note continues to mark the archived first-look CSVs as ineligible for current-source replay because their rows lack `profile_level` metadata and their package source hashes differ.

The earlier v1-v3 stage-two adapter source audits remain historical and retain their prior combiner hash. Audit v4 now records current candidate HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`, the current 17-file source manifest, and the successful no-fit combiner negative control. An independent reviewer verified all 17 file hashes, the CSV and JSON hash chain, and the expected negative-control log marker with no discrepancy. This is source-snapshot evidence only, not adapter qualification or campaign authorization. A separate read-only design audit found stale check-log and after-task claims that treated 97.5% fitted profiles as current; those records now identify the completed run as historical and preserve 95% fitted profiles with 97.5% Monte Carlo intervals as the operative contract. The timing capsule uses its own complete source registry and does not rely on this adapter seal.

## 9. What Did Not Go Smoothly

The first remote timing-manifest command expanded `$timing` in the local shell and wrote a malformed manifest. The preparer rejected it before creating a fit directory. Explicit list indexing generated the intended 45-row file and the schema check passed. The first preparation attempt also lacked the personal R library in `.libPaths()`; setting `R_LIBS_USER` and the isolated package library explicitly fixed it. The compiler emitted Eigen and unused-variable warnings, but both package installs completed.

## 10. Known Residuals

The timing supervisor did not record child-process RSS, so peak and aggregate memory remain unmeasured. This evidence makes no recovery, bias, false-positive, or interval-coverage claim. The throughput projection is preliminary: 3,000 comparable fits scale to about 25.5 minutes by summed fit service time divided by 15 workers, or about 32.3 minutes by scaling observed wall time; 9,000 comparable fits scale to about 76.6 or 96.8 minutes, respectively. These estimates do not include shared-host contention or memory constraints and do not replace a campaign-specific pre-run. No DRAC work was run. Julia parity, remaining family and random-effect combinations, calibration, and NotebookLM methods review remain open.

## 11. Team Learning

Nested shell commands can expand R `$` expressions before they reach R. Use explicit list indexing or quote the remote command so R receives the intended expression. A supervisor's completed count is not a numerical pass; run the source-pinned summarizer and inspect all attempt rows. Keep timing receipts source-specific.

## 12. Cross-Product Coverage

This task covers current-source native Bernoulli random-intercept SD-slope timing and the no-fit stage-two adapter replay guard. It does NOT cover Julia parity, recovery or interval calibration, additional response families, other random-effect types, DRAC execution, or the broader programme finish line. Next: prepare the current-source Bernoulli recovery and uncertainty run from fresh frozen seeds, with a campaign-specific pre-run and memory measurement.
