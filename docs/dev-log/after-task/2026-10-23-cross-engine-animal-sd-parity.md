# After Task: Current-source animal SD parity checks

## 1. Goal

Strengthen focused cross-engine evidence for predictor-dependent animal random-effect SDs without changing either model builder.

## 2. Implemented

Added a seeded Poisson animal-intercept parity test across native TMB and Julia, and added a log-likelihood comparison to the existing Gamma animal-slope parity test. Linked the exact Poisson native and Julia capability rows to a source-bound focused-test receipt. Refreshed six existing Gamma evidence rows after rerunning the whole test file on the changed test source.

## 3. Mathematical Contract

The checks use the existing model contract: the animal effect has covariance `D A D`, where the group SD is `exp(alpha_0 + alpha_z * z)`. The Poisson test compares same-data TMB and Julia fits with a labelled supplied `A`; the Gamma test checks same-data likelihood, SD coefficient, and predicted-SD agreement. No likelihood or covariance parameterization changed.

## 3a. Decisions and Rejected Alternatives

Kept both changes in tests and evidence records because the current candidate already fits these routes. Did not alter shared native or Julia model builders, did not relax convergence or Hessian expectations, and did not generalize either result beyond its exact synthetic row.

## 4. Files Touched

- `tests/testthat/test-julia-poisson-animal-sd-parity.R`
- `tests/testthat/test-julia-gamma-sd.R`
- `docs/dev-log/general-sd-regression/evidence/poisson-animal-intercept-parity-20261023/test-console.log`
- `docs/dev-log/general-sd-regression/evidence/poisson-animal-intercept-parity-20261023/source-manifest.json`
- `docs/dev-log/general-sd-regression/evidence/poisson-animal-intercept-parity-20261023/receipt.json`
- `docs/dev-log/general-sd-regression/evidence/gamma-animal-slope-parity-20261023/test-console-current-source-loglik-20261023.log`
- `docs/dev-log/general-sd-regression/evidence/gamma-animal-slope-parity-20261023/test-console-whole-file-loglik-20261023.log`
- `docs/dev-log/general-sd-regression/evidence/gamma-animal-slope-parity-20261023/source-manifest-current-loglik.json`
- `docs/dev-log/general-sd-regression/evidence/gamma-animal-slope-parity-20261023/source-manifest-whole-file-loglik.json`
- `docs/dev-log/general-sd-regression/evidence/gamma-animal-slope-parity-20261023/receipt-whole-file-loglik.json`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/after-task/2026-10-23-cross-engine-animal-sd-parity.md`
- `docs/dev-log/check-log.d/2026-10-23-cross-engine-animal-sd-parity.md`

## 5. Checks Run

- Focused Poisson animal-intercept test: passed, one live test. Native and Julia fits converged; the native Hessian was positive definite; the SD coefficients, log likelihoods, group SD predictions, and named parameter outputs met the test comparisons.
- Full `julia-gamma-sd` test file: passed, five live Julia tests. The newly added animal-slope log-likelihood comparison passed at relative tolerance `1e-3`.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 19,118 candidate rows, 30 evidence receipts, 25 distinct rows linked, and 19,093 rows still unlinked.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: 11 tests passed.
- Whitespace scan of the two test files and new receipts: no trailing whitespace.
- JuliaCall printed a non-fatal `LogExpFunctionsInverseFunctionsExt` warning during bridge setup; both live test runs completed.

## 6. Tests of the Tests

The first Poisson run exposed that `control = drm_control(se = FALSE)` leaves no Hessian diagnostic, so the test's positive-Hessian assertion failed. Removing that test-only override made the assertion exercise the fitted Hessian; the fits and recovery fixture were unchanged. The new Gamma likelihood assertion passed alongside the existing coefficient and prediction checks.

## 7. Design and User Documentation

No model behavior or public formula syntax changed, so README, NEWS, formula grammar, limitations, vignette, and pkgdown navigation were not changed. The work is recorded in the internal evidence ledger and this report.

## 7a. Issue Ledger

Read-only issue search found open issues #932, #1301, and #59 on broader Laplace-bias, non-Gaussian repeatability, and simulation-framework topics. None specifically tracks these current-source parity checks, so the issue tracker was left unchanged.

## 8. Consistency Audit

The Poisson receipt links only the exact `native` and `Julia` animal-intercept rows with supplied covariance. The Gamma receipt refreshes the prior iid-intercept, iid-slope, and phylogenetic-intercept point-parity rows from a full current-source run. The Gamma animal-slope fixture is slope-only and does not satisfy the separate required intercept-plus-slope row. Neither receipt establishes general support or interval calibration. No formula grammar, public docs, examples, or package capability claims changed.

## 9. What Did Not Go Smoothly

The first Poisson test attempt stopped in JuliaCall before model fitting because it tried to write under the home Julia cache. Routing the Julia depot through `/private/tmp/drmtmb-julia-depot` allowed the bridge to run. A later assertion also caught the test's own disabled-Hessian setting, which was corrected before accepting the result.

## 10. Known Residuals

These are single synthetic fixtures and focused parity checks. They do not measure repeated recovery or confidence-interval coverage, and they do not establish full family, random-effect, or engine parity. JuliaCall's extension warning remains unresolved but did not prevent either run.

## 11. Team Learning

For cross-engine tests that assert `pdHess`, do not disable standard-error/Hessian reporting in the fit control. When a shared test file changes, rerun the complete focused file and refresh every evidence row whose source hash names that file.

## 12. Cross-Product Coverage

The same synthetic data were fitted with native TMB and Julia for each parity check. This covers Poisson `mu` animal intercepts with supplied `A` covariance, plus the existing Gamma test rows refreshed by the full test-file run. Julia-specific output comparisons ran through the R bridge. This slice does NOT cover other families, bivariate responses, other distributional endpoints, non-animal random-effect types, multi-coefficient animal blocks, A-inverse or pedigree providers, repeated recovery, interval calibration, an external package comparator, or a cross-version matrix.

## Next Actions

Continue through the exact required-row inventory, adding implementation and current-source tests for uncovered combinations. Keep calibrated uncertainty, Totoro/DRAC work, and the NotebookLM methods review in the active goal; these checks do not close those requirements.
