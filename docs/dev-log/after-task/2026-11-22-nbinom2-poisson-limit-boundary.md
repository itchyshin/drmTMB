# After task: nbinom2 at the Poisson limit is boundary

Reader: the next reviewer of draft PR #1801 (Gauss / Emmy / Rose).

## Goal

Make the branch match Shinichi's later ruling and merge `origin/main`.
On 18 Nov 2026 (#1554) a fit is `"converged"` only when no parameter is
at a boundary, and a dispersion at its limit is `"boundary"`, checked
before the Hessian. The 25 Oct 2026 note on #1535 asked for
`is_converged() == TRUE` plus Poisson-equal location standard errors and
a missing phi standard error. That converged reading is the earlier one.
This slice does not rewrite the converged rule, and it does not change
the covariance.

## Files

- `R/check.R` (classifier already on the branch; roxygen sentence added)
- `man/convergence_status.Rd`
- `NEWS.md`
- `docs/design/278-twin-convergence-status.md`
- this note and `docs/dev-log/check-log.d/2026-11-22-nbinom2-poisson-limit-boundary.md`

## Checks

R 4.3.3, `testthat::test_local()` with filter
`convergence-status-twin|mle-existence|julia-convergence-status-parity`:
FAIL 0, PASS 84, SKIP 2 (Julia not installed). The bladder-cancer test
passed: status `"boundary"`, `is_converged()` `FALSE`, log-likelihood
matches the Poisson fit, log-sigma `<= -8`. All-zero `nbinom2` stays
`"degenerate"`. `python3 -m unittest tools.tests.test_capability_ledger`
ran 92 tests, OK. `devtools` itself did not install.

## Consistency

`is_converged()` remains `TRUE` only when `convergence_status()` is
`"converged"`. The design note now says the intercept-only R step exists
and that Student `nu` to infinity, covariate `sigma`, and the Julia twin
still use the inflated-SE screen.

## What did not change

No test expectation moved. Sigma standard errors are still the Wald
values (the bladder-cancer sigma SE near 7242 is still printed).
`sigma ~ spray` (#1496) is not classified. DRModels.jl was not edited.

## Next action for the maintainer

Two items are still open and were not guessed here:

1. Whether the 25 Oct request for Poisson-equal location standard errors
   and `NA` for the phi standard error is still wanted after the 18 Nov
   rule. That edit is in the `sdreport` / `vcov` path.
2. Whether a `sigma` coefficient at the Poisson limit (`sigma ~ spray`,
   #1496) should use the same `"boundary"` status, and what numeric cut
   identifies that coefficient.
