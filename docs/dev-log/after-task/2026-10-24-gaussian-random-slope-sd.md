## 1. Goal

Add predictor-dependent SD regression for one ordinary independent numeric Gaussian location slope, with recovery, public-output checks, simulation, constant-SD equivalence, and same-data Julia parity.

## 2. Implemented

- Enabled scalar independent slope targets in the Gaussian location adapter by setting `allow_slopes = TRUE`. The shared target helper still rejects correlated blocks and multi-coefficient targets.
- Added a fixed-seed synthetic native test for a group-level predictor of random-slope SD. It checks fit convergence, Hessian status, coefficient recovery, group-specific SD predictions, marginal simulation, and equivalence to the established constant-SD random-slope fit.
- Added a same-data Julia bridge fixture that checks target labels, point recovery, TMB/Julia coefficient agreement, log-likelihood agreement, and group-SD predictions for both the existing intercept case and the new slope case.
- Updated the random-effect scale design table, family adapter map, known-limitations page, NEWS, the predictor-dependent SD vignette, and the general-SD gate ledger.
- No C++ likelihood changes were needed. Existing Gaussian code already maps each random-effect coefficient to its fitted group-SD row.

## 3a. Decisions and Rejected Alternatives

- Limited this change to one ordinary independent numeric slope. Correlated intercept-slope blocks, structured slopes, multiple slope coefficients, and bivariate routes remain outside this slice.
- Reused the existing coefficient selector `sd(id, coef = "x") ~ w`; no formula grammar or public function changed.
- Assumption made without asking: existing Gaussian group-SD row mapping is correct for a scalar independent slope. The recovery, prediction, simulation, constant-SD, and same-data parity fixtures exercise that mapping.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-gaussian-sd-slope-regression.R`
- `tests/testthat/test-julia-gaussian-sd-parity.R`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `NEWS.md`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-24-gaussian-random-slope-sd.md`

## 5. Checks Run

- RED: the new native test failed at the expected Gaussian intercept-only guard, identifying coefficient `x` as an unsupported slope target.
- GREEN: focused native test filter `gaussian-sd-slope-regression` passed 12 expectations with no failures, warnings, or skips.
- Same-data Julia bridge filter `julia-gaussian-sd-parity` passed two live tests and 22 expectations with no failures or skips under Julia 1.10.0.
- The two ordinary-intercept parity ledger rows now point to the preserved test snapshot whose SHA-256 matches the original source manifest. The hash-checking reconciler passes for 52 receipt records and 43 distinct candidate rows; the table reports linked evidence rows; broader implementation and interval coverage remain unverified.
- The native constant-SD likelihood comparison passed at tolerance `1e-8`; the correlated-block refusal assertion also passed.
- Focused source hashes: `R/drmTMB.R` `b47b4e438c030f6c7d8f17c3508497a8708089e8baa2fee5312a642fa67d6735`; native test `5de3f75befc4f977c2a0aa1a97cc1c2fe7b9dbcd6ef6b8b2d181043ff818e414`; Julia parity test `1987789bb6949f38ebb702b8195b39fc13a5a150285d84508021c3a35b8a03ee`.

## 6. Tests of the Tests

The native regression failed before the adapter change with the specific intercept-only rejection, then passed after enabling scalar slopes. A negative assertion confirms that the same selector still rejects a correlated intercept-slope block. The constant-SD control requires the modeled `sd ~ 1` likelihood to equal the established random-slope likelihood.

## 7a. Issue Ledger

- Fixed: Gaussian `mu` SD target resolution refused an otherwise-supported independent numeric random slope.
- Deferred: correlated or structured slope SD regression, broader Gaussian combinations, profile/bootstrap refit coverage, and interval-coverage calibration.

## 8. Consistency Audit

Compared the Gaussian adapter, common target resolver, existing TMB group-SD row mapping, native simulator, Julia bridge fixture, formula-selector documentation, family map, and known-limitations wording. The interface and equations use the same group-level log-SD predictor. No likelihood parameterization or C++ code changed.

## 9. What Did Not Go Smoothly

The first expanded constant-SD assertion compared the log-SD coefficient with a natural-scale prediction. The failing values exposed the scale mismatch; the test now compares against the exponentiated intercept and passes.

## 10. Known Residuals

This is one ordinary univariate Gaussian slope route. It does NOT establish support for correlated blocks, structured Gaussian slopes, bivariate models, arbitrary random-effect types, profile/bootstrap refits, or calibrated uncertainty. G3 and G4 remain open; coverage calibration is deferred under the current plan.

## 11. Team Learning

Memory receipt: the repository route script returned no LOAD-FIRST manifest for this worktree. I used the project-local diff review, exact-path preflight output, and the repository after-task protocol. Golden Set: not in scope for this family-admission slice.

## 12. Cross-Product Coverage

Covers: native R/TMB fitting, coefficient extraction, group-SD prediction, marginal simulation, constant-SD equivalence, and one same-data Julia point-parity route for an ordinary independent Gaussian numeric slope.

Does NOT cover: other Gaussian effect shapes or endpoints, structured or correlated slopes, bivariate fits, profile/bootstrap refits, other families through this same slice, or interval-coverage calibration. It is partial capability evidence and closes no programme gate.
