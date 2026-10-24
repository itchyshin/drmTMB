# R/TMB fixed-effects CJS M1 receipt

Date: 2026-10-06  
Status: exact fixed-effects objective and ML fit path implemented; M2 public prediction/simulation methods remain a draft.

## 1. Request and boundary

Implement the R/TMB fixed-effects Cormack–Jolly–Seber path with first-capture conditioning, exact state summation, masks, interval survival, explicit terminal identification, process-specific design matrices, and an ML fitter. The path is separate from ordinary response families and uses the `model_type = 1000` CJS dispatch.

This receipt covers fixed effects. Random effects, predictor-dependent random-effect scales, reference-cohort selection, and population abundance remain unsupported.

## 2. Inputs and validation

`cmr_data()` accepts an individuals-by-occasions history matrix, optional IDs, a survey mask, ordered numeric occasions, positive interval lengths, numeric time-unit scale, administrative endpoints, and positive integer frequencies. R IDs default to deterministic row indices. A missing encounter requires an explicit `observed = FALSE`; masked zeroes are allowed, masked captures are rejected. All-zero histories and captures after administrative endpoints are rejected. Final-first histories are retained.

`drm_cjs()` accepts separate one-sided `phi` and `p` formulas plus keyed predictor tables. Survival predictors use `id`, `interval_start`, and `interval_end`; detection predictors use `id` and `occasion`. Joins restore the model's individual-major order by key. Missing covariates are allowed outside contributing rows; required contributing values fail through the formula model-frame check. Survival uses logit unit-time survival raised to the declared interval length; detection uses logit probability without interval scaling. Offsets remain on their formula link scale.

The public `terminal_constraint` fixes exactly one of the common final-interval unit survival or final-occasion detection probabilities. Without it, fitting is refused only when both process designs gain a free direction at their respective common final time. Administrative endpoints truncate each history and never move this identification constraint.

## 3. Objective and native integration

The two-state forward recursion conditions on the first capture, omits earlier encounters and the first-capture emission, applies every later survival transition through `end`, and omits emissions at unsurveyed occasions. The log-state implementation uses stable softplus, log-add-exp, and log-death calculations, including interval lengths and extreme linear predictors. Integer frequency multiplies each integrated individual log likelihood.

The TMB payload uses individual-major encounters and intervals, with `first` and `end` converted from R's one-based indexing to zero-based kernel indices. A fixed-only design receives an inert TMB slot because TMB's zero-parameter constructor segfaulted in the package version used here; the slot is excluded from returned coefficients and optimization. Ordinary model data and family routes are not modified by this R interface.

## 4. Changed files

- `R/cmr-data.R`: validated CJS history object.
- `R/cjs.R`: keyed model preparation, terminal-rank check, TMB ML fit, and fit diagnostics.
- `src/cjs_kernel.hpp`: exact C++ state recursion called by the CJS objective branch.
- `tests/testthat/test-cmr-data.R`, `test-cmr-exact.R`, `test-cmr-derivatives.R`: constructor, exact-likelihood, and derivative checks.
- `tools/check-cmr.R`: fail-closed exact and derivative runners.
- `docs/dev-log/cmr/r-m1-runner-negative.log`: runner failure-injection output.

The unreviewed M2 prediction/simulation draft is parked at `docs/dev-log/cmr/drafts/cjs-methods.R`; it is not in `R/`, exported, or included in M1 gates. It still needs new-data prediction, correct unseeded RNG behavior, and reader review.

## 5. Test-first evidence

Before implementation, `Rscript -e 'testthat::test_file("tests/testthat/test-cmr-data.R")'` failed twice with “could not find function `cmr_data`”. After implementation, sourcing the constructor and running that file passed 12 assertions. The original failing-test state is recorded in the turn output; no fixture or production code was present when it was recorded.

## 6. Exact-likelihood evidence

`Rscript tools/check-cmr.R --gate exact` passed and printed `CMR_EXACT_OK`. The gate sends each of the **719** rows in `docs/dev-log/cmr/fixtures/exact.tsv` through `TMB::MakeADFun(DLL = "drmTMB")` and the native `model_type = 1000` branch, including masked histories and structural zero probabilities. Frequencies are set to two in these objective calls and compared against squared fixture probabilities. An additional production-objective check covers irregular Δ and an unobserved middle occasion whose state transition still contributes to a later noncapture.

## 7. Derivative evidence

`Rscript tools/check-cmr.R --gate derivatives` passed and printed `CMR_DERIVATIVES_OK`. At fixed non-optimal coefficients, TMB AD gradients agreed with central finite differences at steps (10^{-4}) and (5\times10^{-5}), with both step-halving stability and AD/FD error below (10^{-6}). The case includes irregular intervals, a survey mask, frequency replication, keyed sparse predictor tables, and formula offsets. A second native objective case with link predictors at (+1000) and (-1000) returned finite objective and gradient values.

## 8. Runner failure check

The derivative test was temporarily given an intentional failing assertion and the exact runner was invoked. It exited with status 1 and did not print `CMR_DERIVATIVES_OK`; the original test file was restored. The retained output is `docs/dev-log/cmr/r-m1-runner-negative.log`.

## 9. Fit result and limits

The ML fit stores process-labelled coefficients, log likelihood, optimizer/convergence information, gradient and finite-difference comparison, gradient norm, Hessian, informative-history count, and surveyed post-capture row count. The current route does not provide standard errors, confidence intervals, bootstrap inference, out-of-sample prediction, or simulation as accepted M1 functionality. `selection`, `sd_phi`, and `sd_p` are explicitly refused until their stages.

## 10. Neighbor and claim check

The implementation adds the standalone `cmr_data()` / `drm_cjs()` route and C++ kernel include. It does not add CJS to `drmTMB()`, alter `bf()` or the response-family registry, or change model types below 1000. Source build and DLL dispatch were compiled by the parent integration lane. NAMESPACE and Rd integration are parent-owned and remain pending there; no package-wide `R CMD check` is claimed.

## 11. Handoff and remaining acceptance

Parent must finish export/S3/Rd integration and review the new-objective branch with this interface. The exact and derivative gates are available through `Rscript tools/check-cmr.R --gate exact` and `--gate derivatives`. Integration, selection, parity, recovery, and documentation gates intentionally fail with `CMR_GATE_UNAVAILABLE` until those later stages exist. No release, CRAN, bridge, or calibration claim follows from these M1 checks.
