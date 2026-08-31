# Selected-state CI repair

## 1. Goal

Repair the six R-CMD-check failures on PR #1104 without changing fitted values,
convergence rules, likelihoods, or tolerances.

## 2. Implemented

The affected test oracles now reconstruct TMB parameter lists from the fitted
object's saved `tmb_state$last.par.best`. A shared test helper makes that state
choice explicit across Gaussian, count, MSPL, missing-predictor, and optimizer
neighbours. Production extraction already used this selected state.

## 3a. Decisions and Rejected Alternatives

The failures were not repaired by relaxing numerical tolerances or rerunning
the inner optimizer. Diagnostics showed that `sdreport()` leaves mutable
`obj$env$last.par` at a Hessian perturbation, while the stored production modes
match `last.par.best` exactly and have inner gradients near `2e-14`. The tests
were corrected to use the same saved fitted state as production.

## 4. Files Touched

One test helper, nine existing numerical test files, one selected-state
regression file, this report, and its check-log entry. No R or C++ production
file changed in this repair.

## 5. Checks Run

The five files that reproduced GitHub's six failures pass 238 assertions with
no failures, warnings, or skips. The selected-state test plus every remaining
file touched by the oracle sweep passes 925 assertions with no failures,
warnings, or skips. `git diff --check` passes.

## 6. Tests of the Tests

The new regression deliberately changes only `obj$env$last.par`. The old bare
`parList(fit$opt$par)` result changes, while the explicit selected-state helper
remains exactly equal to its pre-damage value. This proves the test can detect
the mutable-Hessian-state mistake it is intended to prevent.

## 7a. Issue Ledger

This repairs the current R-CMD-check failures on PR #1104. DRM.jl PR #565
remains the merge-order dependency and must merge first. The global parity
programme and Ayumi-facing follow-up remain open.

## 8. Consistency Audit

All bare `parList(fit$opt$par)` test oracles in the affected suite were replaced;
the production selected-state extraction remains unchanged. Existing numerical
tolerances and estimator contracts are unchanged.

## 9. What Did Not Go Smoothly

The GitHub failures initially appeared as six model-specific random-effect
differences. Cross-family diagnostics showed one shared state-selection cause:
the tests were reading a mutable post-Hessian workspace rather than the fitted
state retained by drmTMB.

## 10. Known Residuals

Fresh GitHub R-CMD-check on the pushed head remains the merge gate. This slice
does not establish Julia inference parity or close the broader programme.

## 11. Team Learning

TMB test oracles must name the full selected parameter state explicitly.
Supplying only fixed parameters to `parList()` can silently borrow random modes
from mutable workspace state left by standard-error calculations.

## 12. Cross-Product Coverage

This covers the selected-state extraction used by the six observed failures and
their swept neighbours. It does NOT cover all drmTMB families, JuliaCall,
profile or bootstrap correctness, performance, release, or deployment.

## 13. Next Action and Routing

Obtain independent review, push the repair, require fresh green R-CMD-check,
then merge #1104 only after DRM.jl #565 is merged and green.
