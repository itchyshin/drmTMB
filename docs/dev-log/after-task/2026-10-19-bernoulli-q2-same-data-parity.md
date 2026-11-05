# After Task: Bernoulli Correlated-q2 Same-data Point and Output Parity

## 1. Goal

Add one same-data Bernoulli correlated intercept/slope SD-regression comparison through the R/TMB and Julia engines, and record exactly what that fixture establishes. Keep the broader SD-regression programme active.

## 2. Implemented

Added a synthetic 64-group by 32-observation fixture to the live Julia bridge suite. The same response, fixed-effect formula, correlated random intercept/slope structure, and coefficient-specific SD designs are fitted through both engines. The test compares convergence flags, fixed effects, both SD regressions, latent correlation, predicted SD values, and group labels at the tolerances stated in the test. A read-only fixture audit found no obvious predictor collinearity, but 64 group-level latent draws support seven fitted parameters and Julia reports a near-singular Hessian. The test therefore gives a plumbing/rough point-alignment check, not evidence that every q2 estimate is practically well identified.

Updated the capability inventory, Julia output contract, and recovery checkpoint to record this one candidate point/output cell. The native correlated-q2 test suite remains separate evidence; it is not a cross-engine comparison.

## 3a. Decisions and Rejected Alternatives

Kept the fixture synthetic and self-contained, with no collaborator data or examples. Did not add another likelihood oracle: independent correlated-q2 integration checks already exist in both packages. Did not compare log likelihoods because the two engines use different integration approximations. Did not treat convergence flags or point agreement as uncertainty validation.

Assumptions made without asking: the existing paired dirty candidate checkouts are the intended development targets for this bridge test. If that assumption is wrong, rerun the same fixture against the designated candidate pair before relying on this result.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-sd.R`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/general-sd-regression/julia-output-contract.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/check-log.md` (entry remains pending while another lane holds an overlapping lease)
- `docs/dev-log/after-task/2026-10-19-bernoulli-q2-same-data-parity.md`

## 5. Checks Run

- `DRMTMB_JULIA_TESTS=true NOT_CRAN=true` with `DRM_JL_PATH` and `DRMODELS_JL_PATH` set to the paired candidate worktrees; task-specific writable Julia depot; Julia threads capped at 4 and BLAS/OpenMP/MKL at 1; `Rscript -e 'devtools::test(filter = "julia-binomial-sd")'`: **112 assertions, five live tests, zero testthat failures, warnings, or skips; 115.4 seconds**. Julia printed two singular-Hessian diagnostics: one with `rcond = 9.23265335367337e-10` and coordinate 7 flagged, and one with `rcond = 3.879150990279055e-17` and no flat coordinate flagged. Initial reporter output did not identify the generating fit; later isolation localized the second warning to the final test's bootstrap call, not the q2 parity fit.
- `NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-correlated-sd")'`: **60 assertions, zero failures, warnings, or skips**. This is native correlated-q2 coverage, not engine parity.
- Refit the exact parity fixture through native TMB alone to inspect its observed-information proxy: `native$sdr$pdHess = TRUE`; the eigenvalues of `native$sdr$cov.fixed` ranged from `0.00356957` to `0.181036`, a condition number of about `50.7`. This is not interval-calibration evidence and does not resolve the separate bootstrap-refit warning.
- Refit the exact fixture through Julia with the writable depot isolated under `/private/tmp`: the fit converged and the bridge returned a finite `6 x 6` covariance for `mu` and the two SD targets (condition number `45.42`). The public uncertainty payload says `status = "ok"`, `se = TRUE`; the correlated-block parameter has a separate output and is not in that covariance matrix.
- Refit the same synthetic fixture directly through the Julia Bernoulli SD fitter and compared its seven-parameter automatic-differentiation Hessian with a central finite-difference Hessian. Their eigenvalues agreed to the displayed precision (range `6.01956`–`274.24`); relative Frobenius discrepancy was `4.05e-7`. A first finite-difference script produced an invalid large result due to a diagnostic-script error and was discarded. The q2 parity test was then isolated in a temporary directory and passed **17 assertions with no Hessian warning**.
- Isolated the final independent-intercept/slope test from the Julia bridge file. Its point fit and profile checks completed before the `3.879150990279055e-17` warning appeared during the bootstrap call. The returned 80% bootstrap interval reports `bootstrap.n = 2`, `bootstrap.failed = 1`, and `profile.message = "2/3 successful refits"`. This does not identify whether the singular-Hessian warning came from the failed or one of the accepted refits.
- Added public-output assertions to that test for `conf.status`, the `bootstrap.n + bootstrap.failed = 3` denominator, nonnegative counts, and finite interval endpoints. The isolated test now passes **18 assertions** on the current candidate; it still prints the singular-Hessian warning and returns 2 used refits plus 1 failed refit. These checks protect attempt accounting only; they do not establish interval calibration or identify which replicate warned.
- Source inspection of the current Julia candidate shows the bootstrap accepts a refit when `check_converged` passes `is_converged(fitb)`, then stores its coefficients; the Binomial SD fitter's convergence flag reflects optimizer convergence, while the singular-Hessian guard returns a pseudo-inverse without changing that flag. Therefore the warning alone does not prove the refit was excluded. The bridge reports aggregate used/failed counts but not per-refit Hessian status or failure reasons. No Julia source was changed because that worktree is handed to Cursor.
- The initial parity-test file hash at the time of the original slice was `c5eccbf93e56b783aa9c5dc26dfbf9ee77c4f9224db6a0990662d3b718b59aa1`; after the bootstrap denominator assertions, the current file hash is `905e44b4b77cf09b70798d63878b46615ab39884cd31a19dc37d25addec06f19`.
- `git diff --check`: pass. The after-task structural/negative-space validator passed. The `partial-arc-negative-space` and `completion-overclaim` Golden Set checks both passed against this report.
- No package-wide suite or documentation build was run for this focused test/evidence slice.

## 6. Tests of the Tests

The same-data comparison would flag disagreement between the two candidate engines in each listed estimate or output label. No deliberate mutation or broken-index control was run for this new test, so its sensitivity to a shared error in both engines is unknown. Existing numerical integration checks are separate and do not validate this bridge fixture's Hessian or interval inference.

## 7a. Issue Ledger

- **Fixed:** the Bernoulli q2 same-data point/output comparison was missing from the live R bridge suite.
- **Resolved for this fixture:** the q2 parity fit's singular-Hessian attribution was wrong. Its isolated test passes without a warning, and an independent direct-fit AD-versus-finite-difference check confirms a positive, well-conditioned seven-parameter Hessian. Do not generalize this single-fixture result to q2 recovery or interval calibration.
- **Open:** the focused Julia file also warns during the bootstrap call in the final independent-intercept/slope test. That bootstrap returns two successful refits out of three; it remains unknown whether the near-singular refit was rejected or included in the interval. Record the failed-refit mechanism and test public uncertainty behavior before using this path as calibrated evidence.
- **Open:** the shared `docs/dev-log/check-log.md` entry is waiting for the active bias-diagnostics lease to clear.
- **Open:** broad family, effect-type, endpoint, provider, and engine coverage remains unresolved in the programme inventory.

## 8. Consistency Audit

Checked the capability inventory, Julia output contract, programme checkpoint, native correlated-q2 test outcome, and the independent review of the proposed claim. Wording is limited to one synthetic fixture and the specific comparisons encoded in the test. The separate native test is not described as cross-engine parity. No likelihood equality, recovery, uncertainty, identifiability, or family-wide claim is made.

## 9. What Did Not Go Smoothly

The first lane preflight invocation used the wrong script location; the repository points to the brain tools directory. The corrected preflight found an active lease overlapping `docs/dev-log/check-log.md`, so that shared file could not be updated in this slice. The Julia diagnostic also exposed a near-singular Hessian despite successful point comparisons.

## 10. Known Residuals

The candidate test does not establish recovery, identifiability, profile reliability, standard-error reliability, interval calibration, or general TMB/Julia parity. The q2 fit's direct curvature check supports only this synthetic point fit. The separate bootstrap warning and one failed refit need mechanism-level follow-up; the three-refit smoke test is not calibration. The paired worktrees are dirty development candidates, not released-source evidence. The check-log entry remains outstanding until the shared-file lease clears. The repo's `closeout.py check` resolves its own global brain root and failed while validating that unrelated ledger; the project-scoped after-task structural validator passed, but that does not replace the pending shared check-log update.

## 11. Team Learning

Report engine parity at the level actually tested: same-data point and output comparisons can be useful even when integration methods differ, but they do not validate the Hessian or uncertainty. Keep the numerical warning next to the positive result. Memory receipt: loaded the drmTMB LOAD-FIRST manifest, repository AGENTS.md instructions, and after-task protocol; they shaped the lane preflight, evidence limits, and report structure. Golden Set: `partial-arc-negative-space` and `completion-overclaim` both passed against this report.

## 12. Cross-Product Coverage

Covers: one Bernoulli correlated random-intercept/random-slope SD block; one same-data TMB/Julia candidate comparison; the listed fixed-effect, SD-regression, correlation, and predicted-output comparisons.

Does NOT cover: calibrated uncertainty, q2 standard-error calibration or correlation-parameter uncertainty, independent recovery, a shared likelihood oracle for this bridge fixture, other response families, other random-effect types or providers, other distributional endpoints, bivariate routes, released Julia support, or general engine parity.
