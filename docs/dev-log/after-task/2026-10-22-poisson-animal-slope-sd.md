# After Task: Poisson Animal Slope SD Regression

## 1. Goal

Admit and test a predictor-dependent SD for one Poisson animal-model random slope, extending the structured direct-SD inventory by one concrete native TMB cell.

## 2. Implemented

The native Poisson builder now admits `animal(0 + x | id, A = A)` with `sd(id, level = "animal") ~ z` for complete, non-inflated data. The route uses one animal slope coefficient and a supplied covariance matrix `A`.

## 3a. Decisions and Rejected Alternatives

For each group g, the log-mean is `eta_ig = beta_0 + beta_x * x_ig + x_ig * u_g`. The animal slope has covariance `Cov(u) = D A D`, where `D_gg = exp(alpha_0 + alpha_z * z_g)`. Thus the modeled SD multiplier is `exp(alpha_0 + alpha_z * z_g)`; if `A` has a non-unit diagonal, the marginal SD is additionally multiplied by `sqrt(A_gg)`. The test uses a unit-diagonal, non-invariant interleaved `A` matrix and does not normalize or reorder its covariance meaning.

I used a slope-only q1 term. I did not add intercept-plus-slope animal blocks because the current Poisson structured-SD path does not resolve coefficient-specific animal selectors; that is a separate target-resolution and likelihood slice.

## 4. Files Touched

- `R/drmTMB.R`: admit the Poisson animal q1 slope-only structured term and correct the nearby unsupported-route message.
- `tests/testthat/test-poisson-animal-slope-sd-regression.R`: add a fixed-seed recovery and workflow test.
- `R/random-effect-scale-formulas.R` and generated `man/random_effect_scale_formulas.Rd`: document the exact route and boundary.
- `README.md`, `NEWS.md`, `docs/design/18-random-effect-scale-models.md`, `docs/design/59-structural-slope-and-non-gaussian-map.md`, `docs/dev-log/known-limitations.md`, `docs/dev-log/general-sd-regression/inventory.md`, and `docs/dev-log/internal-roadmap.md`: synchronize the support map.
- `.unlazy/general-sd-regression/GATES.md`: add partial evidence to G3, G4, and G6 without closing those programme-wide gates.
- `docs/dev-log/check-log.md`: record exact checks and remaining limits.

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "poisson-animal-slope-sd-regression")'`: 13 passed, 0 failed, 0 skipped.
- `Rscript -e 'devtools::test(filter = "poisson-animal-(slope-)?sd-regression")'`: 24 passed, 0 failed, 0 skipped across the animal intercept and slope files.
- `Rscript -e 'devtools::document()'`: completed and regenerated the reference page.
- `git diff --check` on the implementation, test, reference, support-map, and ledger paths: passed.

## 6. Tests of the Tests

The initial test-first run failed at the Poisson structured-effect admission guard for a pure animal slope. After admitting the exact family/provider/effect combination, the test reached fitting. An earlier low-information fixture put one SD group near its boundary; the final fixed-seed fixture uses 96 animals, 16 observations per animal, randomized balanced group predictors, and a stronger but moderate SD contrast. The final test checks coefficient recovery, name-keyed group SD predictions, simulation, save/reload, constant-SD equivalence, and rejection when the SD predictor varies within animal. This is one high-information point-recovery test, not a calibration campaign.

## 8. Consistency Audit

The formula and covariance description match the `animal(0 + x | id, A = A)` builder route and the test DGP. The docs identify only the supplied-`A` complete-data Poisson case and leave the full capability ledger open. No formula grammar or TMB likelihood parameterization changed. Searches used `rg -n -i -m 30 'animal.*SD|Poisson.*SD|predictor-dependent.*SD|animal.*slope' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd docs/dev-log/known-limitations.md` and `rg -n -i 'structured count slope-only|animal.*slope-only|Poisson.*spatial.*slope-only' docs/design docs/dev-log/known-limitations.md docs/dev-log/general-sd-regression R/drmTMB.R`.

## 7a. Issue Ledger

The open-issue search for “Poisson animal slope SD” returned issue #1463, “Test sweep 3 Oct 2026: what passed”; it is a test-sweep record rather than a feature request, so no issue was changed.

## 9. What Did Not Go Smoothly

The first Poisson test correctly showed that animal slope-only count effects were explicitly excluded. A second trial with an intercept-plus-slope block exposed a separate parser selector limitation; that route is outside this q1 slice and was not silently added. Early synthetic designs also produced boundary estimates, so the final case is presented only as a high-information recovery check.

## 11. Team Learning

Capability must be checked at the family × provider × random-effect-shape intersection. Existing Poisson animal-intercept support and generic animal covariance plumbing did not imply animal slope-only SD support.

## 10. Known Residuals

This result covers one native TMB Poisson animal slope-only coefficient with supplied `A`, complete responses, no zero inflation, and one fixed predictor in the SD formula. It does not validate `Ainv` or pedigree construction, Julia parity, marginal refit/bootstrap routing, interval calibration, multiple coefficients, or other animal/random-effect combinations. The broader programme and its `19,118`-row requirement remain open.

## 12. Cross-Product Coverage

This native TMB result does NOT cover `Ainv` or pedigree slope inputs, Julia parity, marginal refit/bootstrap routing, interval calibration, multiple animal coefficients, or the other required family/provider/effect combinations. The broad programme remains open. Next, add an independent likelihood or covariance oracle for this cell, then test `Ainv` and pedigree inputs and reconcile the corresponding Julia route.
