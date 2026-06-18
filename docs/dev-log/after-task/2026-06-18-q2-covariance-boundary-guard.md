# After Task: Q2 Covariance Boundary Guard Diagnostic

## Goal

Make q2 random-effect covariance correlations near `+/-1` visible to users and
bank a narrow diagnostic artifact for the `drmTMB#59` numerical-guard
sensitivity row.

## Implemented

`check_drm()` now threads `rho_boundary` into q2 random-effect covariance
diagnostics. Univariate Gaussian `mu`/`sigma`, bivariate Gaussian `mu1`/`mu2`,
bivariate Gaussian `sigma1`/`sigma2`, and bivariate same-response
`mu`/`sigma` covariance rows now print `rho_abs` and `boundary`; rows with
non-finite or near-boundary fitted correlations report `warning`.

The artifact
`docs/dev-log/simulation-artifacts/2026-06-18-q2-covariance-boundary-guard/`
adds a source transform grid and a four-cell fitted diagnostic for univariate
Gaussian `mu`/`sigma` covariance with true correlations 0, 0.4, 0.9, and 0.98.
The runner uses the default optimizer path and records warnings, failures,
convergence, `pdHess`, gradients, log likelihood, AIC/BIC, and full
`check_drm()` rows.

## Mathematical Contract

The fitted q2 covariance route uses the same open-interval transform family as
other latent correlations:

```r
rho = 0.999999 * tanh(eta)
```

This transform keeps the covariance matrix inside `(-1, 1)`. It does not make a
near-boundary covariance inferentially reliable. A fitted correlation close to
`+/-1` is now a diagnostic warning, even when the optimizer converges and
`pdHess = TRUE`.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `tests/testthat/test-biv-gaussian.R`
- `NEWS.md`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/simulation-artifacts/2026-06-18-q2-covariance-boundary-guard/`

## Checks Run

- `/usr/local/bin/Rscript --vanilla /tmp/drmtmb-re-correlation-probe.R`
- `/usr/local/bin/Rscript --vanilla -e "devtools::test(filter = '^check-drm$', reporter = 'summary')"`
- `/usr/local/bin/Rscript --vanilla -e "devtools::test(filter = '^(check-drm|biv-gaussian)$', reporter = 'summary')"`
- `/opt/homebrew/bin/air format R/check.R tests/testthat/test-check-drm.R tests/testthat/test-biv-gaussian.R`
- `/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-18-q2-covariance-boundary-guard/run-pilot.R`
- `cd /tmp && /usr/local/bin/Rscript --vanilla /Users/z3437171/.codex/worktrees/1d33/drmTMB/docs/dev-log/simulation-artifacts/2026-06-18-q2-covariance-boundary-guard/run-pilot.R`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `git diff --check`

## Tests Of The Tests

The pre-fix probe showed a fitted `mu`/`sigma` q2 covariance at true
`rho = 0.98` returning `rho = 0.999999`, convergence, and `pdHess = TRUE` while
the old `check_drm()` row still reported `ok`. The new tests mutate already
fitted q2 covariance objects to `rho = 0.995` and require a warning, printed
boundary value, and `attr(chk, "ok") = FALSE`.

## Consistency Audit

The numerical-guard audit, finish matrix, worklist, dashboard status, sweep,
NEWS, and this after-task report now name the q2 covariance diagnostic. The
wording stays diagnostic-only and keeps residual `rho12`, random effects in
`rho12`, bivariate q2 breadth, q4/q8 covariance intervals, structured
correlations, Julia bridge parity, release readiness, CRAN readiness, and
non-Gaussian REML/AI-REML out of scope.

## GitHub Issue Maintenance

No issue was closed. This remains part of the active `drmTMB#59`
numerical-guard sensitivity ledger.

## What Did Not Go Smoothly

The first focused test run caught one missing `rho_boundary` argument in the
legacy multi-row univariate `mu`/`sigma` helper. The patch now threads the same
threshold through both registry and legacy q2 covariance paths.

## Team Learning

Hao's concern was right in the most practical sense: convergence plus a
positive Hessian is not enough when a fitted covariance reaches the numerical
guard. The diagnostic row must show the intervention boundary before any
downstream artifact interprets the fit.

## Known Limitations

This artifact is a four-cell diagnostic, not a recovery or calibration grid.
The zero-correlation cell is noisy in one replicate, so the artifact should not
be read as q2 covariance accuracy evidence. It only proves that a fitted
near-boundary q2 `mu`/`sigma` covariance is now visible in `check_drm()`.

## Next Actions

Rebase this branch after the post-#622 dashboard refresh merges, run the local
validation suite, then open a focused PR. The next numerical-guard slice can
extend the same boundary-visibility pattern to structured q2 covariance or
design a deliberately larger random-effect correlation grid.
