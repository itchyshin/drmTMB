# After Task: Ordinary Q2 Correlation-Grid Diagnostic

## Goal

Extend the `drmTMB#59` numerical-guard ledger from a single q2 `mu`/`sigma`
covariance diagnostic to a small ordinary q2 fitted-boundary grid, while
keeping the claim diagnostic-only.

## Implemented

The artifact
`docs/dev-log/simulation-artifacts/2026-06-18-q2-correlation-grid-diagnostic/`
adds a self-contained runner and committed output tables for three already
fitted ordinary q2 covariance routes:

- univariate Gaussian `mu`/`sigma` random-intercept covariance;
- bivariate Gaussian `mu1`/`mu2` random-intercept covariance;
- bivariate Gaussian `sigma1`/`sigma2` random-intercept covariance.

Each route is crossed with true latent correlations 0, 0.4, 0.9, and 0.98.
The runner uses the default optimizer path and records warnings, failures,
convergence, `pdHess`, fixed gradients, log likelihood, AIC/BIC,
route-specific fitted correlations, boundary distances, and full
`check_drm()` rows.

## Mathematical Contract

The q2 covariance routes use the same open-interval transform family as other
latent correlations:

```r
rho = 0.999999 * tanh(eta)
```

The transform keeps fitted correlations inside `(-1, 1)`. This task does not
claim that one-replicate fitted correlations recover the true correlations.
It only checks whether fitted near-boundary status is visible in diagnostics.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-18-q2-correlation-grid-diagnostic/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-18-q2-correlation-grid-diagnostic.md`

No R package code, TMB likelihood, formula grammar, public API, example,
pkgdown navigation, or mission-control count changed.

## Checks Run

- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-18-q2-correlation-grid-diagnostic/run-pilot.R`
- `air format docs/dev-log/simulation-artifacts/2026-06-18-q2-correlation-grid-diagnostic/run-pilot.R`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `Rscript --vanilla - <<'RS' ... artifact consistency assertions ... RS`
- `git diff -U0 | rg -n 'CRAN ready|CRAN-ready|release ready|release-ready|coverage claim|power claim|calibrated interval|engine_control|AI-REML|Julia bridge parity|Julia-side algorithm|random effects in `rho12`|structured correlations|recovery accuracy|promote|promotion' || true`
- `Rscript --vanilla -e "pkgdown::check_pkgdown()"`

## Tests Of The Tests

The runner itself is the executable diagnostic: it fits all 12 route-cell
pairs and writes the observed diagnostic rows. The generated output includes
ordinary cells with no covariance warning, high or boundary cells with
route-specific covariance warnings, and four fixed-gradient warnings. The
bivariate `sigma1`/`sigma2` true `rho = 0.98` cell fit back to `rho = 0.9031`
and therefore did not warn, which proves the artifact is recording fitted
boundary status rather than assuming true-boundary recovery.

## Consistency Audit

The numerical-guard audit, finish capability worklist, R-Julia finish matrix,
mission-control status, dashboard sweep, and check log now name the ordinary q2
correlation-grid diagnostic. The wording keeps recovery accuracy, interval
coverage, power, structured correlations, q4/q8 covariance intervals, random
effects in `rho12`, Julia bridge parity, release readiness, CRAN readiness, and
non-Gaussian REML/AI-REML out of scope.

## GitHub Issue Maintenance

No issue was closed. `drmTMB#59` remains open as the parent numerical-guard
and simulation evidence ledger. I did not add a GitHub issue comment in this
local slice; the focused PR should add the public breadcrumb after CI evidence
exists.

## What Did Not Go Smoothly

The first generated run used seed values adjacent to the probe seeds and the
route-summary helper summed quantities that should have been min/max
summaries. I corrected the runner, regenerated the artifact, and kept the
final committed tables tied to the fixed script.

## Team Learning

Curie and Fisher should treat this as visibility evidence only. A fitted
boundary warning can appear in a high-correlation cell, but a true boundary
cell can also fit back away from the boundary. That is exactly why broad
recovery, coverage, and interval claims still need deliberately sized grids.

## Known Limitations

This is a 12-fit diagnostic pilot with one replicate per route-cell pair. It
does not estimate bias, RMSE, coverage, power, Monte Carlo standard error, or
runtime distributions. It does not exercise structured covariance, q4/q8
covariance, random effects in `rho12`, non-Gaussian covariance, profile
intervals, bootstrap intervals, or Julia bridge parity.

## Next Actions

Open a focused PR for this diagnostic artifact after the remaining local
package checks pass. After that PR is green and merged, the next safe
`drmTMB#59` slice is still design/evidence depth, not promotion: either
structured q2 boundary visibility or a deliberately sized calibration pilot for
one of the already banked guard classes.
