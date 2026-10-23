# Native missing-predictor covariance repair

## 1. Goal
Repair the native regression-coefficient covariance mapping found during approved Julia–R parity work (DRM.jl#563). This is a bounded slice; programme G0–G8 remain OPEN.

## 2. Implemented
Exact fitted-variable metadata maps public mi_<variable> coefficients to the native first or second predictor slot. All three profile target callers carry the fitted object. This restores selected public covariance, regression SEs and direct Wald target availability without changing the fitted likelihood.

## 3a. Decisions and Rejected Alternatives
Do not change optimizer defaults or the frozen 4e-6 parity contract. Do not map positive scales or mixture probabilities to raw parameters without their Jacobian and interval transformation. These remain required follow-up work.

## 4. Files Touched
R/profile.R; tests/testthat/test-missing-predictor-public-covariance.R; docs/dev-log/evidence/julia-r-parity/native-mi-covariance/; this report. Preserved the foreign ZOB bridge/tests and every other lane's work.

## 5. Checks Run
Final regression receipt-004 records unchanged R/test/build source and 101 passing assertions in 5.78 seconds including startup. Six existing profile inventory/Wald neighbour tests pass 77 assertions. Independent Rose review approved source SHA455310984cf1244a90b7f3ce184e82a1f75fbdf50acde243694b53d181d6b5a5 and ran pure metadata boundary probes. Native finite-state and two-Gaussian fits exercised full covariance, summary SEs and raw-normal intervals. No profile/bootstrap campaign or whole-package qualification claimed.

## 6. Tests of the Tests
Before the fix, the new test failed 16 assertions with missing covariance rows and misrouted predictor target names. Negative metadata cases cover absence, invalid types, vector names, punctuation and transformed summaries. Fixtures contain nonzero response/predictor and predictor/predictor cross-covariance; full matrix equality checks both axes.

## 7a. Issue Ledger
DRM.jl#563 stays OPEN. No native capability row or whole parity obligation closed. Both strict finite-state 4e-6 cases remain FAIL. The approved programme plan is unchanged.

## 8. Consistency Audit
Rose's independent review identified the positive-scale neighbour before any raw mapping was added. Root recorded that required transformation gap explicitly and added the requested assertions. Golden Set: two finite predictor families, two Gaussian predictors with custom variable names, existing ordinary profile/Wald tests. Source and tests agree on the bounded regression-only scope.

## 9. What Did Not Go Smoothly
A public accessor bug initially resembled unavailable Hessian inference, but the raw fitted covariance was finite. Inspection across 915 branch helper variants found no existing corrected mapping. The broader natural-scale contract requires separate work; substituting a raw covariance would introduce a new error.

## 10. Known Residuals
Positive predictor scales, mixture probabilities and random-predictor summaries need transformation-aware public covariance. Native log-Wald versus current bridge delta-Wald conventions must be reconciled. Actual profile/bootstrap execution, full native/direct-Julia/bridge parity, large-tree checks, every registered warm win and full documentation verification remain required. Receipt-004 stamps a tested working tree, including preserved foreign R bridge changes; it is not a clean committed-head qualification. No release, deployment, remote campaign, worktree retirement or collaborator message. Actual agent-hours were not instrumented.

## 11. Team Learning
Map public coefficient blocks through fitted model metadata. Public names and internal storage slots need not match; matching shapes alone does not establish covariance correctness. Transform both covariance axes when public scales differ.

## 12. Cross-Product Coverage
This repair changes native R target resolution only. Direct Julia and the R-to-Julia bridge use their own paths and do not inherit this native helper. The native fixture covers Gaussian responses with ordinal, categorical and two Gaussian missing predictors; it does NOT cover non-Gaussian response families, random/structured predictor providers, REML, penalty, aggregation, transformed predictor scales, or executed profile/bootstrap intervals. Julia factor-coding and broader public-output parity are separate active slices. Both repositories' outstanding obligations remain in the programme ledger.
