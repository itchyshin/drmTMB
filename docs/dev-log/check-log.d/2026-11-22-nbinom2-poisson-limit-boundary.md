# Check log: nbinom2 Poisson limit is boundary (refs #1535)

**Date:** 2026-11-22
**Branch:** `claude/d-nbinom2-boundary-1535-20261120`

## Goal

Finish the draft slice that classifies a plain fixed-effect `nbinom2()`
fit at the Poisson limit as `convergence_status() == "boundary"`. Merge
`origin/main`. Leave the shared converged rule as Shinichi stated it on
18 Nov 2026 (#1554): a dispersion at its limit is `boundary`, and
`is_converged()` is `TRUE` only for `"converged"`.

## Change

`origin/main` (`a8c034388`) merged cleanly. `R/check.R` auto-merged; the
intercept-only classifier (`log sigma <= -8`, before the inflated-SE
screen, after the optimiser gate, and still deferring to rank deficiency
and the MLE-existence screen) is unchanged. Added the `NEWS.md` bullet,
the `?convergence_status` sentence, and the matching paragraph in
`docs/design/278-twin-convergence-status.md`.

## Verification

R 4.3.3. Package installed with `R CMD INSTALL` into a user library
(TMB  from CRAN, compiled `-j1`). `devtools` 2.5.2 did not install
(`pkgdown` is an Import and was not built). The run is
`testthat::test_local()`, which is the test runner `devtools::test()`
calls after `pkgload::load_all()`.

```sh
R_LIBS_USER="$HOME/R/library" Rscript -e \
  'testthat::test_local(".", filter = "convergence-status-twin|mle-existence|julia-convergence-status-parity", load_package = "source")'
python3 -m unittest tools.tests.test_capability_ledger -q
```

| Check | Result |
| --- | --- |
| `test-convergence-status-twin.R` | 41 expectations, 0 failed (includes `HSAUR3::bladdercancer`) |
| `test-mle-existence.R` | 39 expectations, 0 failed (all-zero `nbinom2` stays `"degenerate"`) |
| `test-julia-convergence-status-parity.R` | 4 passed, 2 skipped (no Julia) |
| Total | FAIL 0, PASS 84, SKIP 2 |
| `tools/tests/test_capability_ledger.py` | 92 tests, OK |

No test expectation, tolerance, guard, cap, timeout, ledger value, or
reference number was moved.

## Claim boundary

Covariate `sigma` formulas, the limit-conditioned location covariance,
and the Julia twin are unchanged. The printed sigma standard error is
still the Wald value from `sdreport()`.
