# R message for a failed Julia fit

## Problem and change

The Julia bridge in DRModels.jl #1270 now sends `NaN` for `loglik` after a failed fit, plus `fit_failed` and `fit_failed_message`. R accepted the `NaN` but said nothing, so a user could read a failed fit as a normal one.

`new_drmTMB_julia()` and `new_drmTMB_julia_xfam()` now warn when `fit_failed` is `TRUE`. The warning gives Julia's message, says `logLik` is `NaN`, and suggests refitting with `engine = "tmb"` or checking data scaling. The object stores `fit_failed`, the opt slot says "failed fit" instead of "reported no convergence", and the three Julia print methods add a FAILED FIT line. `logLik()` still returns `NaN`.

## Validation

New tests in `test-julia-failed-fit-message.R` cover a failed fit (warns, `NaN` logLik, printed line), a good fit (silent), a missing key (silent, old wording), the cross-family constructor, and the opt slot. They pass 27 of 27, and five neighbouring bridge test files pass unchanged.

## Limits

Only hand-built bridge results were tested. The real payload from DRModels.jl #1270 was not exercised end to end. An older Julia package sends no `fit_failed` key and behaves as before. No exports or Rd files changed.

## Follow-up: two cosmetic fixes from a live bridge test

A live failed fit showed two defects. The warning printed `"NaN"` in quotes, so it now uses code formatting (`logLik()` is `NaN`). `summary()` printed the coefficient table of a failed fit with no marking, so the table header now reads "NOT VALID, the fit failed" (the random-effects header likewise). The values themselves are unchanged and other methods still read them; successful-fit output is identical.
