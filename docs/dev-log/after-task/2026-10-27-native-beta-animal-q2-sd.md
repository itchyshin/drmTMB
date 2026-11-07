# After Task: Beta animal intercept and slope SD regression

## 1. Goal

Fit separate predictor-dependent SDs for independent animal intercept and slope fields in a Beta response model, using supplied covariance or precision matrices. Preserve the complete-response boundary and keep `sigma` regression free of random effects.

## 2. Implemented

The native Beta builder admits two coefficient-selected SD formulas for one unlabelled `animal(1 + x | id, A = A)` term. Equivalent precision input uses `Ainv = solve(A)` with the full named matrix inverted before any subsetting. Each field has its own group-level SD design and standardized animal latent field. A new coefficient-row branch in the Beta TMB loading applies the correct SD surface to each field. Existing density, shape floors, mean adjustment, prior normalization and reporting are unchanged.

The route requires one SD formula for each coefficient. For example, `sd(id, level = "animal", coef = "x") ~ z1` models a slope field's log-SD; a separate formula selects the intercept. Predictors are constant within animal. `sigma ~ 1` estimates one precision-scale parameter shared across observations. It introduces no random effect on `sigma`.

## 3. Mathematical Contract

For coefficient k, `log(s_gk) = W_gk alpha_k`, `u_k ~ N(0,A)` and `b_gk = s_gk u_gk`. The two fields are independent. The observation predictor is `eta_i = X_i beta + b_g0 + x_i b_g1`. The Beta mean retains the implementation's adjustment `mu_i = 1e-12 + (1 - 2e-12) * plogis(eta_i)`, and precision is `phi = sigma^-2`. The supplied covariance retains its scaling: `Cov(b_k) = D_k A D_k`, so marginal SD is `s_gk * sqrt(A_gg)`.

The dense oracle uses an independently evaluated Beta density, analytic score and Hessian, and two deterministic latent-mode starts. It includes the mean adjustment and checks that neither Beta shape reaches the existing `1e-8` floor. Its Laplace correction uses the full two-field latent dimension and includes the kernel determinant. Score and Hessian finite differences are checked away from the optimum.

## 3a. Decisions and Rejected Alternatives

Admission alone was rejected because the old Beta loading applied one shared SD row to both fields. The implementation extends the existing coefficient-row map and scaled extraction instead of adding a new likelihood. Supplied `Ainv` was included because it reaches the same precision backend as `A`; their equivalence is checked directly. Pedigree input remains a separately unimplemented two-field SD route. The fixed-seed fixture, ordinary-condition tolerances and covariance contract were written before fitting; no failed recovery threshold was relaxed.

## 4. Files Touched

Implementation is limited to `R/drmTMB.R` and one field-loading hunk in `src/drmTMB.cpp`. The new test is `tests/testthat/test-beta-animal-q2-sd-regression.R`; the runnable example is `inst/examples/beta-animal-q2-sd.R`. The scoped check-log fragment and source-bound evidence are under `docs/dev-log/check-log.d/2026-10-27-native-beta-animal-q2-sd.md` and `docs/dev-log/general-sd-regression/evidence/native-beta-animal-q2-sd-20261027/`. Native build artifacts were regenerated under the same lease. All existing shared edits were preserved.

## 5. Checks Run

The native rebuild completed in 41.726 seconds, using one compiler process with temporary `-O0 -g0` flags. It emitted 15 warnings in untouched C++ code or headers and no errors. The first actual-engine Beta suite passed 52 checks in 53.216 seconds. After adding public-output and refusal checks and changing the reversed-formula comparison to the declared absolute tolerance, the five-file regression run passed 162 expectations with zero failures, errors, warnings or skips in 135.625 seconds. The new file contributes 58 checks. Neighbors cover Beta animal intercept SDs, ordinary Beta SD assembly, existing non-Gaussian structured intercept/slope fits, and the completed Gamma relatedness coefficient-SD route.

The standalone synthetic example converged in 15.806 seconds. Subsequent example edits clarified comments only. A setup-mocked public-interface check confirmed that the Julia bridge refuses this two-field route before setup; no Julia process ran. Interval coverage, a full package check and a pkgdown build were not run. Exact commands, logs, native flags and source hashes are retained in the receipt.

## 6. Tests of the Tests

Before implementation, the fixture confirmed zero boundary responses and minimum generated Beta shape 0.546346. The underlying constant-SD q2 model assembled, while all three new test cases failed at the existing single-coefficient SD guard. The numerical oracle independently solves the latent mode and compares absolute objective and predictor differences; it also checks score/Hessian finite differences and agreement between two mode starts.

The final tests distinguish the two SD surfaces, reverse their formula order, independently reorder the full inverse matrix, and verify constant-SD equivalence. They check group labels, parameter tables, fitted means, selected-optimum conditional predictors, raw versus scaled latent extraction, an unobserved matrix node, save/reload and seeded conditional simulation. Failure-path checks cover absent, duplicate or wrong coefficient selectors, labels, pedigree input, additional random layers, within-group SD predictor variation, missing-response inclusion and the named zero/constant-loading degeneracies. Fresh q2 marginal simulation remains an explicit refusal.

## 7a. Issue Ledger

The bounded open-issue query `gh issue list --state open --search 'Beta animal random-effect SD' --limit 10` returned the general trackers #1463 and #1464 and the simulation-framework issue #59. No issue was closed, created or commented on. The broader SD goal remains open.

## 8. Consistency Audit

The frozen map contains required native Beta animal numeric-slope rows for covariance and precision input, with no linked evidence at selection time. The receipt records those exact candidate row keys and the tested one-slope facet. It does not promote an entire coefficient domain or rewrite the shared evidence ledger.

The exact status scan was `Beta.*animal|Beta.*slope|beta.*animal.*SD` over `README.md`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, `vignettes/formula-grammar.Rmd` and `vignettes/predictor-dependent-random-sd.Rmd`. Public status-map integration stays with the separate documentation lane; the new source example, this report and the receipt describe the candidate scope.

## 8a. Design and Documentation

Formula grammar and the Beta response parameterization are unchanged. The example pairs the selected SD formulas with their covariance interpretation and distinguishes Beta precision from latent field SDs. It gives the full named-matrix inverse route and the current conditional-simulation boundary. Documentation and Julia parity lanes receive the exact candidate delta; no publication or deployment claim is made.

## 9. What Did Not Go Smoothly

The original parser rejected multiple structured SD coefficients. Review identified that both the R data gate and the C++ loading needed attention. Review also replaced a relative reversed-formula tolerance with its declared absolute counterpart before the final run. No numerical failure required changing the fixture or thresholds.

Exact foreign-ref review found nearby provider-selection, stable-density and reporting changes. The patch preserves those current regions and changes only the planned SD insertion/loading. Their later merge integration remains a separate responsibility. The shared repository and lease scans took minutes; no broad registry cleanup was attempted in this slice.

## 10. Known Residuals

The recovery checks use one ordinary-condition synthetic seed with 64 groups and 20 observations per group. They support a bounded point-fit smoke check and numerical correctness. General bias and recovery properties remain unassessed. The identifiability guard catches the specified zero-loading and constant-design degeneracies; it is not a general identifiability proof. Interval coverage remains deferred.

Pedigree input, richer fields, extra random layers, labelled covariance, interval workflows and fresh q2 marginal simulation remain open for this route. Public status maps, global row reconciliation, full package/platform checks and Julia parity remain separate open work. The worktree is a dirty development candidate; no commit, push, merge or release was made.

## 11. Team Learning

Inspect admission, row assembly, field loading and extraction together. A correct single-field SD implementation can silently reuse the wrong scale when a second field is admitted. The independent density calculation, reversed formula order and separately permuted inverse matrix exercise different parts of that path. Reuse the existing precision backend across equivalent input representations, then keep the tested representation and coefficient scope explicit.

## 12. Cross-Product Coverage

The slice covers native Beta complete-response point fitting with one unlabelled independent animal intercept and slope, supplied `A` or `Ainv`, group-constant SD predictors, unit weights in the recovery fixture, and `sigma ~ 1`. It covers coefficient extraction, group predictions, parameter tables, fitted conditional means, conditional simulation and save/reload in that configuration. It does NOT cover Julia, pedigree, interval calibration, weighted or missing-response validation, additional random layers, labelled/correlated fields, multiple slopes, new-data SD extrapolation, or fresh q2 field draws. The next proposed row is the same Beta animal slope mechanism with pedigree input, including unobserved ancestors.

## 13. Prose Assessment

The separate exact-draft self-assessment is stored as `report-prose-assessment.json` in the evidence directory. Perceived AI-like style is rated 3/10 with medium confidence. The required technical structure is explicit; scientific and factual gates are limited to the recorded checks, with no external literature claim.
