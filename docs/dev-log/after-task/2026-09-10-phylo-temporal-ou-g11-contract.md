# After-task — phylogenetic-temporal OU G11 calibration contract

## 1. Goal

Freeze the profile-calibration design and its fail-closed integrity rules without launching a campaign.

## 2. Implemented

Added a pure G11 assessment helper and a no-fit contract worker. They create and validate the 3,500-task P1--P4 manifest, the twelve fixed-mean cell-target rows, all-attempt and conditional coverage fields, primary acceptance criteria, and P4's stress-only status.

## 3a. Decisions and Rejected Alternatives

P1--P3 each retain 1,000 generated datasets; P4 retains 500 and is never used to qualify nominal coverage. Every unavailable endpoint is uncovered in the all-attempt denominator, with conditional coverage reported separately. The primary criteria are availability at least 0.99, coverage plus/minus MCSE within 0.925--0.975, absolute bias at most 0.10 empirical SD, and the profile-width SE analogue ratio from 0.90 to 1.10. No campaign, public inference promotion, or future temporal provider is authorized here.

## 4. Files Touched

- `tools/assess-phylo-temporal-ou-g11.R`
- `tools/run-phylo-temporal-ou-g11-contract.R`
- `tools/phylo-temporal-ou-gates.R`
- G11 assessment and gate-runner tests
- the G11 contract artifact, ledger, check log, and this report

## 5. Checks Run

The G11 assessment test passed. The contract worker returned `PHYLO_TEMPORAL_OU_G11_CONTRACT_SELFTEST_PASS`. Writing the immutable contract returned `PHYLO_TEMPORAL_OU_G11_CONTRACT_WRITE_PASS`, and `Rscript --vanilla tools/phylo-temporal-ou-gates.R G11` returned `PHYLO_TEMPORAL_OU_G11_PASS`.

## 6. Tests of the Tests

The assessment test failed before the helper existed. It now rejects a missing cell-coefficient row and forged worker MD5, while a known P1 0.90-coverage fixture is explicitly unqualified. The worker independently mutates a missing manifest row, a forged MD5, and the same failing coverage scenario; each must fail its negative control.

## 7a. Issue Ledger

Open issue #1302, “Feature: phylogenetically correlated temporal OU series,” remains the tracker. No new issue or comment was needed for the local no-fit contract.

## 8. Consistency Audit

The G11 ledger, worker, helper, test names, and artifact all use P1--P4 and 3,500 total datasets. The plan's P1--P4 values, target coefficients, all-attempt endpoint policy, and primary/stress distinction match the contract. Existing G9 and G9c boundaries remain unchanged.

## 9. What Did Not Go Smoothly

No model or numerical failure occurred. The gate runs its test file through `testthat`, which emits the package's existing Julia bridge status line; it does not exercise a Julia engine or change the G11 result.

## 10. Known Residuals

The contract is not evidence that profiles are calibrated. It has no observed coverage, runtime campaign evidence, Fir/DRAC submission, or external storage receipt. G12 remains a manual decision based on the measured G10 cost and this frozen denominator.

## 11. Team Learning

An assessment gate should prove both optimistic and pessimistic paths: a qualified synthetic reference confirms the formula, while an explicit failing coverage fixture prevents a permissive criterion from silently promoting a bad campaign.

## 12. Cross-Product Coverage

This covers only the future calibration design for the additive phylogenetic-stable plus independent-OU Gaussian ML slice and its three fixed `mu` effects. It does not cover temporal scale effects, other covariance structures, a separable phylogeny-by-OU field, non-Gaussian families, REML, forecasts, `newdata`, or actual campaign computation.
