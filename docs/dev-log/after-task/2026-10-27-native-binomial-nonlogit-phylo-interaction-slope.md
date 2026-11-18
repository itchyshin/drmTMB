# After Task: Non-Logit Binomial Phylogenetic-Interaction Slope Checks

## 1. Goal

Add point-recovery evidence for native Binomial phylogenetic-interaction random slopes with predictor-dependent SDs under probit and complementary log-log links.

## 2. Implemented

Extended the existing synthetic slope test with separate probit and cloglog datasets. The test checks convergence, the sign and recovery of the log-SD slope, pair-level predicted SDs, and deterministic marginal simulation. The current native builder and TMB likelihood already admit these link/effect combinations, so this slice added tests and evidence records without changing model code.

## 3a. Decisions and Rejected Alternatives

The truth slope remains 0.55 and the existing absolute recovery bound remains 0.35. The first 64-pair cloglog run estimated 1.212, so I increased the synthetic design to 256 pair groups to improve information under the correlated phylogenetic covariance. The expanded fixed-seed case passed. No interval-coverage claim is made.

## 4. Files Touched

- `tests/testthat/test-binomial-phylo-interaction-slope-sd.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-nonlogit-phylo-interaction-slope-20261027/`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-nonlogit-phylo-interaction-slope.md`
- `docs/dev-log/after-task/2026-10-27-native-binomial-nonlogit-phylo-interaction-slope.md`

## 5. Checks Run

- `NOT_CRAN=true OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-interaction-slope-sd", reporter = "summary", stop_on_failure = TRUE)'`: exit 0, native test passed; one Julia bridge companion was skipped because neither Julia engine path was configured. Receipt: `docs/dev-log/general-sd-regression/evidence/native-binomial-nonlogit-phylo-interaction-slope-20261027/test-console.log`.
- Source hashes before and after the run match for `R/drmTMB.R`, `src/drmTMB.cpp`, and the test file.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: PASS, 19,230 candidate rows, 87 linked rows, 19,143 unlinked rows, 107 evidence records.
- `git diff --check` on the test, evidence ledger, report, and check log: PASS.

## 6. Tests of the Tests

The DGP uses two balanced synthetic trees and their Kronecker tip covariance. It generates one random slope per plant-pollinator pair with SD `exp(log(0.45) + 0.55 * z_pair)`, then generates binary responses with the selected inverse link. The 256-pair non-logit fixture passed the original recovery criterion. The logit sibling remains at its existing 64-pair design.

## 7a. Issue Ledger

No GitHub issue was inspected or updated. The new probit and cloglog evidence records are marked `unreviewed`. They do not establish calibrated intervals or cross-engine parity.

## 8. Consistency Audit

The direct-SD evidence ledger now links native logit, probit, and cloglog phylogenetic-interaction slope rows to the source-pinned test file. Julia bridge parity remains unverified; the companion bridge test was skipped in this environment. No public support claim was changed in this test-only slice.

## 9. What Did Not Go Smoothly

The first test run exposed an unsupported `info` argument on `expect_gt()` in the installed testthat version. Replacing it with `expect_true()` fixed the harness. The second run exposed a weak cloglog recovery fixture with 64 correlated pairs. I increased the number of pairs to 256 and retained the same truth and recovery bound. The expanded case passed.

## 10. Known Residuals

This evidence covers native Binomial phylogenetic-interaction numeric slopes for logit, probit, and cloglog with one SD formula and complete responses. It does NOT cover Julia bridge recovery, other interaction coefficient blocks, additional random effects, interval coverage, or the remaining response families and effect types. The general SD-regression goal remains active.

## 11. Team Learning

For structured random-slope recovery, the number of observations alone does not determine information: correlated groups can leave few effective contrasts for estimating the SD predictor. Keep the declared recovery bound fixed and increase independent group information when a synthetic fixture is weak; report the initial miss instead of hiding it.

Memory receipt: followed the project operating contract, current candidate inventory, path-specific preflight, scoped lease, and evidence reconciler. The graft executable remains unavailable, so the exact test and source spans were inspected directly. Golden Set: NOT RUN; this was a focused synthetic point-recovery check.

Prose assessment: style 2/10, medium confidence. Genre and coverage: short technical after-task report, reviewed in full. Evidence and repair: the failed pilot estimate, final exit status, skip reason, and reconciliation counts are tied to saved outputs; no further wording change was needed. Gates: science pass for the stated point-recovery fixtures only; facts pass against receipts; references not applicable because no literature claim is made. Provenance: self-review, 2026-10-27, no style controls used.

## 12. Cross-Product Coverage

Covers native Binomial phylogenetic-interaction numeric-slope SD point recovery and predicted pair SD output for all three links, plus deterministic marginal simulation checks.

This slice does NOT cover interval calibration, live Julia bridge parity, or the full distribution/effect universe.
