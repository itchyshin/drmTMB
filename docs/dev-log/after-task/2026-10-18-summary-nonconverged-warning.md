# summary() flags non-converged fits

## 1. Goal

Close #1545: `summary()` printed only `convergence: 1` for a non-converged fit, while `print()` said "not converged".

## 2. Implemented

`summary.drmTMB()` now stores `convergence_message`. `print.summary.drmTMB()` reuses `drm_convergence_label()` to print "not converged" with the optimizer message and emits a warning, matching `print()`.

## 3a. Decisions and Rejected Alternatives

Warn at print time, not at `summary()` time, so programmatic use of the summary object stays quiet. The Julia-bridge summaries are out of scope.

## 4. Files Touched

`R/methods.R`, `tests/testthat/test-summary-nonconverged.R`.

## 5. Verification

Not run locally: the sandbox has no TMB, testthat or network access to install them. Relies on CI for red-to-green proof.
