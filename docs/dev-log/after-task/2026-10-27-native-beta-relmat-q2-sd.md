# After task: Beta relatedness intercept and slope SDs

## 1. Goal

Fit separate predictor-dependent SDs for independent relatedness intercept and numeric-slope fields in a native Beta model, using supplied K or Q.

## 2. Implemented

The Beta builder now extracts one relatedness term and admits the previously missing constant-SD base route for an unlabelled intercept plus one numeric slope. Two coefficient-selected SD formulas use the same field-loading and extraction machinery as the completed Beta animal route. The parser recognizes canonical sd_relmat targets, builds distinct field designs and retains provider-specific target names. No C++ source, compiled object or DLL changed.

For each coefficient k, u_k ~ N(0,K), b_k = D_k u_k and D_k = diag(exp(W_k alpha_k)). Thus Cov(b_k) = D_k K D_k. The fields are independent. The observation predictor is X beta+b_0+x*b_1. The existing Beta mean adjustment and phi=sigma^-2 remain unchanged. A non-unit K diagonal contributes to marginal field variance; the supplied kernel is not normalized. The example pairs these equations with relmat(1 + x | id, K = K) and two selected sd(id, level="relmat", coef=...) formulas.

## 3a. Decisions and Rejected Alternatives

A ledger base-admission entry did not establish a working Beta relmat builder. Extraction was missing on this candidate, so this slice includes that prerequisite and tests constant-SD equivalence directly. Automatic q1 admission was rejected: the current candidate explicitly refuses relmat intercept-only, slope-only, multiple-slope and labelled terms. Other refs contain separate q1 work that remains a later integration concern. Additional random layers, structured mu/sigma combinations and missing-data routes are refused.

The synthetic fixture and tolerances were recorded before fits: seed 2026102709, 64 groups with 20 observations, non-unit named K, independent field draws and distinct binary SD predictors. Single-seed slope errors must be below .4. Independent absolute Laplace likelihood, eta and provider differences must be below 1e-4. No seed, data size or numerical tolerance changed after fitting.

## 4. Files Touched

Scoped implementation is in R/drmTMB.R. New files are tests/testthat/test-beta-relmat-q2-sd-regression.R, inst/examples/beta-relmat-q2-sd.R, this report, docs/dev-log/check-log.d/2026-10-27-native-beta-relmat-q2-sd.md and evidence under docs/dev-log/general-sd-regression/evidence/native-beta-relmat-q2-sd-20261027/. Foreign dirty work was preserved.

## 5. Checks Run

The initial red test produced three expected unsupported sd_relmat errors in 6.133 seconds. The first post-change run passed 56 expectations but had one error because the new test expected the wrong existing sigma refusal text; its numerical checks passed. Only that error matcher was corrected, and four parser boundary checks were added. The final seven-file neighboring regression passed 259 expectations with zero failures, errors, warnings or skips in 213.970 seconds.

The standalone example converged in 12.841 seconds. Estimated SD slopes were 0.5332939 and -0.3947029, with truths 0.5 and -0.5. These support one-seed point-fit checks only. No full package check, pkgdown build, interval calibration or live Julia process ran in this slice.

## 6. Tests of the Tests

The dense oracle independently evaluates the Beta density, score, Hessian and two latent-mode starts. It includes the Gaussian determinant and Laplace correction. Score and Hessian finite differences are checked away from the optimum. K and full Q are separately permuted; full Q is inverted before selecting observed covariance. Reversed formula order distinguishes coefficient maps. Constant-SD formulas are compared with the newly admitted base model.

Named group predictions, parameter tables, conditional predictors against the selected TMB optimum, save/reload and seeded conditional simulation are exercised. An unused matrix node retains raw latent values and has NA scaled extraction, but this is an assembly/extraction test, not a reduced-observation marginal-likelihood test. Fresh q2 marginal simulation remains an explicit refusal.

## 7a. Issue Ledger

Two exact native Beta mu relmat_numeric_slope candidate rows, K_covariance and Q_precision, are saved in candidate-rows.tsv. Sigma endpoint rows are excluded. No shared evidence ledger was promoted and no issue was closed or external comment posted. The broader programme remains open.

## 8. Consistency Audit

The classifier, extraction, provider collision rules, coefficient-target naming, data map and existing native loading were reviewed together. Parent and independent scout found no P0/P1 issue in the bounded patch. Their minor feedback corrected K/Q error advice and the wording around unused-node evidence. The Julia bridge statically refuses the exact Beta relatedness slope route before setup; native builder changes do not enable it. No runtime Julia parity is claimed.

The newest relevant foreign diff includes a separate q1 Beta relatedness route that is absent on this candidate. This patch does not transplant or overwrite it. Public capability maps remain owned by the documentation lane and are not changed here. The formula grammar and Beta likelihood parameterization are unchanged; the example and report document the new bounded route.

Memory receipt: the coordinator loaded the routed drmTMB manifest, graph map and relevant prior receipts. Existing non-unit kernel and separate coefficient-map lessons shaped this slice. No expensive sister-repository search was repeated. The Golden Set check was not run; independent numerical and neighboring regression checks provide the present evidence.

## 9. What Did Not Go Smoothly

Preflight and lease scans took minutes. The first successful numerical run exposed a refusal-message mismatch, which was repaired without changing model behavior. No convergence or recovery failure required a different seed, fixture or tolerance. All attempted runs are retained.

## 10. Known Residuals

The fixture establishes bounded numerical and one-seed point-fit evidence only. General bias, interval behavior and coverage are unassessed. Weighted, missing-response, missing-predictor, labelled/correlated, multiple-slope and extra-layer routes are outside this slice. New-data SD prediction and profile/bootstrap workflows were not newly tested. Reduced-observation K/Q marginal-likelihood equivalence was not newly fitted. The checkout is a dirty development candidate; nothing was committed, pushed, merged or released.

## 11. Team Learning

Check base extraction as well as SD admission. A required-row map can record a base capability whose implementation is absent from the current branch. Keep provider-specific parameter names when reusing coefficient maps, and test the constant-SD model before interpreting SD regression.

## 12. Cross-Product Coverage

This slice covers native Beta mu complete-data point fitting with supplied K/Q, one independent intercept and numeric slope, group-constant selected SD predictors, unit weights and fixed-effect sigma regression. It exercises equivalent input forms, extraction, named group SDs, conditional prediction/simulation and save/reload. It does NOT cover q1 relmat, correlated/labelled blocks, sigma random effects, multiple slopes, additional random layers, missing data, new-data prediction, marginal q2 draws, uncertainty workflows, interval calibration, Julia parity, full package checks or release.

## 13. Prose Assessment

The exact-draft self-assessment is stored separately in report-prose-assessment.json. Scientific and factual gates are limited to the saved tests, example and scoped source review. No external reference claim is made.
