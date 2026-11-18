# After Task: Julia Binomial Probit and Cloglog SD Slope Bridge

## 1. Goal

Extend the R-to-Julia bridge for Binomial probit and complementary log-log models to one ordinary independent numeric random slope with a matching coefficient-specific predictor-dependent SD formula.

## 2. Implemented

The non-logit Binomial bridge admission now accepts one ordinary mean random intercept or one independent numeric mean slope with one matching `sd()` formula. The coefficient selector is optional when the model has a unique target and may be explicit as `sd(group, coef = "x")`. The bridge coefficient-label payload now uses DRM.jl's hashed target key whenever a formula selects an SD target; an unselected single ordinary target retains the stable `sd` key. Synthetic probit and cloglog slope fixtures pass recovery and group-SD prediction checks against native TMB.

## 3a. Decisions and Rejected Alternatives

I extended the existing narrow non-logit exception rather than opening all Binomial formula shapes. The route still refuses multiple random terms, structured effects, and mismatched SD targets. I kept the selected-target label fix at the shared target-key source so explicit selectors remain coherent across the bridge.

## 3b. Mathematical Contract

For observation `i` in group `g`, the slope contribution is `x_i b_g`, with `b_g ~ Normal(0, s_g^2)` and `log(s_g) = alpha_0 + alpha_1 w_g`. The response probability uses the requested probit or complementary log-log link. Bernoulli responses have no free residual `sigma`. TMB uses Laplace integration and DRM.jl uses adaptive quadrature, so the test checks point recovery and group-SD behavior rather than exact likelihood equality.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-binomial-nonlogit-slope-sd-bridge.R`
- `NEWS.md`
- `vignettes/julia-engine.Rmd`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-nonlogit-slope-sd-bridge-20261024/`

## 5. Checks Run

- The new route tests first failed for the expected reason: the bridge refused the ordinary slope target. After that route was admitted, the live test exposed an R/Julia label mismatch. The final focused opt-in test exited 0 with 27 passing expectations, including two TMB/Julia fits each for probit and complementary log-log, SD-slope recovery, and group-SD prediction checks.
- The R-side admission and coefficient-label tests pass; the direct Julia family mapping is unchanged from the preceding intercept slice.
- R parsing, scoped `git diff --check`, and `pkgdown::check_pkgdown()` passed. Pkgdown's `--mathml` deprecation warnings are pre-existing.
- The broader pure `julia-bridge` test filter passed. Three live tests skipped because that separate command did not receive the paired Julia path; two existing `beta()` deprecation warnings were reported. A full site build was not run because it would overwrite this worktree's existing ignored 29 MB `pkgdown-site` output.
- The failed label-mapping run and passing rerun are preserved in the evidence folder. Its manifest records the exact source hashes.
- After-task structure validation passed. The general acceptance ledger remains NOT RUNNABLE with state UNKNOWN, so no broader programme gate is claimed as passed.

## 6. Tests of the Tests

The route-admission test failed before its implementation. The first live fit then failed at Julia's coefficient-label echo: R supplied the generic `sd` key while DRM.jl reported the selected slope as `sdtarget_69647c6969647c6d757c787c6e6f6e65`. A pure payload regression assertion reproduced the mismatch before the source fix. The passing live test checks both links and both public SD predictions. The generic test footer still says zero live tests ran; its startup and post-startup assertions show the live path executed, and the focused command exited 0.

## 7a. Issue Ledger

The read-only open-issue search for the Binomial non-logit selected-slope bridge and SD target labels returned no matching issue. No issue was created, changed, or closed.

## 8. Consistency Audit

The admission guard, Julia target label, synthetic data generator, and docs now describe one independent numeric slope with a coefficient-specific log-SD predictor. The intercept example remains valid and the new slope example selects `coef = "x"`. The formula guide now keeps the other probit/cloglog bridge shapes explicitly unavailable. No response likelihood code or integration method changed.

## 9. What Did Not Go Smoothly

The first live slope fit uncovered a marshalling defect that pure route-admission tests could not detect. The model reached Julia and failed before fitting because the label key did not preserve the selected coefficient identity. A payload-level regression assertion now catches that boundary directly.

## 10. Known Residuals

This slice covers one independent slope only. Correlated intercept-slope blocks, crossed terms, structured providers, missing responses, additional SD targets, and other Binomial bridge shapes remain outside the non-logit exception. Recovery uses fixed seeds and does not establish broad recovery or interval coverage. No general-SD programme gate closes.

## 11. Team Learning

For selected-target bridge work, test both formula admission and the serialized coefficient-label key before a full live fit. A model can pass parsing and still fail at the cross-language echo boundary.

## 12. Cross-Product Coverage

**Covers:** native R/TMB and paired DRM.jl for complete-response Binomial probit and complementary log-log models with one ordinary independent numeric mean slope and a matching predictor-dependent SD; fixed-seed point recovery, group-SD prediction, coefficient labels, and route-refusal controls.

**Does NOT cover:** correlated or structured non-logit effects, multiple random terms, other non-logit Binomial shapes, calibrated intervals, or broad recovery. The complete goal remains active.
