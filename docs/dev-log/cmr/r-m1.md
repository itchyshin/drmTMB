# R/TMB fixed-effects CJS M1 receipt

Date: 2026-10-06  
Status: native fixed-effects objective and ML fit path implemented; parent integration owns exports and generated help.

## 1. Goal

Add a separate R/TMB fixed-effects Cormack–Jolly–Seber route with first-capture conditioning, exact two-state summation, masks, irregular survival intervals, explicit terminal identification, keyed process-specific predictors, and an ML fitter. The TMB route uses the CJS `model_type = 1000` branch and avoids ordinary response-family preparation.

## 2. Implemented

`cmr_data()` validates individuals-by-occasion histories, optional IDs and masks, strictly ordered numeric occasions, positive interval lengths, administrative endpoints, and positive integer frequencies. `units` is a non-empty string label such as `"years"`; interval lengths are already expressed in that unit and are not rescaled. Encounter histories preserve masked zeroes and internally encode explicitly masked `NA` as zero with `observed = FALSE`. All-zero histories, masked captures, and captures after an administrative endpoint are rejected. Final-first histories remain in the data and contribute likelihood one.

`drm_cjs()` accepts separate one-sided survival (`phi`) and detection (`p`) formulas, keyed predictor tables, offsets, and `terminal_constraint`. Survival is logit unit-time survival raised to interval length; detection is logit probability without interval scaling. Predictor schemas, contrasts, factor levels, offsets, and coefficient names are retained in the fit. Predictor rows are joined by explicit keys and restored to individual-major order. Missing covariates are required only on contributing post-capture rows.

Terminal identification is assessed at the common final declared interval and occasion. The fit refuses the case where both process designs add independent terminal directions unless one `phi` or `p` probability is explicitly fixed. Each individual endpoint truncates only that individual's likelihood.

The C++ kernel uses log-state recursion with stable softplus, log-add-exp, and interval log-death expressions. It includes each post-first-capture survival transition through administrative follow-up and omits emissions at unsurveyed occasions. Frequency multiplies the complete individual marginal log likelihood.

The fit records ML log likelihood, process-labelled coefficients, optimizer status, gradient, a step-halved finite-difference gradient, gradient norm, Hessian, informative-history count, and surveyed post-capture row count. Fixed-only formulae use an inert, excluded TMB coefficient slot; no fit optimization is performed when there are no estimable coefficients.

## 3a. Decisions and Rejected Alternatives

- CJS stays outside `drmTMB()` ordinary response parsing and the family registry. Its histories and conditioning do not have a one-response family likelihood shape.
- Survival design rows use `id` / `interval_start` / `interval_end`; detection rows use `id` / `occasion`. Shuffled positional joins are refused.
- Administrative endpoints are follow-up truncation, not last sightings and not time-specific parameter constraints.
- `selection`, `sd_phi`, and `sd_p` are rejected until their declared later stages.
- The TMB objective uses one inert coefficient slot for fixed-only designs. A local no-free-coefficient `MakeADFun` experiment segfaulted when every parameter was mapped away; that experiment's output was in the turn stream and was not retained as a disk log, so the precise failure mechanism is not independently archived.
- Model uncertainty intervals, predictions, and simulation are not part of this M1 acceptance. Draft M2 prediction/simulation code is parked at `docs/dev-log/cmr/drafts/cjs-methods.R` and must be reviewed and tested before it enters `R/` or is exported.

## 4. Files Touched

- `R/cmr-data.R`: history constructor and validation.
- `R/cjs.R`: keyed design preparation, terminal rank guard, TMB objective construction, and ML fit diagnostics.
- `src/cjs_kernel.hpp`: stable two-state CJS likelihood kernel.
- `tests/testthat/test-cmr-data.R`, `test-cmr-exact.R`, `test-cmr-derivatives.R`: constructor, native exact objective, and derivative checks.
- `tools/check-cmr.R`: fail-closed exact and derivative test runner.
- `docs/dev-log/cmr/r-m1-red-test.log`, `r-m1-exact.log`, `r-m1-derivatives.log`, `r-m1-runner-negative.log`: retained test evidence.
- `docs/dev-log/cmr/drafts/r-m1-v1.md`: preserved previous report version.

The parent integration lane owns `src/drmTMB.cpp`, NAMESPACE, and generated Rd files. It has completed the `cmr_data` / `drm_cjs` exports and help pages in this shared tree; I made no edits to those files.

## 5. Checks Run

- Test-first constructor check initially failed twice with `could not find function "cmr_data"`; the pre-implementation summary is retained in `r-m1-red-test.log`.
- The constructor test file then passed 15 assertions, including the `units` label and unchanged interval-length checks.
- `Rscript tools/check-cmr.R --gate exact` passed and printed `CMR_EXACT_OK`. It calls the native TMB `model_type = 1000` objective for all 719 rows in `docs/dev-log/cmr/fixtures/exact.tsv`, including structural-zero probabilities, masked histories, and frequency multiplication. An additional objective case checks irregular interval survival and a skipped survey whose state transition remains in the likelihood.
- `Rscript tools/check-cmr.R --gate derivatives` passed and printed `CMR_DERIVATIVES_OK`. At non-optimal coefficients, AD gradients agreed with central finite differences at steps (10^{-4}) and (5\times10^{-5}); step-halving and AD/FD errors were below (10^{-6}). The case includes irregular intervals, a mask, frequency replication, offsets, and sparse keyed predictor rows. A separate objective with linear predictors at (+1000) and (-1000) returned finite objective and gradients.
- Parent reports that the full native objective build passed; its logs are `r-build-first.log` and `r-build-second.log`.
- No package-wide `R CMD check`, broad regression suite, inference calibration, or release check is claimed.

## 6. Tests of the Tests

The derivative test was temporarily given an intentional failing assertion. The derivative runner exited with status 1 and did not print `CMR_DERIVATIVES_OK`; its output is retained in `r-m1-runner-negative.log`. The original test was restored. The runner checks that each selected file produced expectations and stops on test failures before emitting its success marker.

## 7a. Issue Ledger

No GitHub issue was opened or closed in this lane. The work remains attached to the parent CMR programme and its local acceptance ledger. Future CMR gate names are recognized by the runner but fail explicitly as unavailable until their implementation exists.

## 8. Consistency Audit

The implementation does not register CJS as an ordinary `drmTMB()` family and does not change `bf()`. The CJS branch is added before ordinary-response fields; the existing Gaussian neighbour check passes. The test fixture provenance remains unchanged. Public R values for first capture and end are one-based; the C++ payload converts them to zero-based indices. The C++ encounter and interval vectors and R design matrices use individual-major row ordering.

Boole review found a semantic mismatch in the earlier draft: `units` had been made a numeric multiplier. It is now a character label, and interval lengths are left unchanged. Constructor and model-objective gates were rerun after that repair; retained exact and derivative logs below reflect the repaired source.

## 9. What Did Not Go Smoothly

The first exact runner version used `devtools::test(filter=...)` with a filter that selected no files. It was replaced by explicit test-file calls, `stop_on_failure`, and a nonempty-expectation check. A first test draft passed unsupported `info` arguments to `expect_length`; these were corrected. A terminal constraint initially used R's partial `$` matching and accidentally selected `phi` when reading `p`; exact `[["p"]]` indexing fixed it, and the fixed-offset fit test now guards the result. TMB's AD build rejected the native `log1p` overload; the kernel now uses a stable local AD-compatible implementation. These failures are distinct from the retained test-first and runner-negative evidence.

## 10. Known Residuals

This M1 leaf **does NOT cover** random effects, scale predictors, reference-cohort selection, population abundance, R-to-Julia bridge transport, profile/Wald/bootstrap intervals, or calibrated inference. It also does not claim out-of-sample prediction or accepted simulation behavior. The M2 method draft remains outside package autoload and export paths. Parent-owned export/help integration is present in the shared working tree but was not independently package-checked here.

## 11. Team Learning

Keep the CJS likelihood behind a dedicated objective branch, and make its exact gate evaluate the production TMB objective rather than a test-only R recursion. For AD stability, use log-state updates and finite inactive branches; probability-scale scaling made extreme predictors and state zeros harder to differentiate safely. A runner's success marker must follow real nonempty tests and must disappear on an injected failure.

Memory receipt: no second-brain note or durable decision was created by this lane.  
GoldenSet: `r-m1-exact.log` retains the passing 719-case production objective run; `r-m1-derivatives.log` retains the passing non-optimum derivative run; `r-m1-runner-negative.log` retains the injected-failure check.

Previous report snapshot: `drafts/r-m1-v1.md`; SHA-256 `b973a6a68d15b19bf2c102b9986561f67c824ca2f25f8193204d6f9ce41b819d`. Its naturalness assessment was NOTASSESSED.

Worker naturalness assessment: NOTASSESSED. Parent exact-draft review is retained in r-m1-assessment-parent.json.

## 12. Cross-Product Coverage

This receipt covers only the native R/TMB fixed-effects likelihood and ML fit preparation for CJS. It does not establish parity with Julia or drmTMB's ordinary families, R bridge support, simulation recovery, uncertainty coverage, or publication readiness. The parent also accepted the added contract tests and fixed-parameter parity. This M1 receipt does NOT cover integration, selection, recovery, documentation builds or programme closure; those gates remain pending.

Parent follow-up: contract test passes 35 assertions after preserving contrast metadata, rejecting non-finite designs/offsets and unsupported random terms, detecting aliased columns, learning factor levels on contributing rows, and rejecting unknown/missing keyed predictors. The exact runner now includes these checks. Parent final M1 reverify passes; see r-m1-final-reverify.log. Fixed-parameter parity and the marked comparator also pass; see curie-m1.md.
