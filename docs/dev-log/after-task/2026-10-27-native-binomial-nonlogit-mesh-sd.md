# After Task: Native Non-Logit Binomial Mesh SD Checks

## 1. Goal

Verify predictor-dependent SDs for a Binomial spatial mesh intercept under probit and complementary log-log links, extending the existing logit-only test.

## 2. Implemented

Added independent synthetic probit and complementary log-log fits to the mesh SD test. Each fit checks optimizer convergence, point recovery of the SD slope, prediction on the SD scale, and marginal simulation. The likelihood and builder already route these links through the shared Binomial model; no source-code likelihood change was needed.

Added hash-bound receipts for the current test source and linked unreviewed recovery evidence to the exact native probit and cloglog mesh-intercept rows. Refreshed the existing logit evidence row to the same test source and full-file run; its earlier receipt remains saved separately.

## 3a. Decisions and Rejected Alternatives

Each link uses a separate synthetic response and latent field draw, with truth slope 0.5. The test retains the existing broad absolute recovery bound of 0.4 used for the logit route. This is a seeded point-recovery check, not interval calibration.

## 4. Files Touched

- `tests/testthat/test-binomial-mesh-sd-regression.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-nonlogit-mesh-sd-20261027/`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-nonlogit-mesh-sd.md`
- `docs/dev-log/after-task/2026-10-27-native-binomial-nonlogit-mesh-sd.md`

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-mesh-sd-regression")'`: PASS, 22 assertions, 0 failures, 0 warnings, 0 skips; elapsed 10.8 seconds. Receipt: `docs/dev-log/general-sd-regression/evidence/native-binomial-nonlogit-mesh-sd-20261027/test-console.log`.
- The SHA-256 manifests before and after the test run match for the R builder, TMB source, simulation methods, SD formula helpers, and test file. Manifest files are in the evidence directory.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: PASS, 19,230 candidate rows, 84 linked rows, 19,146 unlinked rows, 104 evidence records.
- `git diff --check` on the test, evidence ledger, report, and check log: PASS.

## 6. Tests of the Tests

The generators draw latent mesh coefficients from the same fixed-kappa precision supplied to the fitted mesh. The response is generated with the selected link inverse. The fixture asserts a nonzero-direction SD slope within a declared bound, checks the predicted SD against the fitted log-SD design, and ensures simulated outcomes are binary.

## 7a. Issue Ledger

No GitHub issue was inspected or updated. The two new evidence rows remain marked `unreviewed`; they do not admit capability rows or establish interval calibration.

## 8. Consistency Audit

The current test file covers logit, probit, and cloglog mesh intercepts. The evidence summary now links receipts to all three native link rows. The frozen required-row status still describes the base source pin; it was not changed by this candidate-only receipt. I asked the documentation-audit lane to update the user-facing family/reference text and leave Julia mesh parity unclaimed. That lane is active and has not replied yet.

## 9. What Did Not Go Smoothly

The first evidence reconciliation caught that the old logit receipt referenced an earlier hash of the now-extended test file. I refreshed the logit ledger binding to the new full-file run and preserved the older receipt unchanged. The initial ledger reconciliation then passed.

## 10. Known Residuals

This evidence covers native Binomial mesh spatial intercepts with logit, probit, and cloglog links for complete responses under ML. It does NOT cover mesh slopes, other structured providers, the R-to-Julia bridge, standalone Julia mesh fits, interval coverage, profile/bootstrap calibration, or other response families. The overall SD-regression goal remains active.

## 11. Team Learning

When a shared test file changes, refresh every evidence row whose hash binds that file. Keep old receipts available, and bind current claims to a complete rerun of the changed test source.

Memory receipt: followed the project operating contract, source-first route, scoped preflight/lease, and evidence reconciliation procedure. The graft executable remains unavailable, so source spans were inspected directly. Golden Set: NOT RUN; the validation was a focused link-specific synthetic test. The full link test took 10.8 seconds.

Prose assessment: style 2/10, medium confidence. Genre and coverage: short technical after-task report, reviewed in full. Evidence and repair: counts, hashes, and scope were checked against the saved run output and reconciled ledger; no further wording change was needed. Gates: science pass for the stated point-recovery checks only; facts pass against current receipts; references not applicable because the report makes no literature claims. Provenance: self-review, 2026-10-27, no style controls used.

## 12. Cross-Product Coverage

Covers native R/TMB Binomial mesh spatial-intercept SD point recovery and marginal simulation for logit, probit, and cloglog links, plus predicted SD output.

This slice does NOT cover calibrated uncertainty, any Julia mesh route, or general SD regression across the remaining families and random-effect structures.
