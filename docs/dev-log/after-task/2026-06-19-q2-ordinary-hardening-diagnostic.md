# After Task: Ordinary q2 Covariance Hardening Diagnostic

## Goal

Bank the second Big 4 implementation block after the post-#633 decision
ledger: a larger native R/TMB ordinary q2 covariance diagnostic for
`drmTMB#59`.

## Implemented

The implemented claim is narrow: the repository now has a reproducible
diagnostic artifact for ordinary q2 fitted-boundary visibility and
route-specific recovery screening across univariate same-response
`mu`/`sigma`, bivariate `mu1`/`mu2`, and bivariate `sigma1`/`sigma2`
random-intercept covariance routes.

This is not a package-code change. It is an evidence and status update for the
numerical-guard programme.

## Mathematical Contract

The primary grid is complete-data Gaussian only. It uses seven true latent
random-effect correlations: `-0.95`, `-0.80`, `0`, `0.40`, `0.80`, `0.95`,
and `0.98`. Each route-cell has 100 replicates.

The fitted routes are:

```r
bf(y ~ x + f + (1 | p | id), sigma ~ z + f + (1 | p | id))

bf(
  mu1 = y1 ~ x + f + (1 | p | id),
  mu2 = y2 ~ x + f + (1 | p | id),
  sigma1 = ~ 1,
  sigma2 = ~ 1,
  rho12 = ~ 1
)

bf(
  mu1 = y1 ~ x + f,
  mu2 = y2 ~ x + f,
  sigma1 = ~ z + f + (1 | p | id),
  sigma2 = ~ z + f + (1 | p | id),
  rho12 = ~ 1
)
```

The route is ordinary q2 random-effect covariance. It does not include
structured `spatial()`, `animal()`, or `relmat()` terms, q4/q8 covariance,
profile intervals, bootstrap intervals, random effects in residual `rho12`,
direct Julia, or Julia-via-R.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-19-q2-ordinary-hardening-diagnostic/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/177-big4-finish-plan-2026-06-19.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-19-q2-ordinary-hardening-diagnostic.md`

## Checks Run

```sh
air format docs/dev-log/simulation-artifacts/2026-06-19-q2-ordinary-hardening-diagnostic/run-pilot.R
DRMTMB_Q2_N_REP=1 /usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-q2-ordinary-hardening-diagnostic/run-pilot.R
/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-q2-ordinary-hardening-diagnostic/run-pilot.R
```

The full-run assertion command is recorded in
`docs/dev-log/check-log.md`. It checked the 2100-fit denominator, required
tables, native R/TMB evidence-lane fields, absent profile/bootstrap requests,
absent structured routes, absent random residual `rho12`, absent fallback
optimizer, and route-specific `check_drm()` rows.

## Tests Of The Tests

The one-replicate smoke run verified that the new runner could write all tables,
carry evidence-lane fields, record separated missing-response smoke rows, and
parse route-specific `check_drm()` rows before the full 2100-fit run.

The full-run assertions protect the main denominators and boundary fields:
2100 requested and attempted complete-data primary fits, 0 fit errors, 2100
optimizer-converged fits, 2100 `pdHess = TRUE` fits, three required
route-specific covariance checks, and explicit `FALSE`/`NA` intervention fields
for profile, bootstrap, structured routes, random residual `rho12`, direct
Julia, and Julia-via-R.

## Consistency Audit

The q2 artifact updates diagnostic evidence only. It does not alter TMB source,
formula grammar, user-facing functions, examples, pkgdown navigation, or tests.
The dashboard and finish-plan files now describe this as native R/TMB
diagnostic evidence only.

The separate missing-response smoke rows record complete-case dropping for one
moderate cell per route. They are intentionally not included in the primary q2
recovery or status summaries, so the complete-data and missing-data boundaries
remain separate.

## GitHub Issue Maintenance

The active issue remains `drmTMB#59`, "Phase 18: comprehensive simulation
framework and reporting". The post-block breadcrumb was posted here:
https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4752175161.

The breadcrumb records the artifact path, 2100-fit denominator, route-level
warning and gradient summaries, validation commands, served mission-control
refresh, and the boundary that this is native R/TMB diagnostic evidence only.

## What Did Not Go Smoothly

The full 2100-fit runner took about 63 minutes and emitted no progress until
completion. The process was healthy and CPU-bound when checked, but the lack of
route/cell progress output made the run hard to supervise. Future long
simulation runners should print compact progress after each route-cell.

The result was also rougher than a simple convergence story. All primary fits
converged with `pdHess = TRUE`, but fixed-gradient ok counts were only 274/700
for `biv_mu` and 360/700 for `biv_sigma`, and fitted-minus-true correlation
errors were large in some `biv_sigma` cells. The artifact therefore cannot be
used as ordinary q2 promotion evidence.

## Team Learning

For q2 covariance routes, positive-Hessian status is not enough. The durable
status row needs route-specific covariance warnings, fixed-gradient status,
fitted-minus-true correlation errors, fitted boundary distance, and optimizer
intervention fields together.

Curie's larger denominator made the status rates interpretable, Fisher's review
kept "hardening" from becoming "validated", and Grace's metadata checklist made
the R/TMB, direct Julia, and Julia-via-R boundaries explicit in the artifact.

## Known Limitations

This artifact does not support interval coverage, power, structured q2,
q4/q8 covariance, random effects in residual `rho12`, direct Julia parity,
Julia-via-R bridge parity, selectable Julia `engine_control`, release
readiness, CRAN readiness, missing-data recovery, or non-Gaussian REML/AI-REML.

## Next Actions

Before moving to q8 endpoint hardening, treat ordinary q2 as banked
diagnostic evidence only. The next q8 block should stay native R/TMB and
endpoint-status focused unless a separate bridge issue is opened.
