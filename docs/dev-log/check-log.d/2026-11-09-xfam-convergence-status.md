# Cross-family convergence status

Goal: stop `is_converged()` returning `FALSE` for every cross-family Julia fit.

Commands: `devtools::test(filter = "xfam|convergence|check")`, plus
`tests/testthat/test-xfam-bridge.R` with `NOT_CRAN=true` and
`DRMODELS_JL_PATH` set to a DRM.jl worktree at `0bfcde2bb` (Julia 1.12.6, one
thread, private depot).

Results: before the fix the live file had seven failures (four on the
convergence flag, three on the NB2 by Gaussian profile interval). After the fix the four convergence-flag failures are gone and three NB2 by Gaussian interval assertions still fail (NaN upper bound; Julia side, unchanged). The filtered offline suite passed 499 expectations with 0 failures and 7 skips.

Claim boundary: the flag now follows the optimizer and log-likelihood for a
point-estimate-only route. No claim about standard errors or intervals.
