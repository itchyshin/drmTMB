# After Task: Tweedie Related-Matrix SD Bridge Parity

## 1. Goal

Verify that the public R bridge carries the related-matrix covariance into both candidate engines for one predictor-dependent Tweedie random-intercept SD model.

## 2. Implemented

The focused bridge fixture was run with temporary per-engine timing output. Both candidate fits completed, and the same-data coefficient, group-SD prediction, public-output, and log-likelihood comparisons passed. The exact timed test source is archived in the evidence bundle; the live test file was restored to its earlier byte-identical version so its historical source receipt remains valid.

## 3. Mathematical Contract

The fitted SD multiplier is `exp(W alpha)`. With supplied covariance `K`, the latent intercept covariance is `D K D`, so its marginal SD is `exp(W_g alpha) * sqrt(K[g,g])`. This test uses a non-unit-diagonal `K` and compares the same labeled matrix through both engines. It does not establish other Tweedie effect types or general kernel parity.

## 3a. Decisions and Rejected Alternatives

Kept the candidate model implementation unchanged because the direct Julia regression and public R bridge both pass for this fixture. Preserved the timed test snapshot to identify the slow stage, and retained the result as one bounded parity cell rather than describing it as general Tweedie or structured-effect parity.

## 4. Files Touched

- `tests/testthat/test-julia-tweedie-relmat-sd.R`: restored to the byte-identical source already bound by the earlier receipt after the timed run.
- `docs/dev-log/general-sd-regression/inventory.md` and `native-family-sd-adapter-map.md`: replaced the stale Julia-only / structured-exclusion wording with the bounded candidate TMB/Julia parity evidence.
- `.unlazy/general-sd-regression/GATES.md`: recorded the source-refreshed rerun as partial evidence without closing a gate.
- `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261024-current-v4/`: added the 199-file source manifest, exact timed-test snapshot, result receipt, and run note.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and `direct-sd-evidence-summary.md`: linked the refreshed exact-row receipt and regenerated the evidence-only summary. The older receipt still binds its archived test hash.
- This report and `docs/dev-log/check-log.d/2026-10-24-julia-tweedie-relmat-cross-engine-sd.md`.

## 5. Checks Run

- Direct paired-Julia regression: `~/.juliaup/bin/julia --project=. test/test_tweedie_relmat_sd_regression.jl` passed 7/7 mode-polish, 43/43 related-matrix regression, and 4/4 unused-keyword checks.
- Focused R bridge: `DRM_JL_PATH="$(pwd | sed 's/general-sd-regression/general-sd-julia/')" DRM_JL_JULIA_HOME="/Users/z3437171/.juliaup/bin" Rscript -e 'devtools::test(filter = "julia-tweedie-relmat-sd")'` passed 24/24 expectations with one live Julia bridge fit. Julia took 544.9 seconds; TMB took 2.6 seconds. JuliaCall used Julia 1.10.0 from the selected paired worktree.
- The first R attempt stopped before fitting because its login shell could not find Julia. Setting `DRM_JL_JULIA_HOME=/Users/z3437171/.juliaup/bin` resolved setup. The next attempt exceeded its initial eight-minute estimate and was stopped; the timed rerun completed in 548.2 seconds.
- `git diff --check -- tests/testthat/test-julia-tweedie-relmat-sd.R` passed.
- `python3 tools/general-sd-regression/reconcile_evidence.py` passed with 19,118 candidate rows, 37 receipt records, 28 linked rows, and 19,090 unlinked rows. This is a hash-checked evidence join; it promotes no capability row.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <report>` passed the report structure check and warned that the 13-file acceptance ledger is not runnable in this checkout because `node` or `gate-check` is missing. The validator therefore reports gate state as unknown, not satisfied.
- `python3 ~/shinichi-brain/tools/slop_check.py <report>` returned zero findings.
- Candidate source identities: drmTMB HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl HEAD `70dbf564eb670144c63c08f61ea099084d95add2`. Both worktrees contain uncommitted changes. The 199-file source manifest and run receipt are in `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261024-current-v4/`; manifest SHA-256 is `a15e7331c4d66041e533117b50e9119112e4f85c2f665f6ebb299f9d9244e7ca`. Archived timed-test SHA-256 is `69be7b24caaa56457cbf7217151207397d5e78a351dd3486784c59e7c27a237c`; restored live test SHA-256 is `e870bc909c4ea7fd4a05385fcb8948751a33503c12fbf86430aae5b9c161c36a`.

## 6. Tests of the Tests

The bridge fixture checks the selected `K` payload and formula admission before fitting, then checks both fitted engines against the same synthetic data. It asserts named SD coefficients, group-level predictions, public prediction identity and agreement, positive fitted group SDs, and log-likelihood agreement. These checks cover one Tweedie related-matrix intercept cell only.

## 7. Design and Documentation Updates

The internal capability inventory and family adapter map now record one complete-response Tweedie related-matrix intercept cell with fixed `sigma ~ 1` and `nu ~ 1`. The public formula grammar and user guides were not changed because the model route was already documented in the candidate; this task refreshed test evidence and corrected internal status wording only. No pkgdown render was needed.

## 7a. Issue Ledger

Searched open issues for `Tweedie related-matrix SD`. No matching issue was found. No issue was opened, commented on, or closed.

## 8. Consistency Audit

The Julia test exercises `D K D` scaling and fitted/new-data output; the bridge test confirms that the R interface forwards the covariance matrix to both candidate engines. The result is candidate-only evidence because both source worktrees are dirty. It adds one point-parity fixture and closes no programme gate.

## 9. What Did Not Go Smoothly

JuliaCall could not locate Julia through the login shell at first. The configured Juliaup directory fixed discovery. The Julia fit took over nine minutes, while the TMB fit took under three seconds; the earlier eight-minute test budget was therefore too short. The reconciler caught that the timed test edit would invalidate the earlier receipt. Archiving the exact timed test and restoring the earlier live source kept both records verifiable.

## 10. Known Residuals

This is one synthetic Tweedie related-matrix intercept comparison. It does not establish other providers, slopes, correlated blocks, missing-data routes, broad R/TMB and Julia parity, calibrated interval coverage, full package checks, or rendered documentation.

## 11. Team Learning

For mixed-engine tests, time each engine separately and set the run estimate from the slowest measured fit. Keep environment discovery failures distinct from model failures.

## 12. Cross-Product Coverage

Covers one complete-response Tweedie related-matrix q1 mean-intercept SD route with a non-unit diagonal kernel, same-data candidate TMB/Julia point comparison, fit-level and new-data SD output, plus a source manifest. It does not cover other family/provider/effect/backend combinations, broad output/refit parity, or calibrated uncertainty. Continue with the remaining required rows; keep coverage calibration as the agreed deferred follow-up.
