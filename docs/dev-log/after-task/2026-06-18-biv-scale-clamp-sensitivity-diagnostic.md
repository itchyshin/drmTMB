# After Task: Bivariate Scale Clamp-Sensitivity Diagnostic

## Goal

Bank one conservative bivariate Gaussian `sigma1`/`sigma2` guard-sensitivity
artifact for the active `drmTMB#59` numerical-guard ledger.

## Implemented

The artifact
`docs/dev-log/simulation-artifacts/2026-06-18-biv-scale-clamp-sensitivity-diagnostic/`
adds a reproducible runner, CSV tables, run summary, session info, and README
for fixed-effect bivariate Gaussian scale cells. It compares the default
`log(sigma)` clamp, `logsigma_clamp = NULL`, and a wide
`logsigma_clamp = c(-25, 25)` band across ordinary scale, high `sigma1`, high
`sigma2`, and high-both-axis cells.

## Mathematical Contract

The fitted model is
`bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ z1, sigma2 = ~ z2, rho12 = ~ 1)`
with `family = biv_gaussian()`. `mu1` and `mu2` are locations. `sigma1` and
`sigma2` are residual scales on the two response axes. `rho12` is the residual
correlation, i.e. the coscale component for the bivariate Gaussian residual
covariance. The `log(sigma)` soft-clamp is a numerical overflow guard; if it
binds, the fit is guard-sensitive and should not be treated as an ordinary
scale estimate without inspection.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-18-biv-scale-clamp-sensitivity-diagnostic/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-18-biv-scale-clamp-sensitivity-diagnostic.md`

## Checks Run

- `air format docs/dev-log/simulation-artifacts/2026-06-18-biv-scale-clamp-sensitivity-diagnostic/run-pilot.R`
- `/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-18-biv-scale-clamp-sensitivity-diagnostic/run-pilot.R`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `git diff -U0 | rg -n 'CRAN ready|CRAN-ready|release ready|release-ready|coverage claim|power claim|calibrated interval|engine_control|AI-REML|Julia bridge parity|Julia-side algorithm|random effects in `rho12`|recovery accuracy|promote|promotion' || true`
- `rg -n "bivariate scale clamp|biv-scale|sigma1.*sigma2.*clamp|logsigma_clamp_active|383\\.851|16\\.500|16\\.341" docs/design/176-numerical-guard-simulation-audit.md docs/design/157-capability-completion-worklist.md docs/design/168-r-julia-finish-capability-matrix.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-18-biv-scale-clamp-sensitivity-diagnostic.md docs/dev-log/simulation-artifacts/2026-06-18-biv-scale-clamp-sensitivity-diagnostic/README.md`
- `rg -n 'bivariate scale.*(coverage|power|release|CRAN|Julia bridge|AI-REML|REML|recovery accuracy|random effects in `rho12`)|sigma1.*sigma2.*(coverage|power|release|CRAN|Julia bridge|AI-REML|REML|recovery accuracy)' README.md ROADMAP.md NEWS.md docs vignettes R tests || true`
- `rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs vignettes R tests || true`
- `Rscript --vanilla -e "pkgdown::check_pkgdown()"`

Results: the runner reproduced 120 requested fits, 0 fit errors, 120
optimizer-converged fits, 120 `pdHess = TRUE` fits, 30 clamp-active warnings,
34 fixed-gradient warnings, maximum reported `log(sigma1) = 16.500978`,
maximum reported `log(sigma2) = 16.341581`, and maximum absolute log
likelihood difference against the unclamped reference of `383.851973`. Both
dashboard JSON files parsed. Mission-control validation passed with `25/68
banked_or_verified`, `1 active`, `17 matrix rows`, `11 finish rows`, `15 Julia
gate rows`, and `9 Julia capability rows`. `git diff --check` passed. The
claim-boundary scan hit only explicit negative-boundary wording in the changed
files. The bivariate-scale scan found the intended artifact, dashboard,
design, worklist, check-log, and after-task references. The broader
bivariate-scale scan was noisy from existing roadmap and vignette guardrails,
but the new hits were diagnostic-only boundaries. The meta-analysis scan found
only existing `meta_V()` / deprecated `meta_known_V()` compatibility text and
intentional guardrails against `meta_gaussian()`, `tau ~`, and `rho ~`.
`pkgdown::check_pkgdown()` reported no problems.

## Tests Of The Tests

The pre-artifact probe first tried `family = gaussian()` and confirmed that the
univariate Gaussian route rejects `mu1`, `mu2`, `sigma1`, `sigma2`, and
`rho12`. The committed runner uses `family = biv_gaussian()`, the implemented
two-response Gaussian route. The final artifact includes ordinary cells where
the clamp should stay inactive and high-scale cells where the default clamp
should bind, plus off and wide controls that should match each other in the
audited cells.

## Consistency Audit

The numerical-guard audit, finish worklist, capability matrix, dashboard
status, sweep text, check-log entry, artifact README, and this report all keep
the claim diagnostic-only. The wording does not promote bivariate scale-route
recovery accuracy, interval coverage, power, q2/q4/q8 covariance readiness,
random effects in `rho12`, structured correlation readiness, release
readiness, CRAN readiness, Julia bridge parity, missing-data behavior, or
non-Gaussian REML/AI-REML.

## GitHub Issue Maintenance

No issue was closed. This remains evidence depth for the active
`drmTMB#59` numerical-guard sensitivity ledger.

## What Did Not Go Smoothly

The first probe used the wrong family. That was useful: it confirmed the
ordinary Gaussian route still rejects bivariate parameters, so the artifact
records the current supported syntax rather than relying on shorthand.

## Team Learning

The bivariate fixed-effect scale route mirrors the univariate fixed-effect
clamp story: the wide band and disabled guard match in these audited cells,
while the default guard leaves a visible warning and material fit differences
when it binds.

## Known Limitations

This is a 120-fit diagnostic artifact. It does not estimate coverage, power,
profile intervals, bootstrap intervals, or broader operating characteristics.
It does not test random effects, structured effects, missing responses, known
sampling covariance, or Julia bridge parity.

## Next Actions

Keep `drmTMB#59` active. The next safe guard slices remain larger
guard-sensitivity grids, Student-t calibration depth, interval consequences,
and additional random-effect or structured-correlation guard depth.
