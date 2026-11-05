# After task: Beta phylogenetic intercept and slope SDs

## 1. Goal

Fit separate predictor-dependent SDs for independent phylogenetic intercept and numeric-slope fields in a native Beta model, preserving the existing tree correlation scale.

## 2. Implemented

The Beta phylogenetic validator now admits an unlabelled intercept plus one numeric slope alongside its existing intercept-only route. Coefficient-selected SD formulas use the generic two-field native loading and extraction. Phylogenetic structures have no matrix-provider structure field, so tree admission is handled explicitly rather than checking A/K provider names. Complete-data and no-other-random-layer boundaries apply to the new base model as well as SD regression. No C++ source or compiled artifact changed.

For independent fields k, u_k ~ N(0,K), b_k = D_k u_k and D_k = diag(exp(W_k alpha_k)); covariance is D_k K D_k. K is shared ancestry divided by tree height. This preserves the established phylo correlation convention, which differs from the raw supplied relmat kernel convention. The example uses phylo(1+x|id,tree=tree) and two sd(id,level="phylogenetic",coef=...) formulas. The Beta mean adjustment and phi=sigma^-2 are unchanged.

## 3a. Decisions and Rejected Alternatives

The DGP specifies a balanced 64-tip binary tree independently. Five internal path edges of .1 and a terminal edge of 1.5 give height 2. Expected K has diagonal 1 and off-diagonal .1 times common binary-prefix depth divided by 2. No package covariance helper generates the DGP. This directly checks normalization as well as node ordering.

Assumptions without asking: retained prior single-seed SD-slope tolerance .4 and absolute numerical tolerance 1e-4. Seed 2026102711, 64 groups and 20 observations per group were recorded before fitting. No seed, data size or tolerance changed after results. Existing q1 behavior remains supported; slope-only, multiple slopes, labels, extra random layers and missing-data routes are outside this slice.

## 4. Files Touched

R/drmTMB.R contains the scoped validator, provider, target and data-map changes. New files are tests/testthat/test-beta-phylo-q2-sd-regression.R, inst/examples/beta-phylo-q2-sd.R, this report, docs/dev-log/check-log.d/2026-10-27-native-beta-phylo-q2-sd.md and evidence under docs/dev-log/general-sd-regression/evidence/native-beta-phylo-q2-sd-20261027/. An obsolete slope-refusal assertion in tests/testthat/test-beta-location-scale.R now checks a still-unsupported slope-only route. Foreign dirty changes are preserved.

## 5. Checks Run

The red test failed twice at the expected intercept-only validator in 4.919 seconds. The focused suite passed 46 checks with no failures or errors in 35.359 seconds. The standalone example converged in 8.586 seconds. SD-slope estimates were 0.6587271 and -0.4297496, against truths 0.5 and -0.5. These are one-seed point-fit checks only. The separate location-scale neighbor passed 108 checks with no failures, errors, warnings or skips in 16.070 seconds. The nine-file neighboring regression passed 349 checks with no failures, errors, warnings or skips in 256.755 seconds, below its 300-second estimate. The separate neighbor is recorded independently from these counts.

No full package check, pkgdown build, interval calibration or live Julia process ran in this slice.

## 6. Tests of the Tests

The inverse augmented tree precision, restricted to tips after inversion, must equal the independently specified normalized K. A separate observed-tip Beta joint density, analytic score and Hessian, two latent-mode starts, finite differences and absolute Laplace likelihood provide the numerical oracle. This includes integration over internal tree nodes. Tip labels are reversed with matching edge-index remapping and edge order changed; reversed SD formulas must yield the same fitted model. Constant-SD formulas are compared with the new base route.

Named group SDs, public parameter tables, selected-optimum fitted means, save/reload and seeded conditional simulation are checked. Internal nodes and an unused tip retain raw latent values and have NA scaled extraction when predictors are absent. The unused-tip test establishes assembly/extraction; reduced-observation likelihood fitting remains unassessed. Fresh two-field marginal simulation remains explicitly refused.

## 7a. Issue Ledger

The exact native Beta mu phylo_numeric_slope tree candidate row is saved in candidate-rows.tsv, without promotion in the shared evidence ledger. No issue or external comment was posted. The broader programme and Julia parity remain open.

## 8. Consistency Audit

Parent and independent read-only scout reviewed the exact patch and math, finding no P0/P1 issue in the bounded route. Gamma coefficient-provider admission remains equivalent, and existing Beta q1 remains admitted. The Julia bridge refuses this exact Beta phylo slope route before setup; source inspection is not live parity evidence.

The status inventory remains under the separate documentation lane. The formula grammar and likelihood parameterization are unchanged; the example and report document the new route. The stale-refusal search was rg -n 'phylogenetic slopes remain|intercept-only q1|beta.*phylo.*slope|Beta.*phylo.*slope|validate_beta_phylo_mu_structured_term' tests/testthat; it found the neighboring location-scale assertions. Public maps are not changed here.

Memory receipt: the coordinator loaded the routed drmTMB manifest, graph map, prior receipts and kernel-scaling lessons. They shaped the normalization and separate coefficient checks. No expensive sister-repository discovery was repeated. Golden Set: not run; independent numerical and neighboring regression checks provide present evidence.

## 9. What Did Not Go Smoothly

Preflight and lease scans took minutes. Walking the neighboring tests found an obsolete assertion that the newly admitted slope model must fail. It is replaced with a still-unsupported slope-only assertion; the new positive test covers the admitted base route. All attempts are retained.

## 10. Known Residuals

Single-seed point checks do not establish general bias or calibrated intervals. Unused-tip likelihood integration, weighted and missing-data fits, correlated blocks, extra random layers, multiple slopes, new-data SD prediction and profile/bootstrap workflows are unassessed. No live Julia parity is established. The checkout is a dirty development candidate; no commit, push, merge or release occurred.

## 11. Team Learning

For tree effects, distinguish the tip covariance from augmented precision and preserve height normalization. A provider object without a matrix-input structure field needs an explicit admission case. Search neighboring refusal tests whenever extending a validator.

## 12. Cross-Product Coverage

This slice covers native complete-data Beta mu point fitting with a tree, one independent phylogenetic intercept plus numeric slope, selected group-constant SD predictors, unit weights and fixed-effect sigma. It exercises tree normalization, internal-node integration, coefficient order, extraction, conditional prediction/simulation and save/reload. It does NOT cover slope-only or multiple slopes, labels, sigma random effects, extra layers, missing data, new-data prediction, marginal two-field draws, uncertainty workflows, coverage, Julia parity, full checks or release.

## 13. Prose Assessment

The separate exact-draft self-assessment is saved with the evidence. Scientific and factual gates are limited to the recorded source, tests and example. No external reference claim is made.
