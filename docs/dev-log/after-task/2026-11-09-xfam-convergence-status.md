# Cross-family convergence status

## Problem and change

Every cross-family Julia fit (`drmTMB_julia_xfam`) reported
`convergence_status()` `"degenerate"` and `is_converged()` `FALSE`, although the
bridge returned `converged = TRUE` and optimizer code 0. Cross-family fits are
point-estimate only and carry `vcov = NULL`. The shared twin rule reads an
empty standard-error vector as degenerate, and commit 4deb47493 moved
`is_converged()` onto that rule without re-running the live cross-family tests.
Fits and log-likelihoods were never affected; the flag was wrong.

The fix adds `convergence_status.drmTMB_julia_xfam()`. It returns
`"converged"` when the optimizer code is 0, the log-likelihood is finite and
above the sentinel, and the bridge raised no geometry flag; otherwise
`"degenerate"`. `is_converged(include_hessian = TRUE)` stays `FALSE` because no
covariance exists. The shared function is untouched, so every other route is
byte-identical. The alternative (treat `vcov = NULL` as acceptable in the shared
rule) would have changed the contract for native fits and for Julia fits whose
covariance is missing by mistake, so it was not chosen.

## Validation

An offline mock test fails without the fix and passes with it. The four live
cross-family tests ran against DRM.jl `0bfcde2bb` on Julia 1.12.6; see the
check-log entry for results.

## Limits

The status says nothing about standard errors or interval quality. There is no
`"boundary"` value for this route. The NB2 by Gaussian profile interval
returning NaN is a separate Julia-side issue and is not changed here.
