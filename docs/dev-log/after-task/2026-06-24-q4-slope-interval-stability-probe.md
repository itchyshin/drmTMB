# After Task: Q4 All-Four One-Slope Interval Stability Probe

## Goal

Run a deterministic follow-up Hessian-stability probe for the exact
shared-label bivariate Gaussian all-four one-slope q8-shaped structured cells
in `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()`.

## Implemented

- Added `tools/run-structured-re-q4-slope-interval-stability-probe.R`.
- Added
  `docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-stability-probe/structured-re-q4-slope-interval-stability-probe-results.tsv`
  with 128 method rows: 2 variants times 4 providers times 8 direct-SD targets
  times Wald/profile.
- Added
  `docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv`
  with 64 direct-SD stability rows.
- Wired the new sidecar into mission-control validation and
  `test-structured-re-conversion-contracts.R`.
- Updated the dashboard README and q-series completion map.

All eight provider-variant fits converged, but all eight returned
`pdHess = FALSE`. The sidecar therefore records all Wald/profile method rows as
`not_run_pdhess_false`. This is negative diagnostic evidence, not interval
readiness.

## Mathematical Contract

The probe keeps the same q8-shaped all-four structured covariance block used by
the q4 slope fixture and smoke status:

`mu1 + mu2 + sigma1 + sigma2` each carry `1 + x` structured random effects with
the same labelled grouping factor `p`. Direct-SD targets are the eight endpoint
members `mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x`,
`sigma1:(Intercept)`, `sigma1:x`, `sigma2:(Intercept)`, and `sigma2:x`.

The `strong` design uses 8 levels with 24 observations per level and larger
latent SDs. The `more_levels` design uses 16 levels with 12 observations per
level. Wald/profile intervals are attempted only when the fitted Hessian is
positive definite.

## Files Changed

- `tools/run-structured-re-q4-slope-interval-stability-probe.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-stability-probe/structured-re-q4-slope-interval-stability-probe-results.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-24-q4-slope-interval-stability-probe.md`

## Checks Run

- `Rscript --vanilla tools/run-structured-re-q4-slope-interval-stability-probe.R`
  passed and wrote the artifact/status TSVs. The run reported 7 fallback
  optimizer warnings; the status sidecar records every provider-variant fit as
  converged but Hessian-blocked.
- `Rscript --vanilla -e 'x<-read.delim("docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv", sep="\t", quote="", check.names=FALSE); print(dim(x)); print(table(x$variant, x$structured_type)); print(table(x$n_fit_ok, x$n_pdhess, x$stability_status)); y<-read.delim("docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-stability-probe/structured-re-q4-slope-interval-stability-probe-results.tsv", sep="\t", quote="", check.names=FALSE); print(dim(y)); print(table(y$interval_method, y$method_status));'`
  reported 64 sidecar rows, 128 method rows, and all rows as
  `pdhess_blocked` / `not_run_pdhess_false`.
- `air format tools/run-structured-re-q4-slope-interval-stability-probe.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 2791 assertions.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 64
  structured RE q4 slope interval-stability probe rows.
- `git diff --check` passed.
- The q4-slope interval overclaim scan for unsupported interval, coverage,
  REML, AI-REML, and supported-status wording returned no hits.

## Tests Of The Tests

The new R contract test checks the sidecar row count, the 128 method rows, both
variant designs, all eight direct-SD targets per provider, the `sd:mu:sigma*`
profile-target identity for sigma endpoints, zero positive-definite Hessians,
and the diagnostic-only claim boundary. It would fail if the stability probe
silently moved to interval-ready wording or if the plan and stability sidecar
stopped agreeing on targets.

## Consistency Audit

The dashboard README, q-series completion map, mission-control validator,
conversion-contract test, check log, and after-task note now distinguish the
first q4 direct-SD smoke from the follow-up Hessian-stability probe. Both
artifacts report the same current boundary: q4 all-four one-slope direct-SD
targets are point-fit and extractor/fixture ready, but interval diagnostics are
Hessian-blocked.

## GitHub Issue Maintenance

No GitHub issue was opened or updated in this slice. The work is internal
dashboard evidence for the active q-series completion lane and remains inside
the draft PR branch.

## What Did Not Go Smoothly

The first summary command used shell double quotes around `x$variant`, so the
shell expanded `$variant` before R saw the expression. Rerunning with single
quotes fixed the summary. The statistical result itself was also negative:
neither stronger signal nor more levels opened the q4 Hessian gate.

## Team Learning

For q4 all-four one-slope cells, increasing signal strength and adding levels
are not sufficient by themselves to make direct-SD interval diagnostics
available. The next efficient slice should inspect Hessian geometry and
parameterization before spending time on denominator or coverage machinery.

## Known Limitations

This slice does not admit coverage denominators, claim q4 interval reliability,
claim q4 interval coverage, promote q4 REML, native-TMB q4 REML, q4 AI-REML,
HSquared AI-REML, non-Gaussian REML, broad bridge support, public optimizer
controls, DRAC execution, SR150 coverage readiness, PR undrafting/merging, or
an Ayumi-facing reply.

## Next Actions

Diagnose the persistent q4 all-four one-slope Hessian failures before any
denominator accounting or coverage-grid design. The likely next slice is a
Hessian-geometry audit that separates boundary SD estimates from covariance
parameterization and optimizer fallback behavior.
