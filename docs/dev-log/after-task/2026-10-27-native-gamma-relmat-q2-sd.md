# After Task: Gamma relatedness intercept and slope SD regressions

## 1. Goal

Fit separate predictor-dependent SDs for a Gamma model's relatedness intercept and slope, and verify that its reported random effects and conditional predictions use those scales.

## 2. Implemented

The native Gamma builder accepts two coefficient-selected SD formulas for one unlabelled `relmat(1 + x | id, K = K)` term. The equivalent supplied-precision form uses `Q = solve(K)`. Each latent field is independent of the other and has covariance `D_k K D_k`, where `D_k` contains its fitted group SD multipliers. The supplied kernel retains its existing scaling; a non-unit kernel diagonal contributes to marginal variance. For example, `sd(id, level = "relmat", coef = "x") ~ environment` changes the slope field's log-SD. It requires a separate intercept SD formula and predictors constant within group.

The extension reuses the Gamma animal coefficient-SD mechanism. Both the builder and TMB-data admission now recognize relatedness fields. Conditional extraction uses the observation-by-coefficient SD map for each field. This also repairs an existing Gamma animal q2 bug: a converged synthetic fit's conditional predictor differed from TMB's fitted predictor by up to 1.341697 link-scale units before the extraction repair. Raw latent values are retained. Nodes without observations retain missing scaled values because their SD predictors are unavailable.

## 4. Files Touched

Implementation is in `R/drmTMB.R`. Tests are in `tests/testthat/test-gamma-relmat-q2-sd-regression.R`; the existing Gamma animal slope test receives an updated coefficient-selector refusal assertion. A runnable synthetic example is in `inst/examples/gamma-relmat-q2-sd.R`. The source manifest, commands, logs and exact limits are in `docs/dev-log/general-sd-regression/evidence/native-gamma-relmat-q2-sd-20261027/`.

## 3. Mathematical Contract

For each coefficient k, `log(sd_gk) = W_gk alpha_k`, `u_k ~ N(0, K)` and `b_gk = sd_gk u_gk`. The observation predictor is `eta_i = X_i beta + b_g0 + x_i b_g1`. The response mean is `exp(eta_i)` and the Gamma shape is `sigma_i^-2`; `sigma` is the coefficient of variation. The independent oracle optimizes both latent fields with precision `blockdiag(K^-1, K^-1)` and adds the analytic latent-Hessian Laplace correction. It includes both Gaussian normalization constants and the kernel determinant. The test uses non-unit diagonal K, permuted matrix and factor labels, and two different SD predictors.

## 3a. Decisions and Rejected Alternatives

Reuse the existing normalized Gamma latent-field density and coefficient-specific map. A builder-only admission was rejected because it would leave the TMB row map and conditional extraction incorrect. Preserve the existing explicit marginal-simulation refusal and defer fresh q2 field draws.

## 5. Checks Run

The new focused suite passed 42 expectations on the candidate source. The first broader Gamma run passed 107 expectations and exposed one stale animal test assertion that expected a superseded refusal message. The refusal still occurs and now tells users to select the coefficient. After correcting that assertion, the final five-file run passed 108 expectations, with zero failures, errors, warnings or skips, in 44.864 seconds. The standalone synthetic example also converged. The independent dense likelihood oracle, independently optimized latent mode, K/Q equivalence, SD-formula-order equivalence, constant-SD equivalence, group predictions, selected-optimum conditional predictions, raw/scaled extraction, unused nodes, save/reload, and conditional simulation are checked. Interval coverage and Julia parity were not run.

## 6. Tests of the Tests

The original builder rejected the two relatedness SD formulas while accepting the underlying two-field model. A separate pre-fix animal fit measured the conditional-predictor discrepancy. The new likelihood test compares the fit with a dense calculation that independently solves the latent mode. Its checks distinguish the two SD surfaces and reverse their formula order. Malformed-input checks retain refusal for missing or incorrect selectors, within-group predictor variation, zero slope loading, and identical constant SD designs with globally constant slope loading. Marginal q2 simulation is tested as an explicit refusal.

## 8. Consistency Audit

The existing Gamma relatedness one-slope support is retained. This change models independent coefficient fields and introduces no slope correlation. The exact audit pattern is `Gamma.*animal|Gamma.*q2|Gamma.*relmat|Gamma animal|Gamma related` over `README.md`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, `vignettes/formula-grammar.Rmd` and `vignettes/predictor-dependent-random-sd.Rmd`. Public status-map synchronization remains with the separate documentation lane; the new source example and this report record the current bounded claim. No aggregate capability row is promoted by this receipt.

## 8a. Design-Doc and Pkgdown Updates

The formula grammar and Gamma likelihood parameterization are unchanged. The source example pairs the coefficient-specific formulas with the covariance construction and current simulation limit. The separate documentation lane receives the exact source and receipt so it can synchronize its public maps. No full pkgdown build or deployment was performed in this slice.

## 7a. Issue Ledger

The bounded query `gh issue list --state open --search 'Gamma random SD' --limit 10` returned the general test-sweep trackers #1463 and #1464. No targeted issue was returned. The trackers remain open; no comment or public completion claim was posted.

## 9. What Did Not Go Smoothly

The initial scratch test needed a kernel binding in the low-level builder environment, an unname operation for the oracle predictor, and an explicit conditional-simulation argument. After these corrections its 42 checks passed. The broader run exposed an older Gamma animal test expecting a refusal message that no longer matched coefficient-selector guidance. Coordination scripts took several minutes while scanning the large shared repository and lease registry. Repository-name strings in leases require care: both canonical and worktree identities must be reconciled before treating an absolute-path lease as exclusive ownership. The predecessor confirmed its canonical SD lease and explicitly delegated the narrower Gamma change. An attempted cleanup of expired registry entries was stopped on the coordinator's instruction; active leases were retained.

## 11. Team Learning

A working coefficient-SD likelihood does not guarantee correct conditional output. Check the builder, data map, likelihood loading, extraction and prediction together. The read-only reviewer found the separate data gate and extraction defect before the relatedness extension could inherit them. The independent oracle and the fitted-predictor check exercise different failure modes.

## 10. Known Residuals

Evidence covers native Gamma complete-response point fitting in the synthetic configuration, with unit weights and no other random effects. The identifiability guard catches the named zero-loading and constant-design degeneracies; it is not a general identifiability test. Interval calibration, Julia bridge parity, richer field combinations, labelled blocks and fresh q2 marginal simulation remain open. Preserve the broader goal, reconcile the evidence links, and coordinate the matching Julia implementation with the parity lane.

## 12. Cross-Product Coverage

The slice covers complete responses, supplied K and Q, two independent Gamma location fields, coefficient-selected group SD formulas, extraction, fitted conditional predictions, conditional simulation, and save/reload in the tested configuration. It does NOT cover Julia parity, interval coverage, weighted or missing-response models, additional random layers, labelled or correlated fields, new-data SD extrapolation, or fresh q2 marginal simulation. Earlier saved fits contain their earlier extracted values and should be refitted before relying on corrected conditional predictions.

## 13. Prose Assessment

The exact saved draft has a separate self-review record in the evidence directory (`report-prose-assessment.json`). The perceived AI-like style score is 3/10 with medium confidence; the technical heading structure is required, while the model and limits are stated concretely. Scientific and factual gates are scoped to the recorded checks. No external literature claim is made.
